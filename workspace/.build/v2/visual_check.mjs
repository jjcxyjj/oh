import {chromium} from 'playwright';
import assert from 'node:assert/strict';
const root='/Users/jiaoyuanxiang/Desktop/oh/workspace',url='http://127.0.0.1:18765/output/Demo%E6%BC%94%E7%A4%BA/index.html';
const browser=await chromium.launch({executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true,args:['--disable-gpu']});
const context=await browser.newContext({viewport:{width:390,height:844},reducedMotion:'reduce'});const page=await context.newPage();
await page.goto(url+'#eq');await page.waitForFunction(()=>document.querySelector('#metaA').textContent.includes('指纹'));await page.screenshot({path:root+'/.build/v2/mobile-top.png'});
await page.locator('#eqSettings').scrollIntoViewIfNeeded();await page.screenshot({path:root+'/.build/v2/mobile-controls.png'});
assert.equal(await page.locator('header').count(),1);assert(await page.evaluate(()=>document.documentElement.scrollWidth===innerWidth));
await page.setViewportSize({width:1440,height:1100});
for(const mode of ['eq','separate','mix','cascade','remix']) {
 await page.locator(`[data-mode="${mode}"]`).click();
 await page.waitForFunction(()=>document.querySelector('#official-diagram').complete&&document.querySelector('#official-diagram').naturalWidth>0);
 const box=await page.locator('.tab-cursor').boundingBox(),tab=await page.locator(`[data-mode="${mode}"]`).boundingBox();assert(Math.abs(box.x-tab.x)<2);
 await page.screenshot({path:root+'/.build/v2/final-'+mode+'.png',fullPage:true,animations:'disabled'});
}
// 双击本地 HTML 也能运行，不依赖服务器。
await page.goto('file://'+root+'/output/Demo演示/index.html#eq');await page.locator('#run').click();await page.waitForFunction(()=>window.lastRun?.mode==='eq');
assert.equal(await page.locator('#results audio').count(),1);
console.log('PASS: five tabs, indicator alignment, local diagrams, mobile layout, file:// EQ execution');
await browser.close();
