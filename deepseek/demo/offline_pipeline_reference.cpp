/*
 * 离线音频编创 Demo（参考实现）
 * 场景：清唱/混音音频 → 降噪 + 均衡 → 音源分离(人声/伴奏) → 混音 → 输出 PCM
 *
 * 说明：
 *   - 本文件是"仿照官方 AudioSuiteSample/entry/src/main/cpp/manual_rendering.cpp"写的
 *     定制参考实现，供集成到 HarmonyOS(DevEco) 工程。真正编译需在 entry 的
 *     CMakeLists.txt 里 target_link_libraries(entry PUBLIC libohaudiosuite.so)，
 *     并包含 <ohaudiosuite/native_audio_suite_base.h> / <native_audio_suite_engine.h>。
 *   - 关键约束（官方文档）：
 *       * 音源分离节点(EFFECT_MULTII_OUTPUT_NODE_TYPE_AUDIO_SEPARATION) 多输出、
 *         后面只能连"输出节点"，所以"分离"和"混音"要分两条管线做（两趟）。
 *       * 混音节点(EFFECT_NODE_TYPE_AUDIO_MIXER) 支持多路输入。
 *       * 管线为"反向驱动"：RenderFrame 从输出端逐级向上游要数据，最终回调
 *         输入节点的 RequestDataCallback 由我们填 PCM。
 *   - 采样格式统一 S16LE / 48k / 立体声；帧 20ms（11025Hz 时用 40ms）。
 */
#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <vector>
#include <ohaudiosuite/native_audio_suite_base.h>
#include <ohaudiosuite/native_audio_suite_engine.h>

namespace demo {

constexpr int kChannels = 2;
constexpr int kSampleBytesS16 = 2;      // S16LE: 2 bytes/sample
constexpr int kFrameMs = 20;
constexpr int kMsPerSec = 1000;

// 内存中的 PCM 数据源（实际工程里从文件/解码器填充）
struct PcmBuffer {
    uint8_t *data = nullptr;
    int32_t size = 0;       // 总字节
    int32_t written = 0;    // 已交给管线的字节
};

// 输入节点回调：管线来要数据时，把 PcmBuffer 里的 PCM 拷进去
static int32_t OnRequestData(OH_AudioNode *, void *userData, void *audioData,
                             int32_t audioDataSize, bool *finished) {
    if (!userData || !audioData || audioDataSize <= 0 || !finished) return -1;
    auto *src = static_cast<PcmBuffer *>(userData);
    int32_t n = std::min(audioDataSize, src->size - src->written);
    if (n > 0) {
        std::copy(src->data + src->written, src->data + src->written + n,
                  static_cast<uint8_t *>(audioData));
        src->written += n;
    }
    if (src->written >= src->size) *finished = true;
    return n;
}

static OH_AudioFormat MakeFormat() {
    OH_AudioFormat f;
    f.samplingRate = OH_Audio_SampleRate::SAMPLE_RATE_48000;
    f.channelLayout = OH_AudioChannelLayout::CH_LAYOUT_STEREO;
    f.channelCount = kChannels;
    f.sampleFormat = OH_Audio_SampleFormat::AUDIO_SAMPLE_S16LE;
    f.encodingType = OH_Audio_EncodingType::AUDIO_ENCODING_TYPE_RAW;
    return f;
}

// 创建输入节点（绑定回调 + 格式）
static OH_AudioNode *CreateInputNode(OH_AudioSuitePipeline *pipe,
                                     OH_AudioNodeBuilder *builder, PcmBuffer *buf) {
    OH_AudioSuiteNodeBuilder_Reset(builder);
    OH_AudioSuiteNodeBuilder_SetNodeType(builder, OH_AudioNode_Type::INPUT_NODE_TYPE_DEFAULT);
    OH_AudioSuiteNodeBuilder_SetFormat(builder, MakeFormat());
    OH_AudioSuiteNodeBuilder_SetRequestDataCallback(builder, OnRequestData, buf);
    OH_AudioNode *node = nullptr;
    OH_AudioSuiteEngine_CreateNode(pipe, builder, &node);
    return node;
}

static OH_AudioNode *CreateOutputNode(OH_AudioSuitePipeline *pipe,
                                      OH_AudioNodeBuilder *builder) {
    OH_AudioSuiteNodeBuilder_Reset(builder);
    OH_AudioSuiteNodeBuilder_SetNodeType(builder, OH_AudioNode_Type::OUTPUT_NODE_TYPE_DEFAULT);
    OH_AudioSuiteNodeBuilder_SetFormat(builder, MakeFormat());
    OH_AudioNode *node = nullptr;
    OH_AudioSuiteEngine_CreateNode(pipe, builder, &node);
    return node;
}

// ---------------------------------------------------------------- 第一趟：音源分离
// input(src) -> AUDIO_SEPARATION -> output(multi: [0]=人声, [1]=伴奏)
// 把分离结果分别写到 vocals.pcm / accomp.pcm
bool RunSeparation(const uint8_t *srcPcm, int32_t srcSize,
                   const char *vocalsOut, const char *accompOut) {
    OH_AudioSuiteEngine *engine = nullptr;
    OH_AudioSuiteEngine_Create(&engine);
    OH_AudioSuitePipeline *pipe = nullptr;
    OH_AudioSuiteEngine_CreatePipeline(engine, &pipe,
        OH_AudioSuite_PipelineWorkMode::AUDIOSUITE_PIPELINE_EDIT_MODE);

    // 设备是否支持分离节点（依赖 NPU）
    bool supported = false;
    OH_AudioSuiteEngine_IsNodeTypeSupported(
        OH_AudioNode_Type::EFFECT_MULTII_OUTPUT_NODE_TYPE_AUDIO_SEPARATION, &supported);
    if (!supported) { /* 提示不支持，降级为纯去噪/均衡 */ return false; }

    PcmBuffer buf{const_cast<uint8_t *>(srcPcm), srcSize, 0};
    OH_AudioNodeBuilder *builder = nullptr;
    OH_AudioSuiteNodeBuilder_Create(&builder);
    OH_AudioNode *in = CreateInputNode(pipe, builder, &buf);

    OH_AudioSuiteNodeBuilder_Reset(builder);
    OH_AudioSuiteNodeBuilder_SetNodeType(builder,
        OH_AudioNode_Type::EFFECT_MULTII_OUTPUT_NODE_TYPE_AUDIO_SEPARATION);
    OH_AudioNode *sep = nullptr;
    OH_AudioSuiteEngine_CreateNode(pipe, builder, &sep);

    OH_AudioNode *out = CreateOutputNode(pipe, builder);
    OH_AudioSuiteNodeBuilder_Destroy(builder);

    OH_AudioSuiteEngine_ConnectNodes(in, sep);
    OH_AudioSuiteEngine_ConnectNodes(sep, out);   // 分离节点后面只能接输出

    int32_t frameSize = kFrameMs * 48000 * kChannels * kSampleBytesS16 / kMsPerSec;
    OH_AudioDataArray arr;
    arr.arraySize = 2;                            // 人声 1 路 + 伴奏 1 路
    arr.requestFrameSize = frameSize;
    arr.audioDataArray = (void **)malloc(sizeof(void *) * arr.arraySize);
    for (int i = 0; i < arr.arraySize; ++i) arr.audioDataArray[i] = malloc(frameSize);

    FILE *fv = fopen(vocalsOut, "wb");
    FILE *fa = fopen(accompOut, "wb");
    int32_t resp = 0; bool finished = false;
    OH_AudioSuiteEngine_StartPipeline(pipe);
    do {
        auto r = OH_AudioSuiteEngine_MultiRenderFrame(pipe, &arr, &resp, &finished);
        if (r != OH_AudioSuite_Result::AUDIOSUITE_SUCCESS || resp <= 0) break;
        fwrite(arr.audioDataArray[0], 1, resp, fv);   // 人声
        fwrite(arr.audioDataArray[1], 1, resp, fa);   // 伴奏
    } while (!finished);
    OH_AudioSuiteEngine_StopPipeline(pipe);

    if (fv) fclose(fv);
    if (fa) fclose(fa);
    for (int i = 0; i < arr.arraySize; ++i) free(arr.audioDataArray[i]);
    free(arr.audioDataArray);

    OH_AudioSuiteEngine_DestroyNode(in);
    OH_AudioSuiteEngine_DestroyNode(sep);
    OH_AudioSuiteEngine_DestroyNode(out);
    OH_AudioSuiteEngine_DestroyPipeline(pipe);
    OH_AudioSuiteEngine_Destroy(engine);
    return true;
}

// ---------------------------------------------------------------- 第二趟：降噪 + 均衡 + 混音
// inputVocals -> DENOISE --\
//                           >--> MIXER -> output
// inputAccomp -> EQUALIZER-/
bool RunMix(const uint8_t *vocalsPcm, int32_t vocalsSize,
            const uint8_t *accompPcm, int32_t accompSize,
            const char *mixedOut) {
    OH_AudioSuiteEngine *engine = nullptr;
    OH_AudioSuiteEngine_Create(&engine);
    OH_AudioSuitePipeline *pipe = nullptr;
    OH_AudioSuiteEngine_CreatePipeline(engine, &pipe,
        OH_AudioSuite_PipelineWorkMode::AUDIOSUITE_PIPELINE_EDIT_MODE);

    PcmBuffer vbuf{const_cast<uint8_t *>(vocalsPcm), vocalsSize, 0};
    PcmBuffer abuf{const_cast<uint8_t *>(accompPcm), accompSize, 0};

    OH_AudioNodeBuilder *builder = nullptr;
    OH_AudioSuiteNodeBuilder_Create(&builder);

    OH_AudioNode *inVocal = CreateInputNode(pipe, builder, &vbuf);
    OH_AudioNode *inAccomp = CreateInputNode(pipe, builder, &abuf);

    // 人声：降噪（无需参数）
    OH_AudioSuiteNodeBuilder_Reset(builder);
    OH_AudioSuiteNodeBuilder_SetNodeType(builder, OH_AudioNode_Type::EFFECT_NODE_TYPE_NOISE_REDUCTION);
    OH_AudioNode *denoise = nullptr;
    OH_AudioSuiteEngine_CreateNode(pipe, builder, &denoise);

    // 伴奏：均衡器（流行预设: {5,2,1,-1,-5,-5,-2,1,2,4}）
    OH_AudioSuiteNodeBuilder_Reset(builder);
    OH_AudioSuiteNodeBuilder_SetNodeType(builder, OH_AudioNode_Type::EFFECT_NODE_TYPE_EQUALIZER);
    OH_AudioNode *eq = nullptr;
    OH_AudioSuiteEngine_CreateNode(pipe, builder, &eq);
    OH_AudioSuiteEngine_SetEqualizerFrequencyBandGains(eq, OH_EQUALIZER_PARAM_POP);

    // 混音 + 输出
    OH_AudioSuiteNodeBuilder_Reset(builder);
    OH_AudioSuiteNodeBuilder_SetNodeType(builder, OH_AudioNode_Type::EFFECT_NODE_TYPE_AUDIO_MIXER);
    OH_AudioNode *mixer = nullptr;
    OH_AudioSuiteEngine_CreateNode(pipe, builder, &mixer);
    OH_AudioNode *out = CreateOutputNode(pipe, builder);
    OH_AudioSuiteNodeBuilder_Destroy(builder);

    OH_AudioSuiteEngine_ConnectNodes(inVocal, denoise);
    OH_AudioSuiteEngine_ConnectNodes(denoise, mixer);
    OH_AudioSuiteEngine_ConnectNodes(inAccomp, eq);
    OH_AudioSuiteEngine_ConnectNodes(eq, mixer);
    OH_AudioSuiteEngine_ConnectNodes(mixer, out);

    int32_t frameSize = kFrameMs * 48000 * kChannels * kSampleBytesS16 / kMsPerSec;
    std::vector<uint8_t> outBuf(frameSize);
    int32_t resp = 0; bool finished = false;
    FILE *fm = fopen(mixedOut, "wb");
    OH_AudioSuiteEngine_StartPipeline(pipe);
    do {
        auto r = OH_AudioSuiteEngine_RenderFrame(pipe, outBuf.data(), frameSize, &resp, &finished);
        if (r != OH_AudioSuite_Result::AUDIOSUITE_SUCCESS || resp <= 0) break;
        fwrite(outBuf.data(), 1, resp, fm);
    } while (!finished);
    OH_AudioSuiteEngine_StopPipeline(pipe);
    if (fm) fclose(fm);

    OH_AudioSuiteEngine_DestroyNode(inVocal);
    OH_AudioSuiteEngine_DestroyNode(inAccomp);
    OH_AudioSuiteEngine_DestroyNode(denoise);
    OH_AudioSuiteEngine_DestroyNode(eq);
    OH_AudioSuiteEngine_DestroyNode(mixer);
    OH_AudioSuiteEngine_DestroyNode(out);
    OH_AudioSuiteEngine_DestroyPipeline(pipe);
    OH_AudioSuiteEngine_Destroy(engine);
    return true;
}

// ---------------------------------------------------------------- 一段式（仅降噪+均衡，不分离）
// input -> [DENOISE] -> [EQUALIZER] -> output  （最简单，最稳）
bool RunDenoiseEq(const uint8_t *srcPcm, int32_t srcSize, const char *outPath) {
    OH_AudioSuiteEngine *engine = nullptr; OH_AudioSuiteEngine_Create(&engine);
    OH_AudioSuitePipeline *pipe = nullptr;
    OH_AudioSuiteEngine_CreatePipeline(engine, &pipe,
        OH_AudioSuite_PipelineWorkMode::AUDIOSUITE_PIPELINE_EDIT_MODE);
    PcmBuffer buf{const_cast<uint8_t *>(srcPcm), srcSize, 0};
    OH_AudioNodeBuilder *b = nullptr; OH_AudioSuiteNodeBuilder_Create(&b);
    OH_AudioNode *in = CreateInputNode(pipe, b, &buf);
    OH_AudioSuiteNodeBuilder_Reset(b);
    OH_AudioSuiteNodeBuilder_SetNodeType(b, OH_AudioNode_Type::EFFECT_NODE_TYPE_NOISE_REDUCTION);
    OH_AudioNode *dn = nullptr; OH_AudioSuiteEngine_CreateNode(pipe, b, &dn);
    OH_AudioSuiteNodeBuilder_Reset(b);
    OH_AudioSuiteNodeBuilder_SetNodeType(b, OH_AudioNode_Type::EFFECT_NODE_TYPE_EQUALIZER);
    OH_AudioNode *eq = nullptr; OH_AudioSuiteEngine_CreateNode(pipe, b, &eq);
    OH_AudioSuiteEngine_SetEqualizerFrequencyBandGains(eq, OH_EQUALIZER_PARAM_POP);
    OH_AudioNode *out = CreateOutputNode(pipe, b);
    OH_AudioSuiteNodeBuilder_Destroy(b);
    OH_AudioSuiteEngine_ConnectNodes(in, dn);
    OH_AudioSuiteEngine_ConnectNodes(dn, eq);
    OH_AudioSuiteEngine_ConnectNodes(eq, out);

    int32_t frameSize = kFrameMs * 48000 * kChannels * kSampleBytesS16 / kMsPerSec;
    std::vector<uint8_t> outBuf(frameSize); int32_t resp = 0; bool finished = false;
    FILE *fp = fopen(outPath, "wb");
    OH_AudioSuiteEngine_StartPipeline(pipe);
    do {
        auto r = OH_AudioSuiteEngine_RenderFrame(pipe, outBuf.data(), frameSize, &resp, &finished);
        if (r != OH_AudioSuite_Result::AUDIOSUITE_SUCCESS || resp <= 0) break;
        fwrite(outBuf.data(), 1, resp, fp);
    } while (!finished);
    OH_AudioSuiteEngine_StopPipeline(pipe);
    if (fp) fclose(fp);
    OH_AudioSuiteEngine_DestroyNode(in); OH_AudioSuiteEngine_DestroyNode(dn);
    OH_AudioSuiteEngine_DestroyNode(eq); OH_AudioSuiteEngine_DestroyNode(out);
    OH_AudioSuiteEngine_DestroyPipeline(pipe); OH_AudioSuiteEngine_Destroy(engine);
    return true;
}

} // namespace demo
