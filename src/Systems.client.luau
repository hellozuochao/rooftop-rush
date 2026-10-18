local P = game:GetService("Players")
local p = P.LocalPlayer
local S = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local CAS = game:GetService("ContextActionService")
local C = require(S:WaitForChild("RunnerConfig"))
local remote = S:WaitForChild("SkylineAction")
local gui = p:WaitForChild("PlayerGui"):WaitForChild("RunnerHUD")
local function button(n, t, parent)
    local b = Instance.new("TextButton", parent or gui)
    b.Name = n
    b.Text = t
    b.TextWrapped = true
    b.TextSize = 13
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = Color3.new(1, 1, 1)
    b.BackgroundColor3 = Color3.fromRGB(25, 46, 66)
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12)
    return b
end
local function label(t, parent)
    local l = Instance.new("TextLabel", parent or gui)
    l.Text = t
    l.BackgroundTransparency = 1
    l.TextColor3 = Color3.fromRGB(245, 208, 124)
    l.TextSize = 12
    l.TextWrapped = true
    return l
end
local punchButton = button("Punch", "拳套 F")
punchButton.Activated:Connect(function()
    remote:FireServer("Punch")
end)
for _, d in { { "Punch", Enum.KeyCode.F }, { "Item", Enum.KeyCode.Q } } do
    CAS:BindActionAtPriority("Race" .. d[1], function(_, state)
        if state == Enum.UserInputState.Begin then
            remote:FireServer(d[1])
        end
        return Enum.ContextActionResult.Sink
    end, false, 3100, d[2])
end
local status = label("")
status.Position = UDim2.fromOffset(12, 45)
status.Size = UDim2.new(1, -24, 0, 24)
status.TextXAlignment = Enum.TextXAlignment.Left
local itemHint = label("")
itemHint.AnchorPoint = Vector2.new(1, 1)
itemHint.Position = UDim2.new(1, -18, 1, -178)
itemHint.Size = UDim2.fromOffset(240, 30)
local components = script.Parent:WaitForChild("ClientModules")
local deps = { p = p, gui = gui, remote = remote, C = C, button = button, label = label }
local wardrobe = require(components.WardrobeUI)(deps)
local inventory = require(components.InventoryUI)(deps)
require(components.SettingsUI)(deps)
require(components.AudioController).Start(p, gui)
require(components.ItemVisuals).Start()
local Modal = require(components.Modal)
Run.RenderStepped:Connect(function(dt)
    local now = workspace:GetServerTimeNow()
    local racing = p:GetAttribute("Running") and not p:GetAttribute("Finished")
    local running = racing and Modal.Get() == ""
    status.Visible = Modal.Get() == ""
    local v = workspace.CurrentCamera.ViewportSize
    local size = (v.Y < 500 and 54 or 64) * (gui:GetAttribute("ButtonScale") or 1)
    local main = (v.Y < 500 and 62 or 76) * (gui:GetAttribute("ButtonScale") or 1)
    for _, b in { punchButton } do
        b.Visible = running
        b.BackgroundTransparency = gui:GetAttribute("ButtonTransparency") or 0.25
        b.Size = UDim2.fromOffset(size, size)
        b.AnchorPoint = Vector2.new(1, 1)
    end
    if v.X < 600 then
        punchButton.Position = UDim2.new(1, -(main + 34), 1, -(main + 34))
    else
        punchButton.Position = UDim2.new(1, -(48 + main * 2), 1, -20)
    end
    local punchCD = math.max(0, (p:GetAttribute("PunchReadyAt") or 0) - now)
    punchButton.Text = punchCD > 0 and string.format("拳套 %.1f", punchCD)
        or (game:GetService("UserInputService").TouchEnabled and "拳套" or "拳套 F")
    status.Text = string.format(
        "速度 %.0f / %d · 收集 %d/3",
        gui:GetAttribute("Speed") or 0,
        (p:GetAttribute("SprintUntil") or 0) > now and C.BoostSpeed or C.MaxSpeed,
        p:GetAttribute("Collected") or 0
    )
    if (p:GetAttribute("IncomingUntil") or 0) > now then
        status.Text = "追踪警报！使用护盾抵挡"
        status.TextColor3 = Color3.fromRGB(255, 100, 100)
    else
        status.TextColor3 = Color3.fromRGB(245, 208, 124)
    end
    local effects = {}
    for _, entry in
        {
            { "SlowUntil", "减速", true },
            { "ContactUntil", "碰撞恢复", true },
            { "StaggerUntil", "击退", true },
            { "ShieldUntil", "护盾" },
            { "ImmuneUntil", "保护" },
            { "SprintUntil", "涡轮" },
            { "VacuumUntil", "磁吸" },
            { "DecoyUntil", "诱饵" },
        }
    do
        local left = (p:GetAttribute(entry[1]) or 0) - now
        if left > 0 then
            table.insert(effects, entry[2] .. string.format(" %.1fs", left))
        end
    end
    if #effects > 0 then
        status.Text = table.concat(effects, "  ·  ")
    end
    status.Size = UDim2.new(1, -150, 0, 24)
    if (p:GetAttribute("SlowUntil") or 0) > now or (p:GetAttribute("StaggerUntil") or 0) > now then
        status.TextColor3 = Color3.fromRGB(255, 115, 140)
    end
    if (p:GetAttribute("ActionNoticeUntil") or 0) > now then
        gui.Notice.Text = p:GetAttribute("ActionNotice") or ""
    end
    inventory.Update(now, running, v, size, main)
    wardrobe.Update(racing)
    for _, coin in workspace.NeonObby.Collectibles:GetChildren() do
        coin.LocalTransparencyModifier = p:GetAttribute("Picked" .. coin.Name) and 1 or 0
    end
end)

require(script.Parent:WaitForChild("ClientModules"):WaitForChild("NpcAnimator")).Start()
