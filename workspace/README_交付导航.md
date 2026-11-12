# 离线音频编辑 Demo 交付导航

所有内容均位于本文件所在的 oh/chatgpt 目录。

## 建议先看
1. 双击 `output/Demo演示/离线编辑演示.html`：可交互的电脑演示，包含素材，无需联网。
2. 打开 `output/PPT/AudioSuite_离线编辑方案.pptx`：六页方案，沿用指定 ACE-Step 美化版样式。
3. 打开 `output/文档/AudioSuite_离线编辑技术方案.docx`：六页技术说明，另附 Markdown。
4. 播放 `output/Demo演示/离线编辑操作演示.mp4`：无声操作录屏。音效请在 HTML 或 WAV 中试听。

## 原生 Demo
`output/OfflineAudioDemo` 是 DevEco Studio 工程。`output/安装包/OfflineAudioDemo-unsigned.hap` 是 API 24 构建通过的未签名包。
需要自己的开发签名及支持 AudioSuite 的鸿蒙真机。当前 HDC 未发现设备，因此未完成真机安装、听感或性能验收。
根目录 `build_demo.command` 可重新构建。本机 SDK 路径已写在脚本中，其他电脑可按安装位置调整。

## 演示材料
`output/Demo演示` 包含交互 HTML、操作视频、两张截图、三种预设 WAV 与演示讲稿。
电脑版使用 Web Audio，原生版使用 AudioSuite，二者内部算法和耗时不同。附带 WAV 均由电脑版生成。

## 验证记录
`.build/native-build.log`：原生构建日志。
`.build/browser-test.json`：三种预设的浏览器处理记录。
`.build/wav-validation.json`：导出 WAV 格式检查。
`.build/deck-validation.json`：PPT 结构、字体与布局校验。
`.build` 同时保留生成脚本、参考渲染、排版检查图与临时构建内容。
