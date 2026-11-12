/*
* Copyright (C) 2026 Huawei Device Co., Ltd.
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import audioSuiteNapi from 'libentry.so';
import { common } from '@kit.AbilityKit'
import { fileIo as fs } from '@kit.CoreFileKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { DirInitHelper } from '../utils/DirInit';

const EQ_PRESET_NAMES: Resource[] = [
  $r('app.string.eq_preset_custom'), $r('app.string.eq_preset_default'), $r('app.string.eq_preset_folk'),
  $r('app.string.eq_preset_chinese_style'), $r('app.string.eq_preset_classical'), $r('app.string.eq_preset_dance'),
  $r('app.string.eq_preset_jazz'), $r('app.string.eq_preset_pop'), $r('app.string.eq_preset_rb'),
  $r('app.string.eq_preset_rock')
];
const EQ_PRESET_OPTIONS: SelectOption[] = [
  { value: $r('app.string.eq_preset_custom') }, { value: $r('app.string.eq_preset_default') },
  { value: $r('app.string.eq_preset_folk') }, { value: $r('app.string.eq_preset_chinese_style') },
  { value: $r('app.string.eq_preset_classical') }, { value: $r('app.string.eq_preset_dance') },
  { value: $r('app.string.eq_preset_jazz') }, { value: $r('app.string.eq_preset_pop') },
  { value: $r('app.string.eq_preset_rb') }, { value: $r('app.string.eq_preset_rock') }
];
const EQ_PRESET_VALUES: number[][] = [
  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  [3, 5, 2, -4, 1, 2, -3, 1, 4, 5],
  [0, 0, 2, 0, 0, 4, 4, 2, 2, 5],
  [2, 3, 2, 1, 0, 0, -5, -5, -5, -6],
  [4, 3, 2, -3, 0, 0, 5, 4, 2, 0],
  [2, 0, 2, 3, 6, 5, -1, 3, 4, 4],
  [5, 2, 1, -1, -5, -5, -2, 1, 2, 4],
  [1, 4, 5, 3, -2, -2, 2, 3, 5, 5],
  [6, 4, 4, 2, 0, 1, 3, 3, 5, 4]
];
const EQ_BAND_LABELS = ['31Hz', '62Hz', '125Hz', '250Hz', '500Hz', '1kHz', '2kHz', '4kHz', '8kHz', '16kHz'];
const VOICE_BEAUTIFIER_NAMES: Resource[] = [
  $r('app.string.voice_beautifier_clear'), $r('app.string.voice_beautifier_theater'),
  $r('app.string.voice_beautifier_cd'), $r('app.string.voice_beautifier_studio')
];
const VOICE_BEAUTIFIER_OPTIONS: SelectOption[] = [
  { value: $r('app.string.voice_beautifier_clear') }, { value: $r('app.string.voice_beautifier_theater') },
  { value: $r('app.string.voice_beautifier_cd') }, { value: $r('app.string.voice_beautifier_studio') }
];
const SOUND_FIELD_NAMES: Resource[] = [
  $r('app.string.sound_field_forward'), $r('app.string.sound_field_grand'),
  $r('app.string.sound_field_near'), $r('app.string.sound_field_wide')
];
const SOUND_FIELD_OPTIONS: SelectOption[] = [
  { value: $r('app.string.sound_field_forward') }, { value: $r('app.string.sound_field_grand') },
  { value: $r('app.string.sound_field_near') }, { value: $r('app.string.sound_field_wide') }
];
const ENVIRONMENT_NAMES: Resource[] = [
  $r('app.string.environment_broadcast'), $r('app.string.environment_receiver'),
  $r('app.string.environment_underwater'), $r('app.string.environment_phonograph')
];
const ENVIRONMENT_OPTIONS: SelectOption[] = [
  { value: $r('app.string.environment_broadcast') }, { value: $r('app.string.environment_receiver') },
  { value: $r('app.string.environment_underwater') }, { value: $r('app.string.environment_phonograph') }
];
const PURE_VOICE_GENDER_NAMES: Resource[] = [$r('app.string.voice_female'), $r('app.string.voice_male')];
const PURE_VOICE_GENDER_OPTIONS: SelectOption[] = [
  { value: $r('app.string.voice_female') }, { value: $r('app.string.voice_male') }
];
const PURE_VOICE_TYPE_NAMES: Resource[] = [
  $r('app.string.pure_voice_type_cartoon'), $r('app.string.voice_cute'), $r('app.string.voice_female'),
  $r('app.string.voice_male'), $r('app.string.voice_monster'), $r('app.string.pure_voice_type_robot'),
  $r('app.string.voice_husky')
];
const PURE_VOICE_TYPE_OPTIONS: SelectOption[] = [
  { value: $r('app.string.pure_voice_type_cartoon') }, { value: $r('app.string.voice_cute') },
  { value: $r('app.string.voice_female') }, { value: $r('app.string.voice_male') },
  { value: $r('app.string.voice_monster') }, { value: $r('app.string.pure_voice_type_robot') },
  { value: $r('app.string.voice_husky') }
];
const GENERAL_VOICE_CHANGE_NAMES: Resource[] = [
  $r('app.string.voice_cute'), $r('app.string.voice_change_cyberpunk'), $r('app.string.voice_female'),
  $r('app.string.voice_male'), $r('app.string.voice_change_mixed'), $r('app.string.voice_monster'),
  $r('app.string.voice_husky'), $r('app.string.voice_change_synthetic'), $r('app.string.voice_change_tremolo'),
  $r('app.string.voice_change_war')
];
const GENERAL_VOICE_CHANGE_OPTIONS: SelectOption[] = [
  { value: $r('app.string.voice_cute') }, { value: $r('app.string.voice_change_cyberpunk') },
  { value: $r('app.string.voice_female') }, { value: $r('app.string.voice_male') },
  { value: $r('app.string.voice_change_mixed') }, { value: $r('app.string.voice_monster') },
  { value: $r('app.string.voice_husky') }, { value: $r('app.string.voice_change_synthetic') },
  { value: $r('app.string.voice_change_tremolo') }, { value: $r('app.string.voice_change_war') }
];
const SURROUND_DIRECTION_NAMES: Resource[] = [$r('app.string.surround_counterclockwise'), $r('app.string.surround_clockwise')];
const SURROUND_DIRECTION_OPTIONS: SelectOption[] = [
  { value: $r('app.string.surround_counterclockwise') }, { value: $r('app.string.surround_clockwise') }
];
const SPACE_RENDER_MODE_NAMES: Resource[] = [
  $r('app.string.space_render_mode_position'), $r('app.string.space_render_mode_rotation'),
  $r('app.string.space_render_mode_expansion')
];
const SPACE_RENDER_MODE_OPTIONS: SelectOption[] = [
  { value: $r('app.string.space_render_mode_position') }, { value: $r('app.string.space_render_mode_rotation') },
  { value: $r('app.string.space_render_mode_expansion') }
];
const EFFECT_TYPE_NAMES: Resource[] = [
  $r('app.string.effect_type_equalizer'), $r('app.string.effect_type_voice_beautifier'),
  $r('app.string.effect_type_noise_reduction'), $r('app.string.effect_type_sound_field'),
  $r('app.string.effect_type_environment'), $r('app.string.effect_type_space_render'),
  $r('app.string.effect_type_pure_voice_change'), $r('app.string.effect_type_general_voice_change'),
  $r('app.string.effect_type_tempo_pitch')
];
const EFFECT_TYPE_OPTIONS: SelectOption[] = [
  { value: $r('app.string.effect_type_equalizer') }, { value: $r('app.string.effect_type_voice_beautifier') },
  { value: $r('app.string.effect_type_noise_reduction') }, { value: $r('app.string.effect_type_sound_field') },
  { value: $r('app.string.effect_type_environment') }, { value: $r('app.string.effect_type_space_render') },
  { value: $r('app.string.effect_type_pure_voice_change') }, { value: $r('app.string.effect_type_general_voice_change') },
  { value: $r('app.string.effect_type_tempo_pitch') }
];

const NODE_TYPE_EQUALIZER = 201;
const NODE_TYPE_NOISE_REDUCTION = 202;
const NODE_TYPE_SOUND_FIELD = 203;
const NODE_TYPE_AUDIO_SEPARATION = 204;
const NODE_TYPE_VOICE_BEAUTIFIER = 205;
const NODE_TYPE_ENVIRONMENT_EFFECT = 206;
const NODE_TYPE_AUDIO_MIXER = 207;
const NODE_TYPE_SPACE_RENDER = 208;
const NODE_TYPE_PURE_VOICE_CHANGE = 209;
const NODE_TYPE_GENERAL_VOICE_CHANGE = 210;
const NODE_TYPE_TEMPO_PITCH = 211;

const NODE_TYPE_NAMES: Record<number, Resource> = {
  201: $r('app.string.node_equalizer'),
  202: $r('app.string.node_noise_reduction'),
  203: $r('app.string.node_sound_field'),
  204: $r('app.string.node_audio_separation'),
  205: $r('app.string.node_voice_beautifier'),
  206: $r('app.string.node_environment_effect'),
  207: $r('app.string.node_audio_mixer'),
  208: $r('app.string.node_space_render'),
  209: $r('app.string.node_pure_voice_change'),
  210: $r('app.string.node_general_voice_change'),
  211: $r('app.string.node_tempo_pitch'),
};

const EFFECT_TYPE_TO_NODE_TYPE: number[] = [
  NODE_TYPE_EQUALIZER,
  NODE_TYPE_VOICE_BEAUTIFIER,
  NODE_TYPE_NOISE_REDUCTION,
  NODE_TYPE_SOUND_FIELD,
  NODE_TYPE_ENVIRONMENT_EFFECT,
  NODE_TYPE_SPACE_RENDER,
  NODE_TYPE_PURE_VOICE_CHANGE,
  NODE_TYPE_GENERAL_VOICE_CHANGE,
  NODE_TYPE_TEMPO_PITCH
];

@Entry
@Component
struct Index {
  @State message: ResourceStr = $r('app.string.msg_ready');
  @State napiReturnLog: ResourceStr = $r('app.string.msg_no_return_info');
  @State isPlay: boolean = false;
  @State type: number = 1;
  // Loading 状态
  @State isLoadingBaseEditor: boolean = false;
  @State isLoadingAudioSourceSeparation: boolean = false;
  @State isLoadingMixingAndCascading: boolean = false;
  @State isLoadingAudioFormatConverter: boolean = false;
  // 效果完成状态
  @State isBaseEditorCompleted: boolean = false;
  @State isAudioSourceSeparationCompleted: boolean = false;
  @State isMixingAndCascadingCompleted: boolean = false;
  @State isAudioFormatConverterCompleted: boolean = false;
  // 设备类型
  @State deviceType: string = '';
  // 节点支持状态
  @State isAudioSeparationNodeSupported: boolean = true;
  @State isMixingNodeSupported: boolean = true;
  @State isEqualizerNodeSupported: boolean = true;
  @State isSpaceRenderNodeSupported: boolean = true;

  @State effectType: number = 0;
  @State eqPresetIndex: number = 0;
  @State eqGains: number[] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  @State voiceBeautifierType: number = 1;
  @State soundFieldType: number = 1;
  @State environmentType: number = 1;
  @State generalVoiceChangeType: number = 1;
  @State pureVoiceChangeGender: number = 1;
  @State pureVoiceChangeType: number = 1;
  @State pureVoiceChangePitch: number = 0;
  @State tempoSpeed: number = 1.0;
  @State tempoPitch: number = 1.0;
  @State spacePositionX: number = 0;
  @State spacePositionY: number = 0;
  @State spacePositionZ: number = 0;
  @State spaceRotationX: number = 0;
  @State spaceRotationY: number = 0;
  @State spaceRotationZ: number = 0;
  @State spaceRotationSurroundTime: number = 10;
  @State spaceRotationSurroundDirection: number = 0;
  @State spaceExtensionRadius: number = 2.0;
  @State spaceExtensionAngle: number = 180;
  @State spaceRenderMode: number = 0;
  @State showEffectDialog: boolean = false;
  @State dialogEffectType: number = 0;
  @State dialogEqPresetIndex: number = 0;
  @State dialogEqGains: number[] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  @State dialogVoiceBeautifierType: number = 1;
  @State dialogSoundFieldType: number = 1;
  @State dialogEnvironmentType: number = 1;
  @State dialogGeneralVoiceChangeType: number = 1;
  @State dialogPureVoiceChangeGender: number = 1;
  @State dialogPureVoiceChangeType: number = 1;
  @State dialogPureVoiceChangePitch: number = 0;
  @State dialogTempoSpeed: number = 1.0;
  @State dialogTempoPitch: number = 1.0;
  @State dialogSpacePositionX: number = 0;
  @State dialogSpacePositionY: number = 0;
  @State dialogSpacePositionZ: number = 0;
  @State dialogSpaceRotationX: number = 0;
  @State dialogSpaceRotationY: number = 0;
  @State dialogSpaceRotationZ: number = 0;
  @State dialogSpaceRotationSurroundTime: number = 10;
  @State dialogSpaceRotationSurroundDirection: number = 0;
  @State dialogSpaceExtensionRadius: number = 2.0;
  @State dialogSpaceExtensionAngle: number = 180;
  @State dialogSpaceRenderMode: number = 0;

  // 更新NAPI返回信息
  updateNapiLog(msg: ResourceStr) {
    const timestamp = new Date().toLocaleTimeString();
    this.napiReturnLog = `[${timestamp}]\n${msg}`;
  }

  private getResStr(res: Resource, ...args: Array<string | number>): string {
    const ctx = this.getUIContext().getHostContext() as common.Context;
    return ctx.resourceManager.getStringSync(res.id, ...args);
  }

  private logError(err: Object): void {
    this.updateNapiLog(this.getResStr($r('app.string.error_prefix')) + JSON.stringify(err));
  }

  aboutToAppear() {
    this.deviceType = deviceInfo.productModel === 'emulator'
      ? this.getResStr($r('app.string.device_emulator'))
      : this.getResStr($r('app.string.device_real'));
    DirInitHelper.setUIContext(this.getUIContext());
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    let value = context.resourceManager.getRawFileContentSync("S16LE_2_48000.pcm");
    let myBuffer: ArrayBufferLike = value?.buffer;
    let filePath = context.filesDir + "/" + "S16LE_2_48000.pcm";
    let file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    fs.writeSync(file.fd, myBuffer);
    fs.closeSync(file);
  }

  checkNodesAndShowDialog(nodeTypes: number[]): boolean {
    for (let nodeType of nodeTypes) {
      let supported = audioSuiteNapi.CheckNodeSupport(nodeType);
      if (!supported) {
        const nodeName: string = NODE_TYPE_NAMES[nodeType]
          ? this.getResStr(NODE_TYPE_NAMES[nodeType])
          : this.getResStr($r('app.string.alert_node_type_fallback'), nodeType);
        this.getUIContext().showAlertDialog({
          title: $r('app.string.alert_node_not_supported_title'),
          message: this.getResStr($r('app.string.alert_node_not_supported_msg'), this.deviceType, nodeName),
          confirm: {
            value: $r('app.string.btn_confirm'),
            action: () => {}
          }
        });
        return false;
      }
    }
    return true;
  }

  build() {
    Stack() {
      Column() {
        NavDestination() {
          Column() {
            // 信息显示区域 - 固定在顶部
            Column() {
              Text($r('app.string.title_realtime_status'))
                .fontSize(18)
                .fontWeight(600)
                .margin({ bottom: 12 })

              // 当前状态
              Column() {
                Text($r('app.string.label_current_status'))
                  .fontSize(14)
                  .fontWeight(600)
                  .margin({ bottom: 8 })
                Text(this.message)
                  .fontSize(14)
                  .fontColor('#007DFF')
                  .width('100%')
                  .padding(10)
                  .backgroundColor('#F0F0F0')
                  .borderRadius(8)
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .margin({ bottom: 12 })

              // 设备类型
              Column() {
                Text($r('app.string.label_device_type'))
                  .fontSize(14)
                  .fontWeight(600)
                  .margin({ bottom: 8 })
                Text(this.deviceType)
                  .fontSize(14)
                  .fontColor('#FF9800')
                  .width('100%')
                  .padding(10)
                  .backgroundColor('#F0F0F0')
                  .borderRadius(8)
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .margin({ bottom: 12 })

              // NAPI返回信息
              Column() {
                Text($r('app.string.label_napi_return_info'))
                  .fontSize(14)
                  .fontWeight(600)
                  .margin({ bottom: 8 })
                Scroll() {
                  Text(this.napiReturnLog)
                    .fontSize(12)
                    .fontColor('#52C41A')
                    .width('100%')
                    .padding(10)
                    .backgroundColor('#F0F0F0')
                    .borderRadius(8)
                }
                .width('100%')
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .margin({ bottom: 16 })

            // 按钮区域 - 可滚动
            Scroll() {
              Column() {
                // 创建播放流按钮
                Button($r('app.string.btn_play_audio'))
                  .width('90%')
                  .height(30)
                  .margin({ bottom: 12 })
                  .enabled(!this.isPlay)
                  .onClick(async () => {
                    try {
                      this.isPlay = true;
                      this.type = 1;
                      let result: string = await audioSuiteNapi.CreateAudioRender(1);
                      this.message = $r('app.string.msg_play_original_success');
                      this.updateNapiLog(result);
                    } catch (err) {
                      this.message = $r('app.string.msg_play_original_fail');
                      this.logError(err);
                    }
                  })
                // 销毁播放流按钮
                Button($r('app.string.btn_stop_play'))
                  .width('90%')
                  .height(30)
                  .margin({ bottom: 12 })
                  .enabled(this.isPlay)
                  .onClick(async () => {
                    try {
                      this.isPlay = false;
                      let result: string = await audioSuiteNapi.DestroyAudioRender(this.type);
                      this.type = 1;
                      this.message = $r('app.string.msg_stop_play_success');
                      this.updateNapiLog(result);
                    } catch (err) {
                      this.message = $r('app.string.msg_stop_play_fail');
                      this.logError(err);
                    }
})

                Button($r('app.string.btn_add_audio_effect'))
                  .width('90%')
                  .height(30)
                  .margin({ bottom: 12 })
                  .onClick(() => {
                    this.syncCommittedToDialog();
                    this.showEffectDialog = true;
                  })

                Button($r('app.string.btn_play_with_effect'))
                  .width('90%')
                  .height(30)
                  .margin({ bottom: 12 })
                  .enabled(!this.isPlay && this.isBaseEditorCompleted)
                  .onClick(async () => {
                    try {
                      this.isPlay = true;
                      this.type = 1;
                      let result: string = await audioSuiteNapi.CreateAudioRender(2);
                      this.message = $r('app.string.msg_play_with_effect_success');
                      this.updateNapiLog(result);
                    } catch (err) {
                      this.message = $r('app.string.msg_play_with_effect_fail');
                      this.logError(err);
                    }
                  })

                Button($r('app.string.btn_audio_separation'))
                  .width('90%')
                  .height(30)
                  .margin({ bottom: 12 })
                  .enabled(this.isAudioSeparationNodeSupported)
                  .onClick(() => {
                    if (!this.checkNodesAndShowDialog([NODE_TYPE_AUDIO_SEPARATION])) {
                      this.isAudioSeparationNodeSupported = false;
                      this.message = $r('app.string.msg_audio_separation_node_unsupported');
                      return;
                    }
                    try {
                      this.message = $r('app.string.msg_audio_separation_in_progress');
                      this.isLoadingAudioSourceSeparation = true;
                      audioSuiteNapi.AudioSourceSeparationNapi((result: string) => {
                        this.isLoadingAudioSourceSeparation = false;
                        this.isAudioSourceSeparationCompleted = true;
                        this.message = $r('app.string.msg_audio_separation_success');
                        this.updateNapiLog(result);
                      });
                    } catch (err) {
                      this.isLoadingAudioSourceSeparation = false;
                      this.message = $r('app.string.msg_audio_separation_fail');
                      this.logError(err);
                    }
                  })

                Button($r('app.string.btn_play_accompaniment'))
                  .width('90%')
                  .height(30)
                  .margin({ bottom: 12 })
                  .enabled(!this.isPlay && this.isAudioSourceSeparationCompleted)
                  .onClick(async () => {
                    try {
                      this.isPlay = true;
                      this.type = 1;
                      let result: string = await audioSuiteNapi.CreateAudioRender(3);
                      this.message = $r('app.string.msg_play_accompaniment_success');
                      this.updateNapiLog(result);
                    } catch (err) {
                      this.message = $r('app.string.msg_play_accompaniment_fail');
                      this.logError(err);
                    }
                  })

                Button($r('app.string.btn_play_vocal'))
                  .width('90%')
                  .height(30)
                  .margin({ bottom: 12 })
                  .enabled(!this.isPlay && this.isAudioSourceSeparationCompleted)
                  .onClick(async () => {
                    try {
                      this.isPlay = true;
                      this.type = 1;
                      let result: string = await audioSuiteNapi.CreateAudioRender(4);
                      this.message = $r('app.string.msg_play_vocal_success');
                      this.updateNapiLog(result);
                    } catch (err) {
                      this.message = $r('app.string.msg_play_vocal_fail');
                      this.logError(err);
                    }
                  })

                Button($r('app.string.btn_mixing_cascade'))
                  .width('90%')
                  .height(30)
                  .margin({ bottom: 12 })
                  .enabled(this.isAudioSourceSeparationCompleted && this.isMixingNodeSupported)
                  .onClick(() => {
                    if (!this.checkNodesAndShowDialog([NODE_TYPE_SOUND_FIELD, NODE_TYPE_AUDIO_MIXER])) {
                      this.isMixingNodeSupported = false;
                      this.message = $r('app.string.msg_mixing_node_unsupported');
                      return;
                    }
                    try {
                      this.message = $r('app.string.msg_mixing_in_progress');
                      this.isLoadingMixingAndCascading = true;
                      audioSuiteNapi.MixingAndCascadingNapi((result: string) => {
                        this.isLoadingMixingAndCascading = false;
                        this.isMixingAndCascadingCompleted = true;
                        this.message = $r('app.string.msg_mixing_success');
                        this.updateNapiLog(result);
                      });
                    } catch (err) {
                      this.isLoadingMixingAndCascading = false;
                      this.message = $r('app.string.msg_mixing_fail');
                      this.logError(err);
                    }
                  })

                Button($r('app.string.btn_play_mixed'))
                  .width('90%')
                  .height(30)
                  .margin({ bottom: 12 })
                  .enabled(!this.isPlay && this.isMixingAndCascadingCompleted)
                  .onClick(async () => {
                    try {
                      this.isPlay = true;
                      this.type = 1;
                      let result: string = await audioSuiteNapi.CreateAudioRender(5);
                      this.message = $r('app.string.msg_play_mixed_success');
                      this.updateNapiLog(result);
                    } catch (err) {
                      this.message = $r('app.string.msg_play_mixed_fail');
                      this.logError(err);
                    }
                  })

                Button($r('app.string.btn_play_realtime_preview'))
                  .width('90%')
                  .height(30)
                  .margin({ bottom: 12 })
                  .enabled(!this.isPlay && this.isEqualizerNodeSupported)
                  .onClick(async () => {
                    if (!this.checkNodesAndShowDialog([NODE_TYPE_EQUALIZER])) {
                      this.isEqualizerNodeSupported = false;
                      this.message = $r('app.string.msg_equalizer_node_unsupported');
                      return;
                    }
                    try {
                      this.isPlay = true;
                      this.type = 2;
                      let result: string = await audioSuiteNapi.EqualizerEffectNapi();
                      this.message = $r('app.string.msg_realtime_preview_success');
                      this.updateNapiLog(result);
                    } catch (err) {
                      this.message = $r('app.string.msg_realtime_preview_fail');
                      this.logError(err);
                    }
                  })

                Button($r('app.string.btn_play_space_render'))
                  .width('90%')
                  .height(30)
                  .margin({ bottom: 12 })
                  .enabled(!this.isPlay && this.isAudioSourceSeparationCompleted && this.isSpaceRenderNodeSupported)
                  .onClick(async () => {
                    if (!this.checkNodesAndShowDialog([NODE_TYPE_SPACE_RENDER, NODE_TYPE_AUDIO_MIXER])) {
                      this.isSpaceRenderNodeSupported = false;
                      this.message = $r('app.string.msg_space_render_node_unsupported');
                      return;
                    }
                    try {
                      this.isPlay = true;
                      this.type = 3;
                      let result: string = await audioSuiteNapi.SpaceRenderRotationNapi();
                      this.message = $r('app.string.msg_space_render_success');
                      this.updateNapiLog(result);
                    } catch (err) {
                      this.message = $r('app.string.msg_space_render_fail');
                      this.logError(err);
                    }
                  })

                Button($r('app.string.btn_debug'))
                  .width('90%')
                  .height(30)
                  .margin({ bottom: 12 })
                  .enabled(this.type == 2)
                  .backgroundColor(this.type == 2 ? '#8B0000' : '#CCCCCC')
                  .onClick(async () => {
                    try {
                      await DirInitHelper.ensureDirExists();
                      let ret = audioSuiteNapi.TestPrintInfoToFile();
                      this.message = ret ? $r('app.string.msg_printinfo_test_success') : $r('app.string.msg_printinfo_test_fail');
                      this.updateNapiLog(ret ? this.getResStr($r('app.string.msg_printinfo_output_success')) : this.getResStr($r('app.string.msg_printinfo_output_fail')));
                    } catch (err) {
                      this.message = $r('app.string.msg_printinfo_test_fail');
                      this.logError(err);
                    }
                  })

                Button($r('app.string.btn_format_conversion'))
                  .width('90%')
                  .height(30)
                  .margin({ bottom: 12 })
                  .enabled(!this.isPlay)
                  .onClick(() => {
                    try {
                      this.message = $r('app.string.msg_format_conversion_in_progress');
                      this.isLoadingAudioFormatConverter = true;
                      audioSuiteNapi.AudioFormatConverterNapi((result: string) => {
                        this.isLoadingAudioFormatConverter = false;
                        this.isAudioFormatConverterCompleted = true;
                        this.message = $r('app.string.msg_format_conversion_success');
                        this.updateNapiLog(result);
                      });
                    } catch (err) {
                      this.isLoadingAudioFormatConverter = false;
                      this.message = $r('app.string.msg_format_conversion_fail');
                      this.logError(err);
                    }
                  })
              }
              .width('100%')
              .padding({ left: 16, right: 16 })
              .alignItems(HorizontalAlign.Center)
            }
            .width('100%')
            .layoutWeight(1)
            .scrollable(ScrollDirection.Vertical)
            .scrollBar(BarState.Auto)
            .edgeEffect(EdgeEffect.Spring)
          }
          .width('100%')
          .height('100%')
        }
        .width('100%')
        .height('100%')

        // Loading 遮罩层
        if (this.isLoadingBaseEditor || this.isLoadingAudioSourceSeparation || this.isLoadingMixingAndCascading || this.isLoadingAudioFormatConverter) {
          Column() {
            LoadingProgress()
              .width(40)
              .height(40)
              .color('#007DFF')
              .margin({ bottom: 12 })

            Text(this.isLoadingBaseEditor ? $r('app.string.loading_adding_effect') :
              this.isLoadingAudioSourceSeparation ? $r('app.string.loading_audio_separation') :
                this.isLoadingMixingAndCascading ? $r('app.string.loading_mixing_cascade') : $r('app.string.loading_processing'))
              .fontSize(16)
              .fontColor('#FFFFFF')
          }
          .width('100%')
          .height('100%')
          .position({ x: 0, y: 0 })
          .justifyContent(FlexAlign.Center)
          .backgroundColor('rgba(0, 0, 0, 0.6)')
          .zIndex(999)
        }

        if (this.isLoadingBaseEditor || this.isLoadingAudioSourceSeparation || this.isLoadingMixingAndCascading || this.isLoadingAudioFormatConverter) {
          Column() {
            LoadingProgress()
              .width(40)
              .height(40)
              .color('#007DFF')
              .margin({ bottom: 12 })

            Text(this.isLoadingBaseEditor ? $r('app.string.loading_adding_effect') :
              this.isLoadingAudioSourceSeparation ? $r('app.string.loading_audio_separation') :
                this.isLoadingMixingAndCascading ? $r('app.string.loading_mixing_cascade') : $r('app.string.loading_processing'))
              .fontSize(16)
              .fontColor('#FFFFFF')
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .backgroundColor('rgba(0, 0, 0, 0.6)')
        }

        // 效果设置弹窗
        if (this.showEffectDialog) {
          Column() {
            Text($r('app.string.dialog_audio_effect_settings'))
              .fontSize(18)
              .fontWeight(600)
              .margin({ bottom: 16 })

            Text($r('app.string.dialog_effect_type'))
              .fontSize(14)
              .fontWeight(500)
              .margin({ bottom: 8 })
            Select(EFFECT_TYPE_OPTIONS)
              .selected(this.dialogEffectType)
              .value(EFFECT_TYPE_NAMES[this.dialogEffectType])
              .width('100%')
              .onSelect((index: number) => {
                this.dialogEffectType = index;
                if (index === 0) {
                  this.dialogEqPresetIndex = 0;
                  this.dialogEqGains = EQ_PRESET_VALUES[1].slice();
                }
              })

            if (this.dialogEffectType === 0) {
              Text($r('app.string.dialog_preset_effect'))
                .fontSize(14)
                .fontWeight(500)
                .margin({ top: 12, bottom: 8 })
              Select(EQ_PRESET_OPTIONS)
                .selected(this.dialogEqPresetIndex === -1 ? 0 : this.dialogEqPresetIndex + 1)
                .value(EQ_PRESET_NAMES[this.dialogEqPresetIndex === -1 ? 0 : this.dialogEqPresetIndex + 1])
                .width('100%')
                .onSelect((index: number) => {
                  this.dialogEqPresetIndex = index === 0 ? -1 : index - 1;
                  this.dialogEqGains = EQ_PRESET_VALUES[index].slice();
                })

              Text($r('app.string.dialog_band_gain_setting'))
                .fontSize(14)
                .fontWeight(500)
                .margin({ top: 12, bottom: 8 })
              Scroll() {
                Column() {
                  ForEach(EQ_BAND_LABELS, (label: string, index: number) => {
                    Row() {
                      Text(label)
                        .fontSize(12)
                        .width('20%')
                      Slider({
                        value: this.dialogEqGains[index],
                        min: -10,
                        max: 10,
                        step: 1,
                        style: SliderStyle.OutSet
                      })
                        .width('50%')
                        .blockColor('#007DFF')
                        .trackColor('#CCCCCC')
                        .selectedColor('#007DFF')
                        .onChange((value: number) => {
                          this.dialogEqGains[index] = Math.round(value);
                          this.dialogEqPresetIndex = -1;
                        })
                      Text(`${this.dialogEqGains[index]} dB`)
                        .fontSize(12)
                        .width('30%')
                        .textAlign(TextAlign.Center)
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.SpaceBetween)
                    .margin({ bottom: 4 })
                  }, (label: string) => label)
                }
                .width('100%')
              }
              .width('100%')
              .height(150)
              .scrollable(ScrollDirection.Vertical)
              .scrollBar(BarState.Auto)
            }

            if (this.dialogEffectType === 1) {
              Text($r('app.string.dialog_beautifier_type'))
                .fontSize(14)
                .fontWeight(500)
                .margin({ top: 12, bottom: 8 })
              Select(VOICE_BEAUTIFIER_OPTIONS)
                .selected(this.dialogVoiceBeautifierType - 1)
                .value(VOICE_BEAUTIFIER_NAMES[this.dialogVoiceBeautifierType - 1])
                .width('100%')
                .onSelect((index: number) => {
                  this.dialogVoiceBeautifierType = index + 1;
                })
            }

            if (this.dialogEffectType === 2) {
              Text($r('app.string.dialog_noise_reduction_hint'))
                .fontSize(13)
                .fontColor('#666666')
                .margin({ top: 16 })
            }

            if (this.dialogEffectType === 3) {
              Text($r('app.string.dialog_sound_field_type'))
                .fontSize(14)
                .fontWeight(500)
                .margin({ top: 12, bottom: 8 })
              Select(SOUND_FIELD_OPTIONS)
                .selected(this.dialogSoundFieldType - 1)
                .value(SOUND_FIELD_NAMES[this.dialogSoundFieldType - 1])
                .width('100%')
                .onSelect((index: number) => {
                  this.dialogSoundFieldType = index + 1;
                })
            }

            if (this.dialogEffectType === 4) {
              Text($r('app.string.dialog_environment_type'))
                .fontSize(14)
                .fontWeight(500)
                .margin({ top: 12, bottom: 8 })
              Select(ENVIRONMENT_OPTIONS)
                .selected(this.dialogEnvironmentType - 1)
                .value(ENVIRONMENT_NAMES[this.dialogEnvironmentType - 1])
                .width('100%')
                .onSelect((index: number) => {
                  this.dialogEnvironmentType = index + 1;
                })
            }

            if (this.dialogEffectType === 5) {
              Text($r('app.string.dialog_space_render_scene'))
                .fontSize(14).fontWeight(500).margin({ top: 12, bottom: 8 })
              Select(SPACE_RENDER_MODE_OPTIONS)
                .selected(this.dialogSpaceRenderMode)
                .value(SPACE_RENDER_MODE_NAMES[this.dialogSpaceRenderMode])
                .width('100%')
                .onSelect((index: number) => { this.dialogSpaceRenderMode = index; })

              if (this.dialogSpaceRenderMode === 0) {
              Text($r('app.string.dialog_position_params'))
                .fontSize(14).fontWeight(500).margin({ top: 12, bottom: 8 })
              Row() {
                Text('X').fontSize(12).width('10%')
                Slider({ value: this.dialogSpacePositionX, min: -5, max: 5, step: 0.1, style: SliderStyle.OutSet })
                  .width('70%').blockColor('#007DFF').selectedColor('#007DFF')
                  .onChange((v: number) => { this.dialogSpacePositionX = Math.round(v * 10) / 10; })
                Text(`${this.dialogSpacePositionX}`).fontSize(12).width('20%').textAlign(TextAlign.Center)
              }.width('100%').justifyContent(FlexAlign.SpaceBetween).margin({ bottom: 4 })
              Row() {
                Text('Y').fontSize(12).width('10%')
                Slider({ value: this.dialogSpacePositionY, min: -5, max: 5, step: 0.1, style: SliderStyle.OutSet })
                  .width('70%').blockColor('#007DFF').selectedColor('#007DFF')
                  .onChange((v: number) => { this.dialogSpacePositionY = Math.round(v * 10) / 10; })
                Text(`${this.dialogSpacePositionY}`).fontSize(12).width('20%').textAlign(TextAlign.Center)
              }.width('100%').justifyContent(FlexAlign.SpaceBetween).margin({ bottom: 4 })
              Row() {
                Text('Z').fontSize(12).width('10%')
                Slider({ value: this.dialogSpacePositionZ, min: -5, max: 5, step: 0.1, style: SliderStyle.OutSet })
                  .width('70%').blockColor('#007DFF').selectedColor('#007DFF')
                  .onChange((v: number) => { this.dialogSpacePositionZ = Math.round(v * 10) / 10; })
                Text(`${this.dialogSpacePositionZ}`).fontSize(12).width('20%').textAlign(TextAlign.Center)
              }.width('100%').justifyContent(FlexAlign.SpaceBetween)
              }

              if (this.dialogSpaceRenderMode === 1) {
              Text($r('app.string.dialog_rotation_params'))
                .fontSize(14).fontWeight(500).margin({ top: 12, bottom: 8 })
              Row() {
                Text('X').fontSize(12).width('10%')
                Slider({ value: this.dialogSpaceRotationX, min: -5, max: 5, step: 0.1, style: SliderStyle.OutSet })
                  .width('70%').blockColor('#007DFF').selectedColor('#007DFF')
                  .onChange((v: number) => { this.dialogSpaceRotationX = Math.round(v * 10) / 10; })
                Text(`${this.dialogSpaceRotationX}`).fontSize(12).width('20%').textAlign(TextAlign.Center)
              }.width('100%').justifyContent(FlexAlign.SpaceBetween).margin({ bottom: 4 })
              Row() {
                Text('Y').fontSize(12).width('10%')
                Slider({ value: this.dialogSpaceRotationY, min: -5, max: 5, step: 0.1, style: SliderStyle.OutSet })
                  .width('70%').blockColor('#007DFF').selectedColor('#007DFF')
                  .onChange((v: number) => { this.dialogSpaceRotationY = Math.round(v * 10) / 10; })
                Text(`${this.dialogSpaceRotationY}`).fontSize(12).width('20%').textAlign(TextAlign.Center)
              }.width('100%').justifyContent(FlexAlign.SpaceBetween).margin({ bottom: 4 })
              Row() {
                Text('Z').fontSize(12).width('10%')
                Slider({ value: this.dialogSpaceRotationZ, min: -5, max: 5, step: 0.1, style: SliderStyle.OutSet })
                  .width('70%').blockColor('#007DFF').selectedColor('#007DFF')
                  .onChange((v: number) => { this.dialogSpaceRotationZ = Math.round(v * 10) / 10; })
                Text(`${this.dialogSpaceRotationZ}`).fontSize(12).width('20%').textAlign(TextAlign.Center)
              }.width('100%').justifyContent(FlexAlign.SpaceBetween).margin({ bottom: 4 })
              Row() {
                Text($r('app.string.dialog_surround_time')).fontSize(12).width('30%')
                Slider({ value: this.dialogSpaceRotationSurroundTime, min: 2, max: 40, step: 1, style: SliderStyle.OutSet })
                  .width('50%').blockColor('#007DFF').selectedColor('#007DFF')
                  .onChange((v: number) => { this.dialogSpaceRotationSurroundTime = Math.round(v); })
                Text(`${this.dialogSpaceRotationSurroundTime}s`).fontSize(12).width('20%').textAlign(TextAlign.Center)
              }.width('100%').justifyContent(FlexAlign.SpaceBetween).margin({ bottom: 4 })
              Row() {
                Text($r('app.string.dialog_surround_direction')).fontSize(12).width('30%')
                Select(SURROUND_DIRECTION_OPTIONS)
                  .selected(this.dialogSpaceRotationSurroundDirection)
                  .value(SURROUND_DIRECTION_NAMES[this.dialogSpaceRotationSurroundDirection])
                  .width('70%')
                  .onSelect((index: number) => { this.dialogSpaceRotationSurroundDirection = index; })
              }.width('100%').justifyContent(FlexAlign.SpaceBetween)
              }

              if (this.dialogSpaceRenderMode === 2) {
              Text($r('app.string.dialog_extension_params'))
                .fontSize(14).fontWeight(500).margin({ top: 12, bottom: 8 })
              Row() {
                Text($r('app.string.dialog_radius')).fontSize(12).width('30%')
                Slider({ value: this.dialogSpaceExtensionRadius, min: 1, max: 5, step: 0.1, style: SliderStyle.OutSet })
                  .width('50%').blockColor('#007DFF').selectedColor('#007DFF')
                  .onChange((v: number) => { this.dialogSpaceExtensionRadius = Math.round(v * 10) / 10; })
                Text(`${this.dialogSpaceExtensionRadius}`).fontSize(12).width('20%').textAlign(TextAlign.Center)
              }.width('100%').justifyContent(FlexAlign.SpaceBetween).margin({ bottom: 4 })
              Row() {
                Text($r('app.string.dialog_angle')).fontSize(12).width('30%')
                Slider({ value: this.dialogSpaceExtensionAngle, min: 0, max: 360, step: 1, style: SliderStyle.OutSet })
                  .width('50%').blockColor('#007DFF').selectedColor('#007DFF')
                  .onChange((v: number) => { this.dialogSpaceExtensionAngle = Math.round(v); })
                Text(`${this.dialogSpaceExtensionAngle}°`).fontSize(12).width('20%').textAlign(TextAlign.Center)
              }.width('100%').justifyContent(FlexAlign.SpaceBetween)
              }
            }

            if (this.dialogEffectType === 6) {
              Text($r('app.string.dialog_speaker_gender'))
                .fontSize(14).fontWeight(500).margin({ top: 12, bottom: 8 })
              Select(PURE_VOICE_GENDER_OPTIONS)
                .selected(this.dialogPureVoiceChangeGender - 1)
                .value(PURE_VOICE_GENDER_NAMES[this.dialogPureVoiceChangeGender - 1])
                .width('100%')
                .onSelect((index: number) => { this.dialogPureVoiceChangeGender = index + 1; })
              Text($r('app.string.dialog_voice_change_type'))
                .fontSize(14).fontWeight(500).margin({ top: 12, bottom: 8 })
              Select(PURE_VOICE_TYPE_OPTIONS)
                .selected(this.dialogPureVoiceChangeType - 1)
                .value(PURE_VOICE_TYPE_NAMES[this.dialogPureVoiceChangeType - 1])
                .width('100%')
                .onSelect((index: number) => { this.dialogPureVoiceChangeType = index + 1; })
              Text($r('app.string.dialog_pitch_label'))
                .fontSize(14).fontWeight(500).margin({ top: 12, bottom: 8 })
              Row() {
                Text('pitch').fontSize(12).width('30%')
                Slider({ value: this.dialogPureVoiceChangePitch, min: 0, max: 3, step: 0.1, style: SliderStyle.OutSet })
                  .width('50%').blockColor('#007DFF').selectedColor('#007DFF')
                  .onChange((v: number) => { this.dialogPureVoiceChangePitch = Math.round(v * 10) / 10; })
                Text(`${this.dialogPureVoiceChangePitch}`).fontSize(12).width('20%').textAlign(TextAlign.Center)
              }.width('100%').justifyContent(FlexAlign.SpaceBetween)
            }

            if (this.dialogEffectType === 7) {
              Text($r('app.string.dialog_general_voice_change_type'))
                .fontSize(14).fontWeight(500).margin({ top: 12, bottom: 8 })
              Select(GENERAL_VOICE_CHANGE_OPTIONS)
                .selected(this.dialogGeneralVoiceChangeType - 1)
                .value(GENERAL_VOICE_CHANGE_NAMES[this.dialogGeneralVoiceChangeType - 1])
                .width('100%')
                .onSelect((index: number) => { this.dialogGeneralVoiceChangeType = index + 1; })
            }

            if (this.dialogEffectType === 8) {
              Text($r('app.string.dialog_speed_label'))
                .fontSize(14).fontWeight(500).margin({ top: 12, bottom: 8 })
              Row() {
                Text('speed').fontSize(12).width('30%')
                Slider({ value: this.dialogTempoSpeed, min: 0.5, max: 10, step: 0.1, style: SliderStyle.OutSet })
                  .width('50%').blockColor('#007DFF').selectedColor('#007DFF')
                  .onChange((v: number) => { this.dialogTempoSpeed = Math.round(v * 10) / 10; })
                Text(`${this.dialogTempoSpeed}`).fontSize(12).width('20%').textAlign(TextAlign.Center)
              }.width('100%').justifyContent(FlexAlign.SpaceBetween).margin({ bottom: 4 })
              Text($r('app.string.dialog_tempo_pitch_label'))
                .fontSize(14).fontWeight(500).margin({ top: 12, bottom: 8 })
              Row() {
                Text('pitch').fontSize(12).width('30%')
                Slider({ value: this.dialogTempoPitch, min: 0.1, max: 5, step: 0.1, style: SliderStyle.OutSet })
                  .width('50%').blockColor('#007DFF').selectedColor('#007DFF')
                  .onChange((v: number) => { this.dialogTempoPitch = Math.round(v * 10) / 10; })
                Text(`${this.dialogTempoPitch}`).fontSize(12).width('20%').textAlign(TextAlign.Center)
              }.width('100%').justifyContent(FlexAlign.SpaceBetween)
            }

            Row() {
              Button($r('app.string.btn_cancel'))
                .width('45%')
                .height(36)
                .backgroundColor('#CCCCCC')
                .onClick(() => {
                  this.showEffectDialog = false;
                })

              Button($r('app.string.btn_confirm'))
                .width('45%')
                .height(36)
                .onClick(() => {
                  this.commitDialogToCommitted();
                  this.showEffectDialog = false;
                  this.applyEffect();
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ top: 20 })
          }
          .width('85%')
          .padding(20)
          .backgroundColor(Color.White)
          .borderRadius(12)
          .position({ x: '7.5%', y: '50%' })
          .translate({ y: '-50%' })
          .zIndex(1000)
        }

        // 弹窗背景遮罩
        if (this.showEffectDialog) {
          Column()
            .width('100%')
            .height('100%')
            .position({ x: 0, y: 0 })
            .backgroundColor('rgba(0, 0, 0, 0.4)')
            .zIndex(999)
            .onClick(() => {
              this.showEffectDialog = false;
            })
        }
      }
      .width('100%')
      .height('100%')
    }
  }

  syncCommittedToDialog() {
    this.dialogEffectType = this.effectType;
    this.dialogEqPresetIndex = this.eqPresetIndex;
    this.dialogEqGains = this.eqGains.slice();
    this.dialogVoiceBeautifierType = this.voiceBeautifierType;
    this.dialogSoundFieldType = this.soundFieldType;
    this.dialogEnvironmentType = this.environmentType;
    this.dialogGeneralVoiceChangeType = this.generalVoiceChangeType;
    this.dialogPureVoiceChangeGender = this.pureVoiceChangeGender;
    this.dialogPureVoiceChangeType = this.pureVoiceChangeType;
    this.dialogPureVoiceChangePitch = this.pureVoiceChangePitch;
    this.dialogTempoSpeed = this.tempoSpeed;
    this.dialogTempoPitch = this.tempoPitch;
    this.dialogSpacePositionX = this.spacePositionX;
    this.dialogSpacePositionY = this.spacePositionY;
    this.dialogSpacePositionZ = this.spacePositionZ;
    this.dialogSpaceRotationX = this.spaceRotationX;
    this.dialogSpaceRotationY = this.spaceRotationY;
    this.dialogSpaceRotationZ = this.spaceRotationZ;
    this.dialogSpaceRotationSurroundTime = this.spaceRotationSurroundTime;
    this.dialogSpaceRotationSurroundDirection = this.spaceRotationSurroundDirection;
    this.dialogSpaceExtensionRadius = this.spaceExtensionRadius;
    this.dialogSpaceExtensionAngle = this.spaceExtensionAngle;
    this.dialogSpaceRenderMode = this.spaceRenderMode;
  }

  commitDialogToCommitted() {
    this.effectType = this.dialogEffectType;
    this.eqPresetIndex = this.dialogEqPresetIndex;
    this.eqGains = this.dialogEqGains.slice();
    this.voiceBeautifierType = this.dialogVoiceBeautifierType;
    this.soundFieldType = this.dialogSoundFieldType;
    this.environmentType = this.dialogEnvironmentType;
    this.generalVoiceChangeType = this.dialogGeneralVoiceChangeType;
    this.pureVoiceChangeGender = this.dialogPureVoiceChangeGender;
    this.pureVoiceChangeType = this.dialogPureVoiceChangeType;
    this.pureVoiceChangePitch = this.dialogPureVoiceChangePitch;
    this.tempoSpeed = this.dialogTempoSpeed;
    this.tempoPitch = this.dialogTempoPitch;
    this.spacePositionX = this.dialogSpacePositionX;
    this.spacePositionY = this.dialogSpacePositionY;
    this.spacePositionZ = this.dialogSpacePositionZ;
    this.spaceRotationX = this.dialogSpaceRotationX;
    this.spaceRotationY = this.dialogSpaceRotationY;
    this.spaceRotationZ = this.dialogSpaceRotationZ;
    this.spaceRotationSurroundTime = this.dialogSpaceRotationSurroundTime;
    this.spaceRotationSurroundDirection = this.dialogSpaceRotationSurroundDirection;
    this.spaceExtensionRadius = this.dialogSpaceExtensionRadius;
    this.spaceExtensionAngle = this.dialogSpaceExtensionAngle;
    this.spaceRenderMode = this.dialogSpaceRenderMode;
  }

  buildEffectParams(): audioSuiteNapi.EffectParams {
    let params: audioSuiteNapi.EffectParams = {};
    if (this.effectType === 0) {
      params.eqPresetIndex = this.eqPresetIndex;
      params.eqGains = this.eqGains;
    } else if (this.effectType === 1) {
      params.voiceBeautifierType = this.voiceBeautifierType;
    } else if (this.effectType === 3) {
      params.soundFieldType = this.soundFieldType;
    } else if (this.effectType === 4) {
      params.environmentType = this.environmentType;
    } else if (this.effectType === 5) {
      this.fillSpaceRenderParams(params);
    } else if (this.effectType === 6) {
      params.pureVoiceChangeGender = this.pureVoiceChangeGender;
      params.pureVoiceChangeType = this.pureVoiceChangeType;
      params.pureVoiceChangePitch = this.pureVoiceChangePitch;
    } else if (this.effectType === 7) {
      params.generalVoiceChangeType = this.generalVoiceChangeType;
    } else if (this.effectType === 8) {
      params.tempoSpeed = this.tempoSpeed;
      params.tempoPitch = this.tempoPitch;
    }
    return params;
  }

  fillSpaceRenderParams(params: audioSuiteNapi.EffectParams) {
    params.spaceRenderMode = this.spaceRenderMode;
    params.spacePositionX = this.spacePositionX;
    params.spacePositionY = this.spacePositionY;
    params.spacePositionZ = this.spacePositionZ;
    params.spaceRotationX = this.spaceRotationX;
    params.spaceRotationY = this.spaceRotationY;
    params.spaceRotationZ = this.spaceRotationZ;
    params.spaceRotationSurroundTime = this.spaceRotationSurroundTime;
    params.spaceRotationSurroundDirection = this.spaceRotationSurroundDirection;
    params.spaceExtensionRadius = this.spaceExtensionRadius;
    params.spaceExtensionAngle = this.spaceExtensionAngle;
  }

  applyEffect() {
    let nodeType = EFFECT_TYPE_TO_NODE_TYPE[this.effectType];
    if (!this.checkNodesAndShowDialog([nodeType])) {
      this.message = $r('app.string.msg_effect_node_unsupported');
      return;
    }
    try {
      this.message = $r('app.string.msg_add_effect_in_progress');
      this.isLoadingBaseEditor = true;
      let params = this.buildEffectParams();
      audioSuiteNapi.BaseEditor(this.effectType, params, (result: string) => {
        this.isLoadingBaseEditor = false;
        this.isBaseEditorCompleted = true;
        this.message = $r('app.string.msg_add_effect_success');
        this.updateNapiLog(result);
      });
    } catch (err) {
      this.isLoadingBaseEditor = false;
      this.message = $r('app.string.msg_add_effect_fail');
      this.logError(err);
    }
  }
}