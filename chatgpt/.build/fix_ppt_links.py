from zipfile import ZipFile,ZIP_DEFLATED
from pathlib import Path
from lxml import etree as E
p=Path('/Users/jiaoyuanxiang/Desktop/oh/chatgpt/.build/candidate.pptx')
links={'https://github.com/ace-step/ACE-Step-1.5':'https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/audio-suite-manual-rendering','https://github.com/ASLP-lab/MEGA':'https://gitcode.com/HarmonyOS_Samples/guide-snippets/tree/master/Media/Audio/AudioSuiteSample'}
with ZipFile(p) as z:items={n:z.read(n) for n in z.namelist()}
for n,b in list(items.items()):
 if n.endswith('.rels'):
  root=E.fromstring(b)
  for e in root:
   if e.get('Type','').endswith('/hyperlink'):
    old=e.get('Target','')
    e.set('Target',links.get(old,'https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/audio-suite-manual-rendering'))
  items[n]=E.tostring(root,xml_declaration=True,encoding='UTF-8')
with ZipFile(p,'w',ZIP_DEFLATED) as z:
 for n,b in items.items():z.writestr(n,b)
