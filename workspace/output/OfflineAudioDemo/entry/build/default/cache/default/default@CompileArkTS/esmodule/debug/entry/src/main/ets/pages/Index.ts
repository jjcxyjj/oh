if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface Index_Params {
    mode?: number;
    preset?: number;
    gainA?: number;
    gainB?: number;
    inputLabel?: string;
    secondLabel?: string;
    resultPaths?: string[];
    resultLabels?: string[];
    second?: string;
    modes?: string[];
    busy?: boolean;
    ready?: boolean;
    status?: string;
    input?: string;
    original?: string;
    output?: string;
    player?: media.AVPlayer | undefined;
    playingFile?: fs.File | undefined;
    presets?: string[];
}
import engine from "@normalized:Y&&&libentry.so&";
import type common from "@ohos:app.ability.common";
import fs from "@ohos:file.fs";
import picker from "@ohos:file.picker";
import media from "@ohos:multimedia.media";
class Index extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__mode = new ObservedPropertySimplePU(0, this, "mode");
        this.__preset = new ObservedPropertySimplePU(1, this, "preset");
        this.__gainA = new ObservedPropertySimplePU(0.7, this, "gainA");
        this.__gainB = new ObservedPropertySimplePU(0.3, this, "gainB");
        this.__inputLabel = new ObservedPropertySimplePU('内置官方 PCM', this, "inputLabel");
        this.__secondLabel = new ObservedPropertySimplePU('未选择（混音需导入）', this, "secondLabel");
        this.__resultPaths = new ObservedPropertyObjectPU([], this, "resultPaths");
        this.__resultLabels = new ObservedPropertyObjectPU([], this, "resultLabels");
        this.second = '';
        this.modes = ['均衡器 EQ', '音源分离：人声 / 背景声', '双素材混音', '级联：EQ → 声场 → 混音', '分离 → 人声处理 → 重新混音'];
        this.__busy = new ObservedPropertySimplePU(false, this, "busy");
        this.__ready = new ObservedPropertySimplePU(false, this, "ready");
        this.__status = new ObservedPropertySimplePU('准备音频中', this, "status");
        this.input = '';
        this.original = '';
        this.output = '';
        this.player = undefined;
        this.playingFile = undefined;
        this.presets = ['原声直通', '人声清晰', '低频温暖'];
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: Index_Params) {
        if (params.mode !== undefined) {
            this.mode = params.mode;
        }
        if (params.preset !== undefined) {
            this.preset = params.preset;
        }
        if (params.gainA !== undefined) {
            this.gainA = params.gainA;
        }
        if (params.gainB !== undefined) {
            this.gainB = params.gainB;
        }
        if (params.inputLabel !== undefined) {
            this.inputLabel = params.inputLabel;
        }
        if (params.secondLabel !== undefined) {
            this.secondLabel = params.secondLabel;
        }
        if (params.resultPaths !== undefined) {
            this.resultPaths = params.resultPaths;
        }
        if (params.resultLabels !== undefined) {
            this.resultLabels = params.resultLabels;
        }
        if (params.second !== undefined) {
            this.second = params.second;
        }
        if (params.modes !== undefined) {
            this.modes = params.modes;
        }
        if (params.busy !== undefined) {
            this.busy = params.busy;
        }
        if (params.ready !== undefined) {
            this.ready = params.ready;
        }
        if (params.status !== undefined) {
            this.status = params.status;
        }
        if (params.input !== undefined) {
            this.input = params.input;
        }
        if (params.original !== undefined) {
            this.original = params.original;
        }
        if (params.output !== undefined) {
            this.output = params.output;
        }
        if (params.player !== undefined) {
            this.player = params.player;
        }
        if (params.playingFile !== undefined) {
            this.playingFile = params.playingFile;
        }
        if (params.presets !== undefined) {
            this.presets = params.presets;
        }
    }
    updateStateVars(params: Index_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__mode.purgeDependencyOnElmtId(rmElmtId);
        this.__preset.purgeDependencyOnElmtId(rmElmtId);
        this.__gainA.purgeDependencyOnElmtId(rmElmtId);
        this.__gainB.purgeDependencyOnElmtId(rmElmtId);
        this.__inputLabel.purgeDependencyOnElmtId(rmElmtId);
        this.__secondLabel.purgeDependencyOnElmtId(rmElmtId);
        this.__resultPaths.purgeDependencyOnElmtId(rmElmtId);
        this.__resultLabels.purgeDependencyOnElmtId(rmElmtId);
        this.__busy.purgeDependencyOnElmtId(rmElmtId);
        this.__ready.purgeDependencyOnElmtId(rmElmtId);
        this.__status.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__mode.aboutToBeDeleted();
        this.__preset.aboutToBeDeleted();
        this.__gainA.aboutToBeDeleted();
        this.__gainB.aboutToBeDeleted();
        this.__inputLabel.aboutToBeDeleted();
        this.__secondLabel.aboutToBeDeleted();
        this.__resultPaths.aboutToBeDeleted();
        this.__resultLabels.aboutToBeDeleted();
        this.__busy.aboutToBeDeleted();
        this.__ready.aboutToBeDeleted();
        this.__status.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __mode: ObservedPropertySimplePU<number>;
    get mode() {
        return this.__mode.get();
    }
    set mode(newValue: number) {
        this.__mode.set(newValue);
    }
    private __preset: ObservedPropertySimplePU<number>;
    get preset() {
        return this.__preset.get();
    }
    set preset(newValue: number) {
        this.__preset.set(newValue);
    }
    private __gainA: ObservedPropertySimplePU<number>;
    get gainA() {
        return this.__gainA.get();
    }
    set gainA(newValue: number) {
        this.__gainA.set(newValue);
    }
    private __gainB: ObservedPropertySimplePU<number>;
    get gainB() {
        return this.__gainB.get();
    }
    set gainB(newValue: number) {
        this.__gainB.set(newValue);
    }
    private __inputLabel: ObservedPropertySimplePU<string>;
    get inputLabel() {
        return this.__inputLabel.get();
    }
    set inputLabel(newValue: string) {
        this.__inputLabel.set(newValue);
    }
    private __secondLabel: ObservedPropertySimplePU<string>;
    get secondLabel() {
        return this.__secondLabel.get();
    }
    set secondLabel(newValue: string) {
        this.__secondLabel.set(newValue);
    }
    private __resultPaths: ObservedPropertyObjectPU<string[]>;
    get resultPaths() {
        return this.__resultPaths.get();
    }
    set resultPaths(newValue: string[]) {
        this.__resultPaths.set(newValue);
    }
    private __resultLabels: ObservedPropertyObjectPU<string[]>;
    get resultLabels() {
        return this.__resultLabels.get();
    }
    set resultLabels(newValue: string[]) {
        this.__resultLabels.set(newValue);
    }
    private second: string;
    private modes: string[];
    private __busy: ObservedPropertySimplePU<boolean>;
    get busy() {
        return this.__busy.get();
    }
    set busy(newValue: boolean) {
        this.__busy.set(newValue);
    }
    private __ready: ObservedPropertySimplePU<boolean>;
    get ready() {
        return this.__ready.get();
    }
    set ready(newValue: boolean) {
        this.__ready.set(newValue);
    }
    private __status: ObservedPropertySimplePU<string>;
    get status() {
        return this.__status.get();
    }
    set status(newValue: string) {
        this.__status.set(newValue);
    }
    private input: string;
    private original: string;
    private output: string;
    private player: media.AVPlayer | undefined;
    private playingFile: fs.File | undefined;
    private presets: string[];
    aboutToAppear(): void {
        try {
            const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
            this.input = ctx.filesDir + '/source.pcm';
            this.original = ctx.filesDir + '/original.wav';
            this.output = ctx.filesDir + '/edited.wav';
            const bytes = ctx.resourceManager.getRawFileContentSync('S16LE_2_48000.pcm');
            const pcm = bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength);
            const f = fs.openSync(this.input, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
            try {
                fs.writeSync(f.fd, pcm);
            }
            finally {
                fs.closeSync(f);
            }
            const wav = new ArrayBuffer(44 + bytes.byteLength);
            const v = new DataView(wav);
            const header = 'RIFF    WAVEfmt ';
            for (let i = 0; i < header.length; i++) {
                v.setUint8(i, header.charCodeAt(i));
            }
            v.setUint32(4, bytes.byteLength + 36, true);
            v.setUint32(16, 16, true);
            v.setUint16(20, 1, true);
            v.setUint16(22, 2, true);
            v.setUint32(24, 48000, true);
            v.setUint32(28, 192000, true);
            v.setUint16(32, 4, true);
            v.setUint16(34, 16, true);
            v.setUint32(36, 0x61746164, true);
            v.setUint32(40, bytes.byteLength, true);
            new Uint8Array(wav).set(bytes, 44);
            const w = fs.openSync(this.original, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
            try {
                fs.writeSync(w.fd, wav);
            }
            finally {
                fs.closeSync(w);
            }
            this.status = '音频已就绪 · ' + (bytes.byteLength / 192000).toFixed(1) + ' 秒';
        }
        catch (e) {
            this.status = '初始化失败：' + String(e);
            this.input = '';
        }
    }
    async stop(): Promise<void> {
        try {
            if (this.player) {
                await this.player.release();
            }
        }
        catch (e) {
            this.status = '播放器释放失败：' + String(e);
        }
        finally {
            this.player = undefined;
        }
        try {
            if (this.playingFile) {
                fs.closeSync(this.playingFile);
            }
        }
        catch (e) {
            this.status = '音频文件关闭失败：' + String(e);
        }
        finally {
            this.playingFile = undefined;
        }
    }
    async play(path: string): Promise<void> {
        try {
            await this.stop();
            const p = await media.createAVPlayer();
            this.player = p;
            p.on('stateChange', async (state: string) => {
                try {
                    if (state === 'initialized') {
                        await p.prepare();
                    }
                    if (state === 'prepared') {
                        await p.play();
                    }
                }
                catch (e) {
                    this.status = '播放失败：' + String(e);
                }
            });
            p.on('error', () => { this.status = '播放失败，请重试'; });
            this.playingFile = fs.openSync(path, fs.OpenMode.READ_ONLY);
            p.fdSrc = { fd: this.playingFile.fd, offset: 0, length: fs.statSync(path).size };
        }
        catch (e) {
            this.status = '播放失败：' + String(e);
        }
    }
    // 用户导入的文件会复制到沙箱，C++ 再严格校验 WAV 格式。
    async importAudio(second: boolean): Promise<void> {
        if (this.busy) {
            return;
        }
        this.busy = true;
        try {
            const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
            const options = new picker.DocumentSelectOptions();
            options.maxSelectNumber = 1;
            const uris = await new picker.DocumentViewPicker(ctx).select(options);
            if (!uris.length) {
                return;
            }
            const f = fs.openSync(uris[0], fs.OpenMode.READ_ONLY);
            const path = ctx.filesDir + (second ? '/import-b.wav' : '/import-a.wav');
            try {
                if (fs.statSync(f.fd).size > 24 * 1024 * 1024) {
                    throw new Error('输入文件超过 24 MB');
                }
                fs.copyFileSync(f.fd, path);
            }
            finally {
                fs.closeSync(f);
            }
            await this.stop();
            if (second) {
                this.second = path;
                this.secondLabel = '已导入素材 B';
            }
            else {
                this.input = path;
                this.original = path;
                this.inputLabel = '已导入素材 A';
            }
            this.invalidate();
            this.status = '已导入；开始处理时校验 48kHz / 双声道 / PCM16 WAV';
        }
        catch (e) {
            this.status = '导入失败：' + String(e);
        }
        finally {
            this.busy = false;
        }
    }
    invalidate(): void { this.ready = false; this.resultPaths = []; this.resultLabels = []; }
    // 页面处理入口：参数传入 N-API，由后台线程构建和运行 AudioSuite。
    async renderAudio(): Promise<void> {
        this.busy = true;
        this.invalidate();
        this.status = '正在运行 AudioSuite 算法，请稍候';
        try {
            await this.stop();
            const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
            const prefix = ctx.filesDir + '/task-' + Date.now().toString();
            const report = await engine.run(this.input, this.second, prefix, this.mode, this.preset, this.gainA, this.gainB);
            this.resultPaths = report.paths;
            this.resultLabels = report.labels;
            this.ready = true;
            this.status = '本次算法完成 · ' + report.elapsedMs + ' ms · ' + report.paths.length + ' 个输出';
        }
        catch (e) {
            this.status = '处理失败：' + String(e);
        }
        finally {
            this.busy = false;
        }
    }
    async save(path: string, label: string): Promise<void> {
        try {
            const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
            const options = new picker.DocumentSaveOptions();
            options.newFileNames = [label + '.wav'];
            const uris = await new picker.DocumentViewPicker(ctx).save(options);
            if (!uris.length) {
                return;
            }
            const file = fs.openSync(uris[0], fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
            try {
                fs.copyFileSync(path, file.fd);
            }
            finally {
                fs.closeSync(file);
            }
            this.status = label + ' WAV 已导出';
        }
        catch (e) {
            this.status = '导出未完成：' + String(e);
        }
    }
    aboutToDisappear(): void { this.stop(); }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.height('100%');
            Scroll.width('100%');
            Scroll.backgroundColor('#0B1728');
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 18 });
            Column.padding(24);
            Column.width('100%');
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('AUDIO SUITE · ALGORITHM LAB');
            Text.fontSize(12);
            Text.fontColor('#8BA6C4');
            Text.letterSpacing(2);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('离线音频编辑 · v2');
            Text.fontSize(30);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor('#FFFFFF');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('从输入重新计算。结果仅在本次算法成功后开放试听。');
            Text.fontSize(14);
            Text.fontColor('#B3C1D2');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 10 });
            Column.alignItems(HorizontalAlign.Start);
            Column.width('100%');
            Column.padding(18);
            Column.backgroundColor('#15263A');
            Column.borderRadius(16);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('01  输入素材');
            Text.fontColor('#69E4CC');
            Text.fontSize(18);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('A：' + this.inputLabel + ' / B：' + this.secondLabel);
            Text.fontColor('#FFFFFF');
            Text.fontSize(14);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('导入要求：48kHz、双声道、PCM16 WAV，最长 120 秒');
            Text.fontColor('#B3C1D2');
            Text.fontSize(12);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 8 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('导入 A');
            Button.onClick(() => this.importAudio(false));
            Button.enabled(!this.busy);
        }, Button);
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('导入 B');
            Button.onClick(() => this.importAudio(true));
            Button.enabled(!this.busy);
        }, Button);
        Button.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('试听原始 A');
            Button.onClick(() => this.play(this.original));
            Button.enabled(!this.busy && this.input.length > 0);
        }, Button);
        Button.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('02  选择处理任务');
            Text.fontColor('#69E4CC');
            Text.fontSize(18);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = (_item, index: number) => {
                const name = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Button.createWithLabel(name);
                    Button.width('100%');
                    Button.backgroundColor(this.mode === index ? '#69E4CC' : '#263A50');
                    Button.fontColor(this.mode === index ? '#102031' : '#FFFFFF');
                    Button.enabled(!this.busy);
                    Button.onClick(() => { this.mode = index; this.invalidate(); });
                }, Button);
                Button.pop();
            };
            this.forEachUpdateFunction(elmtId, this.modes, forEachItemGenFunction, undefined, true, false);
        }, ForEach);
        ForEach.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.mode === 0 || this.mode === 3 || this.mode === 4) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('EQ 预设（“人声清晰”是 EQ 名称，不是音源分离）');
                        Text.fontColor('#B3C1D2');
                        Text.fontSize(12);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = (_item, index: number) => {
                            const name = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Button.createWithLabel(name);
                                Button.width('100%');
                                Button.backgroundColor(this.preset === index ? '#147AF0' : '#263A50');
                                Button.enabled(!this.busy);
                                Button.onClick(() => { this.preset = index; this.invalidate(); });
                            }, Button);
                            Button.pop();
                        };
                        this.forEachUpdateFunction(elmtId, this.presets, forEachItemGenFunction, undefined, true, false);
                    }, ForEach);
                    ForEach.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.mode >= 2) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.mode === 4 ? '分离人声增益 / 分离背景增益' : '输入 A 增益 / 输入 B 增益');
                        Text.fontColor('#B3C1D2');
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('A ' + this.gainA.toFixed(2) + ' / B ' + this.gainB.toFixed(2));
                        Text.fontColor('#FFFFFF');
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Slider.create({ value: this.gainA, min: 0, max: 1, step: 0.05 });
                        Slider.enabled(!this.busy);
                        Slider.onChange((value: number) => { this.gainA = value; this.invalidate(); });
                    }, Slider);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Slider.create({ value: this.gainB, min: 0, max: 1, step: 0.05 });
                        Slider.enabled(!this.busy);
                        Slider.onChange((value: number) => { this.gainB = value; this.invalidate(); });
                    }, Slider);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('增益过大可能削波，建议两路增益之和 ≤ 1；EQ 增益也需留余量。');
                        Text.fontColor('#B3C1D2');
                        Text.fontSize(12);
                    }, Text);
                    Text.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel(this.busy ? '算法处理中…' : '开始运行算法');
            Button.width('100%');
            Button.height(52);
            Button.backgroundColor('#69E4CC');
            Button.fontColor('#102031');
            Button.enabled(!this.busy && this.input.length > 0 && ((this.mode !== 2 && this.mode !== 3) || this.second.length > 0));
            Button.onClick(() => this.renderAudio());
        }, Button);
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.status);
            Text.fontColor('#B3C1D2');
            Text.fontSize(14);
            Text.width('100%');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.ready) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = (_item, index: number) => {
                            const path = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(this.resultLabels[index]);
                                Text.fontColor('#69E4CC');
                            }, Text);
                            Text.pop();
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Row.create({ space: 12 });
                            }, Row);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Button.createWithLabel('试听');
                                Button.enabled(!this.busy);
                                Button.onClick(() => this.play(path));
                            }, Button);
                            Button.pop();
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Button.createWithLabel('导出 WAV');
                                Button.enabled(!this.busy);
                                Button.onClick(() => this.save(path, this.resultLabels[index]));
                            }, Button);
                            Button.pop();
                            Row.pop();
                        };
                        this.forEachUpdateFunction(elmtId, this.resultPaths, forEachItemGenFunction, undefined, true, false);
                    }, ForEach);
                    ForEach.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('停止播放');
            Button.onClick(() => this.stop());
            Button.backgroundColor('#263A50');
        }, Button);
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('分离任务调用 MultiRenderFrame；分离后重混使用两阶段管线。设备不支持时显示错误，不加载历史结果。');
            Text.fontColor('#B3C1D2');
            Text.fontSize(12);
        }, Text);
        Text.pop();
        Column.pop();
        Scroll.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "Index";
    }
}
registerNamedRoute(() => new Index(undefined, {}), "", { bundleName: "com.example.offlineaudiolab", moduleName: "entry", pagePath: "pages/Index", pageFullPath: "entry/src/main/ets/pages/Index", integratedHsp: "false", moduleType: "followWithHap" });
