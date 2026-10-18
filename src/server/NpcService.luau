-- Dependencies are supplied by Systems.server; requiring this module has no side effects.
return function(deps)
    local rig = deps.rig
    local active = deps.active
    local actors = deps.actors
    local bots = deps.bots
    local S = deps.S
    local C = deps.C
    local Motion = require(deps.S.SharedModules.MovementMath)
    local dress = deps.dress
    local map = deps.map
    local opponents = deps.opponents
    local punch = deps.punch
    local use = deps.use
    local syncBag = deps.syncBag
    local function makeBot(index, owner, difficulty, round)
        local source = assert(owner.Character, "NPC requires the participant avatar")
        local archivable = source.Archivable
        source.Archivable = true
        local bot = source:Clone()
        source.Archivable = archivable
        bot.Name = ({ "疾风", "霓虹", "幻影" })[index]
        bot:SetAttribute("Running", false)
        bot:SetAttribute("RaceRound", round)
        bot:SetAttribute("Outfit", index * 7)
        bot:SetAttribute("Skin", index + 2)
        bot:SetAttribute("Bot", true)
        bot:SetAttribute("BotIndex", index)
        local animations = {}
        local animate = bot:FindFirstChild("Animate")
        if animate then
            for _, name in { "idle", "walk", "run", "jump", "fall" } do
                local group = animate:FindFirstChild(name)
                local anim = group and group:FindFirstChildWhichIsA("Animation", true)
                if anim then
                    animations[name] = anim:Clone()
                end
            end
        end
        for _, v in bot:GetDescendants() do
            if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("Sound") then
                v:Destroy()
            elseif v:IsA("BasePart") then
                v.Anchored = false
                v.CollisionGroup = "RunnerVisual"
            end
        end
        local oldCollider = bot:FindFirstChild("RunnerCollider")
        if oldCollider then
            oldCollider:Destroy()
        end
        local r = bot.HumanoidRootPart
        local h = bot:FindFirstChildOfClass("Humanoid")
        h.Health = h.MaxHealth
        h.DisplayName = bot.Name
        h.AutoRotate = false
        h.UseJumpPower = true
        h.JumpPower = 60
        bot.PrimaryPart = r
        bot.Parent = bots
        bot:PivotTo(CFrame.new((index - 2) * 7, 4, -12))
        r:SetNetworkOwner(nil)
        local row = Instance.new("Folder", S.RaceState.Results)
        row.Name = "NPC" .. index
        row:SetAttribute("PlayerName", bot.Name)
        row:SetAttribute("State", "Countdown")
        row:SetAttribute("BotName", bot.Name)
        row:SetAttribute("Rank", 0)
        actors[bot] = {
            Picked = {},
            Walls = {},
            Items = {},
            Decisions = {},
            Bot = true,
            Difficulty = difficulty,
            Owner = owner,
            Stage = 1,
            Speed = 0,
            Lane = (index - 2) * 7,
            Row = row,
            Tracks = {},
            PrepTarget = Vector3.new((index - 2) * 7, 0, -12),
            Index = index,
        }
        local animator = h:FindFirstChildOfClass("Animator") or Instance.new("Animator", h)
        for name, anim in animations do
            anim.Parent = bot
            local ok, track = pcall(function()
                return animator:LoadAnimation(anim)
            end)
            if ok then
                track.Priority = name == "idle" and Enum.AnimationPriority.Idle
                    or Enum.AnimationPriority.Movement
                track.Looped = name ~= "jump"
                actors[bot].Tracks[name] = track
            end
        end
        dress(bot)
        return bot
    end
    local function clearBots()
        for _, b in bots:GetChildren() do
            actors[b] = nil
            b:Destroy()
        end
    end

    local function animate(st, h, r)
        local speed = Vector3.new(r.AssemblyLinearVelocity.X, 0, r.AssemblyLinearVelocity.Z).Magnitude
        local name = h.FloorMaterial == Enum.Material.Air
                and (r.AssemblyLinearVelocity.Y > 1 and "jump" or "fall")
            or speed > 15 and "run"
            or speed > 0.7 and "walk"
            or "idle"
        local track = st.Tracks[name] or st.Tracks.walk
        if track and st.Playing ~= track then
            if st.Playing then
                st.Playing:Stop(0.16)
            end
            track:Play(0.16)
            st.Playing = track
        end
        if track and (name == "run" or name == "walk") then
            track:AdjustSpeed(math.clamp(speed / 16, 0.4, 2))
        end
    end
    local function move(h, r, velocity, dt)
        h.WalkSpeed = velocity.Magnitude
        h:Move(velocity.Magnitude > 0.05 and velocity.Unit or Vector3.zero, false)
        if velocity.Magnitude > 1 then
            r.CFrame = CFrame.new(r.Position)
                * r.CFrame.Rotation:Lerp(CFrame.lookAt(Vector3.zero, velocity.Unit), 1 - math.exp(-dt * 12))
        end
    end
    local function update(a, st, dt, t)
        local c, h, r = rig(a)
        if not r then
            return
        end
        animate(st, h, r)
        if not active(a) then
            if S.RaceState:GetAttribute("Phase") == "Countdown" then
                if t > (st.PrepNext or 0) then
                    st.PrepNext = t + 1 + math.random()
                    st.PrepTarget = Vector3.new(math.random(-10, 10), 0, math.random(-22, -6))
                end
                local delta = st.PrepTarget - Vector3.new(r.Position.X, 0, r.Position.Z)
                move(h, r, delta.Magnitude > 1 and delta.Unit * 8 or Vector3.zero, dt)
            else
                h:Move(Vector3.zero)
            end
            return
        end
        local z = r.Position.Z
        if z >= st.Stage * 144 - 4 and st.Stage < 12 then
            st.Stage += 1
        end
        if r.Position.Y < -3 then
            r.CFrame = CFrame.new(st.Lane, 4, (st.Stage - 1) * 144)
            r.AssemblyLinearVelocity = Vector3.zero
            st.Speed = 0
            st.Decisions = {}
        end
        if
            r.Position.Y < 1.5
            and h.FloorMaterial ~= Enum.Material.Air
            and t - (st.RecoverJump or 0) > 0.5
        then
            st.RecoverJump = t
            h.Jump = true
            r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, 60, r.AssemblyLinearVelocity.Z)
        end
        local targetSpeed = ({ 22, 28, 32 })[st.Difficulty]
        local ownerRoot = st.Owner.Character and st.Owner.Character:FindFirstChild("HumanoidRootPart")
        if ownerRoot then
            targetSpeed = math.clamp(targetSpeed + (ownerRoot.Position.Z - z) / 100, 18, C.MaxSpeed)
        end
        if (a:GetAttribute("SprintUntil") or 0) > t then
            targetSpeed = 40
        end
        if (a:GetAttribute("SlowUntil") or 0) > t then
            targetSpeed *= 0.6
        end
        st.Speed = Motion.Approach(st.Speed, targetSpeed, C.Acceleration, dt)
        local lane = st.Lane
        for _, o in map.Hazards:GetChildren() do
            local d = o.Position.Z - z
            if d > 0 and d < st.Speed * 0.7 then
                if st.Decisions[o] == nil then
                    st.Decisions[o] = math.random() > ({ 0.3, 0.12, 0.03 })[st.Difficulty]
                end
                if st.Decisions[o] then
                    if o.Size.X < 20 then
                        lane = o.Position.X <= 0 and 11 or -11
                    end
                    if
                        d < st.Speed * 0.3
                        and math.abs(r.Position.X - o.Position.X) < o.Size.X / 2 + 1
                        and h.FloorMaterial ~= Enum.Material.Air
                    then
                        if o.Name == "Slide" then
                            a:SetAttribute("SlideUntil", t + 0.7)
                        else
                            h.Jump = true
                            r.AssemblyLinearVelocity = Vector3.new(0, 60, st.Speed)
                            a:SetAttribute("LastJumpAt", t)
                        end
                    end
                elseif d < 2 and math.abs(r.Position.X - o.Position.X) < o.Size.X / 2 then
                    a:SetAttribute("SlowUntil", t + 0.8)
                end
            end
        end
        for _, gap in map.Gaps:GetChildren() do
            local d = gap.Position.Z - gap.Size.Z / 2 - z
            if d > 0 and d < math.max(4, st.Speed * 0.2) and h.FloorMaterial ~= Enum.Material.Air then
                h.Jump = true
                r.AssemblyLinearVelocity = Vector3.new(0, 60, st.Speed)
                a:SetAttribute("LastJumpAt", t)
            end
        end
        -- Seek a nearby item, defend against warnings, and attack according to difficulty.
        if not a:GetAttribute("HeldItem") and lane == st.Lane then
            for _, v in map.Pickups:GetChildren() do
                if v.Position.Z - z > 0 and v.Position.Z - z < 22 then
                    lane = v.Position.X
                    break
                end
            end
        end
        local cx = (a:GetAttribute("ContactUntil") or 0) > t and (a:GetAttribute("ContactX") or 0) or 0
        local cs = (a:GetAttribute("ContactUntil") or 0) > t and (a:GetAttribute("ContactScale") or 1) or 1
        local velocity =
            Vector3.new(math.clamp((lane - r.Position.X) * 4, -17, 17) * cs + cx, 0, st.Speed * cs)
        local x = Motion.Step(
            st.Move and st.Move.X or 0,
            st.Speed,
            velocity.X,
            st.Speed,
            dt,
            C.Acceleration,
            C.Braking
        )
        st.Move = Vector3.new(x, 0, velocity.Z)
        move(h, r, st.Move, dt)
        if
            t - (st.AIUse or 0) > ({ 6, 4, 2.5 })[st.Difficulty]
            or (a:GetAttribute("IncomingUntil") or 0) > t
        then
            if (a:GetAttribute("IncomingUntil") or 0) > t then
                for i, v in st.Inventory or {} do
                    if v == "Shield" or v == "Decoy" then
                        st.Selected = i
                        syncBag(a)
                        break
                    end
                end
            end
            st.AIUse = t
            use(a)
        end
        if (a:GetAttribute("StaggerUntil") or 0) > t then
            h:Move(Vector3.zero)
            h.WalkSpeed = 0
        end
        if t - (st.PunchThink or 0) > ({ 1.8, 1.1, 0.7 })[st.Difficulty] then
            st.PunchThink = t
            for _, b in opponents(a) do
                local _, _, br = rig(b)
                if (br.Position - r.Position).Magnitude < 4.5 then
                    punch(a)
                    break
                end
            end
        end
        -- A missed jump is recoverable; solid obstacles must never trap a bot forever.
        if
            r.AssemblyLinearVelocity.Magnitude < 2
            and st.Speed > 10
            and h.FloorMaterial ~= Enum.Material.Air
        then
            st.Stuck = (st.Stuck or 0) + dt
            if st.Stuck > 0.45 then
                h.Jump = true
                st.Lane = r.Position.X > 0 and -11 or 11
                st.Stuck = 0
            end
        else
            st.Stuck = 0
        end
        local finish = map.Finish
        if z >= finish.Position.Z - finish.Size.Z / 2 - 1 and st.Stage == 12 then
            a:SetAttribute("Finished", true)
            a:SetAttribute("Running", false)
            local rank = 1
            for _, row in S.RaceState.Results:GetChildren() do
                if row:GetAttribute("State") == "Finished" then
                    rank += 1
                end
            end
            st.Row:SetAttribute("State", "Finished")
            st.Row:SetAttribute("Rank", rank)
            st.Row:SetAttribute("Time", t - S.RaceState:GetAttribute("StartedAt"))
            h:Move(Vector3.zero)
        end
    end
    return { Create = makeBot, Clear = clearBots, Update = update }
end
