from pathlib import Path
import shutil,json
r=Path('/Users/jiaoyuanxiang/Desktop/oh/chatgpt');p=r/'output/OfflineAudioDemo'
f=p/'entry/src/main/cpp/offline_engine.cpp';f.write_text(f.read_text().replace('{-6,-4,-2,0,2,4,4,2,0,-2}','{-8,-6,-4,-2,0,2,2,0,-2,-4}'))
for f in [r/'.build/create_demo.py',r/'output/Demo演示/离线编辑演示.html']:
 f.write_text(f.read_text().replace('[-6,-4,-2,0,2,4,4,2,0,-2]','[-8,-6,-4,-2,0,2,2,0,-2,-4]'))
f=p/'entry/src/main/ets/pages/Index.ets';s=f.read_text().replace("if (state === 'initialized') { await p.prepare(); }\n        if (state === 'prepared') { await p.play(); }", "try {\n          if (state === 'initialized') { await p.prepare(); }\n          if (state === 'prepared') { await p.play(); }\n        } catch (e) { this.status = '播放失败：' + String(e); }")
f.write_text(s)
for f in list((p/'AppScope/resources').rglob('string.json'))+list((p/'entry/src/main/resources').rglob('string.json')):
 data=json.loads(f.read_text());
 for e in data.get('string',[]):
  if e['name'] in ['app_name','EntryAbility_label']:e['value']='离线音频实验室'
 f.write_text(json.dumps(data,ensure_ascii=False,indent=2))
shutil.copy2(p/'README.md',r/'.build/UPSTREAM_README.md')
(p/'README.md').write_text('''# OfflineAudioDemo

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
''')
(r/'build_demo.command').write_text('''#!/bin/zsh
set -e
cd "$(dirname "$0")/output/OfflineAudioDemo"
export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
export PATH=/Applications/DevEco-Studio.app/Contents/tools/node/bin:$PATH
/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin/ohpm install
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --mode module -p product=default -p module=entry@default assembleHap --no-daemon
''')
(r/'build_demo.command').chmod(0o755)
