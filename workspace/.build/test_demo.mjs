import {chromium} from 'playwright';
import fs from 'node:fs/promises';
const root='/Users/jiaoyuanxiang/Desktop/oh/chatgpt';
const browser=await chromium.launch({executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true});
const ctx=await browser.newContext({viewport:{width:1440,height:1100},recordVideo:{dir:root+'/output/Demo演示/录屏',size:{width:1440,height:1100}},acceptDownloads:true});
const page=await ctx.newPage();let errors=[];page.on('pageerror',e=>errors.push(e.message));
await page.goto('file://'+root+'/output/Demo演示/离线编辑演示.html');
await page.screenshot({path:root+'/output/Demo演示/01_演示界面.png',fullPage:true});
const results=[];
for(const preset of [0,1,2]){
 await page.locator('[data-preset="'+preset+'"]').click();
 await page.locator('#render').click();
 await page.waitForFunction(()=>window.demoResult?.preset===Number(document.querySelector('.active').dataset.preset)&&document.querySelector('#status').textContent.includes('渲染完成'));
 results.push(await page.evaluate(()=>window.demoResult));
 const downloadPromise=page.waitForEvent('download');await page.locator('#download').click();
 const download=await downloadPromise;await download.saveAs(root+'/output/Demo演示/'+['原声直通','人声清晰','低频温暖'][preset]+'.wav');
 await page.locator('#result').evaluate(a=>a.play());
 await page.waitForTimeout(1800);
 await page.locator('#result').evaluate(a=>a.pause());
}
await page.screenshot({path:root+'/output/Demo演示/02_渲染结果.png',fullPage:true});
await fs.writeFile(root+'/.build/browser-test.json',JSON.stringify({results,errors},null,2));
await ctx.close();await browser.close();console.log(JSON.stringify({results,errors}));
if(errors.length)process.exitCode=1;
