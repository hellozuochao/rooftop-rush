local Visuals = {}
function Visuals.Start()
    local Run = game:GetService("RunService")
    local player = game.Players.LocalPlayer
    local folder = Instance.new("Folder", workspace)
    folder.Name = "LocalSupplyArt"
    local supplies = {}
    local function piece(name, shape, size, color, parent)
        local part = Instance.new("Part", parent)
        part.Name = name
        part.Shape = shape
        part.Size = size
        part.Color = color
        part.Material = Enum.Material.Neon
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        return part
    end
    for i, supply in workspace.NeonObby.Pickups:GetChildren() do
        local model = Instance.new("Model", folder)
        model.Name = supply.Name
        local core = piece("EnergyCore", Enum.PartType.Ball, Vector3.one * 1.5, supply.Color, model)
        local shells = {}
        for j = 1, 3 do
            shells[j] = piece("Orbit" .. j, Enum.PartType.Ball, Vector3.one * 0.3, supply.Color, model)
        end
        local aura = Instance.new("ParticleEmitter", core)
        aura.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        aura.Color = ColorSequence.new(supply.Color)
        aura.Rate = 5
        aura.Lifetime = NumberRange.new(0.4, 0.8)
        aura.Speed = NumberRange.new(0.2, 0.8)
        aura.Size =
            NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0) })
        aura.LightEmission = 1
        local light = Instance.new("PointLight", core)
        light.Color = supply.Color
        light.Range = 8
        light.Brightness = 0.8
        table.insert(
            supplies,
            { Source = supply, Core = core, Shells = shells, Aura = aura, Light = light, Phase = i }
        )
    end
    Run.RenderStepped:Connect(function()
        local t = workspace:GetServerTimeNow()
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        for _, art in supplies do
            local source = art.Source
            source.LocalTransparencyModifier = 1
            local near = root and (source.Position - root.Position).Magnitude < 110
            local ready = (player:GetAttribute("SupplyReady" .. source.Name) or 0) <= t
            local visible = near and ready
            art.Core.Transparency = visible and 0.12 or 1
            art.Aura.Enabled = visible
            art.Light.Enabled = visible
            if near then
                local center = source.Position + Vector3.new(0, 0.5 + math.sin(t * 2 + art.Phase) * 0.35, 0)
                art.Core.CFrame = CFrame.new(center)
                for j, orb in art.Shells do
                    local angle = t * 2.5 + j * math.pi * 2 / 3
                    orb.Position = center
                        + Vector3.new(math.cos(angle) * 1.6, math.sin(angle) * 0.8, math.sin(angle) * 1.6)
                    orb.Transparency = visible and 0.1 or 1
                end
            else
                for _, orb in art.Shells do
                    orb.Transparency = 1
                end
            end
        end
    end)
end
return Visuals
