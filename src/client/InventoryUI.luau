return function(deps)
    local p, gui, remote, C, button, label = deps.p, deps.gui, deps.remote, deps.C, deps.button, deps.label
    local CAS = game:GetService("ContextActionService")
    local bagPanel = Instance.new("ScrollingFrame", gui)
    bagPanel.Name = "QuickItems"
    bagPanel.BackgroundTransparency = 1
    bagPanel.BorderSizePixel = 0
    bagPanel.ScrollBarThickness = 3
    bagPanel.ScrollingDirection = Enum.ScrollingDirection.Y
    bagPanel.ClipsDescendants = true
    bagPanel.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
    bagPanel.AnchorPoint = Vector2.new(1, 0)
    bagPanel.Position = UDim2.new(1, -12, 0, 50)
    local slots = {}
    for i = 1, C.Rules.InventoryCapacity do
        local b = button("Slot" .. i, "空", bagPanel)
        b.TextSize = 11
        b.BackgroundTransparency = 0.18
        b.Activated:Connect(function()
            remote:FireServer("UseSlot", i)
        end)
        slots[i] = b
    end
    for i, key in
        {
            Enum.KeyCode.One,
            Enum.KeyCode.Two,
            Enum.KeyCode.Three,
            Enum.KeyCode.Four,
            Enum.KeyCode.Five,
            Enum.KeyCode.Six,
        }
    do
        CAS:BindAction("BagSlot" .. i, function(_, state)
            if state == Enum.UserInputState.Begin then
                remote:FireServer("UseSlot", i)
            end
        end, false, key)
    end
    local supplyLabels = {}
    for _, supply in workspace.NeonObby.Pickups:GetChildren() do
        local billboard = Instance.new("BillboardGui", supply)
        billboard.Size = UDim2.fromOffset(90, 30)
        billboard.StudsOffset = Vector3.new(0, 2.5, 0)
        billboard.MaxDistance = 45
        local text = label("", billboard)
        text.Size = UDim2.fromScale(1, 1)
        supplyLabels[supply] = text
    end
    local lastPickup = 0

    local function update(now, running, v, size, main)
        local count = p:GetAttribute("InventoryCount") or 0
        bagPanel.Visible = running and count > 0
        -- Both panels share RunnerHUD coordinates; reserve the actual action-button area.
        local top = 50
        local bottom = gui.AbsoluteSize.Y - 20 - math.max(main, size) - 16
        for _, name in { "Jump", "Slide", "Punch" } do
            local control = gui:FindFirstChild(name)
            if control and control.Visible and control.AbsoluteSize.Y > 0 then
                bottom = math.min(bottom, control.AbsolutePosition.Y - gui.AbsolutePosition.Y - 16)
            end
        end
        local rowHeight = 48
        local height = math.min(count * rowHeight, math.max(0, bottom - top))
        bagPanel.Size = UDim2.fromOffset(v.Y < 500 and 100 or 116, height)
        bagPanel.CanvasSize = UDim2.fromOffset(0, count * rowHeight)
        bagPanel.CanvasPosition =
            Vector2.new(0, math.clamp(bagPanel.CanvasPosition.Y, 0, math.max(0, count * rowHeight - height)))
        for i, b in slots do
            b.Visible = p:GetAttribute("Inv" .. i) ~= nil
            b.Position = UDim2.fromOffset(0, (i - 1) * rowHeight)
            b.Size = UDim2.new(1, -5, 0, rowHeight - 4)
        end
        for supply, text in supplyLabels do
            local remaining = math.max(0, (p:GetAttribute("SupplyReady" .. supply.Name) or 0) - now)
            supply.LocalTransparencyModifier = remaining > 0 and 0.85 or 0
            local category = supply:FindFirstChild("Category")
            text.Text = remaining > 0 and ("刷新 " .. math.ceil(remaining) .. "秒")
                or (category and category.Value or "随机补给")
            text.TextColor3 = remaining > 0 and Color3.fromRGB(160, 170, 180) or supply.Color
        end
        local picked = p:GetAttribute("PickupSerial") or 0
        if picked ~= lastPickup then
            lastPickup = picked
            bagPanel.BackgroundColor3 = Color3.fromRGB(80, 220, 180)
            bagPanel.BackgroundTransparency = 0.65
            game:GetService("TweenService")
                :Create(bagPanel, TweenInfo.new(0.6), { BackgroundTransparency = 1 })
                :Play()
        end
        for i, b in slots do
            local key = p:GetAttribute("Inv" .. i)
            b.Text = i
                .. " · "
                .. (key and C.Items[key] or "空")
                .. (p:GetAttribute("SelectedSlot") == i and " ✓" or "")
            b.BackgroundColor3 = p:GetAttribute("SelectedSlot") == i and Color3.fromRGB(35, 120, 120)
                or Color3.fromRGB(25, 46, 66)
        end
    end
    return { Update = update }
end
