// SPDX-License-Identifier: Apache-2.0
// 首页：多入口菜单，点击进入各自的离线功能界面。
import { router } from '@kit.ArkUI';

interface MenuItem {
  title: string;
  desc: string;
  url: string;
  tag: string;
}

@Entry
@Component
struct Index {
  private items: MenuItem[] = [
    { title: '均衡器 EQ', desc: '调节 10 段频响，三种预设，可试听/导出', url: 'pages/Eq', tag: 'EQ' },
    { title: '音源分离', desc: '把人声与背景声分离为两路输出', url: 'pages/Separation', tag: 'SEP' },
    { title: '双素材混音', desc: '导入两段素材，按增益混合为一路', url: 'pages/Mix', tag: 'MIX' },
    { title: '级联 EQ→声场→混音', desc: '均衡器 → 声场 → 混音 的级联链路', url: 'pages/Cascade', tag: 'CHAIN' },
    { title: '分离→人声处理→重混', desc: '分离后人声再处理，再与背景重新混音', url: 'pages/Remix', tag: 'RE-MIX' }
  ];

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('AUDIO SUITE · ALGORITHM LAB').fontSize(12).fontColor('#8BA6C4').letterSpacing(2)
        Text('离线音频编创').fontSize(30).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
        Text('选择一个功能进入对应界面。输入要求：48kHz / 双声道 / PCM16 WAV。')
          .fontSize(13).fontColor('#B3C1D2')

        ForEach(this.items, (it: MenuItem) => {
          Row({ space: 14 }) {
            Text(it.tag).fontSize(12).fontColor('#102031').fontWeight(FontWeight.Bold)
              .backgroundColor('#69E4CC').borderRadius(8).padding({ left: 10, right: 10, top: 6, bottom: 6 })
            Column({ space: 4 }) {
              Text(it.title).fontSize(19).fontColor('#FFFFFF').fontWeight(FontWeight.Medium)
              Text(it.desc).fontSize(13).fontColor('#B3C1D2')
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            Text('›').fontSize(26).fontColor('#69E4CC')
          }
          .width('100%').padding(18).backgroundColor('#15263A').borderRadius(16)
          .onClick(() => { router.pushUrl({ url: it.url }); })
        }, (it: MenuItem) => it.url)

        Text('说明：音源分离依赖设备 NPU；不支持时界面会提示。所有处理在端侧离线完成。')
          .fontSize(12).fontColor('#7F93A9').margin({ top: 6 })
      }.padding(24).width('100%').alignItems(HorizontalAlign.Start)
    }.height('100%').width('100%').backgroundColor('#0B1728')
  }
}
