"""Build a separate Studio-only QA model. NEVER publish it with the game."""
from pathlib import Path
import xml.etree.ElementTree as E
ROOT=Path(__file__).resolve().parents[1]
doc=E.Element('roblox',version='4')
for value in ('null','nil'):E.SubElement(doc,'External').text=value
bundle=E.SubElement(doc,'Item',{'class':'Model','referent':'QABundle'})
p=E.SubElement(bundle,'Properties');E.SubElement(p,'string',name='Name').text='QAV23Bundle'
for name,cls,file in [('QAV23Server','Script','Suite.server.luau'),('QAV23Client','LocalScript','Suite.client.luau')]:
 node=E.SubElement(bundle,'Item',{'class':cls,'referent':name});props=E.SubElement(node,'Properties');E.SubElement(props,'string',name='Name').text=name
 E.SubElement(props,'ProtectedString',name='Source').text=(ROOT/'tests'/file).read_text()
E.ElementTree(doc).write(ROOT/'tests/QAV23.rbxmx',encoding='utf-8',xml_declaration=False)
print('Built tests/QAV23.rbxmx (Studio tests only).')
