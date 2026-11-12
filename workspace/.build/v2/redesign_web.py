from pathlib import Path
p=Path('output/Demo演示/index.html');s=p.read_text()
a=s.index('<section class="hero">');b=s.index('<fieldset id="controls">',a)
s=s[:a]+'''<section class="hero"><div><p class="eyebrow">AUDIO PROCESSING / LOCAL WORKSPACE</p><h1>离线音频编辑实验室</h1><p>从一段声音开始，理解每个节点如何改变它。</p></div><div class="hero-note"><span class="status-dot"></span> 本地算法运行<span>原始输入 · 可见管线 · 本次输出</span></div></section>
<nav class="task-nav" role="tablist" aria-label="音频编辑任务">
<button id="tab-eq" role="tab" data-mode="eq" aria-controls="task-page" aria-selected="true"><span>01</span>均衡器</button>
<button id="tab-separate" role="tab" data-mode="separate" aria-controls="task-page" aria-selected="false"><span>02</span>音源分离</button>
<button id="tab-mix" role="tab" data-mode="mix" aria-controls="task-page" aria-selected="false"><span>03</span>双素材混音</button>
<button id="tab-cascade" role="tab" data-mode="cascade" aria-controls="task-page" aria-selected="false"><span>04</span>节点级联</button>
<button id="tab-remix" role="tab" data-mode="remix" aria-controls="task-page" aria-selected="false"><span>05</span>分离后重混</button>
<span class="tab-cursor" aria-hidden="true"></span></nav>
<section id="task-page" role="tabpanel" aria-labelledby="tab-eq"><section class="task-intro"><div><p id="task-kicker" class="eyebrow">01 / EQUALIZER</p><h2 id="task-title">塑造音色，保留完整声音</h2><p id="task-description"></p></div><div class="engine-tag">当前执行引擎<strong>Browser DSP / Web Audio</strong><span>鸿蒙版使用 AudioSuite，算法与性能分别验证</span></div></section>
<section class="pipeline-guide"><div class="guide-heading"><h3>先看懂这条管线</h3><span id="diagram-caption">华为官网 · 基础离线编辑示意图</span></div><figure><div class="diagram-scroll"><img id="official-diagram" src="assets/huawei-basic.png" alt="华为基础离线编辑：PCM 经输入节点、均衡器节点、输出节点得到处理后的 PCM"></div><figcaption><span>官网原图，保留原始节点与连线。</span><a id="diagram-download" href="assets/huawei-basic.png" download>下载原图 ↓</a><a href="https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/audio-suite-manual-rendering" target="_blank" rel="noreferrer">查看官方说明 ↗</a></figcaption></figure><div class="node-explanation"><div><span>01</span><p><b>输入节点</b><br>按需读取音频样本，把声音送入处理流程。</p></div><div><span>02</span><p><b id="node-effect-title">处理节点</b><br><span id="node-effect-description">均衡器调整各频段的增益。</span></p></div><div><span>03</span><p><b>输出节点</b><br><span id="node-output-description">收集处理结果，应用将它编码为 WAV。</span></p></div></div><details class="pipeline-details"><summary>什么叫管线？什么叫离线渲染？</summary><p>管线是由节点和连接关系组成的一次音频处理流程。节点各自执行读取、音效或输出等工作，箭头表示数据的流向。分叉可以产生多路结果，多路输入也可以在混音节点汇合。</p><p>离线渲染会主动请求并计算音频数据，不需要边播放边处理。鸿蒙端调用 RenderFrame 或 MultiRenderFrame 拉取结果；网页会完成 DSP 运算后才开放结果试听。图中的 PCM 是音频采样数据，WAV 是保存这些数据的文件容器。</p><p id="diagram-difference"></p></details></section>
<div id="task-notice" class="notice"></div>
''' + s[b:]
s=s.replace('<div class="divider"></div><label class="file">素材 B','<div id="sourceBSection"><div class="divider"></div><label class="file">素材 B')
s=s.replace('<p class="hint">内置 A 是原始素材','</div><p class="hint">内置 A 是原始素材')
a=s.index('<div class="section-title"><span>02 / PROCESS</span>');b=s.index('<div id="mixSettings"',a)
s=s[:a]+'''<div class="section-title"><span>02 / PROCESS</span><h2 id="settings-title">均衡器预设</h2></div>
<div id="eqSettings"><p class="control-intro">选一个音色起点，查看每个频段的实际增益。</p><div class="preset-cards" role="group" aria-label="均衡器预设"><button data-preset="0" aria-pressed="false"><span class="preset-icon">≈</span><b>原声直通</b><small>保持原始频率响应</small></button><button data-preset="1" aria-pressed="true"><span class="preset-icon">≋</span><b>人声清晰</b><small>压低低频，突出中高频</small></button><button data-preset="2" aria-pressed="false"><span class="preset-icon">∿</span><b>低频温暖</b><small>增强低频，柔化高频</small></button></div><select id="preset" hidden aria-label="EQ 预设"><option value="0">原声直通</option><option value="1" selected>人声清晰</option><option value="2">低频温暖</option></select><div class="eq-heading"><span>10 BAND EQUALIZER</span><span>增益 / dB</span></div><canvas id="eqCurve" width="1000" height="260" aria-label="十段均衡器增益图"></canvas><p id="eq-values" class="hint"></p><p class="hint">“人声清晰”调节整段音频的音色，不会单独提取人声。提取任务请切换到「音源分离」。</p></div>
<div id="separationSettings" hidden><div class="stem-preview"><span>输入音频</span><b>STFT 中置软掩码</b><div><span>估计人声</span><span>残余伴奏</span></div></div><p class="control-intro">分析左右声道的相似频谱，将中置成分估计为人声，再从原始信号中减去这部分，得到残余伴奏。</p><p class="hint">这是一种可阅读源码的 DSP 教学算法。它不能区分居中的人声和乐器，不适合单声道素材。</p></div>
''' +s[b:]
s=s.replace('<section class="learning">','</section><section class="learning">')
p.write_text(s)
p=Path('output/Demo演示/app.js');s=p.read_text();a=s.index('function configure()');b=s.index('function setInput(',a)
s=s[:a]+'''const taskInfo={
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
''' + s[b:]
s=s.replace("  document.querySelectorAll('[data-mode]').forEach(button=>button.onclick=()=>{state.mode=button.dataset.mode;invalidate();configure();});", """  document.querySelectorAll('[data-mode]').forEach(button=>{
    button.onclick=()=>changeTask(button.dataset.mode);
    button.onkeydown=event=>{if(!['ArrowLeft','ArrowRight','Home','End'].includes(event.key)||state.busy)return;event.preventDefault();const modes=Object.keys(taskInfo),i=modes.indexOf(state.mode);const next=event.key==='Home'?0:event.key==='End'?4:(i+(event.key==='ArrowRight'?1:4))%5;changeTask(modes[next]);$('#tab-'+modes[next]).focus();};
  });
  document.querySelectorAll('[data-preset]').forEach(button=>button.onclick=()=>{if(state.busy)return;$('#preset').value=button.dataset.preset;invalidate();configure();});
  window.addEventListener('hashchange',()=>changeTask(location.hash.slice(1)));
  if(taskInfo[location.hash.slice(1)])state.mode=location.hash.slice(1);""")
s=s.replace("if(state.busy)return;\n  invalidate();state.busy=true;", "if(state.busy)return;\n  invalidate();state.busy=true;document.querySelectorAll('[data-mode]').forEach(b=>b.disabled=true);")
s=s.replace("finally {state.busy=false;$('#controls').disabled=false;}\n}", "finally {state.busy=false;$('#controls').disabled=false;document.querySelectorAll('[data-mode]').forEach(b=>b.disabled=false);}\n}")
p.write_text(s)
