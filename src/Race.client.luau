local Modal = require(script.Parent:WaitForChild("ClientModules"):WaitForChild("Modal"))
local P = game:GetService("Players")
local p = P.LocalPlayer
local S = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local state = S:WaitForChild("RaceState")
local remote = S:WaitForChild("RaceReady")
local gui = Instance.new("ScreenGui", p:WaitForChild("PlayerGui"))
gui.Name = "RaceHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 5
gui:SetAttribute("SpectateName", "All")
local function button(n, t, parent)
    local b = Instance.new("TextButton", parent)
    b.Name = n
    b.Text = t
    b.TextSize = 13
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = Color3.new(1, 1, 1)
    b.BackgroundColor3 = Color3.fromRGB(30, 65, 90)
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
    return b
end
local function label(t, parent)
    local l = Instance.new("TextLabel", parent)
    l.Text = t
    l.TextColor3 = Color3.new(1, 1, 1)
    l.BackgroundTransparency = 1
    l.TextSize = 14
    l.Font = Enum.Font.GothamBold
    l.TextWrapped = true
    return l
end
local topbar = Instance.new("ScreenGui", p.PlayerGui)
topbar.Name = "SettingsEntryHUD"
topbar.ResetOnSpawn = false
topbar.DisplayOrder = 6
topbar.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
local menu = button("Menu", "设置", topbar)
menu.Size = UDim2.fromOffset(100, 30)
menu.Position = UDim2.new(1, -112, 0, 8)
local panel = Instance.new("Frame", gui)
panel.Name = "Room"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.8, 0, 0.85, 0)
panel.BackgroundColor3 = Color3.fromRGB(15, 24, 38)
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)
local bounds = Instance.new("UISizeConstraint", panel)
bounds.MaxSize = Vector2.new(580, 520)
Modal.Bind("Room", panel)
Modal.Open("Room")
local title = label("竞速房间", panel)
title.Position = UDim2.fromOffset(12, 8)
title.Size = UDim2.new(1, -65, 0, 30)
title.TextSize = 19
title.TextScaled = true
local titleBounds = Instance.new("UITextSizeConstraint", title)
titleBounds.MaxTextSize = 19
titleBounds.MinTextSize = 11
local close = button("Close", "×", panel)
close.Position = UDim2.new(1, -42, 0, 8)
close.Size = UDim2.fromOffset(30, 28)
close.Activated:Connect(function()
    Modal.Close("Room")
end)
local mode = button("Mode", "单人", panel)
mode.Position = UDim2.new(0, 12, 0, 45)
mode.Size = UDim2.new(0.5, -18, 0, 32)
local difficulty = button("Difficulty", "NPC难度", panel)
difficulty.Position = UDim2.new(0.5, 6, 0, 45)
difficulty.Size = UDim2.new(0.5, -18, 0, 32)
local hint = label("", panel)
hint.Position = UDim2.fromOffset(12, 81)
hint.Size = UDim2.new(1, -24, 0, 40)
hint.TextSize = 12
hint.TextColor3 = Color3.fromRGB(255, 201, 103)
local scroll = Instance.new("ScrollingFrame", panel)
scroll.Name = "Standings"
scroll.Position = UDim2.fromOffset(12, 126)
scroll.Size = UDim2.new(1, -24, 1, -264)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()
local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 5)
for i, entry in { { "Wardrobe", "免费衣橱" }, { "Settings", "声音 / 操作 / 游戏说明" } } do
    local b = button(entry[1], entry[2], panel)
    b.Position = UDim2.new((i - 1) * 0.5, i == 1 and 12 or 6, 1, -128)
    b.Size = UDim2.new(0.5, -18, 0, 30)
    b.Activated:Connect(function()
        Modal.Open(entry[1])
    end)
end
local ready = button("Ready", "准备下一场", panel)
ready.Position = UDim2.new(0, 12, 1, -90)
ready.Size = UDim2.new(0.5, -18, 0, 34)
local start = button("Start", "房主开始", panel)
start.Position = UDim2.new(0.5, 6, 1, -90)
start.Size = UDim2.new(0.5, -18, 0, 34)
local watch = button("Spectate", "观战：领跑者", panel)
watch.Position = UDim2.new(0, 12, 1, -48)
watch.Size = UDim2.new(0.5, -18, 0, 34)
local leave = button("Leave", "退出本场", panel)
leave.Position = UDim2.new(0.5, 6, 1, -48)
leave.Size = UDim2.new(0.5, -18, 0, 34)
local banner = label("", gui)
banner.Size = UDim2.new(1, -150, 0, 25)
banner.Position = UDim2.fromOffset(12, 100)
banner.TextColor3 = Color3.fromRGB(255, 210, 110)
banner.TextSize = 12
menu.Activated:Connect(function()
    Modal.Open(Modal.Get() == "Room" and "" or "Room")
end)
ready.Activated:Connect(function()
    remote:FireServer("Ready")
end)
local choices = Instance.new("Frame", panel)
choices.Name = "ModeDropdown"
choices.Position = UDim2.new(0, 12, 0, 79)
choices.Size = UDim2.new(0.5, -18, 0, 78)
choices.BackgroundColor3 = Color3.fromRGB(20, 40, 60)
choices.ZIndex = 20
choices.Visible = false
for i, entry in { { "Solo", "单人 · 与3名NPC竞速" }, { "Multi", "多人 · 好友道具竞速" } } do
    local option = button(entry[1], entry[2], choices)
    option.Size = UDim2.new(1, -8, 0, 34)
    option.Position = UDim2.fromOffset(4, 4 + (i - 1) * 37)
    option.ZIndex = 21
    option.Activated:Connect(function()
        if p.UserId == state:GetAttribute("HostId") and state:GetAttribute("Phase") == "Waiting" then
            remote:FireServer("Mode", entry[1])
        end
        choices.Visible = false
    end)
end
mode.Activated:Connect(function()
    if p.UserId == state:GetAttribute("HostId") and state:GetAttribute("Phase") == "Waiting" then
        choices.Visible = not choices.Visible
    end
end)
difficulty.Activated:Connect(function()
    remote:FireServer("Difficulty", (state:GetAttribute("Difficulty") or 2) % 3 + 1)
end)
start.Activated:Connect(function()
    remote:FireServer(state:GetAttribute("Phase") == "Waiting" and "Start" or "End")
end)
leave.Activated:Connect(function()
    remote:FireServer("Return")
    Modal.Close("Room")
end)
local targets = Instance.new("ScrollingFrame", panel)
targets.Name = "SpectateTargets"
targets.Position = UDim2.fromOffset(12, 126)
targets.Size = UDim2.new(1, -24, 1, -264)
targets.BackgroundColor3 = Color3.fromRGB(18, 40, 58)
targets.ZIndex = 25
targets.Visible = false
targets.AutomaticCanvasSize = Enum.AutomaticSize.Y
targets.CanvasSize = UDim2.new()
targets.ScrollBarThickness = 4
local targetLayout = Instance.new("UIListLayout", targets)
targetLayout.Padding = UDim.new(0, 4)
watch.Activated:Connect(function()
    if targets.Visible then
        targets.Visible = false
        return
    end
    for _, child in targets:GetChildren() do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    local names = { { "All", "领跑者第一视角" } }
    for _, q in P:GetPlayers() do
        if q:GetAttribute("Running") and q.Character then
            table.insert(names, { q.Character.Name, q.DisplayName })
        end
    end
    local bots = workspace:FindFirstChild("RacersNPC")
    if bots then
        for _, b in bots:GetChildren() do
            if b:GetAttribute("Running") then
                table.insert(names, { b.Name, b.Name })
            end
        end
    end
    for i, entry in names do
        local option = button("Target" .. i, "观战 · " .. entry[2], targets)
        option.Size = UDim2.new(1, -8, 0, 34)
        option.ZIndex = 26
        option.LayoutOrder = i
        option.Activated:Connect(function()
            gui:SetAttribute("SpectateName", entry[1])
            targets.Visible = false
            Modal.Close("Room")
        end)
    end
    targets.Visible = true
end)
local function line(text, color)
    local l = label(text, scroll)
    l.Size = UDim2.new(1, -6, 0, 28)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = color or Color3.fromRGB(220, 232, 240)
    l.TextSize = 12
end
local previous, finished
while gui.Parent do
    local phase = state:GetAttribute("Phase")
    local running = p:GetAttribute("Running")
    local host = p.UserId == state:GetAttribute("HostId")
    local hostPlayer = P:GetPlayerByUserId(state:GetAttribute("HostId") or 0)
    title.Text = "竞速房间 · 房主 " .. (hostPlayer and hostPlayer.DisplayName or "交接中")
    mode.Text = state:GetAttribute("Mode") == "Solo" and "模式：单人 + 3名NPC"
        or "模式：多人道具竞速"
    mode.Active = host and phase == "Waiting"
    if not panel.Visible or not host or phase ~= "Waiting" then
        choices.Visible = false
    end
    mode.Text ..= " v"
    difficulty.Text = "NPC：" .. ({ "简单", "标准", "困难" })[state:GetAttribute("Difficulty") or 2]
    difficulty.Visible = state:GetAttribute("Mode") == "Solo"
    difficulty.Active = host and phase == "Waiting"
    ready.Text = p:GetAttribute("Ready") and "已准备 ✓ · 点击取消" or "准备下一场"
    ready.BackgroundColor3 = p:GetAttribute("Ready") and Color3.fromRGB(30, 125, 95)
        or Color3.fromRGB(30, 65, 90)
    start.Visible = host
    start.Text = phase == "Waiting" and "开始新游戏" or "结束本场"
    leave.Visible = running
    watch.Visible = not running and phase == "Racing"
    watch.Text = "观战："
        .. (
            gui:GetAttribute("SpectateName") == "All" and "领跑者（点此切换）"
            or gui:GetAttribute("SpectateName")
        )
    hint.Text = phase == "Waiting"
            and (host and "仅房主开局；多人只带入已准备玩家，单人加入3名NPC。" or "请准备，等待房主开始多人游戏。")
        or "本场已锁定参赛名单。后来加入的玩家观战，准备只对下一场生效。"
    banner.Visible = Modal.Get() == "" and (phase == "Countdown" or (not running and phase == "Racing"))
    if not panel.Visible then
        targets.Visible = false
    end
    menu.Visible = Modal.Get() == "" or Modal.Get() == "Room"
    banner.Text = phase == "Countdown"
            and ("倒计时 " .. math.max(
                0,
                math.ceil(state:GetAttribute("Deadline") - workspace:GetServerTimeNow())
            ))
        or (
            "观战中 · "
            .. (p:GetAttribute("Ready") and "已准备下一场" or "打开房间菜单准备下一场")
        )
    if phase == "Countdown" and previous ~= phase then
        Modal.Close("Room")
    end
    if phase == "Waiting" and previous and previous ~= phase then
        Modal.Open("Room")
    end
    if p:GetAttribute("Finished") and not finished then
        Modal.Open("Room")
    end
    previous = phase
    finished = p:GetAttribute("Finished")
    if panel.Visible then
        for _, v in scroll:GetChildren() do
            if v:IsA("TextLabel") then
                v:Destroy()
            end
        end
        for _, q in P:GetPlayers() do
            line(
                (q == hostPlayer and "[房主] " or "")
                    .. q.DisplayName
                    .. " · "
                    .. (
                        q:GetAttribute("Running") and "比赛中"
                        or q:GetAttribute("Ready") and "已准备"
                        or "等待 / 观战"
                    )
            )
        end
        line("—— 本场排名 ——", Color3.fromRGB(90, 220, 240))
        local results = state.Results:GetChildren()
        table.sort(results, function(a, b)
            local ar = a:GetAttribute("Rank") or 0
            local br = b:GetAttribute("Rank") or 0
            return (ar > 0 and ar or 999) < (br > 0 and br or 999)
        end)
        for _, row in results do
            local rank = row:GetAttribute("Rank") or 0
            line(
                (rank > 0 and tostring(rank) .. ". " or "• ")
                    .. (row:GetAttribute("PlayerName") or row.Name)
                    .. " · "
                    .. (
                        row:GetAttribute("State") == "Finished"
                            and string.format("%.1f秒", row:GetAttribute("Time") or 0)
                        or row:GetAttribute("State") == "Racing" and "比赛中"
                        or "本场结束"
                    )
            )
        end
    end
    task.wait(0.25)
end
