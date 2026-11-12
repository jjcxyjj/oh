// SPDX-License-Identifier: Apache-2.0
#pragma once
#include <string>
#include <vector>

// 0 EQ / 1 分离 / 2 混音 / 3 EQ→声场→混音 / 4 分离后重新混音。
struct RenderJob {
    std::string inputA, inputB, prefix;
    int mode = 0, preset = 1;
    double gainA = 0.7, gainB = 0.3;
    std::vector<std::string> paths, labels;
    std::string error;
    long elapsedMs = 0;
};
// 在 N-API 后台线程调用。内部运行 AudioSuite，输出全新的 WAV 文件。
void RunAudioJob(RenderJob& job);
