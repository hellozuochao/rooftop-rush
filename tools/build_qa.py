"""Build a separate Studio-only QA model. NEVER publish it with the game."""
from pathlib import Path
import xml.etree.ElementTree as E
ROOT=Path(__file__).resolve().parents[1]
doc=E.Element('roblox',version='4')
for value in ('null','nil'):E.SubElement(doc,'External').text=value
bundle=E.SubElement(doc,'Item',{'class':'Model','referent':'QABundle'})
p=E.SubElement(bundle,'Properties');E.SubElement(p,'string',name='Name').text='QAV25Bundle'
for name,cls,file in [('QAV25Server','Script','Suite.server.luau'),('QAV25Client','LocalScript','Suite.client.luau')]:
 node=E.SubElement(bundle,'Item',{'class':cls,'referent':name});props=E.SubElement(node,'Properties');E.SubElement(props,'string',name='Name').text=name
 E.SubElement(props,'ProtectedString',name='Source').text=(ROOT/'tests'/file).read_text()
E.ElementTree(doc).write(ROOT/'tests/QAV25.rbxmx',encoding='utf-8',xml_declaration=False)
print('Built tests/QAV25.rbxmx (Studio tests only).')

# A self-contained local test place avoids manual script installation mistakes.
import argparse
parser=argparse.ArgumentParser()
parser.add_argument('--place', choices=['Solo','Multi'])
args=parser.parse_args()
if args.place:
    place=E.parse(ROOT/'SkylineSample.rbxlx')
    def named(n): return n.findtext('./Properties/string[@name="Name"]')
    services={named(n):n for n in place.getroot().findall('Item')}
    for name,cls,file,parent in [
        ('QAV25Server','Script','Suite.server.luau',services['ServerScriptService']),
        ('QAV25Client','LocalScript','Suite.client.luau',next(n for n in services['StarterPlayer'].findall('Item') if named(n)=='StarterPlayerScripts'))]:
        node=E.SubElement(parent,'Item',{'class':cls,'referent':name})
        props=E.SubElement(node,'Properties');E.SubElement(props,'string',name='Name').text=name
        source=(ROOT/'tests'/file).read_text()
        if cls=='Script': source='workspace:SetAttribute("QAMode", "'+args.place+'")\n'+source
        E.SubElement(props,'ProtectedString',name='Source').text=source
    output=ROOT/'tests'/('QAV25'+args.place+'.rbxlx')
    place.write(output,encoding='utf-8',xml_declaration=False)
    print('Built',output,'— LOCAL TEST ONLY, never publish.')
