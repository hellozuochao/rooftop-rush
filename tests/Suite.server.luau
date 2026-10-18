-- Studio-only integration runner. Import separately and remove before publishing.
local P = game:GetService("Players")
local S = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
assert(Run:IsStudio(), "QA must never run in production")
local control = Instance.new("RemoteEvent", S)
control.Name = "QAV23Control"
local rpc = Instance.new("RemoteFunction", S)
rpc.Name = "QAV23Case"
local report = Instance.new("Folder", S)
report.Name = "QAV23Report"
local function check(ok, label)
    assert(ok, label)
    print("V23_PASS", label)
end
local function waitFor(fn, seconds, label)
    local deadline = os.clock() + seconds
    repeat
        if fn() then
            return
        end
        task.wait(0.1)
    until os.clock() > deadline
    error("Timeout: " .. label)
end
waitFor(function()
    return #P:GetPlayers() > 0 and S:FindFirstChild("RaceState") and S:FindFirstChild("SpawnBots")
end, 30, "startup")
local state = S.RaceState
local runtime = require(game.ServerScriptService.ServerModules.GameplaySystems).Get()
local function rig(a)
    local c = a:IsA("Player") and a.Character or a
    return c, c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
end
local function resetBag(a)
    local st = runtime.Actors[a]
    st.Inventory = {}
    st.Selected = 1
    st.UseAt = nil
    runtime.Inventory.Sync(a)
end
rpc.OnServerInvoke = function(p, kind, value)
    if kind == "Fill" then
        resetBag(p)
        for i = 1, value do
            runtime.Inventory.Add(p, ({ "Boost", "Shield", "Rocket", "EMP", "Trap", "Steal" })[i])
        end
        return true
    elseif kind == "Drop" then
        local _, _, r = rig(p)
        S.MarkImpactRespawn:Fire(p)
        r.CFrame = CFrame.new(20, -8, r.Position.Z)
        return true
    elseif kind == "Route" then
        report:SetAttribute("RouteTime", value)
        return true
    end
end
control.OnServerEvent:Connect(function(p, kind, value)
    if kind == "SpectatePassed" then
        p:SetAttribute("QASpectatePassed", true)
    elseif kind == "PrepPassed" then
        p:SetAttribute("QAPrepPassed", true)
    elseif kind == "ClientReady" then
        p:SetAttribute("QAReady", true)
    elseif kind == "ClientPass" then
        print("V23_CLIENT_PASS", p.Name, value)
        p:SetAttribute("QAClientPass", true)
    elseif kind == "ClientFail" then
        warn("V23_CLIENT_FAIL", p.Name, value)
        report:SetAttribute("Failed", true)
    end
end)
local function start(host)
    waitFor(function()
        S.RoomStartRequest:Fire(host)
        return host:GetAttribute("Running")
    end, 15, "race start")
end
local function solo()
    local p = P:GetPlayers()[1]
    waitFor(function()
        return p:GetAttribute("QAReady") and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
    end, 30, "client ready")
    control:FireClient(p, "PrepTest")
    waitFor(function()
        return p:GetAttribute("QAPrepPassed")
    end, 40, "new UI and waiting movement")
    S.RoomStartRequest:Fire(p)
    waitFor(function()
        return #workspace.RacersNPC:GetChildren() == 3
    end, 10, "countdown NPC spawn")
    local before = {}
    for _, bot in workspace.RacersNPC:GetChildren() do
        before[bot] = bot.HumanoidRootPart.Position
        check(bot.Humanoid.RigType == p.Character.Humanoid.RigType, "NPC matches player rig")
        check(next(runtime.Actors[bot].Tracks) ~= nil, "NPC has avatar animation tracks")
    end
    task.wait(1)
    for bot, pos in before do
        check((bot.HumanoidRootPart.Position - pos).Magnitude > 0.2, "NPC moves during preparation")
        check(
            math.abs(bot.HumanoidRootPart.Position.X) <= 13 and bot.HumanoidRootPart.Position.Z <= -2,
            "NPC stays in preparation area"
        )
    end
    waitFor(function()
        return p:GetAttribute("Running")
    end, 10, "countdown ends")
    waitFor(function()
        return #workspace.RacersNPC:GetChildren() == 3
    end, 10, "NPC spawn")
    local bots = workspace.RacersNPC:GetChildren()
    local target = bots[1]
    local function arrange()
        runtime.Items.Clear()
        local t = workspace:GetServerTimeNow()
        local _, _, pr = rig(p)
        pr.Anchored = true
        pr.CFrame = CFrame.lookAt(Vector3.new(0, 3, 50), Vector3.new(0, 3, 60))
        pr.AssemblyLinearVelocity = Vector3.zero
        for i, b in bots do
            runtime.Actors[b].Bot = false
            local _, h, r = rig(b)
            b:SetAttribute("Running", true)
            b:SetAttribute("Finished", false)
            b:SetAttribute("RaceRound", p:GetAttribute("RaceRound"))
            for _, k in { "ShieldUntil", "ImmuneUntil", "SlowUntil", "DecoyUntil", "ContactProtectedUntil" } do
                b:SetAttribute(k, 0)
            end
            b:SetAttribute("PunchReadyAt", t + 100)
            r.Anchored = true
            r.CFrame = CFrame.new(i == 1 and 0 or 12, 3, i == 1 and 57 or 30 - i * 4)
            h.PlatformStand = true
            resetBag(b)
        end
        for _, k in { "SprintUntil", "ShieldUntil", "ImmuneUntil", "SlowUntil", "DecoyUntil", "VacuumUntil" } do
            p:SetAttribute(k, 0)
        end
        resetBag(p)
    end
    for _, item in
        {
            "Boost",
            "Magnet",
            "Shield",
            "Cleanse",
            "Decoy",
            "Vacuum",
            "Smoke",
            "Spring",
            "Trap",
            "EMP",
            "Shockwave",
            "Rocket",
            "Leader",
            "Steal",
        }
    do
        arrange()
        runtime.Inventory.Add(p, item)
        if item == "Cleanse" then
            p:SetAttribute("SlowUntil", workspace:GetServerTimeNow() + 20)
        end
        if item == "Steal" then
            runtime.Inventory.Add(target, "Shield")
        end
        runtime.Items.Use(p)
        task.wait((item == "Leader" and 2) or ((item == "Rocket" or item == "Steal") and 1.4) or 0.15)
        local t = workspace:GetServerTimeNow()
        if item == "Boost" or item == "Magnet" then
            check((p:GetAttribute("SprintUntil") or 0) > t, item)
        elseif item == "Shield" then
            check(p:GetAttribute("ShieldUntil") > t, item)
        elseif item == "Cleanse" then
            check(p:GetAttribute("SlowUntil") == 0 and p:GetAttribute("ImmuneUntil") > t, item)
        elseif item == "Decoy" then
            check(p:GetAttribute("DecoyUntil") > t, item)
        elseif item == "Vacuum" then
            check(p:GetAttribute("VacuumUntil") > t, item)
        elseif item == "Smoke" then
            check(workspace:FindFirstChild("SmokeCloud") ~= nil, item)
        elseif item == "Spring" or item == "Trap" then
            local part = workspace:FindFirstChild(item == "Spring" and "SpringPad" or "SlowField")
            check(part ~= nil, item .. " spawn")
            local _, _, tr = rig(target)
            tr.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
            tr.Anchored = false
            tr:SetNetworkOwner(nil)
            task.wait(0.15)
            check(
                item == "Spring" and tr.AssemblyLinearVelocity.Y > 20
                    or item == "Trap" and target:GetAttribute("SlowUntil") > workspace:GetServerTimeNow(),
                item .. " trigger"
            )
        elseif item == "Steal" then
            check(p:GetAttribute("HeldItem") == "Shield" and target:GetAttribute("InventoryCount") == 0, item)
        else
            check(
                (target:GetAttribute("SlowUntil") or 0) > t or (target:GetAttribute("ImmuneUntil") or 0) > t,
                item
            )
        end
    end
    arrange()
    target.HumanoidRootPart.CFrame = CFrame.new(0, 3, 40)
    for i = 2, 3 do
        bots[i]:SetAttribute("Running", false)
    end
    runtime.Inventory.Add(p, "Rocket")
    runtime.Items.Use(p)
    check(p:GetAttribute("InventoryCount") == 1, "no target preserves item")
    arrange()
    target:SetAttribute("ShieldUntil", workspace:GetServerTimeNow() + 10)
    runtime.Inventory.Add(p, "Rocket")
    runtime.Items.Use(p)
    task.wait(1.4)
    check(
        target:GetAttribute("ShieldUntil") == 0 and target:GetAttribute("SlowUntil") == 0,
        "shield blocks projectile"
    )
    arrange()
    target:SetAttribute("DecoyUntil", workspace:GetServerTimeNow() + 10)
    runtime.Inventory.Add(p, "Rocket")
    runtime.Items.Use(p)
    task.wait(1.4)
    check(
        target:GetAttribute("DecoyUntil") == 0 and target:GetAttribute("SlowUntil") == 0,
        "decoy intercepts projectile"
    )
    runtime.Items.Clear()
    p.Character.HumanoidRootPart.Anchored = false
    report:SetAttribute("ItemsPassed", true)
    control:FireClient(p, "UIAndRoute")
    waitFor(function()
        return state:GetAttribute("Round") >= 2 and p:GetAttribute("Running")
    end, 20, "route restart")
    task.wait(0.5)
    task.spawn(function()
        while state:GetAttribute("Phase")=="Racing" do
            for _, bot in workspace.RacersNPC:GetChildren() do
                local st=runtime.Actors[bot]
                print("V23_NPC_PROGRESS",bot.Name,bot.HumanoidRootPart.Position,st.Stage,bot:GetAttribute("Running"),bot.Humanoid.WalkSpeed)
            end
            task.wait(20)
        end
    end)
    for i, b in workspace.RacersNPC:GetChildren() do
        runtime.Actors[b].Difficulty = i
    end
    waitFor(function()
        return p:GetAttribute("Finished") or report:GetAttribute("Failed")
    end, 210, "full route completion")
    check(not report:GetAttribute("Failed"), "client suite")
    check(p.leaderstats.Stage.Value == 12, "all twelve checkpoints")
    print("V23_ROUTE_RESULT", p:GetAttribute("FinishTime"), p.leaderstats.Deaths.Value)
    waitFor(function()
        return state:GetAttribute("Phase") == "Waiting"
    end, 185, "NPC completion / room finish")
    local finished = 0
    for _, row in state.Results:GetChildren() do
        if row:GetAttribute("BotName") then
            print(
                "V23_NPC_RESULT",
                row:GetAttribute("PlayerName"),
                row:GetAttribute("State"),
                row:GetAttribute("Time")
            )
            if row:GetAttribute("State") == "Finished" then
                finished += 1
            end
        end
    end
    check(finished == 3, "all three NPC difficulties finish")
    report:SetAttribute("SoloPassed", true)
    print("V23_SOLO_SUITE_PASS")
end
local function multi()
    waitFor(function()
        return #P:GetPlayers() == 3
    end, 40, "three clients")
    waitFor(function()
        for _, p in P:GetPlayers() do
            if not p:GetAttribute("QAReady") then
                return false
            end
        end
        return true
    end, 40, "three clients ready")
    local list = P:GetPlayers()
    local host = P:GetPlayerByUserId(state:GetAttribute("HostId"))
    local others = {}
    for _, p in list do
        if p ~= host then
            table.insert(others, p)
        end
    end
    local b, c = others[1], others[2]
    control:FireClient(host, "ModeMulti")
    task.wait(0.5)
    control:FireClient(b, "Ready")
    task.wait(0.5)
    start(host)
    check(b:GetAttribute("Running") and not c:GetAttribute("Running"), "only ready players enter")
    task.wait(0.5)
    control:FireClient(host, "Slide")
    task.wait(0.3)
    check((host:GetAttribute("SlideUntil") or 0) > workspace:GetServerTimeNow(), "stationary slide starts")
    check(host.Character.RunnerCollider.Size.Y < 2, "slide collider shrinks")
    control:FireClient(c, "Ready")
    task.wait(0.4)
    check(c:GetAttribute("Ready") and not c:GetAttribute("Running"), "late readiness waits next round")
    control:FireClient(c, "Start")
    task.wait(0.4)
    check(not c:GetAttribute("Running"), "nonhost cannot start")
    control:FireClient(c, "SpectateTest")
    waitFor(function()
        return c:GetAttribute("QASpectatePassed")
    end, 8, "selected spectator camera")
    local ar = host.Character.HumanoidRootPart
    local br = b.Character.HumanoidRootPart
    ar.Anchored = true
    ar.CFrame = CFrame.lookAt(Vector3.new(0, 3, 50), Vector3.new(10, 3, 50))
    br.CFrame = CFrame.new(3.5, 3, 50)
    br.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.3)
    control:FireClient(host, "Punch")
    task.wait(0.45)
    check(
        br.Position.X > 4 and (b:GetAttribute("SlowUntil") or 0) > workspace:GetServerTimeNow(),
        "multiplayer punch displacement"
    )
    task.wait(3)
    ar.Anchored = false
    ar.CFrame = CFrame.new(-6, 3, 50)
    ar.AssemblyLinearVelocity = Vector3.zero
    ar:SetNetworkOwnershipAuto()
    br.CFrame = CFrame.new(0, 3, 50)
    br.Anchored = true
    control:FireClient(host, "Move")
    task.wait(1)
    check(ar.Position.X < -1.7, "players cannot ghost")
    br.Anchored = false
    br:SetNetworkOwnershipAuto()
    task.wait(0.7)
    check(br.Position.X > 0.2, "physical push")
    control:FireClient(host, "Stop")
    local oldCharacter = b.Character
    S.MarkImpactRespawn:Fire(b)
    Run.Heartbeat:Wait()
    br:SetNetworkOwner(nil)
    br.CFrame = CFrame.new(20, -8, 50)
    br.AssemblyLinearVelocity = Vector3.zero
    waitFor(function()
        local _, h, r = rig(b)
        return b.Character ~= oldCharacter and h and h.Health > 0 and r and math.abs(r.Position.Z - 50) < 8
    end, 10, "impact fall recovery")
    print("V23_RECOVERY_POSITION", b.Character.HumanoidRootPart.Position, b:GetAttribute("LastDeathReason"))
    check(math.abs(b.Character.HumanoidRootPart.Position.Z - 50) < 8, "impact fall recovery")
    control:FireClient(host, "End")
    task.wait(0.5)
    control:FireClient(b, "Ready")
    task.wait(0.5)
    start(host)
    check(b:GetAttribute("Running") and c:GetAttribute("Running"), "next round includes waiting ready player")
    control:FireClient(b, "Return")
    task.wait(0.4)
    check(not b:GetAttribute("Running") and host:GetAttribute("Running"), "withdraw without ending others")
    control:FireClient(host, "End")
    task.wait(0.5)
    check(state:GetAttribute("Phase") == "Waiting", "host ends room")
    report:SetAttribute("MultiPassed", true)
    print("V23_MULTI_SUITE_PASS")
end
local ok, err = xpcall(function()
    if workspace:GetAttribute("QAMode") == "Multi" then
        multi()
    else
        solo()
    end
end, debug.traceback)
if not ok then
    report:SetAttribute("Failed", true)
    warn("V23_SERVER_FAIL", err)
end
