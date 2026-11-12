# OfflineAudioDemo v2

基于华为 AudioSuite 的离线音频任务 Demo，支持 EQ、音源分离、双素材混音、EQ/声场/混音级联和分离后重混。

## 入口和代码

系统入口是 `entry/src/main/ets/entryability/EntryAbility.ets` 的 `onWindowStageCreate()`，加载 `pages/Index`。按钮调用 `Index.ets` 的 `renderAudio()`，通过 `engine.run()` 进入 C++。

- `entry/src/main/cpp/offline_engine.cpp`：N-API 异步桥接。
- `entry/src/main/cpp/audio_pipeline.cpp`：AudioSuite 节点组网与五任务运行。
- `entry/src/main/cpp/wav_io.h`：PCM16 WAV 解析、输入增益和 WAV 输出。
- `entry/src/main/cpp/types/libentry/Index.d.ts`：ArkTS 接口声明。

完整学习说明在 `../学习指南/代码导读.md`。系统算法由 `libohaudiosuite.so` 实现，本项目不是华为分离模型源码。

## 构建和使用

使用 DevEco Studio 打开本目录，SDK 为 HarmonyOS 6.1.1 API 24。根目录 `workspace/build_demo.command` 可重新构建，产物是未签名 HAP。配置自己的签名并连接支持所需 AudioSuite 节点的设备后运行。

内置 50 秒原始 PCM，也可选择导入 A/B；导入要求 48kHz、双声道、PCM16 WAV，最长 120 秒。混音和级联必须选择 B；分离后重混自动使用第一阶段的两路输出。

点击「开始运行算法」后后台新建管线与输出文件，成功后返回本次结果供试听和导出。设备不支持节点时明确失败，不使用预生成音频替代。Previewer 不能运行 AudioSuite，mock 会明确报错。

## 当前限制

API 24 编译通过；尚未进行真机运行、听感、性能和导出系统交互验收。当前不支持任意节点图、任务取消、原生压缩音频解码或自动响度归一化。两路增益默认 0.7/0.3，EQ 提升仍可能导致削波。

基础工程和素材来自 Huawei HarmonyOS_Samples/guide-snippets 的 AudioSuiteSample，保留上游声明，新代码以 Apache-2.0 标识发布。
上游：https://gitcode.com/HarmonyOS_Samples/guide-snippets/tree/master/Media/Audio/AudioSuiteSample
