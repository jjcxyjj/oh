import {chromium} from 'playwright';
import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
const root='/Users/jiaoyuanxiang/Desktop/oh/workspace';
const browser=await chromium.launch({executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true});
const context=await browser.newContext({viewport:{width:1440,height:1100},acceptDownloads:true});
const page=await context.newPage(),errors=[],requests=[];page.on('pageerror',e=>errors.push(e.message));page.on('request',r=>requests.push(r.url()));
await page.goto('http://127.0.0.1:18765/output/Demo%E6%BC%94%E7%A4%BA/index.html');
await page.waitForFunction(()=>!!globalThis.AudioLab && document.querySelector('#metaA').textContent.includes('指纹'));
assert.equal(await page.locator('#results audio').count(),0);
assert.equal(await page.locator('header').evaluate(e=>getComputedStyle(e).backgroundColor),'rgb(47, 85, 151)');
const unit=await page.evaluate(async()=>{
  const a=AudioLab.makeBuffer(48000),b=AudioLab.makeBuffer(24000);
  for(let i=0;i<a.length;i++) {const center=.2*Math.sin(2*Math.PI*750*i/48000),side=.1*Math.sin(2*Math.PI*3000*i/48000);a.getChannelData(0)[i]=center+side;a.getChannelData(1)[i]=center;}
  b.getChannelData(0).fill(.05);b.getChannelData(1).fill(-.03);
  const flat=await AudioLab.equalize(a,0),m=AudioLab.mix(a,b,.7,.3),stems=await AudioLab.separate(a);
  let flatError=0,reconstructError=0,mixError=0,centerError=0;
  for(let i=0;i<a.length;i++) {
    for(let ch=0;ch<2;ch++) {
      flatError=Math.max(flatError,Math.abs(a.getChannelData(ch)[i]-flat.getChannelData(ch)[i]));
      reconstructError=Math.max(reconstructError,Math.abs(a.getChannelData(ch)[i]-stems.vocal.getChannelData(ch)[i]-stems.background.getChannelData(ch)[i]));
      mixError=Math.max(mixError,Math.abs(m.getChannelData(ch)[i]-(.7*a.getChannelData(ch)[i]+.3*(b.getChannelData(ch)[i]||0))));
    }
    if(i>2048&&i<45952)centerError+=Math.abs(stems.vocal.getChannelData(0)[i]-.2*Math.sin(2*Math.PI*750*i/48000));
  }
  let missingB=false;try{await AudioLab.run({a,mode:'mix',preset:0,gainA:.7,gainB:.3});}catch(e){missingB=true;}
  return {flatError,reconstructError,mixError,centerMeanError:centerError/(45952-2049),frames:m.length,missingB};
});
assert(unit.flatError<1e-6);assert(unit.reconstructError<1e-6);assert(unit.mixError<1e-6);assert(unit.centerMeanError<.015);assert.equal(unit.frames,48000);assert(unit.missingB);
await page.locator('[data-mode="mix"]').click();await page.locator('#generateB').click();
const runs=[];
for(const mode of ['eq','separate','mix','cascade','remix']) {
  await page.locator(`[data-mode="${mode}"]`).click();assert.equal(await page.locator('#results audio').count(),0);
  await page.locator('#run').click();
  await page.waitForFunction(m=>window.lastRun?.mode===m,mode,{timeout:120000});
  const run=await page.evaluate(()=>window.lastRun);runs.push(run);
  assert.equal(run.outputs.length,mode==='separate'?2:mode==='remix'?3:1);
  assert(run.outputs.every(o=>o.frames===2400000 && o.bytes===9600044));
  assert(await page.locator('#results audio').first().evaluate(a=>a.src.startsWith('blob:')));
}
await page.screenshot({path:root+'/.build/v2/browser-desktop.png',fullPage:true});
const downloadPromise=page.waitForEvent('download');await page.locator('#results a').last().click();
const download=await downloadPromise;await download.saveAs(root+'/.build/v2/test-remix.wav');
// 用户文件导入之后应替换原素材，输出长度必须随之改变。
const fixture=await page.evaluate(async()=>{const b=AudioLab.makeBuffer(48000);for(let i=0;i<48000;i++)for(let c=0;c<2;c++)b.getChannelData(c)[i]=.1*Math.sin(i*.1+c);return Array.from(new Uint8Array(await AudioLab.wav(b).arrayBuffer()));});
await page.locator('#inputA').setInputFiles({name:'user-fixture.wav',mimeType:'audio/wav',buffer:Buffer.from(fixture)});
await page.waitForFunction(()=>document.querySelector('#metaA').textContent.includes('user-fixture.wav'));
assert.equal(await page.locator('#results audio').count(),0);
await page.locator('[data-mode="eq"]').click();await page.locator('#run').click();await page.waitForFunction(()=>window.lastRun?.outputs[0].frames===48000);
const imported=await page.evaluate(()=>window.lastRun);assert.notEqual(imported.inputFingerprint,runs[0].inputFingerprint);
await page.setViewportSize({width:390,height:844});
await page.screenshot({path:root+'/.build/v2/browser-mobile.png',fullPage:true});
assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
assert(!requests.some(url=>/人声清晰|低频温暖|原声直通|\.wav(?:$|\?)/.test(decodeURI(url))));
assert.equal(errors.length,0);
await page.setViewportSize({width:1440,height:1100});
for(const mode of ['eq','separate','cascade']) {
 await page.locator(`[data-mode="${mode}"]`).click();
 await page.waitForFunction(()=>document.querySelector('#official-diagram').complete&&document.querySelector('#official-diagram').naturalWidth>0);
 assert.equal(await page.locator('[role=tab][aria-selected=true]').count(),1);
 assert.equal(await page.locator('#eqSettings').isVisible(),mode!=='separate');
 if(mode==='eq') {assert.equal(await page.locator('[data-preset]:visible').count(),3);await page.locator('[data-preset="2"]').click();assert.equal(await page.locator('#preset').inputValue(),'2');}
 await page.screenshot({path:root+'/.build/v2/task-'+mode+'.png',fullPage:true});
}
await page.locator('[data-mode="eq"]').click();await page.setViewportSize({width:390,height:844});await page.screenshot({path:root+'/.build/v2/task-mobile.png',fullPage:true});
assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));

await fs.writeFile(root+'/.build/v2/browser-validation.json',JSON.stringify({unit,runs,imported,errors,requests},null,2));
console.log(JSON.stringify({unit,runs:runs.map(r=>({mode:r.mode,ms:r.elapsed,outputs:r.outputs.map(o=>({name:o.name,hash:o.fingerprint,clipped:o.clipped}))})),errors}));
await context.close();await browser.close();
