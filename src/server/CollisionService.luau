-- Dependencies are supplied by Systems.server; requiring this module has no side effects.
return function(deps)
    local rig = deps.rig
    local active = deps.active
    local now = deps.now
    local map = deps.map
    local actors = deps.actors
    local markImpact = deps.markImpact
    local Debris = deps.Debris
    -- One stable body collider; animated limbs and cosmetics cannot snag on geometry.
    local function bodyCollider(a)
        local c, h, r = rig(a)
        if not r then
            return
        end
        local body = c:FindFirstChild("RunnerCollider")
        if not body then
            body = Instance.new("Part")
            body.Name = "RunnerCollider"
            body.Transparency = 1
            body.Size = Vector3.new(2, 5, 2)
            body.Massless = true
            body.CanTouch = false
            body.CustomPhysicalProperties = PhysicalProperties.new(1, 0.05, 0, 100, 100)
            body.CFrame = r.CFrame * CFrame.new(0, -0.4, 0)
            local w = Instance.new("Weld", body)
            w.Name = "BodyWeld"
            w.Part0 = r
            w.Part1 = body
            w.C0 = CFrame.new(0, -0.4, 0)
            body.Parent = c
            if a:GetAttribute("Bot") then
                r:SetNetworkOwner(nil)
            end
        end
        body.CollisionGroup = active(a) and "ObbyPlayers" or "Spectators"
        for _, v in c:GetDescendants() do
            if v:IsA("BasePart") and v ~= body then
                v.CollisionGroup = "RunnerVisual"
            end
        end
        local slide = (a:GetAttribute("SlideUntil") or 0) > now()
        if not slide and body.Size.Y < 2 then
            local params = OverlapParams.new()
            params.FilterType = Enum.RaycastFilterType.Include
            params.FilterDescendantsInstances = { map.Hazards, map.Platforms }
            params.RespectCanCollide = true
            if
                #workspace:GetPartBoundsInBox(
                    r.CFrame * CFrame.new(0, 1, 0),
                    Vector3.new(1.9, 2.8, 1.9),
                    params
                ) > 0
            then
                slide = true
                a:SetAttribute("SlideUntil", now() + 0.15)
            end
        end
        local size = slide and Vector3.new(2, 1.6, 2) or Vector3.new(2, 5, 2)
        if body.Size ~= size then
            body.Size = size
            body.BodyWeld.C0 = CFrame.new(0, slide and -2.1 or -0.4, 0)
        end
    end
    local function knock(a, delta, duration)
        local _, _, r = rig(a)
        if not r then
            return
        end
        markImpact:Fire(a)
        a:SetAttribute("StaggerUntil", now() + duration)
        if r.Anchored then
            return
        end
        r:SetNetworkOwner(nil)
        r:ApplyImpulse(delta * r.AssemblyMass)
        if delta.Y > 0 then
            local old = r:FindFirstChild("HitRecoil")
            if old then
                old:Destroy()
            end
            local attachment = Instance.new("Attachment", r)
            local recoil = Instance.new("LinearVelocity")
            recoil.Name = "HitRecoil"
            recoil.Attachment0 = attachment
            recoil.RelativeTo = Enum.ActuatorRelativeTo.World
            recoil.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
            recoil.VectorVelocity = Vector3.new(delta.X, math.min(delta.Y, 22), delta.Z)
            recoil.ForceLimitsEnabled = true
            recoil.MaxForce = r.AssemblyMass * 1200
            recoil.Parent = r
            Debris:AddItem(recoil, 0.24)
            Debris:AddItem(attachment, 0.26)
        end
        local untilTime = now() + duration
        a:SetAttribute("PhysicsOwnedUntil", untilTime)
        if a:IsA("Player") then
            task.delay(duration + 0.08, function()
                if r.Parent and (a:GetAttribute("PhysicsOwnedUntil") or 0) <= untilTime then
                    r:SetNetworkOwnershipAuto()
                end
            end)
        end
    end
    local contacts = setmetatable({}, { __mode = "k" })
    local function update(dt)
        local t = now()
        for a in actors do
            bodyCollider(a)
        end
        local live = {}
        for a in actors do
            if active(a) then
                local _, _, r = rig(a)
                if r then
                    table.insert(live, { Actor = a, Root = r })
                end
            end
        end
        for i = 1, #live do
            for j = i + 1, #live do
                local aa, bb = live[i], live[j]
                local a, b = aa.Actor, bb.Actor
                local ar, br = aa.Root, bb.Root
                contacts[a] = contacts[a] or setmetatable({}, { __mode = "k" })
                local d = br.Position - ar.Position
                local horizontal = Vector3.new(d.X, 0, d.Z)
                local touching = a:GetAttribute("RaceRound") == b:GetAttribute("RaceRound")
                    and math.abs(d.Y) < 3
                    and horizontal.Magnitude < 2.8
                    and t > (a:GetAttribute("ContactProtectedUntil") or 0)
                    and t > (b:GetAttribute("ContactProtectedUntil") or 0)
                contacts[b] = contacts[b] or setmetatable({}, { __mode = "k" })
                if not touching then
                    contacts[a][b] = nil
                    contacts[b][a] = nil
                elseif
                    not contacts[a][b]
                    and t - (actors[a].ContactAt or 0) > 0.8
                    and t - (actors[b].ContactAt or 0) > 0.8
                then
                    contacts[a][b] = true
                    contacts[b][a] = true
                    actors[a].ContactAt = t
                    actors[b].ContactAt = t
                    local normal = horizontal.Magnitude > 0.01 and horizontal.Unit or Vector3.xAxis
                    local av = actors[a].PreviousVelocity or ar.AssemblyLinearVelocity
                    local bv = actors[b].PreviousVelocity or br.AssemblyLinearVelocity
                    local closing = math.max(0, (av - bv):Dot(normal))
                    if closing > 3 then
                        -- The engine resolves solid contact; a small equal/opposite impulse adds readable recoil.
                        local impulse = math.min(closing * 0.45, 14)
                            / (1 / ar.AssemblyMass + 1 / br.AssemblyMass)
                        knock(a, -normal * (impulse / ar.AssemblyMass), 0.25)
                        knock(b, normal * (impulse / br.AssemblyMass), 0.25)
                        for _, actor in { a, b } do
                            actor:SetAttribute("ContactUntil", t + 0.45)
                            actor:SetAttribute("ContactScale", math.clamp(1 - closing / 90, 0.65, 0.95))
                            actor:SetAttribute("ContactX", 0)
                        end
                    end
                end
            end
        end
        for _, entry in live do
            actors[entry.Actor].PreviousVelocity = entry.Root.AssemblyLinearVelocity
        end
    end

    return { Update = update, Knock = knock }
end
