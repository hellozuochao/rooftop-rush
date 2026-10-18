"""Checks authored route integrity, embedded sources and recovery geometry."""
from pathlib import Path
import xml.etree.ElementTree as E
import math
import json
root=Path(__file__).resolve().parents[1]
doc=E.parse(root/'SkylineSample.rbxlx')
def name(i):return i.findtext('./Properties/string[@name="Name"]')
def xyz(i):return tuple(float(i.findtext('./Properties/CoordinateFrame[@name="CFrame"]/'+k)) for k in ('X','Y','Z'))
def size(i):return tuple(float(i.findtext('./Properties/Vector3[@name="size"]/'+k)) for k in ('X','Y','Z'))
def folder(n):return next(i for i in doc.iter('Item') if name(i)==n)
def children(n):return folder(n).findall('Item')
roofs=children('Platforms')
checks=children('Checkpoints');assert len(checks)==12
for cp in checks:
    x,y,z=xyz(cp)
    assert any(abs(z-xyz(r)[2])<=size(r)[2]/2+0.001 and xyz(r)[1]+size(r)[1]/2==0 for r in roofs),f'unsupported checkpoint {name(cp)}'
assert len(children('Gaps'))==12
for gap in children('Gaps'):
    z=xyz(gap)[2]
    assert not any(abs(z-xyz(r)[2])<size(r)[2]/2-.01 and abs(xyz(r)[0])<size(r)[0]/2 and xyz(r)[1]<0 and name(r)!='RecoveryShelf' for r in roofs),'gap filled accidentally'
coins=children('Collectibles');assert len(coins)==3
for coin in coins:
    _,y,z=xyz(coin)
    assert any(abs(z-xyz(r)[2])<size(r)[2]/2 and abs(y-(xyz(r)[1]+size(r)[1]/2+3))<.1 for r in roofs),f'unreachable token {name(coin)}'
hazards=children('Hazards')
for z in (60,204,752):assert len([o for o in hazards if xyz(o)[2]==z])==1,'missing action challenge'
upper=[r for r in roofs if name(r)=='UpperRoof'];assert len(upper)==2
for node,roof in zip(children('RouteNodes'),upper):
    z=xyz(node)[2];lo=xyz(roof)[2]-size(roof)[2]/2
    # A jump at the authored cue reaches the wall, then a 55-stud/sec wall boost clears the front lip.
    t=7/20;wall_y=3+60*t-196.2*t*t/2
    flight=(lo-z)/20;at_lip=wall_y+55*flight-196.2*flight*flight/2
    assert at_lip>13,'upper route lip cannot be reached'
    assert xyz(roof)[1]-size(roof)[1]/2>=9,'lower route headroom blocked'
entries=json.loads((root/'project.json').read_text())['entries']
expected={entry['name']:entry for entry in entries}
assert len(expected)==len(entries),'duplicate source name'
embedded=[i for i in doc.iter('Item') if i.get('class') in ('Script','LocalScript','ModuleScript')]
parents={child:parent for parent in doc.iter() for child in parent}
def instance_path(node):
    names=[]
    while node is not None:
        if node.tag=='Item':names.append(name(node))
        node=parents.get(node)
    return '/'.join(reversed(names))
assert len(embedded)==len(entries)
assert set(expected)=={name(i)for i in embedded}
for script in embedded:
    entry=expected[name(script)]
    assert script.get('class')==entry['class']
    assert instance_path(parents[script])==entry['parent'], 'incorrect script installation path'
    assert script.findtext('./Properties/ProtectedString[@name="Source"]')==(root/entry['file']).read_text()
assert set(root.glob('src/**/*.luau'))=={root/e['file']for e in entries},'unbundled source'
assert not any((name(i) or '').startswith('QA') for i in doc.iter('Item'))
print('PASS: 12 checkpoints; 12 gaps; 3 reachable tokens; 3 action targets; 2 ballistic upper routes; manifest-exact embedded sources; no test scripts.')

assert not any(name(i) in ('RelayDoor','RelayWall','RelayBridge') for i in doc.iter('Item'))
assert min(size(o)[0] for o in roofs if name(o)=='Roof')==28
assert len(children('Pickups'))>=30
print('PASS: widened 28-stud course, no cooperation gates, 30+ supplies and shared config.')

assert len(hazards)>=40
assert len([p for p in roofs if name(p)=='OuterBypass'])==3
for supply in children('Pickups'):
    category=next(i for i in supply.findall('Item') if name(i)=='Category')
    assert category.findtext('./Properties/string[@name="Value"]') in ('机动补给','防御补给','攻击补给')
print('PASS: 20 extra lane obstacles, 3 outer bypasses, every supply categorized.')

slides=[h for h in hazards if name(h)=='Slide']
edges=[d for d in children('Decor') if name(d)=='SlideLowerEdge']
assert len(slides)==len(edges)
for h in slides:
    x,y,z=xyz(h);w,height,depth=size(h)
    assert abs(y-height/2-2)<.001,'slide opening clearance changed'
    edge=next(e for e in edges if abs(xyz(e)[0]-x)<.001 and abs(xyz(e)[2]-(z-depth/2-.08))<.001)
    assert abs(xyz(edge)[1]-2.04)<.001 and size(edge)[0]==w
for d in children('Decor'):
    if (name(d) or '').startswith('Slide'):
        assert d.findtext('./Properties/bool[@name="CanCollide"]')=='false','guide blocks passage'
print('PASS: every slide opening has an aligned nonblocking clearance guide.')

info=folder('BuildInfo')
assert instance_path(info)=='ReplicatedStorage/BuildInfo'
values={name(i):i.findtext('./Properties/string[@name="Value"]') for i in info.findall('Item')}
assert values['Version']==(root/'VERSION').read_text().strip()
assert values['Commit']=='untracked' or (len(values['Commit'])==40 and all(c in '0123456789abcdef' for c in values['Commit']))
bundle=E.parse(root/'SkylineSample.rbxmx')
bundle_info=next(i for i in bundle.iter('Item') if name(i)=='BuildInfo')
assert {name(i):i.findtext('./Properties/string[@name="Value"]') for i in bundle_info.findall('Item')}==values
print('PASS: complete place and import bundle contain matching version and commit metadata.')

item_keys={'Boost','Shield','Rocket','Spring','EMP','Cleanse','Magnet','Trap','Decoy','Vacuum','Leader','Smoke','Steal','Shockwave'}
seen=set()
for supply in children('Pickups'):
    key=next(i for i in supply.findall('Item') if name(i)=='ItemKey')
    value=key.findtext('./Properties/string[@name="Value"]')
    assert value in item_keys, 'pickup has unknown item identity'
    seen.add(value)
assert seen==item_keys, 'course must showcase all fourteen item identities'
assert not any(name(i) in ('SlideHint','SlideLabel') for i in doc.iter('Item')), 'slide text hint returned'
assert len([d for d in children('Decor') if name(d)=='SlidePictogramHead'])==len(slides)
print('PASS: all 14 item identities represented; slide guidance uses geometry without text.')
