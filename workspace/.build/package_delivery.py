from pathlib import Path
import shutil,wave,json,hashlib,subprocess
r=Path('/Users/jiaoyuanxiang/Desktop/oh/chatgpt');out=r/'output';demo=out/'Demo演示'
videos=sorted((demo/'录屏').glob('*.webm'),key=lambda p:p.stat().st_mtime)
for v in videos[:-1]:shutil.move(v,r/'.build'/v.name)
if videos:
 latest=videos[-1];dest=demo/'录屏/离线编辑操作演示.webm';latest.rename(dest)
 subprocess.run(['/opt/homebrew/bin/ffmpeg','-y','-i',str(dest),'-c:v','libx264','-pix_fmt','yuv420p','-movflags','+faststart',str(demo/'离线编辑操作演示.mp4')],check=True,capture_output=True)
 shutil.move(dest,r/'.build/离线编辑操作演示.webm');(demo/'录屏').rmdir()
checks=[]
for p in demo.glob('*.wav'):
 with wave.open(str(p)) as w:
  info={'file':p.name,'channels':w.getnchannels(),'sample_rate':w.getframerate(),'frames':w.getnframes(),'sample_width':w.getsampwidth(),'bytes':p.stat().st_size}
  assert info['channels']==2 and info['sample_rate']==48000 and info['frames']==2400000 and info['sample_width']==2
  checks.append(info)
(r/'.build/wav-validation.json').write_text(json.dumps(checks,ensure_ascii=False,indent=2))
(out/'安装包').mkdir(exist_ok=True);shutil.copy2(out/'OfflineAudioDemo/entry/build/default/outputs/default/entry-default-unsigned.hap',out/'安装包/OfflineAudioDemo-unsigned.hap')
(r/'README_交付导航.md').write_text('''# 离线音频编辑 Demo 交付导航

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
''')
(demo/'演示讲稿.md').write_text('''# 三分钟演示讲稿

## 开场 20 秒
这是基于华为 AudioSuite 离线编辑流程制作的单音轨 EQ Demo。原生工程已编译，当前现场演示为电脑 Web Audio 版本，音频实际在本地处理，但不作为鸿蒙性能和音质证据。

## 素材与原音 30 秒
展示 50 秒、48 kHz、双声道素材，点击原音播放。指出音频不上传，文件已随演示内置。

## 配置与渲染 40 秒
选择人声清晰，展示 10 个频带增益。点击开始离线渲染。说明鸿蒙实现由 N-API 工作线程按 20 ms 请求 PCM，结束后再保存 WAV。界面计时是浏览器数据。

## 对比与导出 40 秒
在相近时间点切换试听原音与结果，展示 WAV 导出。再切换低频温暖，说明每次从原音重新处理。不要把响度差异直接解释为音质提升。

## 实现与验收 50 秒
结合 PPT 展示输入、均衡器、输出与文件保存。强调错误码校验、临时文件提交和资源释放。最后说明 HAP 需要签名和真机，后续验收包括节点支持、导出完整性、听感、耗时与内存。

录屏为无声交互记录。原生界面尚无真机截图；目录内截图来自电脑演示。
''')
print(json.dumps(checks,ensure_ascii=False))
