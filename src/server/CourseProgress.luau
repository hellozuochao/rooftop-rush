local Module = {}
function Module.Start()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local map = workspace:WaitForChild("NeonObby")
    map.Finish.CanCollide = false -- Finish paint is a trigger, never a physical step.
    local checkpoints = map:WaitForChild("Checkpoints")
    local total = #checkpoints:GetChildren()
    game:GetService("ReplicatedStorage"):SetAttribute("TotalStages", total)
    local Physics = game:GetService("PhysicsService")
    pcall(function()
        Physics:RegisterCollisionGroup("ObbyPlayers")
    end)
    Physics:CollisionGroupSetCollidable("ObbyPlayers", "ObbyPlayers", true)
    pcall(function()
        Physics:RegisterCollisionGroup("Spectators")
    end)
    Physics:CollisionGroupSetCollidable("Spectators", "ObbyPlayers", false)
    Physics:CollisionGroupSetCollidable("Spectators", "Spectators", false)
    pcall(function()
        Physics:RegisterCollisionGroup("RunnerVisual")
    end)
    pcall(function()
        Physics:RegisterCollisionGroup("RunnerObstacle")
    end)
    for _, part in map.Hazards:GetChildren() do
        part.CollisionGroup = "RunnerObstacle"
        part.CanCollide = true
    end
    for _, part in map.RouteNodes:GetChildren() do
        part.CanCollide = true
    end
    for _, group in { "RunnerObstacle", "ObbyPlayers", "Spectators", "RunnerVisual" } do
        Physics:CollisionGroupSetCollidable("RunnerVisual", group, false)
    end
    local function classifyRunner(part, running)
        if part:IsA("BasePart") then
            part.CollisionGroup = part.Name == "RunnerCollider"
                    and (running and "ObbyPlayers" or "Spectators")
                or "RunnerVisual"
        end
    end
    local storeOK, Records = pcall(function()
        return game:GetService("DataStoreService"):GetDataStore("SkylineSample_v10")
    end)
    if not storeOK then
        Records = nil
    end
    local pending, saving = {}, {}
    local hitUntil, cleared = {}, {}
    -- Impact recovery is server-owned and applies only to a subsequent fall in this round.
    local safeGround, impactRecovery, pendingRecovery = {}, {}, {}
    local impactEvent = Instance.new("BindableEvent", game:GetService("ReplicatedStorage"))
    impactEvent.Name = "MarkImpactRespawn"
    local groundParams = RaycastParams.new()
    groundParams.FilterType = Enum.RaycastFilterType.Include
    groundParams.FilterDescendantsInstances = { map.Platforms, map.Checkpoints }
    local function groundPoint(root)
        local hit = workspace:Raycast(root.Position, Vector3.new(0, -8, 0), groundParams)
        if not hit or hit.Normal.Y < 0.9 or not hit.Instance.CanCollide then
            return
        end
        local part = hit.Instance
        local localPoint = part.CFrame:PointToObjectSpace(hit.Position)
        local margin = math.min(2, part.Size.X / 2 - 0.2, part.Size.Z / 2 - 0.2)
        if margin <= 0 then
            return
        end
        localPoint = Vector3.new(
            math.clamp(localPoint.X, -part.Size.X / 2 + margin, part.Size.X / 2 - margin),
            part.Size.Y / 2,
            math.clamp(localPoint.Z, -part.Size.Z / 2 + margin, part.Size.Z / 2 - margin)
        )
        return part.CFrame:PointToWorldSpace(localPoint) + Vector3.new(0, 3.5, 0)
    end
    impactEvent.Event:Connect(function(p)
        if not p:IsA("Player") or not p:GetAttribute("Running") then
            return
        end
        local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if not root then
            return
        end
        local t = workspace:GetServerTimeNow()
        local point = groundPoint(root)
        local previous = safeGround[p]
        if
            not point
            and previous
            and t - previous.Time < 2
            and (previous.Position - root.Position).Magnitude < 25
        then
            point = previous.Position
        end
        if point then
            impactRecovery[p] = { Position = point, Until = t + 4, Round = p:GetAttribute("RaceRound") }
        end
    end)
    local function saveRecord(player)
        if saving[player] or not pending[player] then
            return
        end
        saving[player] = true
        local candidate = pending[player]
        local ok, result = pcall(function()
            return Records:UpdateAsync(tostring(player.UserId), function(old)
                old = type(old) == "table" and old or {}
                return {
                    Time = math.min(tonumber(old.Time) or math.huge, candidate.Time),
                    Deaths = math.min(tonumber(old.Deaths) or math.huge, candidate.Deaths),
                }
            end)
        end)
        saving[player] = nil
        if ok then
            player:SetAttribute(
                "BestTime",
                math.min(player:GetAttribute("BestTime") or math.huge, result.Time)
            )
            player:SetAttribute(
                "BestDeaths",
                math.min(player:GetAttribute("BestDeaths") or math.huge, result.Deaths)
            )
            if pending[player] == candidate then
                pending[player] = nil
                player:SetAttribute("RecordStatus", "Saved")
            end
        else
            player:SetAttribute("RecordStatus", "Pending")
        end
    end
    Players.RespawnTime = 1.5

    local function getPlayer(hit)
        if hit:FindFirstAncestorOfClass("Accessory") or hit:FindFirstAncestorOfClass("Tool") then
            return
        end
        local model = hit:FindFirstAncestorOfClass("Model")
        local humanoid = model and model:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then
            return Players:GetPlayerFromCharacter(model)
        end
    end

    local function setup(player)
        player:GetAttributeChangedSignal("StartedAt"):Connect(function()
            hitUntil[player] = {}
            cleared[player] = {}
            safeGround[player] = nil
            impactRecovery[player] = nil
            pendingRecovery[player] = nil
        end)
        player:SetAttribute("RecordStatus", "Loading")
        task.spawn(function()
            local ok, data = pcall(function()
                return Records:GetAsync(tostring(player.UserId))
            end)
            if not player.Parent then
                return
            end
            if ok and type(data) == "table" then
                if tonumber(data.Time) then
                    player:SetAttribute(
                        "BestTime",
                        math.min(player:GetAttribute("BestTime") or math.huge, data.Time)
                    )
                end
                if tonumber(data.Deaths) then
                    player:SetAttribute(
                        "BestDeaths",
                        math.min(player:GetAttribute("BestDeaths") or math.huge, data.Deaths)
                    )
                end
            end
            if not pending[player] then
                player:SetAttribute("RecordStatus", ok and "Saved" or "Unavailable")
            end
        end)
        local stats = Instance.new("Folder")
        stats.Name = "leaderstats"
        stats.Parent = player
        local stage = Instance.new("IntValue")
        stage.Name = "Stage"
        stage.Value = 1
        stage.Parent = stats
        local deaths = Instance.new("IntValue")
        deaths.Name = "Deaths"
        deaths.Parent = stats
        player.RespawnLocation = checkpoints:FindFirstChild("1")
        player:SetAttribute("StartedAt", workspace:GetServerTimeNow())
        player:SetAttribute("Finished", false)
        player:SetAttribute("Running", false)
        player:GetAttributeChangedSignal("RaceStatus"):Connect(function()
            player:SetAttribute("Running", player:GetAttribute("RaceStatus") == "Racing")
            if player.Character then
                for _, part in player.Character:GetDescendants() do
                    classifyRunner(part, player:GetAttribute("Running"))
                end
            end
        end)
        player.CharacterAdded:Connect(function(character)
            local function classify(part)
                classifyRunner(part, player:GetAttribute("Running"))
            end
            for _, part in character:GetDescendants() do
                classify(part)
            end
            character.DescendantAdded:Connect(classify)
            local root = character:WaitForChild("HumanoidRootPart")
            local spawn = player.RespawnLocation
            if spawn then
                local recovery = pendingRecovery[player]
                pendingRecovery[player] = nil
                local position = spawn.Position + Vector3.new(0, 4, 0)
                if
                    recovery
                    and player:GetAttribute("Running")
                    and recovery.Round == player:GetAttribute("RaceRound")
                then
                    position = recovery.Position
                    player:SetAttribute("ImmuneUntil", workspace:GetServerTimeNow() + 2)
                    player:SetAttribute("ContactProtectedUntil", workspace:GetServerTimeNow() + 2)
                    player:SetAttribute("SlowUntil", 0)
                    player:SetAttribute("ContactUntil", 0)
                    player:SetAttribute("ActionNotice", "被撞跌落 · 已回到碰撞附近")
                    player:SetAttribute("ActionNoticeUntil", workspace:GetServerTimeNow() + 3)
                end
                root.AssemblyLinearVelocity = Vector3.zero
                character:PivotTo(CFrame.lookAt(position, position + Vector3.new(0, 0, 1)))
                if
                    recovery
                    and player:GetAttribute("Running")
                    and recovery.Round == player:GetAttribute("RaceRound")
                then
                    task.delay(0.3, function()
                        if
                            player.Character == character
                            and root.Parent
                            and player:GetAttribute("Running")
                            and recovery.Round == player:GetAttribute("RaceRound")
                        then
                            root:SetNetworkOwner(nil)
                            character:PivotTo(CFrame.lookAt(position, position + Vector3.new(0, 0, 1)))
                            root.AssemblyLinearVelocity = Vector3.zero
                            task.delay(0.3, function()
                                if root.Parent then
                                    root:SetNetworkOwnershipAuto()
                                end
                            end)
                        end
                    end)
                end
            end
            local hum = character:WaitForChild("Humanoid")
            hum.WalkSpeed = 20
            hum.UseJumpPower = true
            hum.JumpPower = 60
            hum.Died:Connect(function()
                deaths.Value += 1
            end)
        end)
    end
    Players.PlayerAdded:Connect(setup)
    for _, player in Players:GetPlayers() do
        setup(player)
    end

    for _, checkpoint in checkpoints:GetChildren() do
        local index = tonumber(checkpoint.Name)
        checkpoint.Touched:Connect(function(hit)
            local player = getPlayer(hit)
            if not player then
                return
            end
            local stage = player.leaderstats.Stage
            if index == stage.Value + 1 then
                stage.Value = index
                player.RespawnLocation = checkpoint
            end
        end)
    end
    map.Finish.Touched:Connect(function(hit)
        local player = getPlayer(hit)
        if not player or player.leaderstats.Stage.Value ~= total or player:GetAttribute("Finished") then
            return
        end
        player:SetAttribute("FinishTime", workspace:GetServerTimeNow() - player:GetAttribute("StartedAt"))
        local elapsed = player:GetAttribute("FinishTime")
        local best = player:GetAttribute("BestTime")
        player:SetAttribute("Improvement", best and best - elapsed or nil)
        player:SetAttribute("NewBest", not best or elapsed < best)
        player:SetAttribute("BestTime", math.min(best or math.huge, elapsed))
        player:SetAttribute(
            "BestDeaths",
            math.min(player:GetAttribute("BestDeaths") or math.huge, player.leaderstats.Deaths.Value)
        )
        pending[player] =
            { Time = player:GetAttribute("BestTime"), Deaths = player:GetAttribute("BestDeaths") }
        player:SetAttribute("RecordStatus", "Pending")
        player:SetAttribute("Running", false)
        player:SetAttribute("Finished", true)
        task.spawn(saveRecord, player)
    end)

    local restart = Instance.new("RemoteEvent")
    restart.Name = "RestartRun"
    restart.Parent = game:GetService("ReplicatedStorage")
    local lastRestart = {}
    Players.PlayerRemoving:Connect(function(player)
        lastRestart[player] = nil
        saveRecord(player)
        -- Failed writes remain queued for retry, including after a disconnect.
    end)
    task.spawn(function()
        while task.wait(30) do
            for player in pending do
                task.spawn(saveRecord, player)
            end
        end
    end)
    game:BindToClose(function()
        for player in pending do
            task.spawn(saveRecord, player)
        end
        local untilTime = os.clock() + 25
        while next(pending) and os.clock() < untilTime do
            task.wait(0.2)
        end
    end)

    -- Server validates obstacle crossings, including between frames, independently of visual touch events.
    for _, o in map.Hazards:GetChildren() do
        if o.Position.Z == 60 or o.Position.Z == 204 or o.Position.Z == 752 then
            o:SetAttribute("Challenge", true)
        end
    end
    local action = Instance.new("RemoteEvent")
    action.Name = "RunnerAction"
    action.Parent = game:GetService("ReplicatedStorage")
    local lastAction, previousZ = {}, {}

    local function fail(p, h, reason, fall)
        if h.Health <= 0 then
            return
        end
        local recovery = impactRecovery[p]
        impactRecovery[p] = nil
        if
            fall
            and recovery
            and workspace:GetServerTimeNow() <= recovery.Until
            and recovery.Round == p:GetAttribute("RaceRound")
        then
            pendingRecovery[p] = recovery
            reason = "被撞后跌落"
        end
        p:SetAttribute("LastDeathReason", reason)
        p:SetAttribute("LastDeathAt", workspace:GetServerTimeNow())
        h.Health = 0
    end
    local function stumble(p, o, message)
        hitUntil[p] = hitUntil[p] or {}
        local now = workspace:GetServerTimeNow()
        if (hitUntil[p][o] or 0) > now then
            return
        end
        hitUntil[p][o] = now + 2
        p:SetAttribute("SlowUntil", now + 1.5)
        p:SetAttribute("Combo", 0)
        p:SetAttribute("ActionNotice", message)
        p:SetAttribute("ActionNoticeUntil", now + 2)
    end
    action.OnServerEvent:Connect(function(p, kind)
        if kind ~= "Start" and kind ~= "Jump" and kind ~= "Slide" and kind ~= "Roll" then
            return
        end
        local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if not h or h.Health <= 0 or not root then
            return
        end
        local now = workspace:GetServerTimeNow()
        local status = p:GetAttribute("RaceStatus")
        if kind == "Start" then
            local request = game.ReplicatedStorage:FindFirstChild("RoomStartRequest")
            if request then
                request:Fire(p)
            end
            return
        end
        if not p:GetAttribute("Running") then
            return
        end
        lastAction[p] = lastAction[p] or {}
        if now - (lastAction[p][kind] or -10) < (kind == "Slide" and 0.15 or 0.25) then
            return
        end
        lastAction[p][kind] = now
        if kind == "Roll" then
            if h.FloorMaterial == Enum.Material.Air then
                p:SetAttribute("RollUntil", now + 1.2)
            end
        elseif kind == "Slide" then
            local ground = RaycastParams.new()
            ground.FilterType = Enum.RaycastFilterType.Include
            ground.FilterDescendantsInstances = { map.Platforms, map.Checkpoints }
            if
                h.FloorMaterial ~= Enum.Material.Air
                or workspace:Raycast(
                    root.Position,
                    Vector3.new(0, -(h.HipHeight + root.Size.Y / 2 + 0.75), 0),
                    ground
                )
            then
                if (p:GetAttribute("SlideUntil") or 0) <= now then
                    p:SetAttribute("SlideStartedAt", now)
                end
                p:SetAttribute("SlideUntil", now + 1.1)
            end
        else
            p:SetAttribute("LastJumpAt", now)
            p:SetAttribute("SlideUntil", 0)
            for _, o in map.Hazards:GetChildren() do
                if
                    o.Name == "Vault"
                    and (o.Position.Z - root.Position.Z) * root.CFrame.LookVector.Z > 0
                    and math.abs(o.Position.Z - root.Position.Z) < 10
                then
                    p:SetAttribute("VaultUntil", now + 0.55)
                    break
                end
            end
        end
    end)
    Players.PlayerRemoving:Connect(function(p)
        lastAction[p] = nil
        previousZ[p] = nil
        hitUntil[p] = nil
        cleared[p] = nil
        safeGround[p] = nil
        impactRecovery[p] = nil
        pendingRecovery[p] = nil
    end)
    RunService.Heartbeat:Connect(function()
        for _, p in Players:GetPlayers() do
            local c = p.Character
            local root = c and c:FindFirstChild("HumanoidRootPart")
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if root and h and h.Health > 0 then
                local z = root.Position.Z
                if p:GetAttribute("Running") and h.FloorMaterial ~= Enum.Material.Air then
                    local point = groundPoint(root)
                    if point then
                        safeGround[p] = { Position = point, Time = workspace:GetServerTimeNow() }
                    end
                end
                if p:GetAttribute("Running") then
                    local nextCP = checkpoints:FindFirstChild(tostring(p.leaderstats.Stage.Value + 1))
                    if
                        nextCP
                        and math.abs(z - nextCP.Position.Z) < 6
                        and math.abs(root.Position.X) < 14
                        and root.Position.Y > -1
                        and root.Position.Y < 30
                    then
                        p.leaderstats.Stage.Value += 1
                        p.RespawnLocation = nextCP
                    end
                end
                cleared[p] = cleared[p] or {}
                for _, o in map.Hazards:GetChildren() do
                    if
                        p:GetAttribute("Running")
                        and not cleared[p][o]
                        and z > o.Position.Z + o.Size.Z / 2 + 1
                        and z < o.Position.Z + 8
                    then
                        cleared[p][o] = true
                        if not hitUntil[p] or not hitUntil[p][o] then
                            p:SetAttribute("Combo", (p:GetAttribute("Combo") or 0) + 1)
                            if o:GetAttribute("Challenge") then
                                p:SetAttribute("ActionCount", (p:GetAttribute("ActionCount") or 0) + 1)
                            end
                        end
                    end
                end
                local previous = previousZ[p]
                previousZ[p] = z
                if root.Position.Y < -5 and not p:GetAttribute("Hanging") then
                    fail(p, h, "没有跨过屋顶间隙 · 提前起跳", true)
                end
                if p:GetAttribute("Running") and not p:GetAttribute("Finished") then
                    -- Ignore teleports/respawns; normal crossing is tested as a swept interval.
                    if previous and math.abs(z - previous) < 12 then
                        for _, o in map.Hazards:GetChildren() do
                            local half = o.Size.Z / 2 + 0.6
                            if
                                math.max(z, previous) >= o.Position.Z - half
                                and math.min(z, previous) <= o.Position.Z + half
                                and math.abs(root.Position.X - o.Position.X) < o.Size.X / 2 + 0.6
                            then
                                local slide = (p:GetAttribute("SlideUntil") or 0)
                                    > workspace:GetServerTimeNow()
                                local feet = root.Position.Y - h.HipHeight - root.Size.Y / 2
                                if o.Name == "Slide" then
                                    if feet < o.Position.Y + o.Size.Y / 2 and (not slide or feet > 0.8) then
                                        stumble(p, o, "低梁碰撞 · 提前按滑铲")
                                    end
                                elseif
                                    (o.Name == "Hurdle" or o.Name == "Vault")
                                    and feet < o.Position.Y + o.Size.Y / 2 - 0.25
                                then
                                    stumble(
                                        p,
                                        o,
                                        o.Name == "Vault" and "翻越失误 · 提前起跳"
                                            or "碰到栏杆 · 提前起跳"
                                    )
                                end
                            end
                        end
                    end
                end
            else
                previousZ[p] = nil
            end
        end
    end)
end
return Module
