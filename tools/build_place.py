"""Build an editable Roblox XML place using only the Python standard library."""
from pathlib import Path
import xml.etree.ElementTree as E
import json
import os
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
doc = E.Element('roblox', {'version': '4'})
E.SubElement(doc, 'External').text = 'null'
E.SubElement(doc, 'External').text = 'nil'
counter = 0

def item(cls, name, parent=doc):
    global counter
    counter += 1
    obj = E.SubElement(parent, 'Item', {'class': cls, 'referent': f'RBX{counter}'})
    props = E.SubElement(obj, 'Properties')
    E.SubElement(props, 'string', name='Name').text = name
    return obj

def prop(obj, typ, name, value):
    node = E.SubElement(obj.find('Properties'), typ, name=name)
    node.text = str(value).lower() if isinstance(value, bool) else str(value)
    return node

def vec(obj, name, values):
    node = prop(obj, 'Vector3', name, '')
    for key, value in zip(('X', 'Y', 'Z'), values):
        E.SubElement(node, key).text = str(value)

def color(obj, name, rgb):
    node = prop(obj, 'Color3', name, '')
    for key, value in zip(('R', 'G', 'B'), rgb):
        E.SubElement(node, key).text = str(value / 255)

ws = item('Workspace', 'Workspace')
prop(ws, 'float', 'FallenPartsDestroyHeight', -60)
map_obj = item('Model', 'NeonObby', ws)
platforms = item('Folder', 'Platforms', map_obj)
checks = item('Folder', 'Checkpoints', map_obj)
hazards = item('Folder', 'Hazards', map_obj)
decor = item('Folder', 'Decor', map_obj)
navy = (27, 40, 66)
cyan = (49, 215, 255)
green = (60, 255, 180)
red = (255, 65, 102)
purple = (159, 105, 255)
geometry = []

def part(name, pos, size, rgb=cyan, parent=platforms, cls='Part', neon=False, collide=True):
    obj = item(cls, name, parent)
    prop(obj, 'bool', 'Anchored', True)
    prop(obj, 'bool', 'CanCollide', collide)
    prop(obj, 'token', 'Material', 288 if neon else 256)
    prop(obj, 'token', 'TopSurface', 0)
    prop(obj, 'token', 'BottomSurface', 0)
    vec(obj, 'size', size)
    prop(obj, 'Color3uint8', 'Color3uint8', 0xFF000000 | (rgb[0] << 16) | (rgb[1] << 8) | rgb[2])
    cf = prop(obj, 'CoordinateFrame', 'CFrame', '')
    for key, val in zip(('X','Y','Z'), pos):
        E.SubElement(cf, key).text = str(val)
    for r in range(3):
        for c in range(3):
            E.SubElement(cf, f'R{r}{c}').text = '1' if r == c else '0'
    geometry.append((name, pos, size))
    return obj

def sign(text, x, z):
    anchor = part('Sign', (x, 12, z), (1,1,1), parent=decor, collide=False)
    prop(anchor, 'float', 'Transparency', 1)
    gui = item('BillboardGui', 'Label', anchor)
    prop(gui, 'bool', 'AlwaysOnTop', False)
    prop(gui, 'float', 'MaxDistance', 45)
    size = prop(gui, 'UDim2', 'Size', '')
    for key, val in [('XS',0),('XO',240),('YS',0),('YO',50)]:
        E.SubElement(size, key).text = str(val)
    label = item('TextLabel', 'Text', gui)
    size = prop(label, 'UDim2', 'Size', '')
    for key, val in [('XS',1),('XO',0),('YS',1),('YO',0)]:
        E.SubElement(size,key).text = str(val)
    prop(label, 'float', 'BackgroundTransparency', 1)
    prop(label, 'bool', 'TextScaled', True)
    prop(label, 'string', 'Text', text)
    color(label, 'TextColor3', (240,250,255))

def slide_guide(x, z, width, depth):
    # A continuous luminous lower edge marks the real collision boundary (y=2).
    part('SlideLowerEdge',(x,2.04,z-depth/2-.08),(width,.12,.16),cyan,decor,neon=True,collide=False)
    for side in (-1,1):
        part('SlideClearancePost',(x+side*(width/2+.12),1,z-depth/2-.08),(.16,2,.16),cyan,decor,neon=True,collide=False)
        part('SlideFloorRail',(x+side*(width/2-.3),.05,z-2),(0.12,.1,depth+7),cyan,decor,neon=True,collide=False)
    for dz in (-6,-4,-2):
        part('SlideApproach',(x,.06,z+dz),(min(width-1,5),.12,.18),cyan,decor,neon=True,collide=False)
    # Low, deep lintel with high-contrast hazard stripes: the opening is visibly below standing height.
    for side in (-1,1):
        part('SlideFrame',(x+side*(width/2+.22),1.65,z),(.35,3.3,depth+.35),(27,40,52),decor,collide=False)
    for dx in range(-int(width/2)+1,int(width/2),2):
        stripe=part('SlideHazardStripe',(x+dx,2.38,z-depth/2-.13),(.55,.55,.12),(245,185,60),decor,collide=False)
        cf=stripe.find('./Properties/CoordinateFrame[@name="CFrame"]')
        import math
        for key,val in {'R00':math.cos(.55),'R01':-math.sin(.55),'R10':math.sin(.55),'R11':math.cos(.55)}.items():cf.find(key).text=str(val)
    # A geometric sliding-person pictogram, no text or floating instruction billboard.
    part('SlidePictogramPlate',(x,3.8,z-depth/2-.2),(3,1.7,.16),(18,30,42),decor,collide=False)
    head=part('SlidePictogramHead',(x-.8,4.1,z-depth/2-.32),(.4,.4,.14),cyan,decor,neon=True,collide=False)
    prop(head,'token','shape',0)
    part('SlidePictogramBody',(x-.3,3.72,z-depth/2-.32),(.9,.25,.14),cyan,decor,neon=True,collide=False)
    part('SlidePictogramLegs',(x+.65,3.48,z-depth/2-.32),(1.25,.22,.14),cyan,decor,neon=True,collide=False)
    for dx in (-.95,-.45,.05):
        part('SlidePictogramMotion',(x+dx,3.3,z-depth/2-.32),(.3,.08,.14),cyan,decor,neon=True,collide=False)

gaps=item('Folder','Gaps',map_obj)
coins=item('Folder','Collectibles',map_obj)
pickups=item('Folder','Pickups',map_obj)
routes=item('Folder','RouteNodes',map_obj)
# One complete sample level with authored action sequences and two optional high routes.
navy=(17,24,35)
accent=(245,167,76)
names=['逃离起点','管道街区','上层捷径','追逐街巷','动作连贯','补给屋顶','道具街区','落点选择','第二条捷径','危险街区','最后冲刺','逃生出口']
for n in range(12):
    z=n*144
    cp=part(str(n+1),(0,0.1,z),(26,0.2,12),(74,192,173),checks,'SpawnLocation',False)
    prop(cp,'bool','Neutral',True);prop(cp,'float','Duration',0)
    prop(cp,'float','Transparency',0.65)
    for key in ('R00','R22'): cp.find('Properties/CoordinateFrame/'+key).text='-1'
    kinds = [['Hurdle','Vault','Gap','Hurdle'],['Hurdle','Slide','Gap','Vault'],['Slide','Vault','Gap','Slide'],['Vault','Slide','Gap','Vault'],['Hurdle','Vault','Gap','Slide'],['Slide','Slide','Gap','Hurdle'],['Hurdle','Slide','Gap','Vault'],['Vault','Hurdle','Gap','Slide'],['Slide','Vault','Gap','Hurdle'],['Vault','Slide','Gap','Slide'],['Hurdle','Vault','Gap','Vault'],['Slide','Hurdle','Gap','Vault']][n]
    gap=z+88; width=4 if n<4 else 5 if n<8 else 6
    marker=part('Gap'+str(n),(0,-4,gap),(12,0.1,width),(0,0,0),gaps,collide=False);prop(marker,'float','Transparency',1)
    start=z-12 if n==0 else z
    end=z+144
    for lo,hi in ((start,gap-width/2),(gap+width/2,end)):
        part('Roof',(0,-3,(lo+hi)/2),(28,6,hi-lo),navy)
        part('RoofEdge',(-14.05,0.02,(lo+hi)/2),(0.12,0.12,hi-lo),accent,decor,collide=False)
        # Side wall windows lie on camera-facing facades.
        for wz in range(int(lo)+4,int(hi)-3,9):
            part('FacadeWindow',(-14.08,-2,wz),(0.1,0.8,3),(45,57,70),decor,collide=False)
    for offset,kind in zip((32,60,88,116),kinds):
        oz=z+offset
        if kind!='Gap' and (n==6 or (offset==116 and n%3==0) or (offset==32 and n in (1,4,7,10))): continue
        if kind=='Gap':
            part('JumpMark',(0,0.04,oz-width/2-3),(11,0.08,0.5),accent,decor,collide=False)
            continue
        y,height,depth=(1,2,1.4) if kind=='Hurdle' else (1.5,3,2.5) if kind=='Vault' else (4.5,5,4)
        part(kind,((n%3-1)*6,y,oz),(18 if n%4==0 else 12,height,depth),(215,98,63) if kind!='Slide' else (40,61,77),hazards,collide=True)
        if kind=='Slide': slide_guide((n%3-1)*6,oz,18 if n%4==0 else 12,depth)
        part('ActionMark',(0,0.04,oz-7),(11,0.08,0.5),accent if kind!='Slide' else (83,197,210),decor,collide=False)
        for x in ((n%3-1)*6-6,(n%3-1)*6+6):
            part('ObstacleOutline',(x,y,oz),(0.12,height+0.1,depth+0.1),accent if kind!='Slide' else (83,197,210),decor,collide=False)
    if n<9:
        part('RecoveryShelf',(0,-3,gap),(28,1,width+3),(36,65,75),platforms)
    # Backdrop deliberately behind the playable plane, clear foreground.
    for j in range(5):
        bz=z+j*29
        h=20+(n*7+j*11)%32
        part('Skyline',(30,-8+h/2,bz),(8,h,23),(69,84,101),decor,collide=False)
        part('FarSkyline',(65,12,bz+10),(10,44+(j%3)*10,26),(120,139,155),decor,collide=False)
        for wy in range(4,h-4,7):
            part('CityWindow',(25.9,-8+wy,bz),(0.1,1,12),(152,168,176),decor,collide=False)
    sign('%02d · %s'%(n+1,names[n]),0,z+8)
# Alternating lane challenges create optional risky inside lines and clear bypasses.
for stage in (3,5,7,9,10):
    base=stage*144
    for k,offset in enumerate((24,46,110,130)):
        x=(-1 if k%2==0 else 1)*7
        kind='Slide' if (stage+k)%2 else 'Vault'
        y,height=(4.5,5) if kind=='Slide' else (1.5,3)
        part(kind,(x,y,base+offset),(10,height,2.5),(70,160,190) if kind=='Slide' else (215,120,65),hazards,collide=True)
        if kind=='Slide': slide_guide(x,base+offset,10,2.5)
        part('LaneCue',(-x,.06,base+offset-7),(5,.12,3),green,decor,collide=False)
    sign('交错障碍 · 绿标换道 / 原道挑战',0,base+16)
# Optional narrow outside bypass around the last three gaps, longer but no jump required.
for stage in (9,10,11):
    z=stage*144+88
    part('OuterBypass',(18,-.5,z),(6,1,22),(40,65,75),platforms)
    for dz in (-10,10):part('BypassLink',(14,-.5,z+dz),(8,1,4),(40,65,75),platforms)
    sign('直线跳跃 / 外侧绕行',10,z-16)
# Collectibles deliberately reward exploring the upper route.
for i,(z,y) in enumerate(((160,3),(365,13),(1240,13)),1):
    part('Token'+str(i),(0,y,z),(1.6,1.6,1.6),(245,205,99),coins,neon=True,collide=False)
# A visible, deterministic item identity: the model always matches the granted item.
item_keys=['Boost','Shield','Rocket','Spring','EMP','Cleanse','Magnet','Trap','Decoy','Vacuum','Leader','Smoke','Steal','Shockwave']
item_categories={key:'机动补给' for key in ('Boost','Magnet','Spring','Vacuum')}
item_categories.update({key:'防御补给' for key in ('Shield','Cleanse','Decoy')})
for i,z in enumerate(range(25,1720,55),1):
    key=item_keys[(i-1)%len(item_keys)]
    category=item_categories.get(key,'攻击补给')
    tint={'机动补给':(80,220,180),'防御补给':(80,170,255),'攻击补给':(255,155,75)}[category]
    supply=part('Supply'+str(i),(((i%3)-1)*8,2,z),(1.8,1.8,1.8),tint,pickups,neon=True,collide=False)
    prop(item('StringValue','Category',supply),'string','Value',category)
    prop(item('StringValue','ItemKey',supply),'string','Value',key)
for i,(node,lo,hi) in enumerate(((308,316,398),(1172,1180,1262)),1):
    part('WallJump'+str(i),(0,3,node),(11,6,0.25),(80,184,200),routes,collide=False)
    part('UpperRoof',(0,9.5,(lo+hi)/2),(12,1,hi-lo),(27,42,55),platforms)
    part('UpperEdge',(-6.05,10,(lo+hi)/2),(.12,.12,hi-lo),(83,197,210),decor,collide=False)
    part('WallCue',(0,.05,node-7),(11,.1,.5),(83,197,210),decor,collide=False)
    sign('起跳蹬墙 · 上层收集路线',0,node-12)
part('FinishIsland',(0,-3,1744),(28,6,32),navy)
part('Finish',(0,0.15,1742),(28,0.3,8),(245,190,86),map_obj,neon=False,collide=False)
for x in (-6,6): part('FinishGate',(x,4,1742),(0.5,8,0.5),accent,decor,collide=False)
part('FinishGateTop',(0,8,1742),(12,0.5,0.5),accent,decor,collide=False)
sign('城市边缘 · 自由抵达',0,1742)

lighting = item('Lighting','Lighting')
prop(lighting,'float','ClockTime',7)
prop(lighting,'float','Brightness',2)
color(lighting,'Ambient',(145,155,170))
color(lighting,'OutdoorAmbient',(135,145,180))
# Explicit source manifest is shared with verification and Studio import.
manifest=json.loads((ROOT/'project.json').read_text())['entries']
containers={}
def container(path):
    if path in containers:return containers[path]
    parts=path.split('/')
    if len(parts)==1:obj=item(parts[0],parts[0])
    else:obj=item('StarterPlayerScripts' if parts[-1]=='StarterPlayerScripts' else 'Folder',parts[-1],container('/'.join(parts[:-1])))
    containers[path]=obj
    return obj
version = (ROOT / 'VERSION').read_text().strip()
if not re.fullmatch(r'v[1-9][0-9]*', version):
    raise ValueError('VERSION must be v followed by a positive integer')
commit = os.environ.get('BUILD_COMMIT')
if not commit:
    result = subprocess.run(['git', 'rev-parse', 'HEAD'], cwd=ROOT, capture_output=True, text=True)
    commit = result.stdout.strip() if result.returncode == 0 else 'untracked'
if commit != 'untracked' and not re.fullmatch(r'[0-9a-f]{40}', commit):
    raise ValueError('BUILD_COMMIT must be a full Git commit SHA')
build_info = item('Folder', 'BuildInfo', container('ReplicatedStorage'))
for key, value in (('Version', version), ('Commit', commit)):
    prop(item('StringValue', key, build_info), 'string', 'Value', value)
source_nodes=[]
for entry in manifest:
    node=item(entry['class'],entry['name'],container(entry['parent']))
    prop(node,'ProtectedString','Source',(ROOT/entry['file']).read_text())
    source_nodes.append(node)
E.indent(doc)
out=ROOT/'SkylineSample.rbxlx'
E.ElementTree(doc).write(out,encoding='utf-8',xml_declaration=True)
assert len(doc.findall('.//Item[@class="SpawnLocation"]'))==12
print(f'Built {out.name}: {counter} instances; {len(source_nodes)} scripts/modules.')
from copy import deepcopy
bundle_doc=E.Element('roblox',version='4')
E.SubElement(bundle_doc,'External').text='null';E.SubElement(bundle_doc,'External').text='nil'
bundle=E.SubElement(bundle_doc,'Item',{'class':'Model','referent':'RaceUpgradeBundle'})
bp=E.SubElement(bundle,'Properties');E.SubElement(bp,'string',name='Name').text='NeonRaceTransfer'
bundle.append(deepcopy(map_obj))
bundle.append(deepcopy(build_info))
for path,obj in containers.items():
    if path in ('ServerScriptService/ServerModules','StarterPlayer/StarterPlayerScripts/ClientModules','ReplicatedStorage/SharedModules'):bundle.append(deepcopy(obj))
for node,entry in zip(source_nodes,manifest):
    if entry['parent'].split('/')[-1] not in ('ServerModules','ClientModules','SharedModules'):bundle.append(deepcopy(node))
E.ElementTree(bundle_doc).write(ROOT/'SkylineSample.rbxmx',encoding='utf-8',xml_declaration=False)
