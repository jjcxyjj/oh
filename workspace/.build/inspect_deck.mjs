import {PresentationFile,FileBlob} from '@oai/artifact-tool';
import fs from 'node:fs/promises';
const p=await PresentationFile.importPptx(await FileBlob.load('/Users/jiaoyuanxiang/Desktop/huawei/ACE-Step_端侧部署选型论证_美化版.pptx'));
console.log('slides',p.slides.items.length,'masters',p.masters.items.length);
await fs.writeFile('.build/reference/inspect.ndjson',(await p.inspect({kind:'slide,layout,textbox,shape',maxChars:1000000})).ndjson);
console.log(p.slides.items[0].shapes.items.map(s=>({id:s.id,text:s.text.toString().slice(0,70)})).slice(0,12));
await fs.writeFile('.build/reference/artifact-preview.png',new Uint8Array(await (await p.export({slide:p.slides.items[0],format:'png',scale:1})).arrayBuffer()));
