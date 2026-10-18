local Module = {}
function Module.Start()
    local P = game:GetService("Players")
    local S = game:GetService("ReplicatedStorage")
    local Run = game:GetService("RunService")
    local map = workspace:WaitForChild("NeonObby")
    local state = Instance.new("Folder", S)
    state.Name = "RaceState"
    local rows = Instance.new("Folder", state)
    rows.Name = "Results"
    local remote = Instance.new("RemoteEvent", S)
    remote.Name = "RaceReady"
    local startRequest = Instance.new("BindableEvent", S)
    startRequest.Name = "RoomStartRequest"
    local order, ready, members, cooldown = {}, {}, {}, {}
    local phase, round, deadline = "Waiting", 0, 0
    state:SetAttribute("Mode", "Solo")
    state:SetAttribute("Difficulty", 2)
    state:SetAttribute("Round", 0)
    local function now()
        return workspace:GetServerTimeNow()
    end
    local function notice(p, t)
        p:SetAttribute("ActionNotice", t)
        p:SetAttribute("ActionNoticeUntil", now() + 4)
    end
    local function host()
        return order[1]
    end
    local function setPhase(v, seconds)
        phase = v
        deadline = now() + (seconds or 0)
        state:SetAttribute("Phase", v)
        state:SetAttribute("Deadline", deadline)
    end
    local function counts()
        local n = 0
        for p in ready do
            if p.Parent then
                n += 1
            end
        end
        state:SetAttribute("Count", n)
    end
    local function lobby(p)
        p:SetAttribute("Running", false)
        p:SetAttribute("RaceStatus", "Waiting")
        local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if r then
            r.Anchored = false
            r.AssemblyLinearVelocity = Vector3.zero
            p.Character:PivotTo(CFrame.new(0, 4, -18))
        end
    end
    local function finishRoom()
        for p in members do
            if p.Parent then
                if p:GetAttribute("RaceStatus") == "Racing" then
                    p:SetAttribute("RaceStatus", "Timeout")
                end
                p:SetAttribute("Running", false)
            end
        end
        for _, row in rows:GetChildren() do
            if row:GetAttribute("State") == "Racing" then
                row:SetAttribute("State", "Timeout")
            end
        end
        local stop = S:FindFirstChild("StopBots")
        if stop then
            stop:Fire()
        end
        members = {}
        setPhase("Waiting")
        for _, p in P:GetPlayers() do
            lobby(p)
        end
    end
    local function addRow(p)
        local row = Instance.new("Folder", rows)
        row.Name = tostring(p.UserId)
        row:SetAttribute("PlayerName", p.DisplayName)
        row:SetAttribute("State", "Countdown")
        row:SetAttribute("UserId", p.UserId)
        row:SetAttribute("Rank", 0)
        members[p] = row
    end
    local function begin(p)
        if p ~= host() then
            notice(p, "只有房主可以开始")
            return
        end
        if phase ~= "Waiting" then
            notice(p, "本场进行中，准备状态用于下一场")
            return
        end
        local mode = state:GetAttribute("Mode")
        local selected = { p }
        if mode == "Multi" then
            for _, q in order do
                if q ~= p and ready[q] then
                    table.insert(selected, q)
                end
            end
            if #selected < 2 then
                notice(p, "多人模式至少需要另一位已准备玩家")
                return
            end
        end
        for _, q in selected do
            local h = q.Character and q.Character:FindFirstChildOfClass("Humanoid")
            if not h or h.Health <= 0 then
                notice(p, "等待参赛玩家复活后再开始")
                return
            end
        end
        rows:ClearAllChildren()
        members = {}
        round += 1
        state:SetAttribute("Round", round)
        setPhase("Countdown", 5)
        for i, q in selected do
            ready[q] = nil
            q:SetAttribute("Ready", false)
            q:SetAttribute("PlayMode", mode)
            q:SetAttribute("Finished", false)
            q:SetAttribute("FinishTime", nil)
            q.leaderstats.Stage.Value = 1
            q.leaderstats.Deaths.Value = 0
            q.RespawnLocation = map.Checkpoints["1"]
            q:SetAttribute("StartedAt", now())
            q:SetAttribute("RaceRound", round)
            q:SetAttribute("RaceStatus", "Countdown")
            q:SetAttribute("StartSlot", i)
            addRow(q)
            q.Character:PivotTo(
                CFrame.lookAt(
                    Vector3.new(((i - 1) % 5 - 2) * 4, 4, -8 - math.floor((i - 1) / 5) * 4),
                    Vector3.new(0, 4, 20)
                )
            )
        end
        if mode == "Solo" then
            S:WaitForChild("SpawnBots"):Invoke(p, state:GetAttribute("Difficulty"), round)
        end
        counts()
    end
    local function command(p, kind, value)
        if now() - (cooldown[p] or 0) < 0.25 then
            return
        end
        cooldown[p] = now()
        if kind == "Start" then
            begin(p)
        elseif
            kind == "Mode"
            and p == host()
            and phase == "Waiting"
            and (value == "Solo" or value == "Multi")
        then
            state:SetAttribute("Mode", value)
        elseif
            kind == "Difficulty"
            and p == host()
            and phase == "Waiting"
            and type(value) == "number"
            and value % 1 == 0
            and value >= 1
            and value <= 3
        then
            state:SetAttribute("Difficulty", value)
        elseif kind == "End" and p == host() then
            finishRoom()
            notice(p, "本场已结束，可组织下一场")
        elseif kind == "Ready" or kind == nil then
            ready[p] = not ready[p] or nil
            p:SetAttribute("Ready", ready[p] == true)
            counts()
            notice(
                p,
                ready[p] and "已准备 · 房主下次开局时加入多人比赛" or "已取消准备"
            )
        elseif kind == "Return" then
            if members[p] then
                members[p]:SetAttribute("State", "Withdrawn")
                members[p] = nil
            end
            lobby(p)
        end
    end
    remote.OnServerEvent:Connect(command)
    startRequest.Event:Connect(function(p)
        command(p, "Start")
    end)
    S:WaitForChild("RestartRun").OnServerEvent:Connect(function(p)
        command(p, "Return")
    end)
    local platform = Instance.new("Part", map)
    platform.Name = "RaceLobby"
    platform.Size = Vector3.new(28, 2, 32)
    platform.Position = Vector3.new(0, -1, -16)
    platform.Anchored = true
    platform.Color = Color3.fromRGB(32, 45, 60)
    local function joined(p)
        table.insert(order, p)
        state:SetAttribute("HostId", host().UserId)
        p:SetAttribute("Ready", false)
        p:SetAttribute("RaceStatus", "Waiting")
        p.CharacterAdded:Connect(function(c)
            local r = c:WaitForChild("HumanoidRootPart")
            task.wait(0.15)
            if not members[p] then
                lobby(p)
            end
        end)
        p:GetAttributeChangedSignal("Finished"):Connect(function()
            local row = members[p]
            if phase ~= "Racing" or not row or not p:GetAttribute("Finished") then
                return
            end
            local rank = 1
            for _, v in rows:GetChildren() do
                if v:GetAttribute("State") == "Finished" then
                    rank += 1
                end
            end
            row:SetAttribute("State", "Finished")
            row:SetAttribute("Rank", rank)
            row:SetAttribute("Time", now() - (state:GetAttribute("StartedAt") or now()))
            p:SetAttribute("RaceStatus", "Finished")
        end)
    end
    P.PlayerAdded:Connect(joined)
    for _, p in P:GetPlayers() do
        joined(p)
    end
    P.PlayerRemoving:Connect(function(p)
        ready[p] = nil
        if members[p] then
            members[p]:SetAttribute("State", "Withdrawn")
            members[p] = nil
        end
        table.remove(order, table.find(order, p))
        cooldown[p] = nil
        state:SetAttribute("HostId", host() and host().UserId or 0)
        counts()
        if not next(members) and phase ~= "Waiting" then
            finishRoom()
        end
    end)
    setPhase("Waiting")
    counts()
    -- Visible boundary plus authoritative containment; no per-frame spawn pinning.
    for _, edge in
        {
            { Vector3.new(-14, 1, -16), Vector3.new(0.2, 2, 32) },
            { Vector3.new(14, 1, -16), Vector3.new(0.2, 2, 32) },
            { Vector3.new(0, 1, -32), Vector3.new(28, 2, 0.2) },
        }
    do
        local rail = Instance.new("Part", map)
        rail.Name = "PreparationRail"
        rail.Anchored = true
        rail.Size = edge[2]
        rail.Position = edge[1]
        rail.Material = Enum.Material.Neon
        rail.Color = Color3.fromRGB(55, 210, 225)
        rail.Transparency = 0.45
    end
    local gate = Instance.new("Part", map)
    gate.Name = "StartBoundary"
    gate.Anchored = true
    gate.CanCollide = false
    gate.Size = Vector3.new(28, 3, 0.2)
    gate.Position = Vector3.new(0, 1.5, -1.5)
    gate.Color = Color3.fromRGB(255, 195, 65)
    gate.Material = Enum.Material.Neon
    local function contain(c)
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if not r then
            return
        end
        local v = r.Position
        local pos =
            Vector3.new(math.clamp(v.X, -12.5, 12.5), v.Y < 1 and 4 or v.Y, math.clamp(v.Z, -29, -2.5))
        if (v - pos).Magnitude > 0.01 then
            r.CFrame = CFrame.new(pos) * r.CFrame.Rotation
            local velocity = r.AssemblyLinearVelocity
            r.AssemblyLinearVelocity = Vector3.new(
                v.X ~= pos.X and 0 or velocity.X,
                v.Y ~= pos.Y and 0 or velocity.Y,
                v.Z ~= pos.Z and 0 or velocity.Z
            )
        end
    end
    Run.Heartbeat:Connect(function()
        gate.Transparency = phase == "Countdown" and 0.45 or 1
        for _, p in P:GetPlayers() do
            if p:GetAttribute("RaceStatus") == "Waiting" or p:GetAttribute("RaceStatus") == "Countdown" then
                contain(p.Character)
            end
        end
        if phase == "Countdown" then
            local bots = workspace:FindFirstChild("RacersNPC")
            if bots then
                for _, bot in bots:GetChildren() do
                    contain(bot)
                end
            end
        end
        if phase == "Countdown" then
            if now() >= deadline then
                state:SetAttribute("StartedAt", now())
                setPhase("Racing", 240)
                for p, row in members do
                    p:SetAttribute("StartedAt", now())
                    p:SetAttribute("RaceStatus", "Racing")
                    row:SetAttribute("State", "Racing")
                end
                local bots = workspace:FindFirstChild("RacersNPC")
                if bots then
                    for _, bot in bots:GetChildren() do
                        bot:SetAttribute("Running", true)
                        local row = rows:FindFirstChild("NPC" .. tostring(bot:GetAttribute("BotIndex")))
                        if row then
                            row:SetAttribute("State", "Racing")
                        end
                    end
                end
            end
        elseif phase == "Racing" then
            local alive = false
            for _, row in rows:GetChildren() do
                if row:GetAttribute("State") == "Racing" then
                    alive = true
                end
            end
            if not alive or now() >= deadline then
                finishRoom()
            end
        end
    end)
end
return Module
