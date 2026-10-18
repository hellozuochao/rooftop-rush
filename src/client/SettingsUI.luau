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
    rows.CanvasSize = UDim2.new()
    rows.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local layout = Instance.new("UIListLayout", rows)
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    for i, entry in
        {
            { "MusicVolume", "背景音乐", { 0.0, 0.25, 0.5, 0.75, 1 }, 0.5 },
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
    Modal.Bind("Settings", panel)
end
