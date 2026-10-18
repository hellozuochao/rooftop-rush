-- Studio-only client tests; use production controls and remotes.
local P = game:GetService("Players")
local p = P.LocalPlayer
local S = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local event = S:WaitForChild("QAV23Control")
local rpc = S:WaitForChild("QAV23Case")
local ready = S:WaitForChild("RaceReady")
local remote = S:WaitForChild("SkylineAction")
local gui = p:WaitForChild("PlayerGui"):WaitForChild("RunnerHUD")
local controls = require(p.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
local original = controls.GetMoveVector
local function check(ok, label)
    assert(ok, label)
    print("V23_CLIENT_CHECK", label)
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
local Modal = require(p.PlayerScripts.ClientModules.Modal)
local function v23UI()
    waitFor(function()
        return p.PlayerGui:FindFirstChild("WardrobeHUD") and p.PlayerGui:FindFirstChild("SettingsHUD")
    end, 10, "new panels")
    for _, name in { "Room", "Wardrobe", "Settings" } do
        Modal.Open(name)
        task.wait(0.2)
        check(p.PlayerGui.RaceHUD.Room.Visible == (name == "Room"), "exclusive room " .. name)
        check(p.PlayerGui.WardrobeHUD.Wardrobe.Visible == (name == "Wardrobe"), "exclusive wardrobe " .. name)
        check(p.PlayerGui.SettingsHUD.Settings.Visible == (name == "Settings"), "exclusive settings " .. name)
        check(not p.PlayerGui.WardrobeHUD.Closet.Visible, "launcher hidden behind modal")
    end
    gui:SetAttribute("MusicVolume", 0)
    gui:SetAttribute("SFXVolume", 0)
    task.wait(0.1)
    check(
        game.SoundService.RaceMusic.Volume == 0 and game.SoundService.RaceSFX.Volume == 0,
        "audio mute settings"
    )
    gui:SetAttribute("MusicVolume", 0.5)
    gui:SetAttribute("SFXVolume", 0.75)
    check(not gui:FindFirstChild("Sprint"), "no sprint button")
    waitFor(function()
        return game.SoundService.RooftopChaser.IsLoaded
    end, 20, "licensed music loads")
    check(game.SoundService.RooftopChaser.IsPlaying, "music playing")
    Modal.Open("")
    local root = p.Character.HumanoidRootPart
    local before = root.Position
    controls.GetMoveVector = function()
        return Vector3.new(0, 0, -1)
    end
    task.wait(1)
    check((root.Position - before).Magnitude > 2, "waiting movement enabled")
    task.wait(1)
    check(math.abs(root.Position.X) <= 13 and root.Position.Z <= -2, "waiting boundary enforced")
    controls.GetMoveVector = original
    event:FireServer("PrepPassed")
end
local function uiAndRoute()
    local old = p:GetAttribute("Outfit")
    remote:FireServer("Outfit", 0 / 0)
    task.wait(0.25)
    check(p:GetAttribute("Outfit") == old, "reject NaN outfit")
    for i = 1, 24 do
        remote:FireServer("Outfit", i)
        task.wait(0.24)
        check(p:GetAttribute("Outfit") == i, "free outfit " .. i)
    end
    for i = 1, 8 do
        remote:FireServer("Skin", i)
        task.wait(0.24)
        check(p:GetAttribute("Skin") == i, "free skin " .. i)
    end
    for _, count in { 0, 1, 6 } do
        rpc:InvokeServer("Fill", count)
        task.wait(0.2)
        check(gui.QuickItems.Visible == (count > 0), "inventory visibility " .. count)
        local visible = 0
        for _, v in gui.QuickItems:GetChildren() do
            if v:IsA("TextButton") and v.Visible then
                visible += 1
            end
        end
        check(visible == count, "no empty slots")
    end
    for _, scale in { 0.85, 1, 1.15 } do
        gui:SetAttribute("ButtonScale", scale)
        task.wait(0.2)
        local bag = gui.QuickItems
        for _, name in { "Jump", "Slide", "Punch" } do
            local b = gui[name]
            local separated = bag.AbsolutePosition.X >= b.AbsolutePosition.X + b.AbsoluteSize.X
                or bag.AbsolutePosition.Y + bag.AbsoluteSize.Y <= b.AbsolutePosition.Y
            check(separated, "inventory avoids " .. name .. " at " .. scale)
        end
    end
    remote:FireServer("UseSlot", 99)
    task.wait(0.2)
    check(p:GetAttribute("InventoryCount") == 6, "invalid use keeps inventory")
    remote:FireServer("UseSlot", 1)
    task.wait(0.2)
    check(
        p:GetAttribute("InventoryCount") == 5
            and (p:GetAttribute("SprintUntil") or 0) > workspace:GetServerTimeNow(),
        "remote item use"
    )
    ready:FireServer("End")
    task.wait(0.5)
    ready:FireServer("Start")
    waitFor(function()
        return p:GetAttribute("Running")
    end, 12, "route start")
    local start = os.clock()
    local lastJump = -10
    local lastSlide = -10
    local lastStage = 0
    local stalled = 0
    local lastZ = 0
    local reverseUntil = 0
    local frames = 0
    local worst = 0
    local cameraMismatch = 0
    controls.GetMoveVector = function()
        local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if not r then
            return Vector3.zero
        end
        return Vector3.new(
            os.clock() < reverseUntil and -1 or 1,
            0,
            -math.clamp((-11 - r.Position.X) / 4, -1, 1)
        )
    end
    while not p:GetAttribute("Finished") do
        local dt = Run.Heartbeat:Wait()
        frames += 1
        worst = math.max(worst, dt)
        assert(os.clock() - start < 200, "route timed out")
        local c = p.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if not r or not h or h.Health <= 0 then
            continue
        end
        local t = os.clock()
        local z = r.Position.Z
        local speed = math.abs(r.AssemblyLinearVelocity.Z)
        if math.abs(z - lastZ) < 0.02 and h.FloorMaterial ~= Enum.Material.Air then
            stalled += dt
        else
            stalled = 0
        end
        lastZ = z
        if stalled > 1.2 then
            reverseUntil = t + 0.5
            stalled = 0
        end
        if t > reverseUntil and h.FloorMaterial ~= Enum.Material.Air then
            local jump = false
            local slide = false
            for _, o in workspace.NeonObby.Hazards:GetChildren() do
                local distance = o.Position.Z - o.Size.Z / 2 - z
                if
                    distance > -1
                    and distance < math.max(6, speed * 0.24)
                    and math.abs(r.Position.X - o.Position.X) < o.Size.X / 2 + 1.2
                then
                    if o.Name == "Slide" then
                        slide = true
                    else
                        jump = true
                    end
                end
            end
            for _, gap in workspace.NeonObby.Gaps:GetChildren() do
                local d = gap.Position.Z - gap.Size.Z / 2 - z
                if d > 0 and d < math.max(5, speed * 0.2) then
                    jump = true
                end
            end
            if jump and t - lastJump > 0.3 then
                gui.Gesture:Fire("Jump")
                lastJump = t
            elseif slide and t - lastSlide > 0.3 then
                gui.Gesture:Fire("Slide")
                lastSlide = t
            end
        end
        local stage = p.leaderstats.Stage.Value
        if stage ~= lastStage then
            print("V23_STAGE", stage, z, p.leaderstats.Deaths.Value)
            lastStage = stage
        end
        cameraMismatch = workspace.CurrentCamera.CameraSubject == h and 0 or cameraMismatch + dt
        assert(cameraMismatch < 0.5, "camera follows current character within 0.5s")
    end
    controls.GetMoveVector = original
    check(p.leaderstats.Stage.Value == 12, "route reaches all checkpoints")
    print("V23_ROUTE_CLIENT_PASS", os.clock() - start, p.leaderstats.Deaths.Value, frames, worst)
    rpc:InvokeServer("Route", os.clock() - start)
    event:FireServer("ClientPass", "UI and full route")
end
event.OnClientEvent:Connect(function(kind)
    local ok, err = xpcall(function()
        if kind == "PrepTest" then
            v23UI()
        elseif kind == "SpectateTest" then
            Modal.Open("")
            local race = p.PlayerGui.RaceHUD
            local selected
            for _, other in P:GetPlayers() do
                if other:GetAttribute("Running") then
                    selected = other
                    break
                end
            end
            check(selected ~= nil, "spectate target exists")
            race:SetAttribute("SpectateName", selected.Character.Name)
            task.wait(0.3)
            check(
                workspace.CurrentCamera.CameraSubject == selected.Character.Humanoid,
                "chosen player camera subject"
            )
            race:SetAttribute("SpectateName", "departed-player")
            task.wait(0.3)
            check(race:GetAttribute("SpectateName") == "All", "departed target returns to overview")
            event:FireServer("SpectatePassed")
        elseif kind == "UIAndRoute" then
            uiAndRoute()
        elseif kind == "Move" then
            controls.GetMoveVector = function()
                return Vector3.new(0, 0, -1)
            end
        elseif kind == "Stop" then
            controls.GetMoveVector = original
        elseif kind == "Slide" then
            gui.Gesture:Fire("Slide")
        elseif kind == "Punch" then
            remote:FireServer("Punch")
        elseif kind == "ModeMulti" then
            ready:FireServer("Mode", "Multi")
        else
            ready:FireServer(kind)
        end
    end, debug.traceback)
    if not ok then
        controls.GetMoveVector = original
        event:FireServer("ClientFail", err)
        warn("V23_CLIENT_FAIL", err)
    end
end)
waitFor(function()
    return p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p:GetAttribute("ProfileReady")
end, 30, "character")
event:FireServer("ClientReady")
