from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=root/'src/Systems.server.luau';s=p.read_text()
s=s.replace('local store=game:GetService("DataStoreService"):GetDataStore("SkylineProfile_v1")','local storeOK,store=pcall(function() return game:GetService("DataStoreService"):GetDataStore("SkylineProfile_v1") end)\nif not storeOK then store=nil end')
s=s.replace('profile.Coins=math.max(0,math.floor(tonumber(d.Coins) or 0))','profile.Coins+=math.max(0,math.floor(tonumber(d.Coins) or 0))')
s=s.replace('p:SetAttribute("WardrobeSave",ok and "Saved" or "SessionOnly");sync(p);dress(p)','p:SetAttribute("ProfileReady",true);p:SetAttribute("WardrobeSave",ok and "Saved" or "SessionOnly");sync(p);dress(p)')
s=s.replace('if active(p) or type(value)~="number" or not outfits[value] then return end','if active(p) or not p:GetAttribute("ProfileReady") or type(value)~="number" or not outfits[value] then return end')
s=s.replace('if not active(p) then return end\n    if kind=="Sprint"','if not active(p) and not (kind=="Interact" and p:GetAttribute("PlayMode")=="Coop" and p:GetAttribute("RaceStatus")=="Finished") then return end\n    if kind=="Sprint"')
s=s.replace('if math.abs(r.Position.Z-885)<22 then\n                p:SetAttribute("GateUntil",t+12);q:SetAttribute("GateUntil",t+12);notice(p,"通道已开启 · 两人通过");return\n            end','''if math.abs(r.Position.Z-885)<22 and (p:GetAttribute("GateUntil") or 0)<t then
                q:SetAttribute("GateUntil",t+20);p:SetAttribute("HoldingGateUntil",t+20);notice(p,"开关已按住 · 等队友到对面解锁");notice(q,"队友打开通道 · 通过后按协助解锁");return
            elseif r.Position.Z>=901 and r.Position.Z<930 then
                p:SetAttribute("GateUntil",t+20);q:SetAttribute("GateUntil",t+20);q:SetAttribute("HoldingGateUntil",0);notice(q,"队友已解锁 · 继续前进");return
            end''')
s=s.replace('if mode=="Coop" and partner(p) and z>880 and z<901 and (p:GetAttribute("GateUntil") or 0)<t then','if mode=="Coop" and partner(p) and ((z>880 and z<901 and (p:GetAttribute("GateUntil") or 0)<t) or (p:GetAttribute("HoldingGateUntil") or 0)>t) then')
s=s.replace('h.WalkSpeed=0;notice(p,"合作通道 · 按协助开门并等待队友")','h.WalkSpeed=0\n            if (p:GetAttribute("HoldingGateUntil") or 0)<=t then notice(p,"合作通道 · 按协助开门并等待队友") end')
s=s.replace('st.Picked={};st.Actions={};st.Rewarded=false;', 'st.Picked={};st.Actions={};st.Cooldown={};st.Rewarded=false;')
s=s.replace('"HangingUntil","GateUntil"','"HangingUntil","GateUntil","HoldingGateUntil"')
s=s.replace('h.WalkSpeed=slow and 11 or sprint and 27 or 20','''h.WalkSpeed=slow and 11 or sprint and 27 or 20
        if h.FloorMaterial==Enum.Material.Air then st.DropSpeed=math.min(st.DropSpeed or 0,r.AssemblyLinearVelocity.Y)
        elseif st.DropSpeed then
            if st.DropSpeed < -48 then
                if (p:GetAttribute("RollUntil") or 0)>t then p:SetAttribute("Combo",(p:GetAttribute("Combo") or 0)+1);notice(p,"落地翻滚 · 保持速度")
                else p:SetAttribute("SlowUntil",t+0.7);notice(p,"重落地 · 落地前下滑可翻滚") end
            end
            st.DropSpeed=nil
        end''')
p.write_text(s)
p=root/'src/Systems.client.luau';s=p.read_text().replace('math.abs(r.Position.Z-885)<24','(r.Position.Z>860 and r.Position.Z<930)')
s=s.replace('interact.Visible=running and context==true','interact.Visible=(running or (m=="Coop" and p:GetAttribute("RaceStatus")=="Finished")) and context==true')
p.write_text(s)
p=root/'src/Hud.client.luau';s=p.read_text()
s=s.replace('local slidePointer','local slidePointer\nlocal jumpPointer,jumpStarted\nlocal function releaseJump()\n    local c=p.Character;local r=c and c:FindFirstChild("HumanoidRootPart")\n    if r and jumpStarted and os.clock()-jumpStarted<0.18 and r.AssemblyLinearVelocity.Y>35 then\n        local velocity=r.AssemblyLinearVelocity;r.AssemblyLinearVelocity=Vector3.new(velocity.X,35,velocity.Z)\n    end\n    jumpStarted=nil;jumpPointer=nil\nend')
s=s.replace('input(kind)\n        end\n    end)', 'if kind=="Jump" then jumpPointer=event;jumpStarted=os.clock() end\n            input(kind)\n        end\n    end)',1)
s=s.replace('if event==slidePointer then','if event==jumpPointer then releaseJump() end\n    if event==slidePointer then')
s=s.replace('if state==Enum.UserInputState.Begin then input("Jump") end return', 'if state==Enum.UserInputState.Begin then jumpStarted=os.clock();input("Jump") elseif state==Enum.UserInputState.End then releaseJump() end return')
s=s.replace('自动向前奔跑 · 12 段屋顶挑战','自动奔跑 · 收集三枚标记，摆脱追兵').replace('空格 / W 跳跃　按住 ↓ / S 滑铲','轻按短跳 / 长按远跳 · 下滑翻滚或滑铲')
p.write_text(s)
