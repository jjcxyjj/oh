# AudioSuite 音频编创示例

## 介绍

本示例基于 AudioSuite 能力，实现了音频编辑、音源分离、混音和实时预览等功能，包含了离线编辑和实时预览两种模式，以及功能调用接口的完整链路。

## 效果图预览

**图1：主界面**

<img src='./screenshots/audioSuite.png' width=320>


点击'播放音频'按钮，即可创建音频流并播放原始音频。

点击'停止播放'按钮，即可销毁音频流。

选择效果类型（均衡器效果、声音美化效果、降噪效果、声场效果、环境效果、空间渲染效果、传统变声效果、通用变声效果、变速变调效果），配置相应参数后点击'添加音频效果'按钮，即可对音频添加相应效果（异步处理）。均衡器效果支持预置效果选择和自定义10个频带增益设置；声音美化效果支持清澈、剧场、CD、录音棚四种模式；降噪效果无需配置参数；声场效果支持前向、宏大、近场、宽广四种模式；环境效果支持广播、听筒、水下、留声机四种场景；空间渲染效果支持位置、旋转、扩展三种模式；传统变声效果支持设置说话人性别、变声类型和音高；通用变声效果支持可爱、赛博朋克、女声、男声、混声、怪兽、沧桑、合成、颤音、战争十种类型；变速变调效果支持设置速度 speed 和音高 pitch。

点击'播放添加音频效果后音频'按钮，即可播放添加音频效果后的音频。

点击'音源分离'按钮，即可将音频分离为人声和伴奏（异步处理）。

点击'播放伴奏'按钮，即可播放分离后的伴奏。

点击'播放人声'按钮，即可播放分离后的人声。

点击'混音与级联'按钮，即可将音频分离的人声与音频分离的伴奏音频进行混音（异步处理）。

点击'播放混音'按钮，即可播放混音后的音频。

点击'播放实时预览'按钮，即可实时处理并播放音频（预览效果）。

点击'播放空间渲染'按钮，即可播放添加空间渲染后的音频。

点击'格式转换'按钮，即可对PCM音频进行格式转换（预览效果）。

点击'调试'按钮，即可输出当前音频引擎的状态信息到文件（仅在播放实时预览渲染时可用）。

## 工程结构&模块类型

```
├── entry/src/main/
│   ├── cpp/                        # C++ 原生代码
│   │   ├── types/libentry/
│   │   │   └── Index.d.ts         # NAPI 接口声明
│   │   ├── CMakeLists.txt         # CMake 编译配置文件
│   │   ├── audio_suite.cpp         # NAPI 接口和音频播放实现
│   │   ├── manual_rendering.cpp    # 离线编辑实现
│   │   ├── audio_effect/            # 音频效果节点策略实现
│   │   │   └── audio_effect.h      # 各效果节点（均衡器、降噪、声场、变声等）创建与参数设置
│   │   ├── real_time_rendering.cpp  # 实时预览实现
│   │   ├── audio_format_converter.cpp  # PCM音频格式转换实现
│   │   ├── pcm_file_utils.cpp       # PCM 文件工具类
│   │   ├── space_render_rotation.cpp     # 空间渲染实现
│   │   └── print_info_to_file.cpp   # 打印信息到文件
│   ├── ets/
│   │   ├── entryability/
│   │   │   └── EntryAbility.ets   # Ability 的生命周期回调内容
│   │   ├── entrybackupability/
│   │   │   └── EntryBackupAbility.ets  # BackupAbility 的生命周期回调内容
│   │   ├── pages/
│   │   │   └── Index.ets          # 主界面
│   │   └── utils/
│   │       └── DirInit.ets        # 目录初始化工具面
│   └── resources/                 # 资源目录
```

## 具体实现

### 使用 AudioSuite 实现离线编辑（离线编辑）

**源码参考：** [manual_rendering.cpp](entry/src/main/cpp/manual_rendering.cpp)

**使用流程：**

#### 音频效果

点击'添加音频效果'按钮，首先选择效果类型（均衡器效果、声音美化效果、降噪效果、声场效果、环境效果、空间渲染效果、传统变声效果、通用变声效果、变速变调效果），配置相应参数后，调用 `OH_AudioSuiteEngine_Create` 创建音频编创引擎，然后调用 `OH_AudioSuiteEngine_CreatePipeline` 创建管线（使用 `AUDIOSUITE_PIPELINE_EDIT_MODE` 编辑模式）。接着根据效果类型创建相应的效果节点：
- 均衡器效果：创建均衡器节点，通过 `OH_AudioSuiteEngine_SetEqualizerFrequencyBandGains` 设置10个频带增益参数
- 声音美化效果：创建声音美化节点，通过 `OH_AudioSuiteEngine_SetVoiceBeautifierType` 设置美化类型
- 降噪效果：创建降噪节点，无需设置额外参数
- 声场效果：创建声场节点，通过 `OH_AudioSuiteEngine_SetSoundFieldType` 设置声场类型
- 环境效果：创建环境效果节点，通过 `OH_AudioSuiteEngine_SetEnvironmentType` 设置环境场景类型
- 空间渲染效果：创建空间渲染节点，根据模式分别通过 `OH_AudioSuiteEngine_SetSpaceRenderPositionParams`、`OH_AudioSuiteEngine_SetSpaceRenderRotationParams`、`OH_AudioSuiteEngine_SetSpaceRenderExtensionParams` 设置位置、旋转、扩展参数
- 传统变声效果：创建传统变声节点，通过 `OH_AudioSuiteEngine_SetPureVoiceChangeOption` 设置说话人性别、变声类型和音高
- 通用变声效果：创建通用变声节点，通过 `OH_AudioSuiteEngine_SetGeneralVoiceChangeType` 设置通用变声类型
- 变速变调效果：创建变速变调节点，通过 `OH_AudioSuiteEngine_SetTempoAndPitch` 设置速度和音高

最后调用 `OH_AudioSuiteEngine_ConnectNodes` 连接各个节点组成组网，调用 `OH_AudioSuiteEngine_ProcessFrame` 处理音频帧并将结果写入文件。

#### 音源分离

点击'音源分离'按钮，首先创建引擎和管线，然后创建输入节点和音源分离节点。接着设置节点格式和回调，连接节点组成组网。最后处理音频帧并将分离后的人声和伴奏分别写入文件。

#### 混音与级联

点击'混音与级联'按钮，首先创建引擎和管线，然后创建输入节点、声场节点和输出节点。接着设置节点格式和回调，连接节点组成组网。最后处理音频帧并将混音后的音频写入文件。

### 使用 AudioSuite 实现实时预览

**源码参考：** [real_time_rendering.cpp](entry/src/main/cpp/real_time_rendering.cpp)

**使用流程：**

点击'播放实时预览'按钮，首先调用 `OH_AudioSuiteEngine_Create` 创建音频编创引擎，然后调用 `OH_AudioSuiteEngine_CreatePipeline` 创建管线（使用 `AUDIOSUITE_PIPELINE_REALTIME_MODE` 实时模式）。接着创建输入节点、均衡器节点和输出节点，并设置节点格式和回调。然后调用 `OH_AudioSuiteEngine_ConnectNodes` 连接各个节点组成组网。再创建 AudioRenderer 并设置写入数据回调，在回调中调用 `OH_AudioSuiteEngine_RenderFrame` 实时获取处理后的音频数据。最后调用 `OH_AudioSuiteEngine_StartPipeline` 启动管线并调用 `OH_AudioRenderer_Start` 开始播放。

点击'停止播放'按钮，调用 `OH_AudioRenderer_Stop` 停止播放，然后调用 `OH_AudioSuiteEngine_StopPipeline` 停止管线，最后释放所有资源。

### 按钮依赖关系

本示例实现了按钮依赖关系管理，确保操作按正确顺序执行：

- '播放添加音频效果后音频'：需先完成音频效果处理
- '播放伴奏'和'播放人声'：需先完成音源分离
- '混音与级联'：需先完成音源分离
- '播放混音'：需先完成混音与级联
- '播放空间渲染'：需先完成音源分离
- '调试'：需先启动播放实时预览

异步操作（音频效果、音源分离、混音与级联）处理过程中会显示 Loading 遮罩，处理完成后自动启用相关播放按钮。

## 相关权限

不涉及。

## 模块依赖

依赖以下模块：
- libohaudio.so
- libohaudiosuite.so

## 约束与限制

1.  本示例支持在真机上运行。

2.  本示例支持API version 23，版本号： 6.0.0。

3.  本示例已支持使Build Version: 6.0.0, built on May 21, 2026.

4.  高等级APL特殊签名说明：无。

**音频格式限制：**
- 仅支持 PCM

**功能限制：**
- 真机上才有音频效果

## 高等级APL特殊签名说明

无。

## 下载

如需单独下载本工程，执行如下命令：

```
git init
git config core.sparsecheckout true
echo Media/Audio/AudioSuiteSample/ > .git/info/sparse-checkout
git remote add origin https://gitcode.com/HarmonyOS_Samples/guide-snippets
git pull origin master
```