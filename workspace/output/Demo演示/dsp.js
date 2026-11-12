/* SPDX-License-Identifier: Apache-2.0
 * 可独立学习的浏览器算法层。没有读取预生成处理结果的路径。
 * 音源分离 = STFT 中置声像软掩码；这是有局限的 DSP 估计，不是华为 AI 模型。
 */
(function (global) {
  'use strict';
  const RATE = 48000;
  const frequencies = [31,62,125,250,500,1000,2000,4000,8000,16000];
  const presets = [[0,0,0,0,0,0,0,0,0,0],[-8,-6,-4,-2,0,2,2,0,-2,-4],[5,4,3,1,0,-1,-2,-2,-3,-4]];
  const makeBuffer = length => new AudioBuffer({length, numberOfChannels:2, sampleRate:RATE});
  const pause = () => new Promise(resolve => setTimeout(resolve, 0));

  // 原地 radix-2 FFT。逆变换除以 N；只在分离算法使用。
  function fft(real, imag, inverse=false) {
    const n=real.length;
    for (let i=1,j=0;i<n;i++) {
      let bit=n>>1;
      for (;j&bit;bit>>=1) j^=bit;
      j^=bit;
      if (i<j) { [real[i],real[j]]=[real[j],real[i]]; [imag[i],imag[j]]=[imag[j],imag[i]]; }
    }
    for (let size=2;size<=n;size*=2) {
      const angle=(inverse?2:-2)*Math.PI/size, wr=Math.cos(angle), wi=Math.sin(angle);
      for (let start=0;start<n;start+=size) {
        let ur=1,ui=0;
        for(let k=0;k<size/2;k++) {
          const a=start+k,b=a+size/2,tr=ur*real[b]-ui*imag[b],ti=ur*imag[b]+ui*real[b];
          real[b]=real[a]-tr;imag[b]=imag[a]-ti;real[a]+=tr;imag[a]+=ti;
          const next=ur*wr-ui*wi;ui=ur*wi+ui*wr;ur=next;
        }
      }
    }
    if(inverse) for(let i=0;i<n;i++) { real[i]/=n;imag[i]/=n; }
  }

  // 将左右声道中相位和幅度相近的频率成分视为“中置候选”。
  // 人声通常居中，但鼓、贝斯也可能居中；单声道无法据此识别人声。
  async function separate(source, progress=()=>{}) {
    const n=2048, hop=512, length=source.length;
    const left=source.getChannelData(0),right=source.getChannelData(1);
    const vocal=makeBuffer(length),background=makeBuffer(length);
    const vr=vocal.getChannelData(0), vl=vocal.getChannelData(1),weights=new Float32Array(length);
    const window=Float64Array.from({length:n},(_,i)=>0.5-0.5*Math.cos(2*Math.PI*i/n));
    const lr=new Float64Array(n),li=new Float64Array(n),rr=new Float64Array(n),ri=new Float64Array(n);
    let frame=0;
    // 从负偏移开始使首尾都经过完整 overlap-add 权重归一化。
    for(let offset=-n+hop;offset<length;offset+=hop) {
      li.fill(0);ri.fill(0);
      for(let i=0;i<n;i++) {const p=offset+i; lr[i]=(left[p]||0)*window[i];rr[i]=(right[p]||0)*window[i];}
      fft(lr,li);fft(rr,ri);
      for(let k=0;k<n;k++) {
        const power=lr[k]*lr[k]+li[k]*li[k]+rr[k]*rr[k]+ri[k]*ri[k];
        const difference=(lr[k]-rr[k])**2+(li[k]-ri[k])**2;
        const similarity=Math.max(0,Math.min(1,1-difference/(power+1e-20)));
        const frequency=Math.min(k,n-k)*RATE/n;
        const band=Math.min(1,frequency/150)*Math.max(0,Math.min(1,(12000-frequency)/3000));
        const mask=similarity*similarity*band;
        lr[k]=(lr[k]+rr[k])*0.5*mask;li[k]=(li[k]+ri[k])*0.5*mask;
      }
      fft(lr,li,true);
      for(let i=0;i<n;i++) {const p=offset+i;if(p>=0 && p<length) {vr[p]+=lr[i]*window[i];weights[p]+=window[i]*window[i];}}
      if(++frame%48===0) {progress(Math.min(1,(offset+n)/length));await pause();}
    }
    const bl=background.getChannelData(0),br=background.getChannelData(1);
    for(let i=0;i<length;i++) {
      vr[i]/=Math.max(weights[i],1e-12);vl[i]=vr[i];bl[i]=left[i]-vr[i];br[i]=right[i]-vr[i];
    }
    progress(1);return {vocal,background};
  }

  // 10 个 peaking filter 串联；OfflineAudioContext 完成整段算法计算后才返回。
  async function equalize(source,preset) {
    const context=new OfflineAudioContext(2,source.length,RATE);
    const input=context.createBufferSource();input.buffer=source;let tail=input;
    frequencies.forEach((frequency,i)=>{
      const node=context.createBiquadFilter();node.type='peaking';node.frequency.value=frequency;
      node.Q.value=1.4;node.gain.value=presets[preset][i];tail.connect(node);tail=node;
    });
    tail.connect(context.destination);input.start();return context.startRendering();
  }
  // 浏览器声场教学实现：Mid/Side 宽度调整，不等同于 AudioSuite 前置声场。
  function soundField(source,width=0.65) {
    const out=makeBuffer(source.length),l=source.getChannelData(0),r=source.getChannelData(1);
    const ol=out.getChannelData(0),or=out.getChannelData(1);
    for(let i=0;i<source.length;i++) {const mid=(l[i]+r[i])/2,side=(l[i]-r[i])/2*width;ol[i]=mid+side;or[i]=mid-side;}
    return out;
  }
  // 双素材从 t=0 对齐，短素材结束后补零。增益作用于各输入。
  function mix(a,b,gainA,gainB) {
    const out=makeBuffer(Math.max(a.length,b.length));
    for(let ch=0;ch<2;ch++) {
      const x=a.getChannelData(ch),y=b.getChannelData(ch),z=out.getChannelData(ch);
      for(let i=0;i<z.length;i++) z[i]=(x[i]||0)*gainA+(y[i]||0)*gainB;
    }
    return out;
  }
  async function run({a,b,mode,preset,gainA,gainB},log=()=>{}) {
    if(!a || !['eq','separate','mix','cascade','remix'].includes(mode)) throw Error('任务或输入无效');
    if(!Number.isInteger(preset)||preset<0||preset>2) throw Error('EQ 预设无效');
    if(![gainA,gainB].every(x=>Number.isFinite(x)&&x>=0&&x<=1)) throw Error('增益必须在 0–1 之间');
    if((mode==='mix'||mode==='cascade')&&!b) throw Error('请先导入素材 B');
    if(a.duration>120 || (b && b.duration>120)) throw Error('输入不能超过 120 秒');
    if(mode==='eq') {log('输入 A → 10 段 EQ → 输出');return [{name:'EQ 处理结果',buffer:await equalize(a,preset)}];}
    if(mode==='mix') {log('输入 A × 增益 + 输入 B × 增益 → 输出');return [{name:'双素材混音',buffer:mix(a,b,gainA,gainB)}];}
    if(mode==='cascade') {
      log('第 1 级：输入 A → EQ');const eq=await equalize(a,preset);
      log('第 2 级：EQ → Mid/Side 声场');const field=soundField(eq);
      log('第 3 级：声场结果 + 输入 B → 混音');return [{name:'级联混音结果',buffer:mix(field,b,gainA,gainB)}];
    }
    log('第 1 阶段：STFT → 中置频谱掩码 → 两路逆变换');
    const stems=await separate(a,p=>log('分离进度 '+Math.round(p*100)+'%',true));
    const results=[{name:'估计人声（中置成分）',buffer:stems.vocal},{name:'残余伴奏',buffer:stems.background}];
    if(mode==='remix') {
      log('第 2 阶段：估计人声 → EQ → 声场，与残余伴奏重混');
      results.push({name:'分离后重新混音',buffer:mix(soundField(await equalize(stems.vocal,preset)),stems.background,gainA,gainB)});
    }
    return results;
  }
  // WAV 编码只在运算完成后进行；没有任何读取“人声清晰.wav”的代码。
  function wav(buffer) {
    const length=buffer.length,bytes=new ArrayBuffer(44+length*4),view=new DataView(bytes);
    const text=(offset,s)=>{for(let i=0;i<s.length;i++)view.setUint8(offset+i,s.charCodeAt(i));};
    text(0,'RIFF');view.setUint32(4,36+length*4,true);text(8,'WAVEfmt ');view.setUint32(16,16,true);
    view.setUint16(20,1,true);view.setUint16(22,2,true);view.setUint32(24,RATE,true);view.setUint32(28,RATE*4,true);
    view.setUint16(32,4,true);view.setUint16(34,16,true);text(36,'data');view.setUint32(40,length*4,true);
    for(let i=0;i<length;i++) for(let ch=0;ch<2;ch++) {
      const x=Math.max(-1,Math.min(1,buffer.getChannelData(ch)[i]));
      view.setInt16(44+(i*2+ch)*2,Math.round(x*(x<0?32768:32767)),true);
    }
    return new Blob([bytes],{type:'audio/wav'});
  }
  function stats(buffer) {
    let peak=0,clipped=0,hash=2166136261;
    for(let ch=0;ch<2;ch++) for(const value of buffer.getChannelData(ch)) {
      peak=Math.max(peak,Math.abs(value));if(Math.abs(value)>1)clipped++;
      hash=Math.imul(hash^Math.round(value*32768),16777619);
    }
    return {peak,clipped,fingerprint:(hash>>>0).toString(16).padStart(8,'0')};
  }
  global.AudioLab={RATE,makeBuffer,fft,separate,equalize,soundField,mix,run,wav,stats};
})(globalThis);
