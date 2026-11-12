# 音频编创 Demo 演示脚本

> 对应 `demo/AudioSuiteSample/`（官方可运行样例）+ `demo/offline_pipeline_reference.cpp`（定制管线）。
> 演示前：DevEco Studio 打开样例，设备选 **API 22+ 真机**（音源分离需 NPU，模拟器可能不支持）。

## 一、环境准备（1 分钟）
1. DevEco Studio → Open → `oh/deepseek/demo/AudioSuiteSample`。
2. 右下角 Sync，等待依赖同步完成。
3. File → Project Structure → Signing Configs → 勾选 Auto（自动签名）。
4. 选择设备（真机），点 Run。

## 二、主流程演示（官方样例功能）

| 步骤 | 操作 | 预期 |
|---|---|---|
| 1 | 点「播放音频」 | 听到原始音频，创建了音频流 |
| 2 | 选「均衡器效果」→ 选预设「流行」/拖 10 段增益 → 点「添加音频效果」 | 异步处理后提示成功 |
| 3 | 点「播放添加音频效果后音频」 | 音色变化（低频/中频/亮度不同） |
| 4 | 选「降噪效果」→ 点「添加音频效果」 | 背景底噪降低、人声更清晰 |
| 5 | 点「音源分离」 | 异步处理，提示成功（设备需支持 NPU） |
| 6 | 点「播放伴奏」/「播放人声」 | 分别听到伴奏轨、人声轨 |
| 7 | 点「混音与级联」→「播放混音」 | 人声+伴奏混合输出 |
| 8 | 点「播放实时预览」 | 边播边处理（注意节点数，避免卡顿） |
| 9 | 点「播放空间渲染」 | 声音有方位/环绕感 |
| 10 | 选「变速变调」设 speed/pitch → 添加效果 → 播放 | 速度/音高改变 |

> 其他效果同理：声音美化（清澈/剧场/CD/录音棚）、声场（前置/宏大/近场/宽广）、
> 环境（广播/听筒/水下/留声机）、传统/通用变声、空间渲染（位置/旋转/扩展）。

## 三、定制管线演示（清唱 → 降噪 → 分离 → 混音）

对应 `offline_pipeline_reference.cpp`：

1. **A 最简**：`RunDenoiseEq(输入PCM, 大小, "denoise_eq.pcm")`
   → 输入 → 降噪 → 均衡(流行) → 输出；用 Audacity「导入原始数据」播放对比。
2. **B 分离**：`RunSeparation(输入PCM, 大小, "vocals.pcm", "accomp.pcm")`
   → 得到人声轨、伴奏轨两个 PCM。
3. **C 混音**：`RunMix(vocals.pcm, accomp.pcm, "mixed.pcm")`
   → 人声走降噪、伴奏走均衡，再混音输出。
4. 播放 `mixed.pcm`，与原始输入 A/B 对比：**底噪更低、人声更清楚、伴奏更均衡**。

> PCM 是无头的裸数据；演示时用 Audacity：文件 → 导入 → 原始数据 → 选
> `Signed 16-bit PCM / Little-endian / 2 声道 / 48000Hz` 即可试听。

**◆ UI 一键演示（已接入）**：样例主界面新增按钮「**离线编创 Demo（分离→降噪→混音）**」，
点击即依次执行 B→C（分离 → 人声降噪/伴奏均衡 → 混音），结果写入应用 files 目录的
`S16LE_2_48000_Vocals/Accompaniment/Mix.pcm`，并在提示/日志显示结果。
（源码：`audio_suite.cpp::CombinedOfflineDemoNapi` + `offline_pipeline_reference.cpp`。
⚠️ 本机无 DevEco/SDK，未编译验证。）

## 四、讲点（面向评审/领导）
- **官方能力、原生 C 接口**：性能/延迟可控，适合端侧离线与实时两用。
- **节点化编排**：像搭积木一样组合效果，业务可自由扩展链路。
- **端侧算力**：音源分离用 NPU，隐私数据不出端。
- **可复用**：同一套引擎支撑"离线成片"和"实时预览"两种模式。

## 五、常见问题
- 音源分离失败/不可用：设备不支持（非 NPU 机型/模拟器）→ 先 `IsNodeTypeSupported` 判断并降级。
- 实时预览卡顿：减少效果节点数量（RenderFrame 耗时随节点数线性增加）。
- 输出没声音/全是噪声：检查采样率/声道/位深是否与输入一致（S16LE/48k/ST），
  `frameSize` 与 `20ms`（11025Hz 用 40ms）计算是否正确。
- 只处理了前一小段：输入回调里 `finished` 判断/`written` 计数有误。
