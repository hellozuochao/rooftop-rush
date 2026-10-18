from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=root/'tools/build_place.py';s=p.read_text()
s=s.replace("names=['初次逃离','屋顶步伐','低梁穿行','跨越街巷','连贯动作','天台巡航','交替反应','高架通道','疾行屋脊','暮色穿越','最后街区','城市边缘']", "names=['逃离起点','管道街区','上层捷径','追逐街巷','动作连贯','补给屋顶','合作通道','落点选择','第二条捷径','危险街区','最后冲刺','逃生出口']")
s=s.replace("kinds = ['Hurdle','Vault','Gap','Hurdle'] if n==0 else (['Hurdle','Slide','Gap','Vault'] if n%2 else ['Slide','Vault','Gap','Slide'])", "kinds = [['Hurdle','Vault','Gap','Hurdle'],['Hurdle','Slide','Gap','Vault'],['Slide','Vault','Gap','Slide'],['Vault','Slide','Gap','Vault'],['Hurdle','Vault','Gap','Slide'],['Slide','Slide','Gap','Hurdle'],['Hurdle','Slide','Gap','Vault'],['Vault','Hurdle','Gap','Slide'],['Slide','Vault','Gap','Hurdle'],['Vault','Slide','Gap','Slide'],['Hurdle','Vault','Gap','Vault'],['Slide','Hurdle','Gap','Vault']][n]")
s=s.replace("# Original skyline course: twelve rooftop districts, four decisions per district.", "gaps=item('Folder','Gaps',map_obj)\ncoins=item('Folder','Collectibles',map_obj)\npickups=item('Folder','Pickups',map_obj)\nroutes=item('Folder','RouteNodes',map_obj)\n# One complete sample level with authored action sequences and two optional high routes.")
s=s.replace("gap=z+88; width=6 if n<4 else 7 if n<8 else 8", "gap=z+88; width=6 if n<4 else 7 if n<8 else 8\n    marker=part('Gap'+str(n),(0,-4,gap),(12,0.1,width),(0,0,0),gaps,collide=False);prop(marker,'float','Transparency',1)")
needle="part('FinishIsland'"
idx=s.index(needle)
s=s[:idx]+'''# Collectibles deliberately reward exploring the upper route.
for i,(z,y) in enumerate(((160,3),(365,11),(1240,11)),1):
    part('Token'+str(i),(0,y,z),(1.6,1.6,1.6),(245,205,99),coins,neon=True,collide=False)
for i,z in enumerate((175,475,655,1020,1320,1510),1):
    part('Supply'+str(i),(0,2,z),(1.8,1.8,1.8),(104,211,193),pickups,neon=True,collide=False)
for i,(node,lo,hi) in enumerate(((308,328,398),(1172,1192,1262)),1):
    part('WallJump'+str(i),(0,3,node),(11,6,0.25),(80,184,200),routes,collide=False)
    part('UpperRoof',(0,7.5,(lo+hi)/2),(12,1,hi-lo),(27,42,55),platforms)
    part('UpperEdge',(-6.05,8,(lo+hi)/2),(.12,.12,hi-lo),(83,197,210),decor,collide=False)
    part('WallCue',(0,.05,node-7),(11,.1,.5),(83,197,210),decor,collide=False)
    sign('起跳蹬墙 · 上层收集路线',0,node-12)
part('CoopGateFrame',(0,6,900),(12,.5,.5),(83,197,210),decor,collide=False)
for x in (-6,6):part('CoopGatePost',(x,3,900),(.5,6,.5),(83,197,210),decor,collide=False)
part('CoopSwitch',(0,.1,885),(10,.2,8),(83,197,210),decor,neon=True,collide=False)
sign('双人通道 · 协助队友通过',0,880)
''' +s[idx:]
s=s.replace("item('ReplicatedStorage','ReplicatedStorage')", "systems_server=item('Script','Systems',ss)\nprop(systems_server,'ProtectedString','Source',(ROOT/'src/Systems.server.luau').read_text())\nsystems_client=item('LocalScript','SystemsUI',scripts)\nprop(systems_client,'ProtectedString','Source',(ROOT/'src/Systems.client.luau').read_text())\nitem('ReplicatedStorage','ReplicatedStorage')")
s=s.replace("== 2","== 3").replace('(map_obj,server,client,race_server,race_client)', '(map_obj,server,client,race_server,race_client,systems_server,systems_client)')
s=s.replace("'NeonSkyObby.rbxlx'","'SkylineSample.rbxlx'").replace("'NeonRaceTransfer.rbxmx'","'SkylineSample.rbxmx'")
p.write_text(s)
# Integrate lifecycle reset and challenge validation.
p=root/'src/Game.server.luau';s=p.read_text();s=s.replace('local pending, saving = {}, {}','local pending, saving = {}, {}\nlocal hitUntil,cleared={},{}');s=s.replace('local hitUntil, cleared = {}, {}','')
s=s.replace('local function setup(player)','local function setup(player)\n    player:GetAttributeChangedSignal("StartedAt"):Connect(function() hitUntil[player]={};cleared[player]={} end)')
s=s.replace('if kind~="Start" and kind~="Jump" and kind~="Slide" then return end','if kind~="Start" and kind~="Jump" and kind~="Slide" and kind~="Roll" then return end')
s=s.replace('if kind=="Slide" then\n        local ground=', 'if kind=="Roll" then\n        if h.FloorMaterial==Enum.Material.Air then p:SetAttribute("RollUntil",now+1.2) end\n    elseif kind=="Slide" then\n        local ground=')
s=s.replace('Players.PlayerRemoving:Connect(function(p) lastAction[p]=nil; previousZ[p]=nil end)', 'Players.PlayerRemoving:Connect(function(p) lastAction[p]=nil; previousZ[p]=nil;hitUntil[p]=nil;cleared[p]=nil end)')
s=s.replace('local action=Instance.new("RemoteEvent")', 'for _,o in map.Hazards:GetChildren() do if o.Position.Z==60 or o.Position.Z==204 or o.Position.Z==748 then o:SetAttribute("Challenge",true) end end\nlocal action=Instance.new("RemoteEvent")')
p.write_text(s)
p=root/'src/Systems.server.luau';s=p.read_text().replace('st.Picked={};st.Actions={};', 'for _,coin in map.Collectibles:GetChildren() do p:SetAttribute("Picked"..coin.Name,false) end\n    st.Picked={};st.Actions={};')
s=s.replace('local paused=h.WalkSpeed==0 or p:GetAttribute("Hanging")','local paused=h.WalkSpeed==0 or p:GetAttribute("Hanging")')
s=s.replace('if z-st.Pursuer>55 then st.Pursuer=z-55 end','if z-st.Pursuer>40 then st.Pursuer=z-40 end')
p.write_text(s)
