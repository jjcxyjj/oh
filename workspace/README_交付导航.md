# 离线音频编辑实验室 v2

所有开发与产出均位于本目录 `oh/workspace`。

## 先打开这两个文件

- `output/Demo演示/index.html`：五个任务页签，现场运行算法、查看官网管线原图、试听和导出。可直接双击，保留旁边的 JS、CSS 与 assets 文件。
- `output/学习指南/代码导读.md`：从入口开始解释 ArkTS、N-API、C++ 管线与浏览器算法，回答预生成 WAV 和现场计算的区别。

## 功能

均衡器（完整三种预设及十段增益图）、音源分离、双素材混音、EQ/声场/混音级联、分离后重新混音。任务页支持 URL 锚点直达。

鸿蒙工程调用 AudioSuite。网页使用 Web Audio 与传统中置频谱 DSP 分离，不能替代华为分离模型；单声道与中置乐器等局限在页面中明确说明。

## 工程和方案

- `output/OfflineAudioDemo`：DevEco Studio 工程，API 24 编译通过。
- `output/安装包/OfflineAudioDemo-unsigned.hap`：新版未签名 HAP，需要配置开发签名和真机验收。
- `output/PPT/AudioSuite_离线编辑方案.pptx`：六页方案，页头 #2F5597，分隔线 #8064A2。
- `output/文档/AudioSuite_离线编辑技术方案.docx` 与 `.md`：v2 技术方案。
- `output/Demo演示/assets`：华为官网三张原始示意图及来源清单。

## 历史材料

`output/Demo演示` 内原有三个预设 WAV、旧截图、旧 MP4 为 v1 EQ 演示的历史导出，保留供对照。新版交互页面不读取这些效果文件。新版的输入仍是原始 PCM，结果按按钮运行后生成。

## 验证与运行

`build_demo.command` 重新构建原生项目。需要 DevEco Studio 和 HarmonyOS 6.1.1 API 24。
`.build/v2` 保存本次构建日志、浏览器实际计算测试、截图、原版备份和文档/PPT 校验记录。
真机尚未验收，编译通过不代表设备运行通过。网页可双击 HTML 使用，或在本目录运行 `python3 -m http.server 18765 --bind 127.0.0.1` 后打开 `/output/Demo演示/index.html`。
