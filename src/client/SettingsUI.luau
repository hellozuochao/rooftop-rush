local Modal = require(script.Parent.Modal)
return function(deps)
    local gui, button, label = deps.gui, deps.button, deps.label
    local screen = Instance.new("ScreenGui", deps.p.PlayerGui)
    screen.Name = "SettingsHUD"
    screen.ResetOnSpawn = false
    screen.DisplayOrder = 12
    local panel = Instance.new("Frame", screen)
    panel.Name = "Settings"
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.new(0.85, 0, 0.85, 0)
    panel.BackgroundColor3 = Color3.fromRGB(15, 24, 38)
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)
    local bounds = Instance.new("UISizeConstraint", panel)
    bounds.MaxSize = Vector2.new(480, 400)
    local title = label("声音与操作", panel)
    title.Position = UDim2.fromOffset(16, 8)
    title.Size = UDim2.new(1, -80, 0, 32)
    title.TextSize = 20
    local close = button("Close", "返回", panel)
    close.Size = UDim2.fromOffset(60, 30)
    close.Position = UDim2.new(1, -72, 0, 10)
    close.Activated:Connect(function()
        Modal.Open("Room")
    end)
    local rows = Instance.new("ScrollingFrame", panel)
    rows.Position = UDim2.fromOffset(16, 50)
    rows.Size = UDim2.new(1, -32, 1, -64)
    rows.BackgroundTransparency = 1
    rows.BorderSizePixel = 0
    rows.ScrollBarThickness = 4
    rows.Active = true
    rows.CanvasSize = UDim2.new()
    rows.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local layout = Instance.new("UIListLayout", rows)
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    for i, entry in
        {
            { "MusicVolume", "背景音乐", { 0, 0.05, 0.1, 0.15, 0.25, 0.5, 0.75, 1 }, 0.15 },
            { "SFXVolume", "动作与道具音效", { 0.0, 0.25, 0.5, 0.75, 1 }, 0.75 },
            { "ButtonScale", "操作按钮大小", { 0.85, 1, 1.15 }, 1 },
            { "ButtonTransparency", "按钮透明度", { 0.15, 0.35, 0.55 }, 0.35 },
        }
    do
        if gui:GetAttribute(entry[1]) == nil then
            gui:SetAttribute(entry[1], entry[4])
        end
        local row = Instance.new("Frame", rows)
        row.Name = entry[1]
        row.LayoutOrder = i
        row.Size = UDim2.new(1, -6, 0, 54)
        row.BackgroundTransparency = 1
        local name = label(entry[2], row)
        name.Size = UDim2.new(0.5, 0, 1, 0)
        name.TextXAlignment = Enum.TextXAlignment.Left
        local value = label("", row)
        value.Size = UDim2.new(0.25, -6, 1, 0)
        value.Position = UDim2.fromScale(0.625, 0)
        for index, direction in { -1, 1 } do
            local control =
                button(direction == -1 and "Decrease" or "Increase", direction == -1 and "−" or "+", row)
            control.Size = UDim2.new(0.125, -4, 0, 42)
            control.Position = UDim2.new(index == 1 and 0.5 or 0.875, 0, 0, 6)
            control.Activated:Connect(function()
                local at = table.find(entry[3], gui:GetAttribute(entry[1])) or 1
                gui:SetAttribute(entry[1], entry[3][math.clamp(at + direction, 1, #entry[3])])
            end)
        end
        local function refresh()
            value.Text = tostring(math.floor(gui:GetAttribute(entry[1]) * 100 + 0.5)) .. "%"
        end
        gui:GetAttributeChangedSignal(entry[1]):Connect(refresh)
        refresh()
    end
    local info = game:GetService("ReplicatedStorage"):WaitForChild("BuildInfo")
    local version = info:WaitForChild("Version")
    local platformVersion = info:WaitForChild("RobloxVersion")
    local versionLabel = label("", rows)
    versionLabel.Name = "GameVersion"
    versionLabel.LayoutOrder = 100
    versionLabel.Size = UDim2.new(1, -6, 0, 32)
    versionLabel.TextSize = 14
    local function refreshVersion()
        local suffix = platformVersion.Value == "0" and "本地测试" or "Roblox " .. platformVersion.Value
        versionLabel.Text = "屋顶狂飙 " .. version.Value .. " · " .. suffix
    end
    version.Changed:Connect(refreshVersion)
    platformVersion.Changed:Connect(refreshVersion)
    refreshVersion()
    local help = button("Help", "游戏说明 · 展开", rows)
    help.LayoutOrder = -2
    help.Size = UDim2.new(1, -6, 0, 44)
    local instructions = label(
        [[屋顶狂飙 · 玩法说明

目标：通过 12 段屋顶赛道，抢先到达终点。绿色检查点会保存本局进度。

移动：摇杆 / WASD 自由移动；持续前进逐步加速，松手平滑减速。跳跃越过矮墙与缺口，滑铲穿过青色低通道。没有独立冲刺按钮。

攻击：点击或按住「攻击」/ F 连续挥拳，靠近并面向对手可击退、减速。障碍会挡住攻击；护盾和短暂保护可避免连续受控。

道具：穿过彩色悬浮补给获取道具，最多保存 6 个。点击右侧道具选择使用时机；道具多时可以滚动。负面状态和剩余时间显示在顶部。

单人：与可选择难度的 NPC 竞速。
多人：房主在等待阶段开始比赛，已准备的玩家一起出发。比赛中加入的玩家等待下一局，可选择观战对象。

准备区内可以走动，但不能提前离开。比赛中所有参赛者会发生碰撞；被撞落时会尝试在受撞位置附近恢复。

设置：调整音乐、音效和操作按钮；从房间面板进入免费衣橱，选择服装与皮肤。]],
        rows
    )
    instructions.Name = "Instructions"
    instructions.LayoutOrder = -1
    instructions.Size = UDim2.new(1, -12, 0, 0)
    instructions.AutomaticSize = Enum.AutomaticSize.None
    instructions.TextSize = 15
    instructions.TextXAlignment = Enum.TextXAlignment.Left
    instructions.TextYAlignment = Enum.TextYAlignment.Top
    local function fitInstructions()
        local width = math.max(80, rows.AbsoluteSize.X - 12)
        local height = game:GetService("TextService"):GetTextSize(
            instructions.Text,
            instructions.TextSize,
            instructions.Font,
            Vector2.new(width, 10000)
        ).Y
        instructions.Size = UDim2.new(1, -12, 0, height + 20)
    end
    rows:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitInstructions)
    instructions:GetPropertyChangedSignal("Text"):Connect(fitInstructions)
    fitInstructions()
    instructions.Visible = false
    help.Activated:Connect(function()
        instructions.Visible = not instructions.Visible
        help.Text = instructions.Visible and "游戏说明 · 收起" or "游戏说明 · 展开"
    end)
    Modal.Bind("Settings", panel)
end
