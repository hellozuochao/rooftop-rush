local Modal = require(script.Parent.Modal)
return function(deps)
    local p, gui, remote, C, button, label = deps.p, deps.gui, deps.remote, deps.C, deps.button, deps.label
    local wardrobeGui = Instance.new("ScreenGui", p.PlayerGui)
    wardrobeGui.Name = "WardrobeHUD"
    wardrobeGui.ResetOnSpawn = false
    wardrobeGui.DisplayOrder = 12
    local closet = button("Closet", "免费衣橱", wardrobeGui)
    closet.Position = UDim2.fromOffset(12, 108)
    closet.Size = UDim2.fromOffset(100, 32)
    local panel = Instance.new("Frame", wardrobeGui)
    panel.Name = "Wardrobe"
    panel.Visible = false
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.new(0.94, 0, 0.9, 0)
    panel.BackgroundColor3 = Color3.fromRGB(13, 22, 35)
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)
    local bound = Instance.new("UISizeConstraint", panel)
    bound.MaxSize = Vector2.new(840, 560)
    local title = label("免费衣橱 · 24套服装 × 8种皮肤", panel)
    title.TextSize = 18
    title.Size = UDim2.new(1, -60, 0, 38)
    title.Position = UDim2.fromOffset(12, 4)
    local close = button("Close", "×", panel)
    close.Size = UDim2.fromOffset(32, 30)
    close.Position = UDim2.new(1, -42, 0, 8)
    close.Activated:Connect(function()
        Modal.Open("Room")
    end)
    local viewport = Instance.new("ViewportFrame", panel)
    viewport.Name = "Preview"
    viewport.Position = UDim2.new(0, 12, 0, 48)
    viewport.Size = UDim2.new(0.34, -18, 1, -140)
    viewport.BackgroundColor3 = Color3.fromRGB(22, 35, 52)
    viewport.Ambient = Color3.fromRGB(210, 210, 220)
    viewport.LightColor = Color3.new(1, 1, 1)
    Instance.new("UICorner", viewport)
    local camera = Instance.new("Camera", viewport)
    viewport.CurrentCamera = camera
    camera.CFrame = CFrame.lookAt(Vector3.new(5, 3, -7), Vector3.new(0, 0, 0))
    local world = Instance.new("WorldModel", viewport)
    local preview
    local function refreshPreview()
        if not panel.Visible or not p.Character then
            return
        end
        world:ClearAllChildren()
        local original = p.Character.Archivable
        p.Character.Archivable = true
        preview = p.Character:Clone()
        p.Character.Archivable = original
        for _, v in preview:GetDescendants() do
            if v:IsA("Script") or v:IsA("LocalScript") then
                v:Destroy()
            elseif v:IsA("BasePart") then
                v.Anchored = true
            end
        end
        preview.Parent = world
        preview:PivotTo(CFrame.new(0, 0, 0))
    end
    local grid = Instance.new("ScrollingFrame", panel)
    grid.Position = UDim2.new(0.34, 0, 0, 48)
    grid.Size = UDim2.new(0.66, -12, 1, -140)
    grid.BackgroundTransparency = 1
    grid.ScrollBarThickness = 4
    grid.BorderSizePixel = 0
    grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
    grid.CanvasSize = UDim2.new()
    local layout = Instance.new("UIGridLayout", grid)
    layout.CellSize = UDim2.new(0.5, -6, 0, 62)
    layout.CellPadding = UDim2.fromOffset(6, 6)
    local cards = {}
    for i = 1, 24 do
        local b = button("Look" .. i, C.OutfitName(i) .. "\n免费 · 点击穿戴", grid)
        b.TextSize = 12
        b.LayoutOrder = i
        b.BackgroundColor3 = C.Palettes[math.floor((i - 1) / 8) + 1]:Lerp(Color3.fromRGB(10, 22, 35), 0.75)
        b.Activated:Connect(function()
            remote:FireServer("Outfit", i)
        end)
        cards[i] = b
    end
    local skins = Instance.new("Frame", panel)
    skins.Position = UDim2.new(0, 12, 1, -82)
    skins.Size = UDim2.new(1, -24, 0, 32)
    skins.BackgroundTransparency = 1
    for i, color in C.Skins do
        local b = button("Skin" .. i, C.SkinNames[i], skins)
        b.Position = UDim2.new((i - 1) / 8, 2, 0, 0)
        b.Size = UDim2.new(1 / 8, -4, 1, 0)
        b.BackgroundColor3 = color
        b.TextSize = 11
        b.Activated:Connect(function()
            remote:FireServer("Skin", i)
        end)
    end
    local footer = label("所有外观免费，不影响速度与碰撞。", panel)
    footer.Position = UDim2.new(0, 12, 1, -42)
    footer.Size = UDim2.new(1, -24, 0, 32)
    closet.Activated:Connect(function()
        Modal.Open("Wardrobe")
        refreshPreview()
    end)
    for _, key in { "Outfit", "Skin" } do
        p:GetAttributeChangedSignal(key):Connect(function()
            task.delay(0.3, refreshPreview)
        end)
    end
    Modal.Bind("Wardrobe", panel, refreshPreview)
    local function update(running)
        closet.Visible = false -- Wardrobe is available inside Settings / Room only.
        if panel.Visible then
            for i, b in cards do
                b.Text = C.OutfitName(i)
                    .. (p:GetAttribute("Outfit") == i and "\n已穿戴 ✓" or "\n免费 · 点击穿戴")
            end
            footer.Text = "全部免费 · 当前 "
                .. C.OutfitName(p:GetAttribute("Outfit") or 1)
                .. (p:GetAttribute("WardrobeSave") == "SessionOnly" and " · 本次会话保存" or "")
        end
        if preview and panel.Visible then
            preview:PivotTo(CFrame.Angles(0, math.sin(os.clock() * 0.5) * 0.35, 0))
        end
    end
    return { Update = update }
end
