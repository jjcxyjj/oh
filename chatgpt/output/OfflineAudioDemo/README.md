# OfflineAudioDemo

基于华为 AudioSuite 离线编辑流程实现的单音轨 EQ demo。

## 运行
1. DevEco Studio 打开本目录，安装 HarmonyOS 6.1.1 API 24 SDK。
2. 同步 OHPM 依赖；在 Signing Configs 中配置自己的开发签名。
3. 连接具备 AudioSuite EQ 能力的鸿蒙真机，运行 entry。
4. 试听原音，选择预设，开始离线渲染，试听结果并导出 WAV。

构建：运行 chatgpt/build_demo.command。产物默认为未签名 HAP，不能直接当作已签名安装包安装。

## 实现范围
内置 50 秒、48kHz 双声道 S16LE PCM。三个自定义 EQ 预设，异步渲染、错误传播、WAV 导出。
原生 demo 暂无外部音频导入、取消处理、实时预览、降噪、音源分离或混音。
电脑演示另在 Demo演示目录，使用 Web Audio，不能代替 AudioSuite 真机验收。

## 核心文件
- entry/src/main/ets/pages/Index.ets：状态、试听与文件导出。
- entry/src/main/cpp/offline_engine.cpp：N-API Promise、AudioSuite、PCM/WAV 和 RAII。
- entry/src/main/cpp/types/libentry/Index.d.ts：接口类型。

## 验证
已完成 API 24 编译。真机尚未连接，音效听感、性能和导出系统交互仍需真机验收。

## 来源与许可
基础工程及音频素材来自 Huawei HarmonyOS_Samples/guide-snippets 的 AudioSuiteSample，保留上游版权声明。
上游：https://gitcode.com/HarmonyOS_Samples/guide-snippets/tree/master/Media/Audio/AudioSuiteSample
新代码以 Apache-2.0 标识发布。上游完整说明备份在 chatgpt/.build/UPSTREAM_README.md。
