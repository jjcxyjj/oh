from pathlib import Path
from docx import Document
from docx.shared import Inches,Pt,RGBColor
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
import shutil
r=Path(__file__).resolve().parents[2];dest=r/'output/文档/AudioSuite_离线编辑技术方案.docx'
if not (r/'.build/v2/技术方案-v1.docx').exists():shutil.copy2(dest,r/'.build/v2/技术方案-v1.docx')
d=Document();sec=d.sections[0];sec.page_width=Inches(8.5);sec.page_height=Inches(11);sec.top_margin=sec.bottom_margin=Inches(.75);sec.left_margin=sec.right_margin=Inches(.8)
for name in ['Normal','Title','Heading 1','Heading 2']:
 s=d.styles[name];s.font.name='Microsoft YaHei';s.font.size=Pt(11 if name=='Normal' else 23 if name=='Title' else 16 if name=='Heading 1' else 13);s.font.color.rgb=RGBColor.from_string('000000');s._element.get_or_add_rPr();fonts=s._element.rPr.rFonts;fonts.set(qn('w:eastAsia'),'Microsoft YaHei')
 for key in list(fonts.attrib):
  if 'Theme' in key:del fonts.attrib[key]
for s in d.styles:
 for b in list(s.element.iter(qn('w:pBdr'))):b.getparent().remove(b)
d.styles['Normal'].paragraph_format.line_spacing=Pt(16);d.styles['Normal'].paragraph_format.space_after=Pt(7)
footer=sec.footer.paragraphs[0];footer.alignment=2;footer.add_run('AudioSuite v2    2026 年 11 月 12 日    ');f=OxmlElement('w:fldSimple');f.set(qn('w:instr'),'PAGE');footer._p.append(f)
md=[]
def title(t):d.add_paragraph(t,'Title');md.append('# '+t+'\n')
next_page=False
def h(t):
 global next_page
 para=d.add_heading(t,1);para.paragraph_format.space_before=Pt(12);para.paragraph_format.space_after=Pt(8)
 if next_page:para.paragraph_format.page_break_before=True;next_page=False
 md.append('\n## '+t+'\n')
def p(t):d.add_paragraph(t);md.append(t+'\n')
def page():
 global next_page
 next_page=True
title('AudioSuite 离线音频编辑技术方案')
p('本方案对应 workspace 中的 v2 工程，面向需要学习入口逻辑、节点组网与音频处理流程的开发者。新版包含均衡器、音源分离、双素材混音、多节点级联和分离后重混。原生工程使用 AudioSuite，电脑网页使用可阅读的 Web Audio 与传统 DSP 算法。')
p('当前原生工程在 HarmonyOS API 24 下编译通过，尚未完成真机运行验收。网页五种任务已经实际运行测试。网页分离属于中置频谱估计，不是华为的人声分离模型，不能用其音质或耗时代替原生结果。')
h('交付与使用')
p('所有文件位于桌面 oh/workspace。打开 output/Demo演示/index.html 可进入交互实验室；页面标题下有五个任务页签，均衡器页保留三种预设和十段增益图。每页配有对应的官网节点图、输入与参数控制、执行记录及结果试听。')
p('output/学习指南/代码导读.md 提供逐函数调用关系和建议阅读顺序。output/OfflineAudioDemo 是 DevEco Studio 工程。output/安装包 保存未签名 HAP。PPT 沿用参考六页版式，页头使用 #2F5597，分隔线使用 #8064A2。')
h('数据来自哪里')
p('source-data.js 只保存未经处理的官方 PCM 输入。点击网页运行按钮后，AudioLab.run 计算新的 AudioBuffer，再编码 WAV 并创建 blob 地址。结果播放器只使用这次输出。改变输入、任务或参数会清空旧结果。')
p('演示目录中原有三个预设 WAV、旧截图和旧录屏是 v1 的历史导出，新版算法不读取它们。原声试听本来就读取输入；处理结果试听必须等待计算完成。相同输入与参数得出相同指纹属于确定性算法的正常行为。')
h('输入与输出约定')
p('原生输入为 48kHz、双声道、PCM16 WAV 或内部裸 PCM，单个输入最长 120 秒。WAV 解析器扫描 fmt/data 块，跳过文件头并校验声道、采样率、位深与长度。网页可解码浏览器支持的音频，统一为 48kHz 双声道。输出均为 PCM16 WAV。')
page();h('入口与代码职责')
p('鸿蒙应用由系统启动 UIAbility，而不是用户编写 int main。EntryAbility.ets 的 onWindowStageCreate 调用 loadContent，加载 Index.ets。页面 aboutToAppear 准备素材，build 绘制界面，renderAudio 响应处理按钮。')
p('renderAudio 调用 engine.run(inputA, inputB, prefix, mode, preset, gainA, gainB)。offline_engine.cpp 通过 Register 和 Init 注册方法，Run 校验并创建 Promise，Execute 在后台线程调用 RunAudioJob，Complete 回传结果或错误。Index.d.ts 定义 RenderReport 的 paths、labels、elapsedMs。')
p('audio_pipeline.cpp 实现项目的任务编排。RunAudioJob 根据 mode 分派，Separate 创建分离管线，ProcessGraph 创建 EQ、混音或级联，Pipeline::Render 负责逐帧拉取。wav_io.h 实现输入格式校验、增益应用和 WAV 文件提交。')
p('系统 libohaudiosuite.so 内部实现 EQ、分离、声场和混音算法。项目源码展示公开 API 的调用和组网，不包含华为分离模型的训练实现或权重。网页 dsp.js 则提供可直接阅读的传统音频数学算法。')
h('管线和节点')
p('管线是一组节点与连接关系。输入节点按回调提供 PCM，效果节点处理数据，输出节点提供结果。箭头表示数据流向，多路输入可以汇合，多输出节点可以产生两份结果。官网三张原图保存在网页 assets 下，并附带来源清单。')
p('离线渲染通过输出端主动拉取数据，不需要边播放边处理。普通任务使用 RenderFrame，分离任务使用 MultiRenderFrame。每次请求 3840 字节，对应 48kHz × 2 声道 × 2 字节 × 20ms。20ms 是音频数据粒度，不是计算延迟。')
h('结果与异常处理')
p('每个原生任务使用独立时间戳前缀，先写 .part，完整渲染后回填 WAV 头并重命名。代码检查 API 返回值、实际输出长度、零进展与帧数上限；RAII 清理管线和文件。设备不支持节点时明确失败。Previewer 的 mock 同样拒绝运行，不伪造成功。')
p('UI 在处理期间锁定参数，原生任务用互斥锁串行执行。当前没有取消接口，退出页面不等于中止任务。输入增益不会自动防止 EQ 或混音产生削波，需要保留余量。')
page();h('五种原生任务')
p('均衡器任务：输入 A 连接 Equalizer，再连接输出。三种预设是直通、清晰、温暖，十个频率为 31、62、125、250、500、1000、2000、4000、8000、16000Hz。“人声清晰”是 EQ 参数名称，不等于提取人声。')
p('音源分离任务：输入连接 EFFECT_MULTII_OUTPUT_NODE_TYPE_AUDIO_SEPARATION，再连接输出。OH_AudioDataArray 提供两个同等长度的缓存，MultiRenderFrame 第 0 路为人声，第 1 路为背景声。本工程显式配置输出节点为 PCM16 双声道并分别写 WAV。')
p('双素材混音任务：两个独立输入节点连接同一个 Mixer。输入读取回调分别应用 gainA 与 gainB。输出是一份混合音频。网页采用两路采样加权求和，短音频结束后补零；原生设备的结束与时长行为需实际验收。')
p('节点级联任务：输入 A 依次经过 EQ、前置声场，再连接 Mixer。输入 B 直接连接 Mixer。多个处理步骤按顺序组成管线。此实现比官网级联图多一个前置 EQ 节点，网页页面明确标出差异。')
p('分离后重新混音：阶段一执行分离并完成两份 WAV；阶段二以新生成的人声、背景声为输入，对人声执行 EQ 和声场，再与背景重混。成功后返回分离两路和最终结果三个文件。')
h('两阶段的必要性')
p('SDK 说明音源分离节点只能连接输出节点，因此不能直接连接 EQ 或 Mixer。两阶段实现先完成第一条管线，再读取其输出建立第二条管线。任何阶段失败都会清理本次任务输出，页面不会把旧文件当成新结果。')
h('网页算法边界')
p('网页 equalize 使用 OfflineAudioContext 和十个 peaking BiquadFilter，Q 为 1.4。soundField 使用 Mid/Side 宽度调整，mix 逐样本计算两路增益和。它们用于学习与电脑交互演示，不声明与 AudioSuite 数值一致。')
p('网页 separate 使用 2048 点 Hann 窗、512 点步长、FFT 与左右相似度软掩码提取中置成分，再用原输入减去该成分得到残余伴奏。居中乐器会混入估计人声，偏置人声可能残留，单声道不适用。它不是神经网络人声识别。')
page();h('验证结果与复现')
p('浏览器测试实际运行五种任务，检查输入导入、结果数量、WAV 大小、任务切换后的结果失效，以及没有请求历史效果 WAV。50 秒素材对应每个输出 2400000 个采样帧和 9600044 字节 WAV。导入 1 秒测试音频后，EQ 输出相应变为 48000 帧。')
p('在双声道合成信号测试中，0dB EQ 最大误差约 2.1×10⁻¹³，分离两路重构最大误差约 3.7×10⁻⁹，混音公式最大误差约 6.9×10⁻⁹。这些测试验证数学与数据流，不代表真实音乐的人声分离质量。')
p('新版原生工程完成 ArkTS、C++ 和未签名 HAP 打包。当前 HDC 未发现设备，因此还未验证原生分离支持性、算法效果、输出时长、系统导出操作和性能。')
h('运行与验收步骤')
p('电脑：双击网页 index.html，保留同目录 JS、CSS 和 assets。选择任务，EQ 页选择预设；混音或级联页导入 B，也可点击算法生成节奏素材。点击运行后查看日志、试听并下载本次 WAV。')
p('鸿蒙：DevEco Studio 打开 OfflineAudioDemo，使用 HarmonyOS 6.1.1 API 24。运行根目录 build_demo.command 构建。配置自己的开发签名，连接设备并授权 USB 调试，确认 hdc 能发现设备后安装运行。')
p('真机验收应覆盖五任务、分离双输出顺序、不同长度混音、第二阶段文件衔接、连续执行、无支持节点与非法 WAV 的错误恢复。性能报告应记录设备型号、系统版本、音频格式、任务参数、处理耗时和内存峰值。')
h('学习路线与当前限制')
p('建议从页面 renderAudio 或 runTask 开始，随后阅读 N-API 桥接、ProcessGraph、Separate 与 Pipeline::Render，再阅读 WAV 读写。要学习数学算法，先读 dsp.js 的 mix，再读 equalize，最后读 fft 与 separate。完整源码导航见代码导读。')
p('当前不包含任意节点拖拽编排、任务取消、神经网络网页分离、原生通用压缩格式解码或自动响度归一化。这些能力不应以展示图代替实现。')
h('参考资料')
p('华为 AudioSuite 离线编辑：\nhttps://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/audio-suite-manual-rendering')
p('本机 SDK 的 native_audio_suite_engine.h 与 native_audio_suite_base.h。项目验证记录位于 .build/v2，官网原图来源位于 output/Demo演示/assets/sources.json。')
d.save(dest);(r/'output/文档/AudioSuite_离线编辑技术方案.md').write_text('\n'.join(md))
print(dest)
