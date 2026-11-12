// SPDX-License-Identifier: Apache-2.0
import { router } from '@kit.ArkUI';
import { OfflineTask } from '../components/OfflineTask';

@Entry
@Component
struct Remix {
  build() {
    Column() {
      Row() {
        Button('‹ 返回').onClick(() => { router.back(); }).backgroundColor('#263A50').fontColor('#FFFFFF')
      }.width('100%').padding({ left: 16, right: 16, top: 10, bottom: 4 })
      OfflineTask({ mode: 4 }).layoutWeight(1)
    }.width('100%').height('100%').backgroundColor('#0B1728')
  }
}
