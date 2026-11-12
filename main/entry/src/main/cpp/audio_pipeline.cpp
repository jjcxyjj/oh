// SPDX-License-Identifier: Apache-2.0
#include "audio_pipeline.h"
#include "wav_io.h"
#include <ohaudiosuite/native_audio_suite_engine.h>
#include <chrono>
#include <memory>
#include <mutex>

namespace {
void Check(OH_AudioSuite_Result code,const char* operation) {
    Require(code==AUDIOSUITE_SUCCESS,std::string(operation)+" 失败，AudioSuite code="+std::to_string(code));
}
#define AS(call) Check((call),#call)
int32_t RequestPcm(OH_AudioNode*,void* user,void* buffer,int32_t size,bool* finished) {
    return user ? static_cast<PcmReader*>(user)->Read(buffer,size,finished) : -1;
}
// 管线拥有节点，离开作用域时停止并释放。输入 reader 的寿命必须长于管线。
class Pipeline {
    OH_AudioSuiteEngine* engine_=nullptr;
    OH_AudioNodeBuilder* builder_=nullptr;
    std::vector<OH_AudioNode*> nodes_;
public:
    OH_AudioSuitePipeline* handle=nullptr;
    bool started=false;
    void Init() {
        AS(OH_AudioSuiteEngine_Create(&engine_));
        AS(OH_AudioSuiteEngine_CreatePipeline(engine_,&handle,AUDIOSUITE_PIPELINE_EDIT_MODE));
        AS(OH_AudioSuiteNodeBuilder_Create(&builder_));
    }
    ~Pipeline() {
        if(started) OH_AudioSuiteEngine_StopPipeline(handle);
        for(auto it=nodes_.rbegin();it!=nodes_.rend();++it) OH_AudioSuiteEngine_DestroyNode(*it);
        if(builder_) OH_AudioSuiteNodeBuilder_Destroy(builder_);
        if(handle) OH_AudioSuiteEngine_DestroyPipeline(handle);
        if(engine_) OH_AudioSuiteEngine_Destroy(engine_);
    }
    OH_AudioNode* Node(OH_AudioNode_Type type,PcmReader* reader=nullptr) {
        bool supported=false;AS(OH_AudioSuiteEngine_IsNodeTypeSupported(type,&supported));
        Require(supported,"当前设备不支持节点 "+std::to_string(type)+"；不会使用预生成结果替代");
        AS(OH_AudioSuiteNodeBuilder_Reset(builder_));AS(OH_AudioSuiteNodeBuilder_SetNodeType(builder_,type));
        if(type==INPUT_NODE_TYPE_DEFAULT || type==OUTPUT_NODE_TYPE_DEFAULT) {
            OH_AudioFormat f{};f.samplingRate=SAMPLE_RATE_48000;f.channelLayout=CH_LAYOUT_STEREO;
            f.channelCount=2;f.sampleFormat=AUDIO_SAMPLE_S16LE;f.encodingType=AUDIO_ENCODING_TYPE_RAW;
            AS(OH_AudioSuiteNodeBuilder_SetFormat(builder_,f));
        }
        if(reader) AS(OH_AudioSuiteNodeBuilder_SetRequestDataCallback(builder_,RequestPcm,reader));
        OH_AudioNode* n=nullptr;AS(OH_AudioSuiteEngine_CreateNode(handle,builder_,&n));nodes_.push_back(n);return n;
    }
    void Connect(OH_AudioNode* a,OH_AudioNode* b) { AS(OH_AudioSuiteEngine_ConnectNodes(a,b)); }
    OH_AudioNode* Equalizer(OH_AudioNode* source,int preset) {
        auto eq=Node(EFFECT_NODE_TYPE_EQUALIZER);
        const int gains[3][10]={{0,0,0,0,0,0,0,0,0,0},{-8,-6,-4,-2,0,2,2,0,-2,-4},{5,4,3,1,0,-1,-2,-2,-3,-4}};
        OH_EqualizerFrequencyBandGains g{};std::copy(gains[preset],gains[preset]+10,g.gains);
        AS(OH_AudioSuiteEngine_SetEqualizerFrequencyBandGains(eq,g));Connect(source,eq);return eq;
    }
    // 分离节点必须使用 MultiRenderFrame，两块缓存分别接收人声、背景声。
    void Render(WavWriter& first,WavWriter* second=nullptr) {
        AS(OH_AudioSuiteEngine_StartPipeline(handle));started=true;
        std::array<unsigned char,3840> a{},b{};
        void* buffers[]={a.data(),b.data()};OH_AudioDataArray multi{buffers,2,3840};
        bool finished=false;int frames=0;
        while(!finished) {
            Require(++frames<=10000,"渲染超过帧数上限");int32_t count=0;
            if(second) { AS(OH_AudioSuiteEngine_MultiRenderFrame(handle,&multi,&count,&finished)); }
            else { AS(OH_AudioSuiteEngine_RenderFrame(handle,a.data(),a.size(),&count,&finished)); }
            Require(count>=0 && count<=3840 && count%4==0 && (count>0 || finished),"无效渲染帧或渲染无进展");
            first.Append(a.data(),count);if(second) second->Append(b.data(),count);
        }
        AS(OH_AudioSuiteEngine_StopPipeline(handle));started=false;
        first.Commit();if(second) second->Commit();
    }
};
void Separate(const std::string& input,const std::string& vocal,const std::string& background) {
    PcmReader a(input);WavWriter v(vocal),b(background);Pipeline p;p.Init();
    auto source=p.Node(INPUT_NODE_TYPE_DEFAULT,&a);
    auto separation=p.Node(EFFECT_MULTII_OUTPUT_NODE_TYPE_AUDIO_SEPARATION);
    auto output=p.Node(OUTPUT_NODE_TYPE_DEFAULT);
    p.Connect(source,separation);p.Connect(separation,output);p.Render(v,&b);
}
void ProcessGraph(const RenderJob& job,const std::string& aPath,const std::string& bPath,
                  const std::string& output,bool mix,bool cascade) {
    PcmReader a(aPath,mix?job.gainA:1.0);
    std::unique_ptr<PcmReader> b;if(mix) b=std::make_unique<PcmReader>(bPath,job.gainB);
    WavWriter writer(output);Pipeline p;p.Init();
    auto tail=p.Node(INPUT_NODE_TYPE_DEFAULT,&a);
    if(!mix || cascade) tail=p.Equalizer(tail,job.preset);
    if(cascade) {
        auto field=p.Node(EFFECT_NODE_TYPE_SOUND_FIELD);
        AS(OH_AudioSuiteEngine_SetSoundFieldType(field,SOUND_FIELD_FRONT_FACING));
        p.Connect(tail,field);tail=field;
    }
    if(mix) {
        auto sourceB=p.Node(INPUT_NODE_TYPE_DEFAULT,b.get());auto mixer=p.Node(EFFECT_NODE_TYPE_AUDIO_MIXER);
        p.Connect(tail,mixer);p.Connect(sourceB,mixer);tail=mixer;
    }
    auto outputNode=p.Node(OUTPUT_NODE_TYPE_DEFAULT);p.Connect(tail,outputNode);p.Render(writer);
}
}
void RunAudioJob(RenderJob& job) {
    static std::mutex mutex;std::lock_guard<std::mutex> lock(mutex);
    auto start=std::chrono::steady_clock::now();std::vector<std::string> created;
    try {
        Require(job.mode>=0 && job.mode<=4 && job.preset>=0 && job.preset<=2,"无效任务或 EQ 预设");
        Require(std::isfinite(job.gainA) && std::isfinite(job.gainB) && job.gainA>=0 && job.gainA<=1 &&
            job.gainB>=0 && job.gainB<=1,"两路增益必须在 0–1 之间");
        std::string result=job.prefix+"-result.wav",vocal=job.prefix+"-vocals.wav",back=job.prefix+"-background.wav";
        for(const auto& path:{result,vocal,back}) {
            Require(path!=job.inputA && path!=job.inputB,"输出不可覆盖输入");
            FILE* existing=fopen(path.c_str(),"rb");if(existing) fclose(existing);
            Require(!existing,"输出已经存在，请使用新的任务前缀");
        }
        if(job.mode==1 || job.mode==4) {
            created={vocal,back};Separate(job.inputA,vocal,back);
            job.paths={vocal,back};job.labels={"分离人声","分离背景声"};
        }
        if(job.mode!=1) {
            created.push_back(result);
            if(job.mode==4) ProcessGraph(job,vocal,back,result,true,true);
            else ProcessGraph(job,job.inputA,job.inputB,result,job.mode>=2,job.mode==3);
            job.paths.push_back(result);job.labels.push_back(job.mode==4?"分离后重新混音":"处理结果");
        }
        job.elapsedMs=std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now()-start).count();
    } catch(const std::exception& error) {
        job.error=error.what();job.paths.clear();job.labels.clear();
        for(const auto& path:created) {remove(path.c_str());remove((path+".part").c_str());}
    } catch(...) {job.error="未知原生异常";}
}
