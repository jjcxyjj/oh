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

#include "audio_effect.h"

std::unique_ptr<AudioEffectStrategy> CreateEffectStrategy(int effectType)
{
    switch (effectType) {
        case AUDIO_EFFECT_TYPE_EQUALIZER:
            return std::make_unique<EqualizerStrategy>();
        case AUDIO_EFFECT_TYPE_VOICE_BEAUTIFIER:
            return std::make_unique<VoiceBeautifierStrategy>();
        case AUDIO_EFFECT_TYPE_NOISE_REDUCTION:
            return std::make_unique<NoiseReductionStrategy>();
        case AUDIO_EFFECT_TYPE_SOUND_FIELD:
            return std::make_unique<SoundFieldStrategy>();
        case AUDIO_EFFECT_TYPE_ENVIRONMENT_EFFECT:
            return std::make_unique<EnvironmentEffectStrategy>();
        case AUDIO_EFFECT_TYPE_SPACE_RENDER:
            return std::make_unique<SpaceRenderStrategy>();
        case AUDIO_EFFECT_TYPE_PURE_VOICE_CHANGE:
            return std::make_unique<PureVoiceChangeStrategy>();
        case AUDIO_EFFECT_TYPE_GENERAL_VOICE_CHANGE:
            return std::make_unique<GeneralVoiceChangeStrategy>();
        case AUDIO_EFFECT_TYPE_TEMPO_PITCH:
            return std::make_unique<TempoPitchStrategy>();
        default:
            return nullptr;
    }
}
