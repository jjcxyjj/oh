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

#ifndef MANUAL_RENDERING_H
#define MANUAL_RENDERING_H

#include "pcm_file_utils.h"
#include <cstdint>

/* 空间渲染模式枚举 */
enum SpaceRenderMode : int {
    SPACE_RENDER_MODE_POSITION = 0,  /* 固定摆位模式 */
    SPACE_RENDER_MODE_ROTATION = 1,  /* 旋转模式 */
    SPACE_RENDER_MODE_EXTENSION = 2, /* 扩展模式 */
};

const int AUDIO_EQ_BAND_NUM = 10;

enum AudioEffectType {
    AUDIO_EFFECT_TYPE_EQUALIZER = 0,
    AUDIO_EFFECT_TYPE_VOICE_BEAUTIFIER = 1,
    AUDIO_EFFECT_TYPE_NOISE_REDUCTION = 2,
    AUDIO_EFFECT_TYPE_SOUND_FIELD = 3,
    AUDIO_EFFECT_TYPE_ENVIRONMENT_EFFECT = 4,
    AUDIO_EFFECT_TYPE_SPACE_RENDER = 5,
    AUDIO_EFFECT_TYPE_PURE_VOICE_CHANGE = 6,
    AUDIO_EFFECT_TYPE_GENERAL_VOICE_CHANGE = 7,
    AUDIO_EFFECT_TYPE_TEMPO_PITCH = 8
};

enum EqualizerPresetType {
    EQ_PRESET_CUSTOM = -1,
    EQ_PRESET_DEFAULT = 0,
    EQ_PRESET_BALLADS = 1,
    EQ_PRESET_CHINESE_STYLE = 2,
    EQ_PRESET_CLASSICAL = 3,
    EQ_PRESET_DANCE_MUSIC = 4,
    EQ_PRESET_JAZZ = 5,
    EQ_PRESET_POP = 6,
    EQ_PRESET_RB = 7,
    EQ_PRESET_ROCK = 8
};

struct EffectParams {
    int effectType;
    int eqPresetIndex;
    int32_t eqGains[AUDIO_EQ_BAND_NUM];
    int voiceBeautifierType;
    int soundFieldType;
    int environmentType;
    int generalVoiceChangeType;
    int pureVoiceChangeGender;
    int pureVoiceChangeType;
    float pureVoiceChangePitch;
    float tempoSpeed;
    float tempoPitch;
    float spacePositionX;
    float spacePositionY;
    float spacePositionZ;
    float spaceRotationX;
    float spaceRotationY;
    float spaceRotationZ;
    int32_t spaceRotationSurroundTime;
    int spaceRotationSurroundDirection;
    float spaceExtensionRadius;
    int32_t spaceExtensionAngle;
    SpaceRenderMode spaceRenderMode;
};

void BaseEditorEffect(AudioDataInfo *audioInfo, const char *newFilePath, int effectType, const EffectParams &params);
bool AudioSourceSeparation(AudioDataInfo *audioInfo, const char *vocalsFilePath, const char *accompanimentFilePath);
void MixingAndCascading(AudioDataInfo *audioInfoForField, AudioDataInfo *audioInfoForMix, const char *mixFilePath);

#endif