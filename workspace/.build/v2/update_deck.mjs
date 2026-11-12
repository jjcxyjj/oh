import {PresentationFile,FileBlob} from '@oai/artifact-tool';
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import {finalizePresentation} from '/Users/jiaoyuanxiang/.codex/plugins/cache/openai-primary-runtime/presentations/26.1026.10807/skills/presentations/container_tools/artifact_tool_utils.mjs';
const root='/Users/jiaoyuanxiang/Desktop/oh/workspace',source=root+'/output/PPT/AudioSuite_离线编辑方案.pptx';
await fs.copyFile(source,root+'/.build/v2/AudioSuite-v1.pptx');
const p=await PresentationFile.importPptx(await FileBlob.load(source));
const updates=[
 {6:'AudioSuite 离线音频编辑与算法演示',7:'五种任务从输入重新计算，完成分离、混音、多节点级联与 WAV 导出',21:'内置 50 秒原始素材，可导入 PCM16 WAV。\n两路输入统一为 48 kHz 双声道。',25:'任务  /  五种模式',31:'5 类任务',32:'EQ、分离、混音与级联',34:'包含分离后重新混音的两阶段任务。\n结果在本次算法完成后生成，支持分别试听。',60:'交付可阅读源码、未签名 HAP 与交互网页。\n浏览器 DSP 与鸿蒙 AudioSuite 分别验证。',64:'原生接入分离与混音接口，网页提供可学习的 DSP 算法与运行记录'},
 {11:'内置 PCM 或导入双路 WAV',20:'任务模式与三种 EQ 预设',21:'两路增益在 0 至 1 之间',29:'ArkTS 调用 run Promise',36:'AudioSuite 任务管线',39:'原始音频',42:'任务节点组',45:'单路或双路渲染接口',49:'普通任务使用 RenderFrame，分离任务使用 MultiRenderFrame，逐帧写入独立结果文件',64:'分离节点仅接输出，分离后重混需要重新建立第二阶段管线',65:'来源：华为 AudioSuite 文档与本项目 audio_pipeline.cpp、Index.ets'},
 {13:'按任务连接节点',25:'查询所需节点支持状态',31:'按任务组网',34:'EQ、分离或双路混音',35:'级联增加声场节点',36:'分离输出人声与背景声',62:'原生接受 48 kHz 双声道 PCM16 WAV 或内部裸 PCM，长度按 4 字节对齐',63:'单个输入最长 120 秒，WAV 解析会跳过文件头，压缩格式需要先转换'},
 {4:'音源分离与混音级联',5:'分离任务输出两路音频，复杂任务通过节点级联和阶段衔接完成',9:'双路分离',10:'2 个输出',12:'输入连接 AudioSuite 音源分离节点',13:'MultiRenderFrame 返回人声和背景声',14:'两个结果分别写成 WAV，独立试听导出',18:'双素材混音',19:'A + B',21:'两路输入分别读取素材，应用各自增益',22:'连接同一个混音节点，生成单路结果',23:'处理期间锁定输入，完成后开放试听',27:'多节点级联',28:'EQ + 声场',30:'输入 A 先经过 EQ，再进入前置声场',31:'处理后的 A 与输入 B 在混音节点汇合',32:'浏览器以 Mid/Side 宽度处理演示声场',36:'分离后重新混音',37:'2 个阶段',39:'阶段一生成分离人声和分离背景 WAV',40:'阶段二对人声执行 EQ、声场与混音',41:'两阶段均成功后返回全部三个结果',45:'网页分离采用中置频谱估计，非 AI 人声模型，也不等同于华为原生分离'},
 {10:'检查任务类型、增益、WAV 格式、文件长度与帧对齐',16:'检查节点支持、连接操作和单路或双路渲染返回值',29:'释放 N-API 异步对象，互斥保护原生处理任务',33:'2026 年 11 月 12 日',42:'原生设备运行结果待验证',43:'编译通过不代表真机分离效果通过',47:'配置签名后验证分离支持、双输入混音、阶段衔接、试听与错误恢复',48:'依据：新版构建日志与浏览器算法测试记录'},
 {5:'源码、安装包、算法网页与代码导读统一交付到 oh/workspace',9:'导入素材，选择任务，运行算法，检查指纹与处理日志，试听并导出本次 WAV',15:'五种任务、用户导入与 WAV 导出通过',16:'检查分离重构误差、增益公式与结果失效',21:'检查分离、混音、声场及 WAV 输出',25:'浏览器分离依赖中置声像假设，原生运行仍需签名安装与设备验收',24:'适用边界'}
];
for(let i=0;i<p.slides.items.length;i++) {
 const slide=p.slides.items[i];
 for(const [id,text] of Object.entries(updates[i])) {const shape=slide.shapes.items.find(s=>s.id===id);if(!shape)throw Error(`Missing ${i+1}/${id}`);shape.text=text;}
 for(const shape of slide.shapes.items) {
   const pos=shape.position;
   // 顶部通栏蓝色与紧随其后的分隔线，保留其他卡片的原参考配色。
   if(pos.width>1200 && pos.top<140) {
     if(pos.height>50) shape.fill='#2F5597';
     else if(pos.height>0 && pos.height<10) shape.fill='#8064A2';
   }
 }
 slide.speakerNotes.text='实现参考：https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/audio-suite-manual-rendering\n本地 SDK：ohaudiosuite/native_audio_suite_engine.h 与 native_audio_suite_base.h。\n源码：entry/src/main/cpp/audio_pipeline.cpp；网页 dsp.js 与 app.js。\n网页分离使用 STFT 中置软掩码，不能识别语义上的人声或替代 AudioSuite 模型。真机尚未验收。';
}
const table=p.slides.items[5].tables.items[0];
table.cells.set(2,1,'五种任务与数据校验');table.cells.set(2,2,'交互测试通过');table.cells.set(3,2,'尚未验收');
for(let c=0;c<4;c++)table.getCell(0,c).fill='#2F5597';
await fs.mkdir(root+'/.build/v2/slides',{recursive:true});
for(let i=0;i<6;i++)await fs.writeFile(root+'/.build/v2/slides/slide-'+(i+1)+'.png',new Uint8Array(await(await p.export({slide:p.slides.items[i],format:'png',scale:1.5})).arrayBuffer()));
const candidatePath=root+'/.build/v2/candidate.pptx';await(await PresentationFile.exportPptx(p)).save(candidatePath);
const skill='/Users/jiaoyuanxiang/.codex/plugins/cache/openai-primary-runtime/presentations/26.1026.10807/skills/presentations';
console.log(await finalizePresentation({workspaceDir:root,candidatePath,finalPath:root+'/.build/v2/final.pptx',pythonExecutable:'/Users/jiaoyuanxiang/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3',integrityValidatorPath:skill+'/container_tools/inspect_presentation_package_integrity.py',layoutValidatorPath:skill+'/container_tools/inspect_presentation_layout_geometry.py',layoutArgs:['--expected-slide-size-emu','12192000,6858000','--validate-bullet-geometry','--validate-heading-fit','--require-native-table-slide','6'],requiredNativeTableOwnerSlides:[6],fontPolicy:{basis:'reference',families:['微软雅黑'],referencePath:source,referenceSha256:crypto.createHash('sha256').update(await fs.readFile(source)).digest('hex')},verifyArtifactToolImport:true,receiptPath:root+'/.build/v2/deck-validation.json'}));
