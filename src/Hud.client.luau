local Modal = require(script.Parent:WaitForChild("ClientModules"):WaitForChild("Modal"))
local Camera = require(script.Parent:WaitForChild("ClientModules"):WaitForChild("CameraController"))
local Motion = require(game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("MovementMath"))
pcall(function()
    game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local Storage = game:GetService("ReplicatedStorage")
local p = Players.LocalPlayer
local action = Storage:WaitForChild("RunnerAction")
local controls = require(p:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
controls:Enable()
local C = require(Storage:WaitForChild("RunnerConfig"))
local momentum = Vector3.zero
local facing = 1
local slideDirection = Vector3.new(0, 0, 1)
local moveAxis = 0
local cameraFacing = 1
local facingSince = 0
local landedAt = -10
local airborneLast = false
local gui = Instance.new("ScreenGui")
gui.Name = "RunnerHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 3
gui.Parent = p:WaitForChild("PlayerGui")
local function text(name, value, parent)
    local t = Instance.new("TextLabel")
    t.Name = name
    t.Text = value
    t.Font = Enum.Font.GothamBold
    t.TextColor3 = Color3.fromRGB(243, 236, 222)
    t.TextSize = 14
    t.BackgroundTransparency = 1
    t.Parent = parent
    return t
end
local function button(name, value, parent)
    local t = Instance.new("TextButton")
    t.Name = name
    t.Text = value
    t.Font = Enum.Font.GothamBold
    t.TextColor3 = Color3.fromRGB(243, 236, 222)
    t.TextSize = 16
    t.BackgroundColor3 = Color3.fromRGB(30, 40, 53)
    t.BackgroundTransparency = 0.08
    t.Parent = parent
    Instance.new("UICorner", t).CornerRadius = UDim.new(0, 14)
    return t
end
local stats = text("Stats", "", gui)
stats.Position = UDim2.fromOffset(12, 8)
stats.Size = UDim2.new(1, -124, 0, 30)
stats.TextXAlignment = Enum.TextXAlignment.Left
local toast = text("Notice", "", gui)
toast.AnchorPoint = Vector2.new(0, 0)
toast.Position = UDim2.fromOffset(12, 72)
toast.Size = UDim2.new(1, -150, 0, 30)
toast.TextWrapped = true
toast.TextColor3 = Color3.fromRGB(255, 176, 102)
toast.TextSize = 13
local bar = Instance.new("Frame", gui)
bar.BorderSizePixel = 0
bar.BackgroundColor3 = Color3.fromRGB(70, 82, 91)
bar.Position = UDim2.fromOffset(12, 40)
bar.Size = UDim2.new(1, -24, 0, 3)
local fill = Instance.new("Frame", bar)
fill.BorderSizePixel = 0
fill.BackgroundColor3 = Color3.fromRGB(245, 174, 82)
fill.Size = UDim2.fromScale(0, 1)
local jump = button("Jump", "跳跃 ↑", gui)
local slide = button("Slide", "滑铲 ↓", gui)
local intro = Instance.new("Frame", gui)
intro.Name = "Intro"
intro.AnchorPoint = Vector2.new(0.5, 0.5)
intro.Position = UDim2.fromScale(0.5, 0.46)
intro.Size = UDim2.new(1, -40, 0, 250)
intro.BackgroundColor3 = Color3.fromRGB(20, 29, 41)
Instance.new("UICorner", intro).CornerRadius = UDim.new(0, 16)
local cap = Instance.new("UISizeConstraint", intro)
cap.MaxSize = Vector2.new(440, 250)
local title = text("Title", "霓虹城市 · 道具竞速", intro)
title.Size = UDim2.new(1, -20, 0, 38)
title.Position = UDim2.fromOffset(10, 12)
title.TextSize = 19
local help = text(
    "Help",
    "WASD / 摇杆：屋顶平面自由移动\n持续前进加速 · 松手逐步减速\n空格跳跃 · C滑铲 · Q道具 · F拳套",
    intro
)
help.Position = UDim2.fromOffset(10, 55)
help.Size = UDim2.new(1, -20, 0, 64)
help.TextSize = 13
help.TextWrapped = true
local start = button("Start", "开始奔跑", intro)
start.Position = UDim2.new(0, 16, 1, -54)
start.Size = UDim2.new(1, -32, 0, 40)
start.BackgroundColor3 = Color3.fromRGB(128, 77, 36)
start.Activated:Connect(function()
    Storage:WaitForChild("RaceReady"):FireServer("Start")
end)
local lastGround, slideLocal, vaultLocal = 0, 0, 0
local rollUntil = 0
local jumpBufferedUntil = 0
local bufferedShort = false
local wasAir = false
local slideHeld, lastSlideSent = false, -10
local slidePointer
local jumpPointer, jumpStarted
local function releaseJump()
    local c = p.Character
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if r and jumpStarted and os.clock() - jumpStarted < 0.18 and r.AssemblyLinearVelocity.Y > 35 then
        local velocity = r.AssemblyLinearVelocity
        r.AssemblyLinearVelocity = Vector3.new(velocity.X, 35, velocity.Z)
    end
    if jumpBufferedUntil > os.clock() then
        bufferedShort = true
    end
    jumpStarted = nil
    jumpPointer = nil
end
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Include
groundParams.FilterDescendantsInstances = { workspace.NeonObby.Platforms, workspace.NeonObby.Checkpoints }
local function grounded(h, root)
    return h.FloorMaterial ~= Enum.Material.Air
        or workspace:Raycast(
                root.Position,
                Vector3.new(0, -(h.HipHeight + root.Size.Y / 2 + 0.6), 0),
                groundParams
            )
            ~= nil
end
local function input(kind)
    if Modal.Get() ~= "" or not p:GetAttribute("Running") or p:GetAttribute("Finished") then
        return
    end
    local c = p.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local root = c and c:FindFirstChild("HumanoidRootPart")
    if not h or h.Health <= 0 or not root then
        return
    end
    if kind == "Jump" then
        if h.FloorMaterial ~= Enum.Material.Air or os.clock() - lastGround < 0.1 then
            jumpBufferedUntil = 0
            lastGround = -10
            slideLocal = 0
            slideHeld = false
            h.Jump = true
            action:FireServer("Jump")
            h:ChangeState(Enum.HumanoidStateType.Jumping)
            root.AssemblyLinearVelocity =
                Vector3.new(root.AssemblyLinearVelocity.X, 60, root.AssemblyLinearVelocity.Z)
            for _, o in workspace.NeonObby.Hazards:GetChildren() do
                if
                    o.Name == "Vault"
                    and (o.Position.Z - root.Position.Z) * facing > 0
                    and (o.Position.Z - root.Position.Z) * facing < 10
                then
                    vaultLocal = workspace:GetServerTimeNow() + 0.55
                    break
                end
            end
        else
            jumpBufferedUntil = os.clock() + 0.16
            bufferedShort = false
        end
    elseif h.FloorMaterial == Enum.Material.Air then
        rollUntil = workspace:GetServerTimeNow() + 1.2
        action:FireServer("Roll")
    elseif grounded(h, root) and os.clock() - lastSlideSent >= 0.25 then
        slideDirection = momentum.Magnitude > 1 and momentum.Unit or root.CFrame.LookVector
        lastSlideSent = os.clock()
        slideLocal = workspace:GetServerTimeNow() + 1.1
        action:FireServer("Slide")
    end
end
-- Respond at press-down, including touch. Activated is retained for keyboard/gamepad UI navigation.
local function pressButton(button, kind)
    button.InputBegan:Connect(function(event)
        if
            event.UserInputType == Enum.UserInputType.Touch
            or event.UserInputType == Enum.UserInputType.MouseButton1
        then
            if kind == "Slide" then
                slideHeld = true
                slidePointer = event
            end
            if kind == "Jump" then
                jumpPointer = event
                jumpStarted = os.clock()
            end
            input(kind)
        end
    end)
    button.Activated:Connect(function(event)
        if
            event.UserInputType ~= Enum.UserInputType.Touch
            and event.UserInputType ~= Enum.UserInputType.MouseButton1
        then
            input(kind)
        end
    end)
end
pressButton(jump, "Jump")
pressButton(slide, "Slide")
local gesture = Instance.new("BindableEvent", gui)
gesture.Name = "Gesture"
gesture.Event:Connect(input)
UIS.InputEnded:Connect(function(event)
    if event == jumpPointer then
        releaseJump()
    end
    if event == slidePointer then
        slideHeld = false
        slidePointer = nil
    end
end)
UIS.WindowFocusReleased:Connect(function()
    slideHeld = false
    slidePointer = nil
    jumpBufferedUntil = 0
    releaseJump()
end)
CAS:BindActionAtPriority("RunnerJump", function(_, state)
    if state == Enum.UserInputState.Begin then
        jumpStarted = os.clock()
        input("Jump")
    elseif state == Enum.UserInputState.End then
        releaseJump()
    end
    return Enum.ContextActionResult.Sink
end, false, 3000, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
CAS:BindActionAtPriority("RunnerSlide", function(_, state)
    if state == Enum.UserInputState.Begin then
        slideHeld = true
        input("Slide")
    elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
        slideHeld = false
    end
    return Enum.ContextActionResult.Sink
end, false, 3000, Enum.KeyCode.C, Enum.KeyCode.LeftControl, Enum.KeyCode.ButtonB)
local rootMotor, originalC0, lastCharacter
local desiredPose = CFrame.new()
local appliedJoint, baseTransform
local slideBlend = 0
local poseJoints = {}
local restoredJoints = {}
local slideRootPose = CFrame.new(0, -2, 0) * CFrame.Angles(math.rad(75), 0, 0)
local remotePoses = {}
-- Feet-first slide: one extended leg, one tucked leg, arms braced behind the torso.
local slideAngles = {
    LeftUpperLeg = Vector3.new(15, 0, -5),
    RightUpperLeg = Vector3.new(45, 0, 7),
    LeftLowerLeg = Vector3.new(-8, 0, 0),
    RightLowerLeg = Vector3.new(-110, 0, 0),
    LeftFoot = Vector3.new(-12, 0, 0),
    RightFoot = Vector3.new(18, 0, 0),
    UpperTorso = Vector3.new(0, 0, -5),
    Head = Vector3.new(-28, 0, 0),
    LeftUpperArm = Vector3.new(-30, 0, -18),
    RightUpperArm = Vector3.new(-20, 0, 20),
    LeftLowerArm = Vector3.new(-35, 0, 0),
    RightLowerArm = Vector3.new(-50, 0, 0),
    ["Left Leg"] = Vector3.new(30, 0, -5),
    ["Right Leg"] = Vector3.new(5, 0, 9),
    ["Left Arm"] = Vector3.new(-30, 0, -18),
    ["Right Arm"] = Vector3.new(-20, 0, 20),
}
Run.PreAnimation:Connect(function()
    if appliedJoint and appliedJoint.Parent then
        appliedJoint.Transform = baseTransform
    end
    appliedJoint = nil
    for joint, transform in restoredJoints do
        if joint.Parent then
            joint.Transform = transform
        end
    end
    table.clear(restoredJoints)
end)
Run.PreSimulation:Connect(function(dt)
    if rootMotor and rootMotor.Parent then
        baseTransform = rootMotor.Transform
        rootMotor.Transform = originalC0:Inverse()
            * desiredPose
            * originalC0
            * baseTransform:Lerp(CFrame.new(), slideBlend)
        appliedJoint = rootMotor
    end
    local landing = math.clamp(1 - (workspace:GetServerTimeNow() - landedAt) / 0.22, 0, 1)
    if landing > 0 and slideBlend < 0.1 then
        for joint in poseJoints do
            local name = joint.Part1 and joint.Part1.Name
            local angle = (name == "LeftLowerLeg" or name == "RightLowerLeg") and -35
                or (name == "LeftUpperLeg" or name == "RightUpperLeg") and 18
                or 0
            if angle ~= 0 then
                restoredJoints[joint] = joint.Transform
                local basis = joint.C0.Rotation
                joint.Transform = joint.Transform
                    * basis:Inverse()
                    * CFrame.Angles(math.rad(angle * landing), 0, 0)
                    * basis
            end
        end
    end
    -- Render the same pose for teammates using server-replicated slide timing.
    local others = Players:GetPlayers()
    local bots = workspace:FindFirstChild("RacersNPC")
    if bots then
        for _, bot in bots:GetChildren() do
            table.insert(others, bot)
        end
    end
    for _, other in others do
        if other == p then
            continue
        end
        local c = other:IsA("Player") and other.Character or other
        local h = c and c:FindFirstChildOfClass("Humanoid")
        local r = c and c:FindFirstChild("HumanoidRootPart")
        local data = remotePoses[other]
        if not c or not h or not r or h.Health <= 0 then
            remotePoses[other] = nil
            continue
        end
        if not data or data.Character ~= c or os.clock() - (data.ScannedAt or 0) > 1 then
            data = (data and data.Character == c) and data or { Character = c, Blend = 0 }
            data.Joints = {}
            data.ScannedAt = os.clock()
            remotePoses[other] = data
            for _, joint in c:GetDescendants() do
                if joint:IsA("Motor6D") or joint:IsA("AnimationConstraint") then
                    if joint.Part0 == r then
                        data.Root = joint
                        data.C0 = joint.C0
                    elseif joint.Part1 and slideAngles[joint.Part1.Name] then
                        local a = slideAngles[joint.Part1.Name]
                        local b = joint.C0.Rotation
                        data.Joints[joint] = b:Inverse()
                            * CFrame.Angles(math.rad(a.X), math.rad(a.Y), math.rad(a.Z))
                            * b
                    end
                end
            end
        end
        local remaining = (other:GetAttribute("SlideUntil") or 0) - workspace:GetServerTimeNow()
        local sliding = other:GetAttribute("Running")
            and not other:GetAttribute("Finished")
            and not other:GetAttribute("Hanging")
            and remaining > 0
            and grounded(h, r)
        local target = sliding and math.clamp(remaining / 0.18, 0, 1) or 0
        data.Blend += (target - data.Blend) * (1 - math.exp(-dt * (sliding and 24 or 18)))
        if data.Blend > 0.001 and data.Root and data.Root.Parent then
            local joint = data.Root
            restoredJoints[joint] = joint.Transform
            joint.Transform = data.C0:Inverse()
                * CFrame.new():Lerp(slideRootPose, data.Blend)
                * data.C0
                * joint.Transform:Lerp(CFrame.new(), data.Blend)
            for j, pose in data.Joints do
                if j.Parent then
                    restoredJoints[j] = j.Transform
                    j.Transform = j.Transform:Lerp(pose, data.Blend)
                end
            end
        end
    end
    if slideBlend > 0.001 then
        for joint, pose in poseJoints do
            if joint.Parent then
                restoredJoints[joint] = joint.Transform
                joint.Transform = joint.Transform:Lerp(pose, slideBlend)
            end
        end
    end
end)
Players.PlayerRemoving:Connect(function(other)
    remotePoses[other] = nil
end)
local function layout()
    local v = workspace.CurrentCamera.ViewportSize
    local size = (v.Y < 500 and 62 or 76) * (gui:GetAttribute("ButtonScale") or 1)
    local alpha = gui:GetAttribute("ButtonTransparency") or 0.35
    jump.Text = UIS.TouchEnabled and "跳跃" or "跳跃 ↑"
    jump.BackgroundTransparency = alpha
    slide.BackgroundTransparency = alpha
    jump.Size = UDim2.fromOffset(size, size)
    slide.Size = UDim2.fromOffset(size, size)
    jump.AnchorPoint = Vector2.new(1, 1)
    slide.AnchorPoint = Vector2.new(1, 1)
    jump.Position = UDim2.new(1, -20, 1, -20)
    slide.Position = UDim2.new(1, -size - 34, 1, -20)
    title.TextSize = v.X < 400 and 15 or 19
end
Run:BindToRenderStep("SkylineRunner", Enum.RenderPriority.Camera.Value + 1, function(dt)
    local c = p.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local root = c and c:FindFirstChild("HumanoidRootPart")
    local now = workspace:GetServerTimeNow()
    local running = p:GetAttribute("Running") and not p:GetAttribute("Finished")
    local status = p:GetAttribute("RaceStatus")
    local canMove = (running or status == "Waiting" or status == "Countdown") and Modal.Get() == ""
    stats.Visible = Modal.Get() == ""
    bar.Visible = Modal.Get() == ""
    toast.Visible = Modal.Get() == ""
    jump.Visible = running and Modal.Get() == ""
    slide.Visible = running and Modal.Get() == ""
    intro.Visible = false
    local touch = p.PlayerGui:FindFirstChild("TouchGui")
    if touch then
        touch.Enabled = canMove
        local tj = touch:FindFirstChild("JumpButton", true)
        if tj then
            tj.Visible = false
        end
    end
    if c ~= lastCharacter then
        rootMotor = nil
        originalC0 = nil
        lastCharacter = c
        slideLocal = 0
        vaultLocal = 0
        slideHeld = false
        jumpBufferedUntil = 0
        lastGround = -10
        desiredPose = CFrame.new()
        slideBlend = 0
        moveAxis = 0
        momentum = Vector3.zero
        airborneLast = false
        landedAt = -10
        table.clear(poseJoints)
    end
    if root and h then
        if running and jumpBufferedUntil > os.clock() and h.FloorMaterial ~= Enum.Material.Air then
            local short = bufferedShort
            input("Jump")
            if short then
                task.defer(function()
                    if root.Parent and root.AssemblyLinearVelocity.Y > 35 then
                        local v = root.AssemblyLinearVelocity
                        root.AssemblyLinearVelocity = Vector3.new(v.X, 35, v.Z)
                    end
                end)
            end
        end
        if slideHeld and running then
            input("Slide")
        end
        if h.FloorMaterial ~= Enum.Material.Air then
            lastGround = os.clock()
        end
        h.AutoRotate = false
        if h.Health > 0 and not p:GetAttribute("Hanging") then
            local input = controls:GetMoveVector()
            local wanted = Vector3.new(-input.Z, 0, input.X)
            if wanted.Magnitude < 0.15 or UIS:GetFocusedTextBox() then
                wanted = Vector3.zero
            elseif wanted.Magnitude > 1 then
                wanted = wanted.Unit
            end
            local slidingNow = running
                and grounded(h, root)
                and math.max(slideLocal, p:GetAttribute("SlideUntil") or 0) > now
            local top = (p:GetAttribute("SprintUntil") or 0) > now and C.BoostSpeed or C.MaxSpeed
            if (p:GetAttribute("SlowUntil") or 0) > now then
                top *= 0.6
            end
            if slidingNow then
                wanted = slideDirection
            end
            -- Independent axes: steering must not consume forward acceleration.
            local largest = math.max(math.abs(wanted.X), math.abs(wanted.Z))
            if largest > 0.15 then
                wanted = wanted / largest * math.min(1, largest / 0.7)
            end
            if not running then
                top = 14
            end
            local target = Vector3.new(wanted.X * (running and C.LateralSpeed or 14), 0, wanted.Z * top)
            local mx, mz =
                Motion.Step(momentum.X, momentum.Z, target.X, target.Z, dt, C.Acceleration, C.Braking)
            momentum = Vector3.new(mx, 0, mz)
            local contactScale = (p:GetAttribute("ContactUntil") or 0) > now
                    and (p:GetAttribute("ContactScale") or 1)
                or 1
            local contactX = (p:GetAttribute("ContactUntil") or 0) > now and (p:GetAttribute("ContactX") or 0)
                or 0
            local motion = Vector3.new(momentum.X * contactScale + contactX, 0, momentum.Z * contactScale)
            if not canMove then
                momentum = Vector3.zero
            end
            if not canMove then
                motion = Vector3.zero
            end
            if (p:GetAttribute("StaggerUntil") or 0) > now then
                motion = Vector3.zero
                momentum = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
            end
            if canMove and not running then
                local pos = root.Position
                if pos.X < -12 and motion.X < 0 or pos.X > 12 and motion.X > 0 then
                    motion = Vector3.new(0, 0, motion.Z)
                end
                if pos.Z < -28 and motion.Z < 0 or pos.Z > -3 and motion.Z > 0 then
                    motion = Vector3.new(motion.X, 0, 0)
                end
            end
            h.WalkSpeed = motion.Magnitude
            h:Move(motion.Magnitude > 0.05 and motion.Unit or Vector3.zero, false)
            moveAxis = momentum.Z / C.MaxSpeed
            if math.abs(momentum.Z) > 1 then
                local f = momentum.Z > 0 and 1 or -1
                if f ~= facing then
                    facing = f
                    facingSince = now
                end
            end
            gui:SetAttribute("MoveAxis", wanted.Z)
            gui:SetAttribute("Speed", math.abs(motion.Z))
            if momentum.Magnitude > 1 then
                local rot = CFrame.lookAt(Vector3.zero, momentum.Unit)
                root.CFrame = CFrame.new(root.Position)
                    * root.CFrame.Rotation:Lerp(rot, 1 - math.exp(-dt * 12))
            end
        end
        if not rootMotor then
            for _, m in c:GetDescendants() do
                if m:IsA("Motor6D") or m:IsA("AnimationConstraint") then
                    if m.Part0 == root then
                        rootMotor = m
                        originalC0 = m.C0
                    elseif m.Part1 and slideAngles[m.Part1.Name] then
                        local a = slideAngles[m.Part1.Name]
                        local basis = m.C0.Rotation
                        poseJoints[m] = basis:Inverse()
                            * CFrame.Angles(math.rad(a.X), math.rad(a.Y), math.rad(a.Z))
                            * basis
                    end
                end
            end
        end
        if rootMotor then
            local slideEnd = math.max(slideLocal, p:GetAttribute("SlideUntil") or 0)
            local sliding = running and slideEnd > now and grounded(h, root) and not p:GetAttribute("Hanging")
            local targetBlend = sliding and math.clamp((slideEnd - now) / 0.18, 0, 1) or 0
            slideBlend += (targetBlend - slideBlend) * (1 - math.exp(-dt * (sliding and 24 or 18)))
            gui:SetAttribute("SlideBlend", slideBlend)
            local isAir = h.FloorMaterial == Enum.Material.Air
            if airborneLast and not isAir then
                landedAt = now
            end
            airborneLast = isAir
            local landing = math.clamp(1 - (now - landedAt) / 0.22, 0, 1)
            local vaulting = running and math.max(vaultLocal, p:GetAttribute("VaultUntil") or 0) > now
            local rolling = rollUntil > now and h.FloorMaterial ~= Enum.Material.Air
            local pose = rolling
                    and CFrame.new(0, -0.8, 0) * CFrame.Angles((rollUntil - now) * -math.pi * 2, 0, 0)
                or slideBlend > 0.001 and CFrame.new():Lerp(slideRootPose, slideBlend)
                or vaulting and CFrame.Angles(math.rad(-24), 0, 0)
                or isAir and CFrame.Angles(math.rad(root.AssemblyLinearVelocity.Y > 0 and -9 or 7), 0, 0)
                or CFrame.new(0, -0.45 * landing, 0)
                    * CFrame.Angles(math.rad(-12 * landing - 4 * math.abs(moveAxis)), 0, 0)
            desiredPose = desiredPose:Lerp(pose, math.min(1, dt * 20))
            slide.Text = sliding and "滑铲中" or (UIS.TouchEnabled and "滑铲" or "滑铲 C")
            slide.BackgroundColor3 = sliding and Color3.fromRGB(44, 125, 143) or Color3.fromRGB(30, 40, 53)
        end
        Camera.Update(p, gui, root, h, running, dt)
        fill.Size = UDim2.fromScale(math.clamp(root.Position.Z / 1742, 0, 1), 1)
    end
    local ls = p:FindFirstChild("leaderstats")
    if ls then
        local elapsed = p:GetAttribute("Finished") and p:GetAttribute("FinishTime")
            or now - (p:GetAttribute("StartedAt") or now)
        stats.Text = string.format(
            "%d/12  ·  %.0f秒  ·  失误%d",
            ls.Stage.Value,
            math.max(0, elapsed or 0),
            ls.Deaths.Value
        )
    end
    local death = p:GetAttribute("LastDeathAt")
    toast.Text = death and now - death < 3 and (p:GetAttribute("LastDeathReason") or "重新挑战") or ""
    layout()
end)
