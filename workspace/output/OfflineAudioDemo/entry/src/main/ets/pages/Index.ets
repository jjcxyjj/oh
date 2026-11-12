// SPDX-License-Identifier: Apache-2.0
import engine from 'libentry.so';
import { common } from '@kit.AbilityKit';
import { fileIo as fs, picker } from '@kit.CoreFileKit';
import { media } from '@kit.MediaKit';

@Entry
@Component
struct Index {
  @State preset: number = 1;
  @State busy: boolean = false;
  @State ready: boolean = false;
  @State status: string = '准备音频中';
  private input: string = '';
  private original: string = '';
  private output: string = '';
  private player: media.AVPlayer | undefined = undefined;
  private playingFile: fs.File | undefined = undefined;
  private presets: string[] = ['原声直通', '人声清晰', '低频温暖'];

  aboutToAppear(): void {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      this.input = ctx.filesDir + '/source.pcm';
      this.original = ctx.filesDir + '/original.wav';
      this.output = ctx.filesDir + '/edited.wav';
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
    } catch (e) { this.status = '初始化失败：' + String(e); this.input = ''; }
  }
  async stop(): Promise<void> {
    if (this.player) { await this.player.release(); this.player = undefined; }
    if (this.playingFile) { fs.closeSync(this.playingFile); this.playingFile = undefined; }
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
  async renderAudio(): Promise<void> {
    this.busy = true; this.ready = false; this.status = '正在离线渲染，请稍候';
    try { await this.stop(); this.status = await engine.render(this.input, this.output, this.preset); this.ready = true; }
    catch (e) { this.status = '渲染失败：' + String(e); }
    finally { this.busy = false; }
  }
  async save(): Promise<void> {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const options = new picker.DocumentSaveOptions(); options.newFileNames = ['OfflineAudio.wav'];
      const uris = await new picker.DocumentViewPicker(ctx).save(options);
      if (!uris.length) { return; }
      const file = fs.openSync(uris[0], fs.OpenMode.READ_WRITE);
      try { fs.copyFileSync(this.output, file.fd); } finally { fs.closeSync(file); }
      this.status = 'WAV 已导出';
    } catch (e) { this.status = '导出未完成：' + String(e); }
  }
  aboutToDisappear(): void { this.stop(); }
  build() {
    Scroll() {
      Column({ space: 22 }) {
        Text('OFFLINE AUDIO LAB').fontSize(13).fontColor('#8BA6C4').letterSpacing(3)
        Text('离线音频编辑').fontSize(34).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
        Text('先渲染，再试听。音频处理全部在设备本地完成。').fontSize(15).fontColor('#B3C1D2')
        Column({ space: 10 }) {
          Text('01  音频素材').fontColor('#69E4CC').fontSize(18)
          Text('内置示例  /  48 kHz  /  双声道  /  16 bit').fontColor('#FFFFFF').fontSize(15)
          Button('试听原音').onClick(() => this.play(this.original)).enabled(!this.busy && this.input.length > 0)
        }.alignItems(HorizontalAlign.Start).width('100%').padding(22).backgroundColor('#15263A').borderRadius(18)
        Column({ space: 12 }) {
          Text('02  选择效果').fontColor('#69E4CC').fontSize(18)
          ForEach(this.presets, (name: string, index: number) => {
            Button(name).width('100%').backgroundColor(this.preset === index ? '#69E4CC' : '#263A50')
              .fontColor(this.preset === index ? '#102031' : '#FFFFFF').enabled(!this.busy)
              .onClick(() => { this.preset = index; this.ready = false; })
          })
          Text('10 段均衡器预设。每次处理均从原音开始。').fontColor('#B3C1D2').fontSize(13)
        }.alignItems(HorizontalAlign.Start).width('100%')
        Button(this.busy ? '渲染中…' : '开始离线渲染').width('100%').height(52)
          .backgroundColor('#69E4CC').fontColor('#102031').enabled(!this.busy && this.input.length > 0)
          .onClick(() => this.renderAudio())
        Text(this.status).fontColor('#B3C1D2').fontSize(14).width('100%')
        Row({ space: 12 }) {
          Button('试听结果').enabled(this.ready && !this.busy).onClick(() => this.play(this.output))
          Button('导出 WAV').enabled(this.ready && !this.busy).onClick(() => this.save())
        }
        Button('停止播放').onClick(() => this.stop()).backgroundColor('#263A50')
      }.padding(28).width('100%').alignItems(HorizontalAlign.Start)
    }.height('100%').width('100%').backgroundColor('#0B1728')
  }
}
