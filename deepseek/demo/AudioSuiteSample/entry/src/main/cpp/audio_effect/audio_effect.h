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

#ifndef AUDIO_EFFECT_H
#define AUDIO_EFFECT_H

#include <memory>
#include <ohaudiosuite/native_audio_suite_base.h>
#include <ohaudiosuite/native_audio_suite_engine.h>
#include "../manual_rendering.h"

class AudioEffectStrategy {
public:
    virtual ~AudioEffectStrategy() = default;
    virtual OH_AudioNode_Type GetNodeType() const = 0;
    virtual void CreateAndApply(OH_AudioSuitePipeline *pipeline, OH_AudioNodeBuilder *builder, OH_AudioNode **node,
                                const EffectParams &params) = 0;
};

class EqualizerStrategy : public AudioEffectStrategy {
public:
    OH_AudioNode_Type GetNodeType() const override
    {
        return OH_AudioNode_Type::EFFECT_NODE_TYPE_EQUALIZER;
    }

    // 根据预置类型或自定义参数获取均衡器增益值。
    static OH_EqualizerFrequencyBandGains GetEqualizerGains(const EffectParams &params)
    {
        OH_EqualizerFrequencyBandGains gains;
        switch (params.eqPresetIndex) {
            case EQ_PRESET_DEFAULT:
                gains = OH_EQUALIZER_PARAM_DEFAULT;
                break;
            case EQ_PRESET_BALLADS:
                gains = OH_EQUALIZER_PARAM_BALLADS;
                break;
            case EQ_PRESET_CHINESE_STYLE:
                gains = OH_EQUALIZER_PARAM_CHINESE_STYLE;
                break;
            case EQ_PRESET_CLASSICAL:
                gains = OH_EQUALIZER_PARAM_CLASSICAL;
                break;
            case EQ_PRESET_DANCE_MUSIC:
                gains = OH_EQUALIZER_PARAM_DANCE_MUSIC;
                break;
            case EQ_PRESET_JAZZ:
                gains = OH_EQUALIZER_PARAM_JAZZ;
                break;
            case EQ_PRESET_POP:
                gains = OH_EQUALIZER_PARAM_POP;
                break;
            case EQ_PRESET_RB:
                gains = OH_EQUALIZER_PARAM_RB;
                break;
            case EQ_PRESET_ROCK:
                gains = OH_EQUALIZER_PARAM_ROCK;
                break;
            case EQ_PRESET_CUSTOM:
            default:
                for (int i = 0; i < AUDIO_EQ_BAND_NUM; i++) {
                    gains.gains[i] = params.eqGains[i];
                }
                break;
        }
        return gains;
    }

    void CreateAndApply(OH_AudioSuitePipeline *pipeline, OH_AudioNodeBuilder *builder, OH_AudioNode **node,
                        const EffectParams &params) override
    {
        // [Start audioSuite_SetEqualizerType]
        // 设置为均衡器节点类型。
        OH_AudioSuiteNodeBuilder_SetNodeType(builder, OH_AudioNode_Type::EFFECT_NODE_TYPE_EQUALIZER);
        // 创建均衡器节点。
        OH_AudioSuiteEngine_CreateNode(pipeline, builder, node);
        // [StartExclude audioSuite_SetEqualizerType]
        OH_EqualizerFrequencyBandGains gains = GetEqualizerGains(params);
        // [EndExclude audioSuite_SetEqualizerType]
        // 设置均衡器节点效果。
        OH_AudioSuiteEngine_SetEqualizerFrequencyBandGains(*node, gains);
        // [End audioSuite_SetEqualizerType]
    }
};

class VoiceBeautifierStrategy : public AudioEffectStrategy {
public:
    OH_AudioNode_Type GetNodeType() const override
    {
        return OH_AudioNode_Type::EFFECT_NODE_TYPE_VOICE_BEAUTIFIER;
    }

    void CreateAndApply(OH_AudioSuitePipeline *pipeline, OH_AudioNodeBuilder *builder, OH_AudioNode **node,
                        const EffectParams &params) override
    {
        // [Start audioSuite_SetVoiceBeautifierType]
        // 设置为声音美化节点类型。
        OH_AudioSuiteNodeBuilder_SetNodeType(builder, OH_AudioNode_Type::EFFECT_NODE_TYPE_VOICE_BEAUTIFIER);
        // 创建声音美化节点。
        OH_AudioSuiteEngine_CreateNode(pipeline, builder, node);
        // 设置声音美化节点效果。
        OH_AudioSuiteEngine_SetVoiceBeautifierType(*node,
                                                   static_cast<OH_VoiceBeautifierType>(params.voiceBeautifierType));
        // [End audioSuite_SetVoiceBeautifierType]
    }
};

class NoiseReductionStrategy : public AudioEffectStrategy {
public:
    OH_AudioNode_Type GetNodeType() const override
    {
        return OH_AudioNode_Type::EFFECT_NODE_TYPE_NOISE_REDUCTION;
    }

    void CreateAndApply(OH_AudioSuitePipeline *pipeline, OH_AudioNodeBuilder *builder, OH_AudioNode **node,
                        const EffectParams &params) override
    {
        // [Start audioSuite_SetNoiseReductionType]
        // 设置为降噪节点类型。
        OH_AudioSuiteNodeBuilder_SetNodeType(builder, OH_AudioNode_Type::EFFECT_NODE_TYPE_NOISE_REDUCTION);
        // 创建降噪节点。
        OH_AudioSuiteEngine_CreateNode(pipeline, builder, node);
        // [End audioSuite_SetNoiseReductionType]
    }
};

class SoundFieldStrategy : public AudioEffectStrategy {
public:
    OH_AudioNode_Type GetNodeType() const override
    {
        return OH_AudioNode_Type::EFFECT_NODE_TYPE_SOUND_FIELD;
    }

    void CreateAndApply(OH_AudioSuitePipeline *pipeline, OH_AudioNodeBuilder *builder, OH_AudioNode **node,
                        const EffectParams &params) override
    {
        // [Start audioSuite_SetSoundFieldType]
        // 设置为声场节点类型。
        OH_AudioSuiteNodeBuilder_SetNodeType(builder, OH_AudioNode_Type::EFFECT_NODE_TYPE_SOUND_FIELD);
        // 创建声场节点。
        OH_AudioSuiteEngine_CreateNode(pipeline, builder, node);
        // 设置声场节点效果。
        OH_AudioSuiteEngine_SetSoundFieldType(*node, static_cast<OH_SoundFieldType>(params.soundFieldType));
        // [End audioSuite_SetSoundFieldType]
    }
};

class EnvironmentEffectStrategy : public AudioEffectStrategy {
public:
    OH_AudioNode_Type GetNodeType() const override
    {
        return OH_AudioNode_Type::EFFECT_NODE_TYPE_ENVIRONMENT_EFFECT;
    }

    void CreateAndApply(OH_AudioSuitePipeline *pipeline, OH_AudioNodeBuilder *builder, OH_AudioNode **node,
                        const EffectParams &params) override
    {
        // [Start audioSuite_SetEnvironmentType]
        // 设置为环境效果节点类型。
        OH_AudioSuiteNodeBuilder_SetNodeType(builder, OH_AudioNode_Type::EFFECT_NODE_TYPE_ENVIRONMENT_EFFECT);
        // 创建环境效果节点。
        OH_AudioSuiteEngine_CreateNode(pipeline, builder, node);
        // 设置环境效果节点效果。
        OH_AudioSuiteEngine_SetEnvironmentType(*node, static_cast<OH_EnvironmentType>(params.environmentType));
        // [End audioSuite_SetEnvironmentType]
    }
};

class SpaceRenderStrategy : public AudioEffectStrategy {
public:
    OH_AudioNode_Type GetNodeType() const override
    {
        return OH_AudioNode_Type::EFFECT_NODE_TYPE_SPACE_RENDER;
    }

    void CreateAndApply(OH_AudioSuitePipeline *pipeline, OH_AudioNodeBuilder *builder, OH_AudioNode **node,
                        const EffectParams &params) override
    {
        // [Start audioSuite_SetSpaceRenderParams]
        // 设置为空间渲染节点类型。
        OH_AudioSuiteNodeBuilder_SetNodeType(builder, OH_AudioNode_Type::EFFECT_NODE_TYPE_SPACE_RENDER);
        // 创建空间渲染节点。
        OH_AudioSuiteEngine_CreateNode(pipeline, builder, node);
        // 按场景设置空间渲染参数。
        switch (params.spaceRenderMode) {
            // 固定摆位模式。
            case SPACE_RENDER_MODE_POSITION: {
                OH_AudioSuite_SpaceRenderPositionParams position;
                position.x = params.spacePositionX;
                position.y = params.spacePositionY;
                position.z = params.spacePositionZ;
                OH_AudioSuiteEngine_SetSpaceRenderPositionParams(*node, position);
                break;
            }
            // 旋转模式。
            case SPACE_RENDER_MODE_ROTATION: {
                OH_AudioSuite_SpaceRenderRotationParams rotation;
                rotation.x = params.spaceRotationX;
                rotation.y = params.spaceRotationY;
                rotation.z = params.spaceRotationZ;
                rotation.surroundTime = params.spaceRotationSurroundTime;
                rotation.surroundDirection =
                    static_cast<OH_AudioSuite_SurroundDirection>(params.spaceRotationSurroundDirection);
                OH_AudioSuiteEngine_SetSpaceRenderRotationParams(*node, rotation);
                break;
            }
            // 扩展模式。
            case SPACE_RENDER_MODE_EXTENSION: {
                OH_AudioSuite_SpaceRenderExtensionParams extension;
                extension.extRadius = params.spaceExtensionRadius;
                extension.extAngle = params.spaceExtensionAngle;
                OH_AudioSuiteEngine_SetSpaceRenderExtensionParams(*node, extension);
                break;
            }
            default:
                break;
        }
        // [End audioSuite_SetSpaceRenderParams]
    }
};

class PureVoiceChangeStrategy : public AudioEffectStrategy {
public:
    OH_AudioNode_Type GetNodeType() const override
    {
        return OH_AudioNode_Type::EFFECT_NODE_TYPE_PURE_VOICE_CHANGE;
    }

    void CreateAndApply(OH_AudioSuitePipeline *pipeline, OH_AudioNodeBuilder *builder, OH_AudioNode **node,
                        const EffectParams &params) override
    {
        // [Start audioSuite_SetPureVoiceChangeOption]
        // 设置为传统变声节点类型。
        OH_AudioSuiteNodeBuilder_SetNodeType(builder, OH_AudioNode_Type::EFFECT_NODE_TYPE_PURE_VOICE_CHANGE);
        // 创建传统变声节点。
        OH_AudioSuiteEngine_CreateNode(pipeline, builder, node);
        // 设置传统变声节点效果。
        OH_AudioSuite_PureVoiceChangeOption option;
        option.optionGender = static_cast<OH_AudioSuite_PureVoiceChangeGenderOption>(params.pureVoiceChangeGender);
        option.optionType = static_cast<OH_AudioSuite_PureVoiceChangeType>(params.pureVoiceChangeType);
        option.pitch = params.pureVoiceChangePitch;
        OH_AudioSuiteEngine_SetPureVoiceChangeOption(*node, option);
        // [End audioSuite_SetPureVoiceChangeOption]
    }
};

class GeneralVoiceChangeStrategy : public AudioEffectStrategy {
public:
    OH_AudioNode_Type GetNodeType() const override
    {
        return OH_AudioNode_Type::EFFECT_NODE_TYPE_GENERAL_VOICE_CHANGE;
    }

    void CreateAndApply(OH_AudioSuitePipeline *pipeline, OH_AudioNodeBuilder *builder, OH_AudioNode **node,
                        const EffectParams &params) override
    {
        // [Start audioSuite_SetGeneralVoiceChangeType]
        // 设置为通用变声节点类型。
        OH_AudioSuiteNodeBuilder_SetNodeType(builder, OH_AudioNode_Type::EFFECT_NODE_TYPE_GENERAL_VOICE_CHANGE);
        // 创建通用变声节点。
        OH_AudioSuiteEngine_CreateNode(pipeline, builder, node);
        // 设置通用变声节点效果。
        OH_AudioSuiteEngine_SetGeneralVoiceChangeType(
            *node, static_cast<OH_AudioSuite_GeneralVoiceChangeType>(params.generalVoiceChangeType));
        // [End audioSuite_SetGeneralVoiceChangeType]
    }
};

class TempoPitchStrategy : public AudioEffectStrategy {
public:
    OH_AudioNode_Type GetNodeType() const override
    {
        return OH_AudioNode_Type::EFFECT_NODE_TYPE_TEMPO_PITCH;
    }

    void CreateAndApply(OH_AudioSuitePipeline *pipeline, OH_AudioNodeBuilder *builder, OH_AudioNode **node,
                        const EffectParams &params) override
    {
        // [Start audioSuite_SetTempoAndPitch]
        // 设置为变速变调节点类型。
        OH_AudioSuiteNodeBuilder_SetNodeType(builder, OH_AudioNode_Type::EFFECT_NODE_TYPE_TEMPO_PITCH);
        // 创建变速变调节点。
        OH_AudioSuiteEngine_CreateNode(pipeline, builder, node);
        // 设置变速变调节点效果。
        OH_AudioSuiteEngine_SetTempoAndPitch(*node, params.tempoSpeed, params.tempoPitch);
        // [End audioSuite_SetTempoAndPitch]
    }
};

std::unique_ptr<AudioEffectStrategy> CreateEffectStrategy(int effectType);

#endif