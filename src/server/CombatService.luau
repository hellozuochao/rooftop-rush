-- Dependencies are supplied by Systems.server; requiring this module has no side effects.
return function(deps)
    local C = deps.C
    local rig = deps.rig
    local active = deps.active
    local now = deps.now
    local actors = deps.actors
    local model = deps.model
    local opponents = deps.opponents
    local notice = deps.notice
    local effect = deps.effect
    local knock = deps.knock
    local function strike(a, duration)
        if not active(a) then
            return false
        end
        if (a:GetAttribute("ShieldUntil") or 0) > now() then
            a:SetAttribute("ShieldUntil", 0)
            notice(a, "护盾抵挡了攻击")
            return false
        end
        if (a:GetAttribute("ImmuneUntil") or 0) > now() then
            return false
        end
        a:SetAttribute("SlowUntil", now() + duration)
        a:SetAttribute("ImmuneUntil", now() + duration + 2)
        notice(a, "受到干扰 · 短暂保护中")
        local _, _, r = rig(a)
        if r then
            effect(r.Position, Color3.fromRGB(245, 80, 160), 4)
        end
        return true
    end
    local function punch(a)
        local st = actors[a]
        local _, _, r = rig(a)
        local t = now()
        if not st or not r or not active(a) or t - (st.AttackAt or -math.huge) < C.Rules.AttackInterval then
            return
        end
        st.AttackAt = t -- One swing at a time; no cooldown or charge resource.
        a:SetAttribute("PunchUntil", t + 0.32)
        local best, nearest = nil, C.Rules.PunchRange
        for _, b in opponents(a) do
            local bc, _, br = rig(b)
            local d = br.Position - r.Position
            local flat = Vector3.new(d.X, 0, d.Z)
            if
                d.Magnitude < nearest
                and flat.Magnitude > 0.05
                and r.CFrame.LookVector:Dot(flat.Unit) > 0.25
            then
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = { model(a) }
                params.RespectCanCollide = true
                local hit = workspace:Raycast(r.Position, d, params)
                if not hit or hit.Instance:IsDescendantOf(bc) then
                    best = b
                    nearest = d.Magnitude
                end
            end
        end
        if not best then
            notice(a, "攻击挥空 · 靠近并面向对手")
            return
        end
        if
            (best:GetAttribute("ContactProtectedUntil") or 0) > t or not strike(best, C.Rules.PunchSlowdown)
        then
            return
        end
        local _, _, br = rig(best)
        local d = br.Position - r.Position
        local direction = Vector3.new(d.X, 0, d.Z).Unit
        knock(best, direction * 28 + Vector3.new(0, 22, 0), C.Rules.PunchRecovery)
        notice(a, "攻击命中")
        notice(best, "被攻击击退 · 短暂减速")
    end

    return { Strike = strike, Punch = punch }
end
