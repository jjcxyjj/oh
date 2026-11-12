import {PresentationFile,FileBlob} from '@oai/artifact-tool';
const p=await PresentationFile.importPptx(await FileBlob.load('/Users/jiaoyuanxiang/Desktop/huawei/ACE-Step_端侧部署选型论证_美化版.pptx'));
for(let i=0;i<p.slides.items.length;i++){console.log('SLIDE',i+1);console.log(p.slides.items[i].shapes.items.filter(s=>s.text.toString()).map(s=>({id:s.id,text:s.text.toString()})));}
console.log('tables',p.slides.items[5].tables.items.length);
