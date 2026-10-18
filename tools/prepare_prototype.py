from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=root/'src/Game.server.luau';s=p.read_text().replace('SkylineEscape_12_v1','SkylineSample_v10')
s=s.replace('if kind=="Start" then','if kind=="Start" then\n        if (p:GetAttribute("PlayMode") or "Solo")~="Solo" then return end')
s=s.replace('if root.Position.Y < -5 then','if root.Position.Y < -5 and not p:GetAttribute("Hanging") then')
s=s.replace('local lastAction, previousZ = {}, {}','local lastAction, previousZ = {}, {}\nlocal hitUntil, cleared = {}, {}')
s=s.replace('if h.Health<=0 then return end\n    p:SetAttribute', 'if h.Health<=0 then return end\n    p:SetAttribute',1)
# Normal obstacles penalize speed; falls and chase remain lethal.
s=s.replace('if not slide or feet>0.8 then fail(p,h,"撞到低梁 · 按滑铲通过") end','if feet<o.Position.Y+o.Size.Y/2 and (not slide or feet>0.8) then stumble(p,o,"低梁碰撞 · 提前按滑铲") end')
s=s.replace('fail(p,h,o.Name=="Vault" and "撞到矮墙 · 提前跳跃翻越" or "碰到栏杆 · 提前起跳")','stumble(p,o,o.Name=="Vault" and "翻越失误 · 提前起跳" or "碰到栏杆 · 提前起跳")')
needle='action.OnServerEvent:Connect(function(p,kind)'
insert='''local function stumble(p,o,message)
    hitUntil[p]=hitUntil[p] or {}
    local now=workspace:GetServerTimeNow()
    if (hitUntil[p][o] or 0)>now then return end
    hitUntil[p][o]=now+2
    p:SetAttribute("SlowUntil",now+1.5);p:SetAttribute("Combo",0)
    p:SetAttribute("ActionNotice",message);p:SetAttribute("ActionNoticeUntil",now+2)
end
'''
s=s.replace(needle,insert+needle)
# Count three authored skill challenges only after successfully clearing their obstacles.
needle='local previous=previousZ[p]'
s=s.replace(needle,'''cleared[p]=cleared[p] or {}
            for _,o in map.Hazards:GetChildren() do
                if o:GetAttribute("Challenge") and not cleared[p][o] and z>o.Position.Z+o.Size.Z/2+1 and z<o.Position.Z+8 then
                    cleared[p][o]=true
                    if not hitUntil[p] or not hitUntil[p][o] then p:SetAttribute("ActionCount",(p:GetAttribute("ActionCount") or 0)+1) end
                end
            end
            '''+needle)
s=s.replace('player:SetAttribute("StartedAt", workspace:GetServerTimeNow())\n    player:SetAttribute("Finished", false)', 'player:SetAttribute("StartedAt", workspace:GetServerTimeNow())\n    player:SetAttribute("Finished", false)')
p.write_text(s)
p=root/'src/Hud.client.luau';s=p.read_text()
s=s.replace('intro.Size=UDim2.new(1,-40,0,190)','intro.Size=UDim2.new(1,-40,0,250)').replace('Vector2.new(440,190)','Vector2.new(440,250)')
s=s.replace('城市剪影 · SKYLINE ESCAPE','城市剪影 · 逃脱样板关')
s=s.replace('start.Activated:Connect(function() action:FireServer("Start") end)','start.Activated:Connect(function() if (p:GetAttribute("PlayMode") or "Solo")=="Solo" then action:FireServer("Start") else Storage:WaitForChild("RaceReady"):FireServer() end end)')
s=s.replace('local lastGround,slideLocal,vaultLocal=0,0,0','local lastGround,slideLocal,vaultLocal=0,0,0\nlocal rollUntil=0\nlocal wasAir=false')
s=s.replace('pressButton(jump,"Jump"); pressButton(slide,"Slide")','pressButton(jump,"Jump"); pressButton(slide,"Slide")\nlocal gesture=Instance.new("BindableEvent",gui);gesture.Name="Gesture";gesture.Event:Connect(input)')
s=s.replace('elseif grounded(h,root) and os.clock()', 'elseif h.FloorMaterial==Enum.Material.Air then\n        rollUntil=workspace:GetServerTimeNow()+1.2; action:FireServer("Roll")\n    elseif grounded(h,root) and os.clock()')
s=s.replace('if h.Health>0 then','if h.Health>0 and not p:GetAttribute("Hanging") then')
s=s.replace('local pose=sliding and', 'local rolling=rollUntil>now and h.FloorMaterial~=Enum.Material.Air\n            local pose=rolling and CFrame.new(0,-0.8,0)*CFrame.Angles((rollUntil-now)*-math.pi*2,0,0) or sliding and')
s=s.replace('toast.Position=UDim2.new(0.5,0,0,46)','toast.Position=UDim2.new(0.5,0,0,72)')
p.write_text(s)
p=root/'src/Race.server.luau';s=p.read_text()
s=s.replace('if count() >= 2 then beginCountdown() end','if count() >= 2 then beginCountdown() end')
s=s.replace('if not p:FindFirstChild("leaderstats") then return end','if not p:FindFirstChild("leaderstats") then return end\n    if (p:GetAttribute("PlayMode") or "Solo")=="Solo" then return end\n    for q in members do if q~=p and q:GetAttribute("PlayMode")~=p:GetAttribute("PlayMode") then p:SetAttribute("ActionNotice","队友需要选择相同模式");p:SetAttribute("ActionNoticeUntil",now()+3);return end end')
s=s.replace('count() >= 8','count() >= 2')
s=s.replace('if phase ~= "Waiting" then return end','if phase ~= "Waiting" or count()>=2 then return end')
p.write_text(s)
