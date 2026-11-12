# HarmonyOS 音频编创（OHAudioSuite）Demo 交付包

> 目录：`~/Desktop/oh/deepseek/`
> 主题：基于 OHAudioSuite **离线编辑（EDIT_MODE）** 的音频编创 Demo（清唱去噪 / 音源分离 / 混音）

## 目录

| 路径 | 内容 |
|---|---|
| `demo/AudioSuiteSample/` | **可运行 Demo**：官方 AudioSuiteSample 样例（DevEco 工程，NAPI + 离线/实时管线和 ArkTS UI） |
| `demo/offline_pipeline_reference.cpp` | **定制参考实现**：输入→降噪/均衡、音源分离、混音 三条离线管线（**已接入工程**） |
| `docs/技术方案.md` | 技术方案（架构/管线/效果节点/构建/约束/交付） |
| `demo演示.md` | 演示脚本（操作步骤 + 预期 + 常见问题） |
| `slides/音频编创Demo方案.pptx` | 演示 PPT |

## 快速开始
1. DevEco Studio 打开 `demo/AudioSuiteSample`，自动签名，选 **API 22+ 真机** 运行。
2. 按 `demo演示.md` 操作：播放 → 加效果（均衡/降噪）→ 音源分离 → 混音 → 实时预览/空间渲染。
3. 定制管线见 `offline_pipeline_reference.cpp`，集成方式见 `docs/技术方案.md §6.4`。

## 定制 Demo 已接入（一键「分离→降噪/均衡→混音」）
- 新增原生接口 `CombinedOfflineDemoNapi(callback)`（`audio_suite.cpp`）：`ReadPcmFile(输入)` → `demo::RunSeparation`(人声/伴奏) → 读回 → `demo::RunMix`(人声降噪 + 伴奏均衡 → 混音)。
- 已改：`CMakeLists.txt`(加源文件)、`types/libentry/Index.d.ts`(声明)、`ets/pages/Index.ets`(新增按钮「离线编创 Demo（分离→降噪→混音）」)。
- 输入/输出 PCM 沿用样例固定路径（应用 files 目录 `S16LE_2_48000*.pcm`）。
- ⚠️ 本机无 DevEco/SDK，**未编译验证**；若编译报错，把日志发我据此修。

## 关键结论
- OHAudioSuite = **引擎 + 管线 + 节点**，反向驱动、节点化编排；
- 离线/实时两种模式同一套接口；**只处理 PCM**（解码/编码自备）；
- 12 种效果节点，**音源分离依赖 NPU**，且分离节点后面只能接输出（分离与混音要分批）。
