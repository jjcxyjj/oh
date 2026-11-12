/* 页面入口：main()；处理按钮：runTask()；算法实现：dsp.js。 */
'use strict';
const $=selector=>document.querySelector(selector);
const state={a:null,b:null,mode:'eq',busy:false,sequence:0,results:[],resultUrls:[],inputUrls:{}};
const chains={eq:'输入 A → 10 段 EQ → 输出 WAV',separate:'输入 A → STFT 中置频谱分离 → 估计人声 + 残余伴奏',mix:'输入 A × 增益 + 输入 B × 增益 → 混音输出',cascade:'输入 A → EQ → Mid/Side 声场 → 与输入 B 混音',remix:'阶段 1：A 分离为两路；阶段 2：估计人声 → EQ → 声场，与残余伴奏重混'};
function log(message,progress=false) {
  const lines=$('#log').textContent.split('\n');
  if(progress && lines[lines.length-1].includes('分离进度')) lines.pop();
  lines.push(new Date().toLocaleTimeString('zh-CN')+'  '+message);$('#log').textContent=lines.join('\n');
  $('#log').scrollTop=$('#log').scrollHeight;
  if(progress) $('#status').textContent=message;
}
function waveform(buffer,canvas,color='#147af0') {
  const ctx=canvas.getContext('2d'),data=buffer.getChannelData(0),w=canvas.width,h=canvas.height;
  ctx.clearRect(0,0,w,h);ctx.strokeStyle=color;ctx.beginPath();
  for(let x=0;x<w;x++) {
    let peak=0;for(let i=Math.floor(x*data.length/w);i<Math.floor((x+1)*data.length/w);i++)peak=Math.max(peak,Math.abs(data[i]));
    const y=Math.min(1,peak)*h*.45;ctx.moveTo(x,h/2-y);ctx.lineTo(x,h/2+y);
  }
  ctx.stroke();
}
function stopAudio() { document.querySelectorAll('audio').forEach(audio=>audio.pause()); }
function invalidate() {
  stopAudio();state.resultUrls.forEach(URL.revokeObjectURL);state.resultUrls=[];state.results=[];
  $('#results').innerHTML='<p class="empty">输入或参数已更新。请重新运行算法。</p>';
  $('#status').textContent='等待运行';window.lastRun=null;$('#log').textContent='当前输入和参数尚未运行。结果将由本次算法生成。';
}
const taskInfo={
 eq:{kicker:'01 / EQUALIZER',title:'塑造音色，保留完整声音',description:'用十个频段控制低频的厚度、中频的存在感与高频的明亮度。选择预设，重新渲染，再与原音对比。',settings:'均衡器预设',diagram:'basic',caption:'基础离线编辑示意图',effect:'均衡器调整不同频段的增益，不改变输出路数。',output:'单路输出完整音频，保存为新的 WAV。',notice:'本页实际运行 10 段 Web Audio 滤波。原声直通、人声清晰、低频温暖均从当前输入重新计算。',difference:'本页与原图保持输入、EQ、输出的处理结构；浏览器滤波器实现与 AudioSuite 内部算法不同。'},
 separate:{kicker:'02 / SOURCE SEPARATION',title:'将一段声音，拆成两路结果',description:'观察一进两出的处理过程：一份输入经过分离节点，得到可分别试听、导出的两路声音。',settings:'分离任务',diagram:'separation',caption:'音源分离编辑示意图',effect:'原生分离节点生成两路数据：人声和背景声。',output:'MultiRenderFrame 同时接收两块缓存，分别保存。',notice:'网页运行中置频谱分离，不是 AI 人声识别。中置乐器可能进入估计人声，偏置人声可能留在伴奏，单声道不适用。真正的 AudioSuite 分离在鸿蒙工程中运行。',difference:'原图描述华为 AudioSuite。网页只演示同样的一进两出任务结构，分离算法使用 dsp.js 中可阅读的 STFT 软掩码。'},
 mix:{kicker:'03 / AUDIO MIXING',title:'两份素材，混成一个作品',description:'给素材 A 和 B 分配不同的音量，再合并为一份音频。两路从起点对齐，短素材结束后补零。',settings:'两路混音控制',diagram:'cascade',caption:'混音与级联示意图',effect:'本任务直接将两路输入汇入混音节点。',output:'输出混合后的单路立体声音频。',notice:'请导入素材 B，或现场生成节奏素材。网页按 sample = A × gainA + B × gainB 逐样本计算，建议为混音保留峰值余量。',difference:'官网原图同时包含声场节点。本页仅演示其中的双输入混音：不经过声场；完整效果串联请切换到「节点级联」。'},
 cascade:{kicker:'04 / CASCADED PROCESSING',title:'把多个处理步骤，连成一条管线',description:'素材 A 依次经过 EQ 与声场处理，再与素材 B 汇合。前一个节点的输出，就是后一个节点的输入。',settings:'级联参数',diagram:'cascade',caption:'级联编辑示意图',effect:'原生 A 先经 EQ 和前置声场，再进入混音节点。',output:'处理后的 A 与 B 汇合，得到最终 WAV。',notice:'网页声场使用 Mid/Side 宽度调节，鸿蒙版调用 AudioSuite 前置声场。两者结构对应，但算法和听感并不等同。',difference:'本 Demo 在官网原图的声场前增加一个 EQ 节点。级联顺序为：A → EQ → 声场 → 混音；B 直接连接混音节点。'},
 remix:{kicker:'05 / SEPARATE & REMIX',title:'先拆开，再决定如何重新组合',description:'第一阶段生成两路分离结果。第二阶段调整估计人声音色和两路音量，再重新混合，保留三个可试听输出。',settings:'重混与人声音色',diagram:'separation',caption:'音源分离编辑示意图 · 第一阶段',effect:'第一阶段分离；第二阶段建立新的 EQ、声场和混音管线。',output:'返回分离人声、背景声和最终重混三个文件。',notice:'本页自动将分离结果作为第二阶段输入，不需要素材 B。网页分离依赖中置声像假设；原生版使用 AudioSuite 分离结果重新组网。',difference:'官网分离节点只能连接输出节点，因此分离后重混分成两个阶段。先完成原图的双输出，再读取两份结果，建立新的混音管线。'}
};
function drawEqualizer() {
 const presets=[[0,0,0,0,0,0,0,0,0,0],[-8,-6,-4,-2,0,2,2,0,-2,-4],[5,4,3,1,0,-1,-2,-2,-3,-4]],frequencies=['31','62','125','250','500','1k','2k','4k','8k','16k'];
 const selected=Number($('#preset').value),values=presets[selected],canvas=$('#eqCurve'),ctx=canvas.getContext('2d');
 ctx.clearRect(0,0,1000,260);ctx.font='18px sans-serif';ctx.textAlign='center';
 for(const db of [-8,0,8]) {const y=120-db*9;ctx.strokeStyle=db===0?'#b6c9de':'#e3ebf3';ctx.beginPath();ctx.moveTo(45,y);ctx.lineTo(970,y);ctx.stroke();}
 const points=values.map((v,i)=>[65+i*96,120-v*9]);
 ctx.beginPath();ctx.moveTo(points[0][0],210);points.forEach(p=>ctx.lineTo(...p));ctx.lineTo(points[9][0],210);ctx.closePath();
 const gradient=ctx.createLinearGradient(0,30,0,210);gradient.addColorStop(0,'#8064a245');gradient.addColorStop(1,'#8064a204');ctx.fillStyle=gradient;ctx.fill();
 ctx.strokeStyle='#8064a2';ctx.lineWidth=3;ctx.beginPath();points.forEach((p,i)=>i?ctx.lineTo(...p):ctx.moveTo(...p));ctx.stroke();
 points.forEach(([x,y],i)=>{ctx.fillStyle='#fff';ctx.strokeStyle='#8064a2';ctx.beginPath();ctx.arc(x,y,5,0,Math.PI*2);ctx.fill();ctx.stroke();ctx.fillStyle='#2F5597';ctx.fillText((values[i]>0?'+':'')+values[i],x,y-15);ctx.fillStyle='#72849a';ctx.fillText(frequencies[i],x,246);});
 document.querySelectorAll('[data-preset]').forEach(b=>b.setAttribute('aria-pressed',String(Number(b.dataset.preset)===selected)));
 $('#eq-values').textContent='频率从 31 Hz 到 16 kHz。当前增益：'+values.map(v=>(v>0?'+':'')+v).join(' / ')+' dB';
}
function configure() {
 const info=taskInfo[state.mode];
 $('#eqSettings').hidden=!['eq','cascade','remix'].includes(state.mode);
 $('#mixSettings').hidden=!['mix','cascade','remix'].includes(state.mode);
 $('#separationSettings').hidden=state.mode!=='separate';
 $('#sourceBSection').hidden=!['mix','cascade'].includes(state.mode);
 $('#gainALabel').textContent=state.mode==='remix'?'估计人声增益':'素材 A 增益';
 $('#gainBLabel').textContent=state.mode==='remix'?'残余伴奏增益':'素材 B 增益';
 $('#valueA').textContent=Number($('#gainA').value).toFixed(2);$('#valueB').textContent=Number($('#gainB').value).toFixed(2);
 $('#chain').textContent=chains[state.mode];
 const tabNames=['eq','separate','mix','cascade','remix'];
 $('.task-nav').style.setProperty('--tab-index',tabNames.indexOf(state.mode));
 document.querySelectorAll('[data-mode]').forEach(b=>{const selected=b.dataset.mode===state.mode;b.setAttribute('aria-selected',String(selected));b.setAttribute('aria-pressed',String(selected));b.tabIndex=selected?0:-1;});
 $('#task-page').setAttribute('aria-labelledby','tab-'+state.mode);
 $('#task-kicker').textContent=info.kicker;$('#task-title').textContent=info.title;$('#task-description').textContent=info.description;$('#settings-title').textContent=info.settings;
 $('#official-diagram').src='assets/huawei-'+info.diagram+'.png';$('#official-diagram').alt='华为官网 '+info.caption;
 $('#diagram-download').href=$('#official-diagram').src;$('#diagram-caption').textContent='华为官网 · '+info.caption;
 $('#node-effect-description').textContent=info.effect;$('#node-output-description').textContent=info.output;
 $('#task-notice').textContent=info.notice;$('#diagram-difference').textContent=info.difference;
 drawEqualizer();
}
function changeTask(mode) {
 if(state.busy || !taskInfo[mode])return;
 state.mode=mode;invalidate();configure();if(location.hash!=='#'+mode)history.replaceState(null,'','#'+mode);
}
function setInput(key,buffer,label) {
  invalidate();state[key]=buffer;const id=key.toUpperCase();
  if(state.inputUrls[key]) URL.revokeObjectURL(state.inputUrls[key]);
  state.inputUrls[key]=URL.createObjectURL(AudioLab.wav(buffer));$('#audio'+id).src=state.inputUrls[key];
  const stats=AudioLab.stats(buffer);
  $('#meta'+id).textContent=label+' · '+buffer.duration.toFixed(2)+' 秒 · 48kHz / 2ch · PCM 指纹 '+stats.fingerprint;
  if(key==='a') waveform(buffer,$('#waveA'));
}
async function importAudio(key,file) {
  if(!file || state.busy)return;state.busy=true;$('#controls').disabled=true;let context;
  try {
    if(file.size>50*1024*1024)throw Error('文件超过 50 MB');
    context=new AudioContext({sampleRate:48000});const decoded=await context.decodeAudioData(await file.arrayBuffer());
    if(decoded.duration>120)throw Error('音频超过 120 秒');
    const offline=new OfflineAudioContext(2,decoded.length,48000),source=offline.createBufferSource();
    source.buffer=decoded;source.connect(offline.destination);source.start();
    const buffer=await offline.startRendering();setInput(key,buffer,file.name);
    log('用户导入素材 '+key.toUpperCase()+'，在本机解码'+(decoded.numberOfChannels===1?'；单声道不适合中置分离':''));
  } catch(error) {$('#status').textContent='导入失败：'+error.message;}
  finally {if(context)await context.close();state.busy=false;$('#controls').disabled=false;}
}
function generateRhythm() {
  // 输入素材合成，不是预生成效果结果；每次使用固定种子以便复现实验。
  const buffer=AudioLab.makeBuffer(Math.min(state.a.length,48000*30));let seed=12345;
  const l=buffer.getChannelData(0),r=buffer.getChannelData(1);
  for(let i=0;i<buffer.length;i++) {
    const t=i/48000,beat=t%0.5,kick=0.24*Math.sin(2*Math.PI*(55*beat+9*(1-Math.exp(-beat*35))))*Math.exp(-beat*22);
    seed=(Math.imul(seed,1664525)+1013904223)>>>0;
    const hat=(seed/4294967296*2-1)*0.06*Math.exp(-(t%0.25)*95);
    const bass=0.05*Math.sin(2*Math.PI*(Math.floor(t/2)%2?110:82.4069)*t);
    l[i]=kick+bass+hat;r[i]=kick+bass-hat;
  }
  setInput('b',buffer,'现场算法合成节奏');log('已用振荡器公式与伪随机噪声生成输入 B');
}
async function runTask() {
  if(state.busy)return;
  invalidate();state.busy=true;document.querySelectorAll('[data-mode]').forEach(b=>b.disabled=true);$('#controls').disabled=true;$('#status').textContent='正在运行算法…';
  const id='run-'+Date.now()+'-'+(++state.sequence),start=performance.now();
  $('#log').textContent='任务 '+id+'\n引擎：浏览器 DSP / Web Audio；不读取历史效果 WAV。';
  try {
    const inputStats=AudioLab.stats(state.a);log('输入 A PCM 指纹 '+inputStats.fingerprint);
    if(['mix','cascade'].includes(state.mode)&&state.b)log('输入 B PCM 指纹 '+AudioLab.stats(state.b).fingerprint);
    const options={a:state.a,b:state.b,mode:state.mode,preset:Number($('#preset').value),gainA:Number($('#gainA').value),gainB:Number($('#gainB').value)};
    log('参数 '+JSON.stringify({mode:options.mode,preset:options.preset,gainA:options.gainA,gainB:options.gainB}));
    // 唯一处理入口，await 等待本次算法实际完成。
    const results=await AudioLab.run(options,log);state.results=results;
    $('#results').replaceChildren();const reports=[];
    for(const result of results) {
      const stats=AudioLab.stats(result.buffer),blob=AudioLab.wav(result.buffer),url=URL.createObjectURL(blob);
      state.resultUrls.push(url);const card=document.createElement('article');card.className='output';
      const title=document.createElement('h3');title.textContent=result.name;
      const canvas=document.createElement('canvas');canvas.width=1200;canvas.height=100;canvas.setAttribute('aria-label',result.name+' 波形');
      waveform(result.buffer,canvas,'#0e8f86');const audio=document.createElement('audio');audio.controls=true;audio.src=url;
      const meta=document.createElement('div');meta.className='meta';const description=document.createElement('span');
      description.textContent=result.buffer.duration.toFixed(2)+' 秒 · PCM 指纹 '+stats.fingerprint+' · 峰值 '+stats.peak.toFixed(3);
      const download=document.createElement('a');download.href=url;download.download=id+'-'+result.name+'.wav';download.textContent='导出本次 WAV ↓';
      meta.append(description,download);card.append(title,canvas,audio,meta);
      if(stats.clipped) {const warning=document.createElement('p');warning.className='hint warning';warning.textContent='检测到 '+stats.clipped+' 个超限采样，WAV 编码时会削波。请降低增益再运行。';card.append(warning);}
      $('#results').append(card);log('生成 '+result.name+'：'+blob.size+' bytes，PCM 指纹 '+stats.fingerprint);
      reports.push({name:result.name,...stats,frames:result.buffer.length,bytes:blob.size});
    }
    const elapsed=performance.now()-start;
    window.lastRun={id,inputFingerprint:inputStats.fingerprint,mode:state.mode,elapsed,outputs:reports};
    $('#status').textContent='本次计算完成 · '+elapsed.toFixed(0)+' ms · '+results.length+' 个输出';
    log('完成。试听地址均为本次输出的 blob: URL。指纹用于对比数据，不是密码学签名。');
  } catch(error) {$('#status').textContent='处理失败：'+error.message;log('失败：'+error.message);}
  finally {state.busy=false;$('#controls').disabled=false;document.querySelectorAll('[data-mode]').forEach(b=>b.disabled=false);}
}
function main() {
  const raw=atob(globalThis.SOURCE_PCM_BASE64),buffer=AudioLab.makeBuffer(raw.length/4);
  const bytes=Uint8Array.from(raw,c=>c.charCodeAt(0)),view=new DataView(bytes.buffer);
  for(let i=0;i<buffer.length;i++)for(let ch=0;ch<2;ch++)buffer.getChannelData(ch)[i]=view.getInt16((i*2+ch)*2,true)/32768;
  setInput('a',buffer,'内置官方原始 PCM');delete globalThis.SOURCE_PCM_BASE64;
  document.querySelectorAll('[data-mode]').forEach(button=>{
    button.onclick=()=>changeTask(button.dataset.mode);
    button.onkeydown=event=>{if(!['ArrowLeft','ArrowRight','Home','End'].includes(event.key)||state.busy)return;event.preventDefault();const modes=Object.keys(taskInfo),i=modes.indexOf(state.mode);const next=event.key==='Home'?0:event.key==='End'?4:(i+(event.key==='ArrowRight'?1:4))%5;changeTask(modes[next]);$('#tab-'+modes[next]).focus();};
  });
  document.querySelectorAll('[data-preset]').forEach(button=>button.onclick=()=>{if(state.busy)return;$('#preset').value=button.dataset.preset;invalidate();configure();});
  window.addEventListener('hashchange',()=>changeTask(location.hash.slice(1)));
  if(taskInfo[location.hash.slice(1)])state.mode=location.hash.slice(1);
  ['preset','gainA','gainB'].forEach(id=>$('#'+id).oninput=()=>{invalidate();configure();});
  $('#inputA').onchange=event=>importAudio('a',event.target.files[0]);$('#inputB').onchange=event=>importAudio('b',event.target.files[0]);
  $('#generateB').onclick=generateRhythm;$('#run').onclick=runTask;
  document.addEventListener('play',event=>{if(event.target.tagName==='AUDIO')document.querySelectorAll('audio').forEach(a=>{if(a!==event.target)a.pause();});},true);
  configure();
}
main();
