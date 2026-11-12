// SPDX-License-Identifier: Apache-2.0
// 共享的离线任务组件：由各功能页以固定 mode 复用。
import engine from 'libentry.so';
import { common } from '@kit.AbilityKit';
import { fileIo as fs, picker } from '@kit.CoreFileKit';
import { media } from '@kit.MediaKit';

@Component
export struct OfflineTask {
  @Prop mode: number = 0;
  @State preset: number = 1;
  @State gainA: number = 0.7;
  @State gainB: number = 0.3;
  @State inputLabel: string = '内置官方 PCM';
  @State secondLabel: string = '未选择（混音需导入）';
  @State resultPaths: string[] = [];
  @State resultLabels: string[] = [];
  @State busy: boolean = false;
  @State ready: boolean = false;
  @State status: string = '准备音频中';

  private second: string = '';
  private input: string = '';
  private original: string = '';
  private player: media.AVPlayer | undefined = undefined;
  private playingFile: fs.File | undefined = undefined;
  private presets: string[] = ['原声直通', '人声清晰', '低频温暖'];
  private titles: string[] = ['均衡器 EQ', '音源分离', '双素材混音', '级联 EQ→声场→混音', '分离→人声处理→重混'];
  private descs: string[] = [
    '调节频段，三种预设，可试听/导出',
    '分离为人声与背景声两路输出',
    '导入两段素材，按增益混合',
    '均衡器 → 声场 → 混音 的级联链路',
    '分离后对人声再处理，再重新混音'
  ];

  aboutToAppear(): void {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      this.input = ctx.filesDir + '/source.pcm';
      this.original = ctx.filesDir + '/original.wav';
      const bytes = ctx.resourceManager.getRawFileContentSync('S16LE_2_48000.pcm');
      const pcm = bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength);
      const f = fs.openSync(this.input, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
      try { fs.writeSync(f.fd, pcm); } finally { fs.closeSync(f); }
      const wav = new ArrayBuffer(44 + bytes.byteLength);
      const v = new DataView(wav);
      const header = 'RIFF    WAVEfmt ';
      for (let i = 0; i < header.length; i++) { v.setUint8(i, header.charCodeAt(i)); }
      v.setUint32(4, bytes.byteLength + 36, true); v.setUint32(16, 16, true);
      v.setUint16(20, 1, true); v.setUint16(22, 2, true); v.setUint32(24, 48000, true);
      v.setUint32(28, 192000, true); v.setUint16(32, 4, true); v.setUint16(34, 16, true);
      v.setUint32(36, 0x61746164, true); v.setUint32(40, bytes.byteLength, true);
      new Uint8Array(wav).set(bytes, 44);
      const w = fs.openSync(this.original, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
      try { fs.writeSync(w.fd, wav); } finally { fs.closeSync(w); }
      this.status = '音频已就绪 · ' + (bytes.byteLength / 192000).toFixed(1) + ' 秒';
    } catch (e) {
      this.status = '初始化失败：' + String(e);
      this.input = '';
    }
  }

  async stop(): Promise<void> {
    try { if (this.player) { await this.player.release(); } }
    catch (e) { this.status = '播放器释放失败：' + String(e); }
    finally { this.player = undefined; }
    try { if (this.playingFile) { fs.closeSync(this.playingFile); } }
    catch (e) { this.status = '音频文件关闭失败：' + String(e); }
    finally { this.playingFile = undefined; }
  }

  async play(path: string): Promise<void> {
    try {
      await this.stop();
      const p = await media.createAVPlayer(); this.player = p;
      p.on('stateChange', async (state: string) => {
        try {
          if (state === 'initialized') { await p.prepare(); }
          if (state === 'prepared') { await p.play(); }
        } catch (e) { this.status = '播放失败：' + String(e); }
      });
      p.on('error', () => { this.status = '播放失败，请重试'; });
      this.playingFile = fs.openSync(path, fs.OpenMode.READ_ONLY);
      p.fdSrc = { fd: this.playingFile.fd, offset: 0, length: fs.statSync(path).size };
    } catch (e) { this.status = '播放失败：' + String(e); }
  }

  // 导入的 WAV 会复制到沙箱，C++ 侧再严格校验格式。
  async importAudio(second: boolean): Promise<void> {
    if (this.busy) { return; }
    this.busy = true;
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const options = new picker.DocumentSelectOptions(); options.maxSelectNumber = 1;
      const uris = await new picker.DocumentViewPicker(ctx).select(options);
      if (!uris.length) { return; }
      const f = fs.openSync(uris[0], fs.OpenMode.READ_ONLY);
      const path = ctx.filesDir + (second ? '/import-b.wav' : '/import-a.wav');
      try {
        if (fs.statSync(f.fd).size > 24 * 1024 * 1024) { throw new Error('输入文件超过 24 MB'); }
        fs.copyFileSync(f.fd, path);
      } finally { fs.closeSync(f); }
      await this.stop();
      if (second) { this.second = path; this.secondLabel = '已导入素材 B'; }
      else { this.input = path; this.original = path; this.inputLabel = '已导入素材 A'; }
      this.invalidate(); this.status = '已导入；开始处理时校验 48kHz / 双声道 / PCM16 WAV';
    } catch (e) { this.status = '导入失败：' + String(e); }
    finally { this.busy = false; }
  }

  invalidate(): void { this.ready = false; this.resultPaths = []; this.resultLabels = []; }

  async renderAudio(): Promise<void> {
    this.busy = true; this.invalidate(); this.status = '正在运行 AudioSuite 算法，请稍候';
    try {
      await this.stop();
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const prefix = ctx.filesDir + '/task-' + Date.now().toString();
      const report = await engine.run(this.input, this.second, prefix, this.mode, this.preset, this.gainA, this.gainB);
      this.resultPaths = report.paths; this.resultLabels = report.labels; this.ready = true;
      this.status = '本次算法完成 · ' + report.elapsedMs + ' ms · ' + report.paths.length + ' 个输出';
    } catch (e) { this.status = '处理失败：' + String(e); }
    finally { this.busy = false; }
  }

  async save(path: string, label: string): Promise<void> {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const options = new picker.DocumentSaveOptions(); options.newFileNames = [label + '.wav'];
      const uris = await new picker.DocumentViewPicker(ctx).save(options);
      if (!uris.length) { return; }
      const file = fs.openSync(uris[0], fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
      try { fs.copyFileSync(path, file.fd); } finally { fs.closeSync(file); }
      this.status = label + ' WAV 已导出';
    } catch (e) { this.status = '导出未完成：' + String(e); }
  }

  aboutToDisappear(): void { this.stop(); }

  build() {
    Scroll() {
      Column({ space: 18 }) {
        Text('AUDIO SUITE · ALGORITHM LAB').fontSize(12).fontColor('#8BA6C4').letterSpacing(2)
        Text(this.titles[this.mode]).fontSize(28).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
        Text(this.descs[this.mode]).fontSize(14).fontColor('#B3C1D2')

        Column({ space: 10 }) {
          Text('01  输入素材').fontColor('#69E4CC').fontSize(18)
          Text('A：' + this.inputLabel + ' / B：' + this.secondLabel).fontColor('#FFFFFF').fontSize(14)
          Text('导入要求：48kHz、双声道、PCM16 WAV，最长 120 秒').fontColor('#B3C1D2').fontSize(12)
          Row({ space: 8 }) {
            Button('导入 A').onClick(() => this.importAudio(false)).enabled(!this.busy)
            Button('导入 B').onClick(() => this.importAudio(true)).enabled(!this.busy)
          }
          Button('试听原始 A').onClick(() => this.play(this.original)).enabled(!this.busy && this.input.length > 0)
        }.alignItems(HorizontalAlign.Start).width('100%').padding(18).backgroundColor('#15263A').borderRadius(16)

        Text('02  参数').fontColor('#69E4CC').fontSize(18)
        if (this.mode === 0 || this.mode === 3 || this.mode === 4) {
          Text('EQ 预设（“人声清晰”是 EQ 名称，不是音源分离）').fontColor('#B3C1D2').fontSize(12)
          ForEach(this.presets, (name: string, index: number) => {
            Button(name).width('100%').backgroundColor(this.preset === index ? '#147AF0' : '#263A50')
              .enabled(!this.busy).onClick(() => { this.preset = index; this.invalidate(); })
          })
        }
        if (this.mode >= 2) {
          Text(this.mode === 4 ? '分离人声增益 / 分离背景增益' : '输入 A 增益 / 输入 B 增益').fontColor('#B3C1D2')
          Text('A ' + this.gainA.toFixed(2) + ' / B ' + this.gainB.toFixed(2)).fontColor('#FFFFFF')
          Slider({ value: this.gainA, min: 0, max: 1, step: 0.05 }).enabled(!this.busy)
            .onChange((value: number) => { this.gainA = value; this.invalidate(); })
          Slider({ value: this.gainB, min: 0, max: 1, step: 0.05 }).enabled(!this.busy)
            .onChange((value: number) => { this.gainB = value; this.invalidate(); })
          Text('增益过大可能削波，建议两路增益之和 ≤ 1；EQ 增益也需留余量。').fontColor('#B3C1D2').fontSize(12)
        }

        Button(this.busy ? '算法处理中…' : '开始运行算法').width('100%').height(52)
          .backgroundColor('#69E4CC').fontColor('#102031')
          .enabled(!this.busy && this.input.length > 0 && ((this.mode !== 2 && this.mode !== 3) || this.second.length > 0))
          .onClick(() => this.renderAudio())

        Text(this.status).fontColor('#B3C1D2').fontSize(14).width('100%')

        if (this.ready) {
          ForEach(this.resultPaths, (path: string, index: number) => {
            Text(this.resultLabels[index]).fontColor('#69E4CC')
            Row({ space: 12 }) {
              Button('试听').enabled(!this.busy).onClick(() => this.play(path))
              Button('导出 WAV').enabled(!this.busy).onClick(() => this.save(path, this.resultLabels[index]))
            }
          })
        }
        Button('停止播放').onClick(() => this.stop()).backgroundColor('#263A50')
      }.padding(24).width('100%').alignItems(HorizontalAlign.Start)
    }.height('100%').width('100%').backgroundColor('#0B1728')
  }
}
