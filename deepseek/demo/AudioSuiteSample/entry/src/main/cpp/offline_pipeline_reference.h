// 定制离线管线：清唱 -> 降噪/均衡；音源分离；混音。供 NAPI 层调用。
#ifndef OFFLINE_PIPELINE_REFERENCE_H
#define OFFLINE_PIPELINE_REFERENCE_H

#include <cstdint>

namespace demo {

// 单管线：input -> 降噪 -> 均衡(流行) -> output（写裸 PCM）
bool RunDenoiseEq(const uint8_t *srcPcm, int32_t srcSize, const char *outPath);

// 第一趟：input -> 音源分离 -> output(人声/伴奏 两路)
bool RunSeparation(const uint8_t *srcPcm, int32_t srcSize,
                   const char *vocalsOut, const char *accompOut);

// 第二趟：人声走降噪、伴奏走均衡 -> 混音 -> output
bool RunMix(const uint8_t *vocalsPcm, int32_t vocalsSize,
            const uint8_t *accompPcm, int32_t accompSize,
            const char *mixedOut);

} // namespace demo

#endif
