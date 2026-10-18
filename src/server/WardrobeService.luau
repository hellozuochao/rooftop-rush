-- Dependencies are supplied by Systems.server; requiring this module has no side effects.
return function(deps)
    local rig = deps.rig
    local C = deps.C
    local function dress(a)
        local c, h, r = rig(a)
        if not c then
            return
        end
        local outfit = a:GetAttribute("Outfit") or 1
        local skin = C.Skins[a:GetAttribute("Skin") or 1]
        local style = (outfit - 1) % 8 + 1
        local tint = C.Palettes[math.floor((outfit - 1) / 8) + 1]
        local old = c:FindFirstChild("RunnerOutfit")
        if old then
            old:Destroy()
        end
        for _, v in c:GetDescendants() do
            if v:IsA("BasePart") and v ~= r then
                v.Color = skin
                v.Material = Enum.Material.SmoothPlastic
                if v:FindFirstAncestorOfClass("Accessory") then
                    v.Transparency = 1
                end
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("Shirt") then
                v.ShirtTemplate = ""
            elseif v:IsA("Pants") then
                v.PantsTemplate = ""
            elseif v:IsA("ShirtGraphic") then
                v.Graphic = ""
            end
        end
        local torso = c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso")
        local head = c:FindFirstChild("Head")
        if not torso or not head then
            return
        end
        local folder = Instance.new("Folder", c)
        folder.Name = "RunnerOutfit"
        local function piece(name, body, size, offset, color, neon)
            local v = Instance.new("Part")
            v.Name = name
            v.Size = size
            v.CFrame = body.CFrame * offset
            v.Color = color or tint
            v.Material = neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
            v.Massless = true
            v.CanCollide = false
            v.CanTouch = false
            v.CanQuery = false
            v.Parent = folder
            local w = Instance.new("WeldConstraint", v)
            w.Part0 = body
            w.Part1 = v
            return v
        end
        for _, n in { "LeftHand", "RightHand", "Left Arm", "Right Arm" } do
            local hand = c:FindFirstChild(n)
            if hand then
                piece(
                    "RaceGlove",
                    hand,
                    Vector3.new(hand.Size.X + 0.2, 0.65, hand.Size.Z + 0.25),
                    CFrame.new(0, -hand.Size.Y / 2 + 0.25, 0),
                    tint
                )
            end
        end
        piece(
            "Jacket",
            torso,
            Vector3.new(torso.Size.X + 0.1, torso.Size.Y * 0.65, torso.Size.Z + 0.12),
            CFrame.new(0, -0.18, 0),
            skin:Lerp(tint, 0.28)
        )
        piece(
            "ChestStripe",
            torso,
            Vector3.new(0.22, torso.Size.Y * 0.85, 0.12),
            CFrame.new(-0.3, 0, -torso.Size.Z / 2 - 0.12),
            tint,
            true
        )
        piece(
            "Visor",
            head,
            Vector3.new(head.Size.X + 0.12, 0.22, 0.16),
            CFrame.new(0, 0.1, -head.Size.Z / 2 - 0.12),
            tint,
            true
        )
        if style == 1 or style == 4 then
            for _, side in { -1, 1 } do
                piece(
                    "ShoulderArmor",
                    torso,
                    Vector3.new(0.55, 0.5, 0.85),
                    CFrame.new(side * (torso.Size.X / 2 + 0.2), 0.55, 0),
                    tint,
                    style == 4
                )
            end
        end
        if style == 2 or style == 6 then
            piece("PowerPack", torso, Vector3.new(1, 1.2, 0.6), CFrame.new(0, 0, torso.Size.Z / 2 + 0.35))
            for _, x in { -0.3, 0.3 } do
                piece(
                    "Thruster",
                    torso,
                    Vector3.new(0.2, 0.65, 0.2),
                    CFrame.new(x, -0.2, torso.Size.Z / 2 + 0.7),
                    tint,
                    true
                )
            end
        end
        if style == 3 then
            piece(
                "Mask",
                head,
                Vector3.new(head.Size.X + 0.08, 0.45, 0.15),
                CFrame.new(0, -0.25, -head.Size.Z / 2 - 0.1),
                skin
            )
            piece(
                "Scarf",
                torso,
                Vector3.new(0.35, 1.4, 0.16),
                CFrame.new(0.45, -0.5, -torso.Size.Z / 2 - 0.15)
            )
        end
        if style == 5 then
            for _, side in { -1, 1 } do
                piece(
                    "Wing",
                    torso,
                    Vector3.new(0.28, 1.8, 1.25),
                    CFrame.new(side * 1.1, 0.1, 0.65) * CFrame.Angles(0, 0, side * 0.45),
                    tint,
                    true
                )
            end
        end
        if style == 7 then
            for _, side in { -1, 1 } do
                piece(
                    "IceFin",
                    head,
                    Vector3.new(0.18, 0.75, 0.35),
                    CFrame.new(side * 0.45, 0.65, 0) * CFrame.Angles(0, 0, -side * 0.3),
                    tint,
                    true
                )
            end
        end
        if style == 8 then
            for i = -1, 1 do
                piece(
                    "Crown",
                    head,
                    Vector3.new(0.2, 0.5 + (0.2 - math.abs(i) * 0.2), 0.25),
                    CFrame.new(i * 0.35, 0.7, -0.1),
                    tint,
                    true
                )
            end
        end
        for _, n in { "LeftFoot", "RightFoot", "Left Leg", "Right Leg" } do
            local foot = c:FindFirstChild(n)
            if foot then
                piece(
                    "BootGlow",
                    foot,
                    Vector3.new(foot.Size.X + 0.08, 0.18, foot.Size.Z + 0.12),
                    CFrame.new(0, -foot.Size.Y / 2 + 0.12, 0),
                    tint,
                    true
                )
            end
        end
        local anchor = piece("TrailAnchor", torso, Vector3.new(0.1, 0.1, 0.1), CFrame.new(0, 0, 0.8))
        anchor.Transparency = 1
        local a0 = Instance.new("Attachment", anchor)
        a0.Position = Vector3.new(-0.45, 0, 0)
        local a1 = Instance.new("Attachment", anchor)
        a1.Position = Vector3.new(0.45, 0, 0)
        local trail = Instance.new("Trail", anchor)
        trail.Attachment0 = a0
        trail.Attachment1 = a1
        trail.Color = ColorSequence.new(tint)
        trail.Lifetime = 0.22
        trail.MinLength = 0.3
        trail.Transparency = NumberSequence.new(0.35, 1)
    end

    return { Dress = dress }
end
