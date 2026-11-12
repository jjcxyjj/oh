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

import { hilog } from '@kit.PerformanceAnalysisKit';
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

const TAG = 'AudioSuiteSampleTest';
const BUNDLE = 'audiosuite_';
const BUNDLE_NAME = 'com.example.audiosuitesample';
const ABILITY_NAME = 'EntryAbility';
const delegator = AbilityDelegatorRegistry.getAbilityDelegator();

async function waitForText(driver: Driver, text: string, timeoutMs: number = 60000): Promise<boolean> {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    try {
      const comp = await driver.findComponent(ON.text(text));
      if (comp !== undefined && comp !== null) {
        return true;
      }
    } catch (e) {
    }
    await driver.delayMs(500);
  }
  return false;
}

async function clickByText(driver: Driver, text: string): Promise<void> {
  const comp = await driver.findComponent(ON.text(text));
  if (comp) {
    await comp.click();
  }
}

async function stopPlayback(driver: Driver): Promise<void> {
  const stopBtn = await driver.findComponent(ON.text('停止播放'));
  if (stopBtn) {
    await stopBtn.click();
    await waitForText(driver, '停止播放成功', 15000);
    await driver.delayMs(500);
  }
}

async function addEffect(driver: Driver, effectName: string, modeName?: string): Promise<boolean> {
  const addBtn = await driver.findComponent(ON.text('添加音频效果'));
  if (addBtn) {
    await addBtn.click();
  }
  await driver.delayMs(800);

  const selects = await driver.findComponents(ON.type('Select'));
  if (selects.length > 0) {
    await selects[0].click();
    await driver.delayMs(800);
    const opts = await driver.findComponents(ON.text(effectName));
    if (opts.length > 0) {
      await opts[opts.length - 1].click();
    }
    await driver.delayMs(800);
  }

  if (modeName) {
    const sels = await driver.findComponents(ON.type('Select'));
    if (sels.length > 1) {
      await sels[1].click();
      await driver.delayMs(800);
      const mopts = await driver.findComponents(ON.text(modeName));
      if (mopts.length > 0) {
        await mopts[mopts.length - 1].click();
      }
      await driver.delayMs(800);
    }
  }

  const okBtn = await driver.findComponent(ON.text('确定'));
  if (okBtn) {
    await okBtn.click();
  }
  return waitForText(driver, '添加音频效果成功', 60000);
}

export default function abilityTest() {
  describe('ActsAbilityTest', () => {
    beforeAll(() => {
    })
    beforeEach(() => {
    })
    afterEach(() => {
    })
    afterAll(() => {
    })

    it(BUNDLE + 'StartAbility_001', 0, async (done: Function) => {
      try {
        await delegator.startAbility({ bundleName: BUNDLE_NAME, abilityName: ABILITY_NAME });
        const driver = Driver.create();
        await driver.delayMs(2000);
        await driver.assertComponentExist(ON.text('播放音频'));
        await driver.assertComponentExist(ON.text('添加音频效果'));
      } catch (err) {
        hilog.error(0x0000, TAG, 'StartAbility_001 err: %{public}s', JSON.stringify(err));
        expect().assertFail();
      }
      done();
    })

    it(BUNDLE + 'PlayAudio_001', 0, async (done: Function) => {
      try {
        const driver = Driver.create();
        await driver.delayMs(1000);
        await clickByText(driver, '播放音频');
        expect(await waitForText(driver, '播放原始音频成功', 30000)).assertTrue();
      } catch (err) {
        hilog.error(0x0000, TAG, 'PlayAudio_001 err: %{public}s', JSON.stringify(err));
        expect().assertFail();
      }
      done();
    })

    it(BUNDLE + 'StopPlay_001', 0, async (done: Function) => {
      try {
        const driver = Driver.create();
        await driver.delayMs(500);
        await clickByText(driver, '停止播放');
        expect(await waitForText(driver, '停止播放成功', 15000)).assertTrue();
      } catch (err) {
        hilog.error(0x0000, TAG, 'StopPlay_001 err: %{public}s', JSON.stringify(err));
        expect().assertFail();
      }
      done();
    })

    it(BUNDLE + 'AddEqualizer_001', 0, async (done: Function) => {
      try {
        const driver = Driver.create();
        await driver.delayMs(500);
        expect(await addEffect(driver, '均衡器效果')).assertTrue();
      } catch (err) {
        hilog.error(0x0000, TAG, 'AddEqualizer_001 err: %{public}s', JSON.stringify(err));
        expect().assertFail();
      }
      done();
    })

    it(BUNDLE + 'AddVoiceBeautifier_001', 0, async (done: Function) => {
      try {
        const driver = Driver.create();
        await driver.delayMs(500);
        expect(await addEffect(driver, '声音美化效果')).assertTrue();
      } catch (err) {
        hilog.error(0x0000, TAG, 'AddVoiceBeautifier_001 err: %{public}s', JSON.stringify(err));
        expect().assertFail();
      }
      done();
    })

    it(BUNDLE + 'AddNoiseReduction_001', 0, async (done: Function) => {
      try {
        const driver = Driver.create();
        await driver.delayMs(500);
        expect(await addEffect(driver, '降噪效果')).assertTrue();
      } catch (err) {
        hilog.error(0x0000, TAG, 'AddNoiseReduction_001 err: %{public}s', JSON.stringify(err));
        expect().assertFail();
      }
      done();
    })

    it(BUNDLE + 'AddSoundField_001', 0, async (done: Function) => {
      try {
        const driver = Driver.create();
        await driver.delayMs(500);
        expect(await addEffect(driver, '声场效果')).assertTrue();
      } catch (err) {
        hilog.error(0x0000, TAG, 'AddSoundField_001 err: %{public}s', JSON.stringify(err));
        expect().assertFail();
      }
      done();
    })

    it(BUNDLE + 'AddEnvironment_001', 0, async (done: Function) => {
      try {
        const driver = Driver.create();
        await driver.delayMs(500);
        expect(await addEffect(driver, '环境效果')).assertTrue();
      } catch (err) {
        hilog.error(0x0000, TAG, 'AddEnvironment_001 err: %{public}s', JSON.stringify(err));
        expect().assertFail();
      }
      done();
    })

    it(BUNDLE + 'AddSpaceRenderPosition_001', 0, async (done: Function) => {
      try {
        const driver = Driver.create();
        await driver.delayMs(500);
        expect(await addEffect(driver, '空间渲染效果', '位置')).assertTrue();
      } catch (err) {
        hilog.error(0x0000, TAG, 'AddSpaceRenderPosition_001 err: %{public}s', JSON.stringify(err));
        expect().assertFail();
      }
      done();
    })

    it(BUNDLE + 'AddSpaceRenderRotation_001', 0, async (done: Function) => {
      try {
        const driver = Driver.create();
        await driver.delayMs(500);
        expect(await addEffect(driver, '空间渲染效果', '旋转')).assertTrue();
      } catch (err) {
        hilog.error(0x0000, TAG, 'AddSpaceRenderRotation_001 err: %{public}s', JSON.stringify(err));
        expect().assertFail();
      }
      done();
    })

    it(BUNDLE + 'AddSpaceRenderExtension_001', 0, async (done: Function) => {
      try {
        const driver = Driver.create();
        await driver.delayMs(500);
        expect(await addEffect(driver, '空间渲染效果', '扩展')).assertTrue();
      } catch (err) {
        hilog.error(0x0000, TAG, 'AddSpaceRenderExtension_001 err: %{public}s', JSON.stringify(err));
        expect().assertFail();
      }
      done();
    })

    it(BUNDLE + 'AddPureVoiceChange_001', 0, async (done: Function) => {
      try {
        const driver = Driver.create();
        await driver.delayMs(500);
        expect(await addEffect(driver, '传统变声效果')).assertTrue();
      } catch (err) {
        hilog.error(0x0000, TAG, 'AddPureVoiceChange_001 err: %{public}s', JSON.stringify(err));
        expect().assertFail();
      }
      done();
    })

    it(BUNDLE + 'AddGeneralVoiceChange_001', 0, async (done: Function) => {
      try {
        const driver = Driver.create();
        await driver.delayMs(500);
        expect(await addEffect(driver, '通用变声效果')).assertTrue();
      } catch (err) {
        hilog.error(0x0000, TAG, 'AddGeneralVoiceChange_001 err: %{public}s', JSON.stringify(err));
        expect().assertFail();
      }
      done();
    })

    it(BUNDLE + 'AddTempoPitch_001', 0, async (done: Function) => {
      try {
        const driver = Driver.create();
        await driver.delayMs(500);
        expect(await addEffect(driver, '变速变调效果')).assertTrue();
      } catch (err) {
        hilog.error(0x0000, TAG, 'AddTempoPitch_001 err: %{public}s', JSON.stringify(err));
        expect().assertFail();
      }
      done();
    })

    it(BUNDLE + 'PlayEffectAudio_001', 0, async (done: Function) => {
      try {
        const driver = Driver.create();
        await driver.delayMs(500);
        await clickByText(driver, '播放添加音频效果后音频');
        expect(await waitForText(driver, '播放添加音频效果后音频成功', 30000)).assertTrue();
        await stopPlayback(driver);
      } catch (err) {
        hilog.error(0x0000, TAG, 'PlayEffectAudio_001 err: %{public}s', JSON.stringify(err));
        expect().assertFail();
      }
      done();
    })

    it(BUNDLE + 'AudioSourceSeparation_001', 0, async (done: Function) => {
      try {
        const driver = Driver.create();
        await driver.delayMs(500);
        await clickByText(driver, '音源分离');
        expect(await waitForText(driver, '音源分离成功', 120000)).assertTrue();
      } catch (err) {
        hilog.error(0x0000, TAG, 'AudioSourceSeparation_001 err: %{public}s', JSON.stringify(err));
        expect().assertFail();
      }
      done();
    })

    it(BUNDLE + 'PlayAccompaniment_001', 0, async (done: Function) => {
      try {
        const driver = Driver.create();
        await driver.delayMs(500);
        await clickByText(driver, '播放伴奏');
        expect(await waitForText(driver, '播放伴奏成功', 30000)).assertTrue();
        await stopPlayback(driver);
      } catch (err) {
        hilog.error(0x0000, TAG, 'PlayAccompaniment_001 err: %{public}s', JSON.stringify(err));
        expect().assertFail();
      }
      done();
    })

    it(BUNDLE + 'PlayVocals_001', 0, async (done: Function) => {
      try {
        const driver = Driver.create();
        await driver.delayMs(500);
        await clickByText(driver, '播放人声');
        expect(await waitForText(driver, '播放人声成功', 30000)).assertTrue();
        await stopPlayback(driver);
      } catch (err) {
        hilog.error(0x0000, TAG, 'PlayVocals_001 err: %{public}s', JSON.stringify(err));
        expect().assertFail();
      }
      done();
    })

    it(BUNDLE + 'MixingAndCascading_001', 0, async (done: Function) => {
      try {
        const driver = Driver.create();
        await driver.delayMs(500);
        await clickByText(driver, '混音与级联');
        expect(await waitForText(driver, '混音与级联成功', 120000)).assertTrue();
      } catch (err) {
        hilog.error(0x0000, TAG, 'MixingAndCascading_001 err: %{public}s', JSON.stringify(err));
        expect().assertFail();
      }
      done();
    })

    it(BUNDLE + 'PlayMix_001', 0, async (done: Function) => {
      try {
        const driver = Driver.create();
        await driver.delayMs(500);
        await clickByText(driver, '播放混音');
        expect(await waitForText(driver, '播放混音成功', 30000)).assertTrue();
        await stopPlayback(driver);
      } catch (err) {
        hilog.error(0x0000, TAG, 'PlayMix_001 err: %{public}s', JSON.stringify(err));
        expect().assertFail();
      }
      done();
    })

    it(BUNDLE + 'SpaceRender_001', 0, async (done: Function) => {
      try {
        const driver = Driver.create();
        await driver.delayMs(500);
        await clickByText(driver, '播放空间渲染');
        expect(await waitForText(driver, '播放空间渲染成功', 30000)).assertTrue();
        await stopPlayback(driver);
      } catch (err) {
        hilog.error(0x0000, TAG, 'SpaceRender_001 err: %{public}s', JSON.stringify(err));
        expect().assertFail();
      }
      done();
    })

    it(BUNDLE + 'AudioFormatConverter_001', 0, async (done: Function) => {
      try {
        const driver = Driver.create();
        await driver.delayMs(500);
        await clickByText(driver, '格式转换');
        expect(await waitForText(driver, '格式转换成功', 120000)).assertTrue();
      } catch (err) {
        hilog.error(0x0000, TAG, 'AudioFormatConverter_001 err: %{public}s', JSON.stringify(err));
        expect().assertFail();
      }
      done();
    })

    it(BUNDLE + 'PlayRealtimePreview_001', 0, async (done: Function) => {
      try {
        const driver = Driver.create();
        await driver.delayMs(500);
        await clickByText(driver, '播放实时预览');
        expect(await waitForText(driver, '播放实时预览成功', 30000)).assertTrue();
      } catch (err) {
        hilog.error(0x0000, TAG, 'PlayRealtimePreview_001 err: %{public}s', JSON.stringify(err));
        expect().assertFail();
      }
      done();
    })

    it(BUNDLE + 'Debug_001', 0, async (done: Function) => {
      try {
        const driver = Driver.create();
        await driver.delayMs(1000);
        await clickByText(driver, '调试');
        expect(await waitForText(driver, 'PrintInfo测试成功', 30000)).assertTrue();
        await stopPlayback(driver);
      } catch (err) {
        hilog.error(0x0000, TAG, 'Debug_001 err: %{public}s', JSON.stringify(err));
        expect().assertFail();
      }
      done();
    })
  })
}
