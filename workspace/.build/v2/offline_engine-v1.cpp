// OfflineAudioLab. Derived from Huawei AudioSuite manual rendering flow.
// SPDX-License-Identifier: Apache-2.0
#include <napi/native_api.h>
#include <ohaudiosuite/native_audio_suite_engine.h>
#include <algorithm>
#include <array>
#include <cstdio>
#include <cstring>
#include <memory>
#include <string>
#include <vector>
#include <chrono>

struct Pipeline {
    OH_AudioSuiteEngine* engine = nullptr;
    OH_AudioSuitePipeline* pipe = nullptr;
    OH_AudioNodeBuilder* builder = nullptr;
    std::vector<OH_AudioNode*> nodes;
    bool started = false;
    ~Pipeline() {
        if (started) OH_AudioSuiteEngine_StopPipeline(pipe);
        for (auto it = nodes.rbegin(); it != nodes.rend(); ++it) OH_AudioSuiteEngine_DestroyNode(*it);
        if (builder) OH_AudioSuiteNodeBuilder_Destroy(builder);
        if (pipe) OH_AudioSuiteEngine_DestroyPipeline(pipe);
        if (engine) OH_AudioSuiteEngine_Destroy(engine);
    }
};
struct Input { FILE* file; };
static int32_t Read(OH_AudioNode*, void* user, void* buffer, int32_t size, bool* finished) {
    if (!user || !buffer || !finished || size <= 0) return -1;
    FILE* f = static_cast<Input*>(user)->file;
    size_t count = fread(buffer, 1, size, f);
    *finished = feof(f);
    return ferror(f) ? -1 : static_cast<int32_t>(count);
}
static void U32(unsigned char* p, uint32_t n) { for (int i=0;i<4;++i) p[i]=(n>>(8*i))&255; }
static std::array<unsigned char,44> Header(uint32_t bytes) {
    std::array<unsigned char,44> h{};
    memcpy(h.data(),"RIFF",4); U32(h.data()+4,bytes+36); memcpy(h.data()+8,"WAVEfmt ",8);
    U32(h.data()+16,16); h[20]=1; h[22]=2; U32(h.data()+24,48000); U32(h.data()+28,192000);
    h[32]=4; h[34]=16; memcpy(h.data()+36,"data",4); U32(h.data()+40,bytes); return h;
}
struct Job { napi_async_work work{}; napi_deferred deferred{}; std::string input, output, error, result; int preset=0; };
#define CHECK(call) do { auto code=(call); if(code!=AUDIOSUITE_SUCCESS) return std::string(#call)+" failed: "+std::to_string(code); } while(0)
static std::string Process(Job& job) {
    using File = std::unique_ptr<FILE, decltype(&fclose)>;
    File in(fopen(job.input.c_str(),"rb"),fclose);
    if(!in) return "Cannot open input PCM";
    if(fseek(in.get(),0,SEEK_END)!=0) return "Cannot seek input";
    long length=ftell(in.get()); rewind(in.get());
    if(length<=0 || length%4 || length>192000*120) return "Input must be 48kHz stereo S16LE PCM, 0-120 seconds";
    const std::string temp=job.output+".part";
    File out(fopen(temp.c_str(),"wb"),fclose);
    if(!out) return "Cannot create output";
    auto header=Header(0);
    if(fwrite(header.data(),1,44,out.get())!=44) return "WAV header write failed";
    Pipeline p; Input input{in.get()};
    CHECK(OH_AudioSuiteEngine_Create(&p.engine));
    CHECK(OH_AudioSuiteEngine_CreatePipeline(p.engine,&p.pipe,AUDIOSUITE_PIPELINE_EDIT_MODE));
    CHECK(OH_AudioSuiteNodeBuilder_Create(&p.builder));
    OH_AudioFormat format{};
    format.samplingRate=SAMPLE_RATE_48000; format.channelLayout=CH_LAYOUT_STEREO;
    format.channelCount=2; format.sampleFormat=AUDIO_SAMPLE_S16LE; format.encodingType=AUDIO_ENCODING_TYPE_RAW;
    OH_AudioNode* source=nullptr; OH_AudioNode* eq=nullptr; OH_AudioNode* sink=nullptr;
    CHECK(OH_AudioSuiteNodeBuilder_SetNodeType(p.builder,INPUT_NODE_TYPE_DEFAULT));
    CHECK(OH_AudioSuiteNodeBuilder_SetFormat(p.builder,format));
    CHECK(OH_AudioSuiteNodeBuilder_SetRequestDataCallback(p.builder,Read,&input));
    CHECK(OH_AudioSuiteEngine_CreateNode(p.pipe,p.builder,&source)); p.nodes.push_back(source);
    bool supported=false;
    CHECK(OH_AudioSuiteEngine_IsNodeTypeSupported(EFFECT_NODE_TYPE_EQUALIZER,&supported));
    if(!supported) return "Device does not support the equalizer node";
    CHECK(OH_AudioSuiteNodeBuilder_Reset(p.builder));
    CHECK(OH_AudioSuiteNodeBuilder_SetNodeType(p.builder,EFFECT_NODE_TYPE_EQUALIZER));
    CHECK(OH_AudioSuiteEngine_CreateNode(p.pipe,p.builder,&eq)); p.nodes.push_back(eq);
    const int values[3][10]={{0,0,0,0,0,0,0,0,0,0},{-8,-6,-4,-2,0,2,2,0,-2,-4},{5,4,3,1,0,-1,-2,-2,-3,-4}};
    OH_EqualizerFrequencyBandGains gains{};
    std::copy(values[job.preset],values[job.preset]+10,gains.gains);
    CHECK(OH_AudioSuiteEngine_SetEqualizerFrequencyBandGains(eq,gains));
    CHECK(OH_AudioSuiteNodeBuilder_Reset(p.builder));
    CHECK(OH_AudioSuiteNodeBuilder_SetNodeType(p.builder,OUTPUT_NODE_TYPE_DEFAULT));
    CHECK(OH_AudioSuiteNodeBuilder_SetFormat(p.builder,format));
    CHECK(OH_AudioSuiteEngine_CreateNode(p.pipe,p.builder,&sink)); p.nodes.push_back(sink);
    CHECK(OH_AudioSuiteEngine_ConnectNodes(source,eq)); CHECK(OH_AudioSuiteEngine_ConnectNodes(eq,sink));
    CHECK(OH_AudioSuiteEngine_StartPipeline(p.pipe)); p.started=true;
    std::array<unsigned char,3840> buffer{};
    bool finished=false; uint32_t bytes=0; int frames=0;
    auto start=std::chrono::steady_clock::now();
    while(!finished) {
        if(++frames>10000) return "Render frame limit reached";
        int32_t count=0;
        CHECK(OH_AudioSuiteEngine_RenderFrame(p.pipe,buffer.data(),buffer.size(),&count,&finished));
        if(count<0 || count>static_cast<int>(buffer.size()) || count%4 || (!count&&!finished)) return "Invalid render frame";
        if(fwrite(buffer.data(),1,count,out.get())!=static_cast<size_t>(count)) return "Audio write failed";
        bytes+=count;
    }
    CHECK(OH_AudioSuiteEngine_StopPipeline(p.pipe)); p.started=false;
    if(!bytes) return "Empty rendered audio";
    header=Header(bytes);
    if(fseek(out.get(),0,SEEK_SET)!=0 || fwrite(header.data(),1,44,out.get())!=44) return "WAV finalization failed";
    if(fclose(out.release())!=0) return "Output close failed";
    if(rename(temp.c_str(),job.output.c_str())!=0) return "Output commit failed";
    auto ms=std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now()-start).count();
    job.result="完成 · "+std::to_string(bytes)+" bytes · "+std::to_string(ms)+" ms";
    return "";
}
static void Execute(napi_env, void* data) {
    auto& j=*static_cast<Job*>(data); j.error=Process(j);
    if(!j.error.empty()) remove((j.output+".part").c_str());
}
static void Complete(napi_env env,napi_status status,void* data) {
    std::unique_ptr<Job> j(static_cast<Job*>(data)); napi_value value;
    if(status!=napi_ok && j->error.empty()) j->error="Worker failed";
    const auto& text=j->error.empty()?j->result:j->error;
    napi_create_string_utf8(env,text.c_str(),NAPI_AUTO_LENGTH,&value);
    if(j->error.empty()) napi_resolve_deferred(env,j->deferred,value);
    else { napi_value error; napi_create_error(env,nullptr,value,&error); napi_reject_deferred(env,j->deferred,error); }
    napi_delete_async_work(env,j->work);
}
static napi_value Render(napi_env env,napi_callback_info info) {
    size_t argc=3; napi_value args[3]; napi_get_cb_info(env,info,&argc,args,nullptr,nullptr);
    char input[4096]{},output[4096]{}; size_t n=0; int32_t preset=0;
    if(argc!=3 || napi_get_value_string_utf8(env,args[0],input,sizeof(input),&n)!=napi_ok || n>=4095 ||
       napi_get_value_string_utf8(env,args[1],output,sizeof(output),&n)!=napi_ok || n>=4095 ||
       napi_get_value_int32(env,args[2],&preset)!=napi_ok || preset<0 || preset>2 || !strcmp(input,output)) {
        napi_throw_type_error(env,nullptr,"Expected distinct input/output paths and preset 0..2"); return nullptr;
    }
    auto j=std::make_unique<Job>(); j->input=input;j->output=output;j->preset=preset;
    napi_value promise,name; napi_create_promise(env,&j->deferred,&promise);
    napi_create_string_utf8(env,"OfflineRender",NAPI_AUTO_LENGTH,&name);
    if(napi_create_async_work(env,nullptr,name,Execute,Complete,j.get(),&j->work)!=napi_ok) {
        napi_throw_error(env,nullptr,"Cannot create render worker");return nullptr;
    }
    if(napi_queue_async_work(env,j->work)!=napi_ok) {
        napi_delete_async_work(env,j->work);napi_throw_error(env,nullptr,"Cannot queue render worker");return nullptr;
    }
    j.release();return promise;
}
static napi_value Init(napi_env env,napi_value exports) {
    napi_property_descriptor props[]={{"render",nullptr,Render,nullptr,nullptr,nullptr,napi_default,nullptr}};
    napi_define_properties(env,exports,1,props); return exports;
}
static napi_module module={1,0,nullptr,Init,"entry",nullptr,{0}};
extern "C" __attribute__((constructor)) void Register() { napi_module_register(&module); }
