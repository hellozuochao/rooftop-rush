local Art = require(game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("ItemArt"))
-- Dependencies are supplied by Systems.server; requiring this module has no side effects.
return function(deps)
    local actors = deps.actors
    local rig = deps.rig
    local active = deps.active
    local now = deps.now
    local opponents = deps.opponents
    local model = deps.model
    local notice = deps.notice
    local C = deps.C
    local effect = deps.effect
    local strike = deps.strike
    local markImpact = deps.markImpact
    local knock = deps.knock
    local addItem = deps.addItem
    local removeItem = deps.removeItem
    local Run = deps.Run
    local Debris = deps.Debris
    local same = deps.same
    local S = deps.S
    local traps = {}
    local function pulse(position, color, radius)
        for i=1,24 do
            local angle=i*math.pi/12
            local direction=Vector3.new(math.cos(angle),0,math.sin(angle))
            local segment=Instance.new("Part",workspace)
            segment.Name="ItemPulseRing"
            segment.Anchored=true
            segment.CanCollide=false
            segment.CanTouch=false
            segment.CanQuery=false
            segment.Material=Enum.Material.Neon
            segment.Color=color
            segment.Size=Vector3.new(0.3,0.2,0.45)
            segment.CFrame=CFrame.lookAt(position+direction,position+direction+Vector3.new(-direction.Z,0,direction.X))
            game:GetService("TweenService"):Create(segment,TweenInfo.new(0.6),{
                Position=position+direction*radius,Size=Vector3.new(0.3,0.2,radius*0.28),Transparency=1
            }):Play()
            Debris:AddItem(segment,0.65)
        end
    end
    local function use(a)
        local st = actors[a]
        local _, _, r = rig(a)
        if not st or not r or not active(a) or now() - (st.UseAt or 0) < 0.5 then
            return
        end
        local item = a:GetAttribute("HeldItem")
        if not item then
            return
        end
        st.UseAt = now()
        local list = opponents(a)
        local target
        for i = #list, 1, -1 do
            local b = list[i]
            if model(b).HumanoidRootPart.Position.Z > r.Position.Z then
                target = b
                break
            end
        end
        if item == "Leader" then
            target = list[1]
            if target and model(target).HumanoidRootPart.Position.Z <= r.Position.Z then
                target = nil
            end
        end
        if (item == "Rocket" or item == "Leader" or item == "Steal") and not target then
            notice(a, "前方没有目标，保留道具")
            return
        end
        removeItem(a)
        notice(a, "已使用：" .. C.Items[item])
        a:SetAttribute("LastUsedItem", item)
        a:SetAttribute("UsedItemSerial", (a:GetAttribute("UsedItemSerial") or 0) + 1)
        if item == "Boost" or item == "Magnet" then
            local duration = 4
            if item == "Magnet" and target then
                duration = math.clamp((model(target).HumanoidRootPart.Position.Z - r.Position.Z) / 35, 3, 7)
            end
            a:SetAttribute("SprintItem", item)
            a:SetAttribute("SprintUntil", now() + duration)
            notice(a, "涡轮启动 · 最高40")
        elseif item == "Shield" then
            a:SetAttribute("ShieldUntil", now() + 6)
            notice(a, "护盾已开启")
        elseif item == "Cleanse" then
            a:SetAttribute("SlowUntil", 0)
            a:SetAttribute("ImmuneUntil", now() + 3)
            pulse(r.Position - Vector3.new(0,2,0), Art.Colors.Cleanse, 5)
        elseif item == "Decoy" then
            a:SetAttribute("DecoyUntil", now() + 8)
            notice(a, "全息诱饵已部署")
        elseif item == "Vacuum" then
            a:SetAttribute("VacuumUntil", now() + 6)
            notice(a, "磁力拾取 · 范围16米")
        elseif item == "Spring" then
            local pad = Instance.new("Part", workspace)
            pad.Name = "SpringPad"
            pad.Shape = Enum.PartType.Cylinder
            pad.Size = Vector3.new(0.3, 5, 5)
            pad.Orientation = Vector3.new(0, 0, 90)
            pad.Position = r.Position - Vector3.new(0, 2.7, 3)
            pad.Anchored = true
            pad.CanCollide = false
            pad.Material = Enum.Material.Neon
            pad.Color = Color3.fromRGB(110, 255, 150)
            pad.CanQuery=false
            local art=Art.Create("Spring",pad)
            art:ScaleTo(1.6)
            art:PivotTo(CFrame.new(pad.Position+Vector3.new(0,1.2,0)))
            table.insert(traps, { Part = pad, Owner = a, Expires = now() + 10, Hit = {}, Spring = true })
        elseif item == "Smoke" then
            local cloud = Instance.new("Part", workspace)
            cloud.Name = "SmokeCloud"
            cloud.Shape = Enum.PartType.Ball
            cloud.Size = Vector3.new(10, 7, 10)
            cloud.Position = r.Position - Vector3.new(0, 0, 5)
            cloud.Anchored = true
            cloud.CanCollide = false
            cloud.CanTouch = false
            cloud.Color = Color3.fromRGB(100, 80, 135)
            cloud.Transparency = 0.55
            cloud.CanQuery=false
            for i=1,5 do
                local puff=Instance.new("Part",cloud)
                puff.Name="SmokePuff"
                puff.Shape=Enum.PartType.Ball
                puff.Size=Vector3.new(5,5,5)
                puff.CFrame=CFrame.new(cloud.Position+Vector3.new(math.cos(i)*3,math.sin(i*2),math.sin(i)*3))
                puff.Anchored=true
                puff.CanCollide=false
                puff.CanTouch=false
                puff.CanQuery=false
                puff.Color=Art.Colors.Smoke
                puff.Transparency=0.5
                game:GetService("TweenService"):Create(puff,TweenInfo.new(4),{
                    Position=puff.Position+Vector3.new(0,2,0),Size=Vector3.one*7,Transparency=1
                }):Play()
            end
            Debris:AddItem(cloud, 4)
        elseif item == "Shockwave" then
            pulse(r.Position - Vector3.new(0,2,0), Art.Colors.Shockwave, 10)
            for _, b in list do
                local _, _, br = rig(b)
                if (br.Position - r.Position).Magnitude < 10 and strike(b, 0.35) then
                    markImpact:Fire(b)
                    local delta = br.Position - r.Position
                    local dir = delta.Magnitude > 0.1 and delta.Unit or Vector3.new(1, 0, 0)
                    knock(b, dir * 18 + Vector3.new(0, 4, 0), 0.25)
                end
            end
        elseif item == "Trap" then
            local v = Instance.new("Part", workspace)
            v.Name = "SlowField"
            v.Anchored = true
            v.CanCollide = false
            v.CanTouch = false
            v.Shape = Enum.PartType.Cylinder
            v.Size = Vector3.new(0.2, 7, 7)
            v.Orientation = Vector3.new(0, 0, 90)
            v.Position = r.Position - Vector3.new(0, 2.6, 4)
            v.Color = Color3.fromRGB(255, 80, 180)
            v.Material = Enum.Material.Neon
            v.Transparency = 0.25
            v.CanQuery=false
            local art=Art.Create("Trap",v)
            art:ScaleTo(2.4)
            art:PivotTo(CFrame.new(v.Position+Vector3.new(0,0.7,0)))
            table.insert(traps, { Part = v, Owner = a, Expires = now() + 9, Hit = {} })
        elseif item == "EMP" then
            pulse(r.Position - Vector3.new(0,1,0), Art.Colors.EMP, 18)
            for _, b in list do
                if (model(b).HumanoidRootPart.Position - r.Position).Magnitude < 18 then
                    strike(b, 1.2)
                end
            end
        else
            local round = a:GetAttribute("RaceRound")
            local marked = target
            local delay = item == "Leader" and 1.8 or 1.2
            notice(
                marked,
                item == "Steal" and "道具将被夺取！可立即使用或开盾"
                    or "追踪警报！立即使用护盾"
            )
            marked:SetAttribute("IncomingItem", item)
            marked:SetAttribute("IncomingUntil", now() + delay)
            local orb = Instance.new("Part", workspace)
            orb.Name = "TrackingItem"
            orb.Shape = Enum.PartType.Ball
            orb.Size = Vector3.new(1, 1, 1)
            orb.Position = r.Position
            orb.Anchored = true
            orb.CanCollide = false
            orb.CanTouch = false
            orb.Material = Enum.Material.Neon
            orb.Color = Art.Colors[item]
            orb.CanQuery=false
            orb.Transparency=1
            local projectileArt=Art.Create(item,orb)
            projectileArt:ScaleTo(0.7)
            projectileArt:PivotTo(CFrame.new(r.Position))
            local a0 = Instance.new("Attachment", orb)
            a0.Position = Vector3.new(-0.3, 0, 0)
            local a1 = Instance.new("Attachment", orb)
            a1.Position = Vector3.new(0.3, 0, 0)
            local trail = Instance.new("Trail", orb)
            trail.Attachment0 = a0
            trail.Attachment1 = a1
            trail.Color = ColorSequence.new(orb.Color)
            trail.Lifetime = 0.3
            trail.LightEmission = 1
            local spark = Instance.new("ParticleEmitter", orb)
            spark.Texture = "rbxasset://textures/particles/sparkles_main.dds"
            spark.Color = ColorSequence.new(orb.Color)
            spark.Lifetime = NumberRange.new(0.2, 0.4)
            spark.Rate = 12
            spark.Speed = NumberRange.new(1, 2)
            spark.Size = NumberSequence.new(0.2)
            local elapsed = 0
            local conn
            conn = Run.Heartbeat:Connect(function(dt)
                local _, _, tr = rig(marked)
                elapsed += dt
                if tr then
                    orb.Position = orb.Position:Lerp(tr.Position, math.min(1, dt * 7))
                    local delta=tr.Position-orb.Position
                    local direction=delta.Magnitude>0.01 and delta.Unit or Vector3.zAxis
                    projectileArt:PivotTo(CFrame.lookAt(orb.Position,orb.Position+direction)*CFrame.Angles(-math.pi/2,0,0))
                end
                if elapsed >= delay or not tr then
                    conn:Disconnect()
                    orb:Destroy()
                    if
                        tr
                        and a.Parent
                        and marked.Parent
                        and same(a, marked)
                        and a:GetAttribute("RaceRound") == round
                    then
                        if (marked:GetAttribute("DecoyUntil") or 0) > now() then
                            marked:SetAttribute("DecoyUntil", 0)
                            notice(marked, "全息诱饵拦截了追踪攻击")
                            return
                        end
                        if item == "Steal" then
                            if
                                strike(marked, 0.25)
                                and marked:GetAttribute("HeldItem")
                                and #(actors[a].Inventory or {}) < 6
                            then
                                addItem(a, removeItem(marked))
                            end
                        else
                            strike(marked, item == "Leader" and 1.6 or 1.1)
                        end
                    end
                end
            end)
        end
    end

    local function update(t)
        for i = #traps, 1, -1 do
            local tr = traps[i]
            if t > tr.Expires or not tr.Owner.Parent then
                tr.Part:Destroy()
                table.remove(traps, i)
            else
                for a in actors do
                    local _, _, r = rig(a)
                    if
                        r
                        and active(a)
                        and (tr.Spring and a:GetAttribute("RaceRound") == tr.Owner:GetAttribute("RaceRound") or same(
                            tr.Owner,
                            a
                        ))
                        and not tr.Hit[a]
                        and math.abs(r.Position.X - tr.Part.Position.X) < 4
                        and math.abs(r.Position.Z - tr.Part.Position.Z) < 4
                        and r.Position.Y - tr.Part.Position.Y < 5
                    then
                        tr.Hit[a] = true
                        if tr.Spring then
                            r.AssemblyLinearVelocity =
                                Vector3.new(r.AssemblyLinearVelocity.X, 75, r.AssemblyLinearVelocity.Z)
                        else
                            strike(a, 1.2)
                        end
                    end
                end
            end
        end
    end
    local function clear()
        for _, tr in traps do
            tr.Part:Destroy()
        end
        table.clear(traps)
    end
    return { Use = use, Update = update, Clear = clear }
end
