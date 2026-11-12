from pathlib import Path
root=Path(__file__).resolve().parents[2]
p=root/'output/OfflineAudioDemo/entry/src/main/ets/pages/Index.ets'
s=(root/'.build/v2/Index-v1.ets').read_text()
s=s.replace("import engine from 'libentry.so';", "import engine from 'libentry.so';")
s=s.replace("  @State preset: number = 1;", """  @State mode: number = 0;
  @State preset: number = 1;
  @State gainA: number = 0.7;
  @State gainB: number = 0.3;
  @State inputLabel: string = '内置官方 PCM';
  @State secondLabel: string = '未选择（混音需导入）';
  @State resultPaths: string[] = [];
  @State resultLabels: string[] = [];
  private second: string = '';
  private modes: string[] = ['均衡器 EQ', '音源分离：人声 / 背景声', '双素材混音', '级联：EQ → 声场 → 混音', '分离 → 人声处理 → 重新混音'];""")
start=s.index('  async renderAudio()')
end=s.index('  aboutToDisappear()',start)
s=s[:start]+'''  // 用户导入的文件会复制到沙箱，C++ 再严格校验 WAV 格式。
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
  // 页面处理入口：参数传入 N-API，由后台线程构建和运行 AudioSuite。
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
''' + s[end:]
start=s.index('  build()')
s=s[:start]+'''  build() {
    Scroll() {
      Column({ space: 18 }) {
        Text('AUDIO SUITE · ALGORITHM LAB').fontSize(12).fontColor('#8BA6C4').letterSpacing(2)
        Text('离线音频编辑 · v2').fontSize(30).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
        Text('从输入重新计算。结果仅在本次算法成功后开放试听。').fontSize(14).fontColor('#B3C1D2')
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
        Text('02  选择处理任务').fontColor('#69E4CC').fontSize(18)
        ForEach(this.modes, (name: string, index: number) => {
          Button(name).width('100%').backgroundColor(this.mode === index ? '#69E4CC' : '#263A50')
            .fontColor(this.mode === index ? '#102031' : '#FFFFFF').enabled(!this.busy)
            .onClick(() => { this.mode = index; this.invalidate(); })
        })
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
        Text('分离任务调用 MultiRenderFrame；分离后重混使用两阶段管线。设备不支持时显示错误，不加载历史结果。')
          .fontColor('#B3C1D2').fontSize(12)
      }.padding(24).width('100%').alignItems(HorizontalAlign.Start)
    }.height('100%').width('100%').backgroundColor('#0B1728')
  }
}
'''
p.write_text(s)
