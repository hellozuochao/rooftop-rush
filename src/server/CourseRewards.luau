local Art = require(game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("ItemArt"))
-- Dependencies are supplied by Systems.server; requiring this module has no side effects.
return function(deps)
    local rig = deps.rig
    local active = deps.active
    local now = deps.now
    local map = deps.map
    local C = deps.C
    local opponents = deps.opponents
    local model = deps.model
    local addItem = deps.addItem
    local notice = deps.notice
    local effect = deps.effect
    local function update(a, st, t)
        local c, h, r = rig(a)
        if not r or not active(a) then
            if c then
                for _, visual in c:GetChildren() do
                    if visual.Name:match("^ActiveItem") or visual.Name == "RaceShield" then visual:Destroy() end
                end
            end
            return
        end
        local z = r.Position.Z
        -- Landing has no automatic slowdown. Only obstacle/item impacts reduce speed.
        for _, coin in map.Collectibles:GetChildren() do
            if
                not st.Picked[coin]
                and (r.Position - coin.Position).Magnitude
                    < ((a:GetAttribute("VacuumUntil") or 0) > t and 16 or 4)
            then
                st.Picked[coin] = true
                a:SetAttribute("Collected", (a:GetAttribute("Collected") or 0) + 1)
                a:SetAttribute("Picked" .. coin.Name, true)
            end
        end
        for _, supply in map.Pickups:GetChildren() do
            if
                (r.Position - supply.Position).Magnitude
                    < ((a:GetAttribute("VacuumUntil") or 0) > t and 16 or 5)
                and t - (st.Items[supply] or -30) > C.Rules.SupplyCooldown
                and #(st.Inventory or {}) < C.Rules.InventoryCapacity
            then
                st.Items[supply] = t
                local list = opponents(a)
                local gap = list[1] and model(list[1]).HumanoidRootPart.Position.Z - z or 0
                local pool = gap > 65
                        and { "Leader", "Leader", "Magnet", "Boost", "Rocket", "Shield", "Vacuum", "Cleanse" }
                    or gap > 15 and {
                        "Rocket",
                        "Boost",
                        "Magnet",
                        "EMP",
                        "Shield",
                        "Steal",
                        "Decoy",
                        "Spring",
                        "Shockwave",
                    }
                    or {
                        "Shield",
                        "Trap",
                        "EMP",
                        "Boost",
                        "Cleanse",
                        "Decoy",
                        "Smoke",
                        "Spring",
                        "Vacuum",
                        "Shockwave",
                    }
                local category = supply:FindFirstChild("Category")
                if category and category.Value == "防御补给" then
                    pool = { "Shield", "Cleanse", "Decoy" }
                elseif category and category.Value == "机动补给" then
                    pool = { "Boost", "Magnet", "Spring", "Vacuum" }
                elseif category and category.Value == "攻击补给" then
                    pool = gap > 65 and { "Leader", "Rocket", "Steal" }
                        or { "Rocket", "EMP", "Trap", "Shockwave", "Smoke", "Steal" }
                end
                local identity = supply:FindFirstChild("ItemKey")
                local gained = identity and C.Items[identity.Value] and identity.Value or pool[math.random(#pool)]
                addItem(a, gained)
                notice(a, "已存入背包：" .. C.Items[gained])
                a:SetAttribute("SupplyReady" .. supply.Name, t + C.Rules.SupplyCooldown)
                a:SetAttribute("PickupSerial", (a:GetAttribute("PickupSerial") or 0) + 1)
                effect(supply.Position, supply.Color, 3)
            end
        end
        for _, node in map.RouteNodes:GetChildren() do
            if
                math.abs(z - node.Position.Z) < 2
                and math.abs(r.Position.X - node.Position.X) < node.Size.X / 2
                and r.Position.Y > 4.5
                and r.AssemblyLinearVelocity.Y > 0
                and t - (a:GetAttribute("LastJumpAt") or -10) < 0.65
                and t - (st.Walls[node] or -10) > 1
            then
                st.Walls[node] = t
                r.AssemblyLinearVelocity =
                    Vector3.new(r.AssemblyLinearVelocity.X, 55, r.AssemblyLinearVelocity.Z)
                notice(a, "蹬墙 · 上层路线")
            end
        end
        -- Persistent effects communicate duration to other racers; first-person HUD mirrors these attributes.
        for _,entry in {{"SprintUntil","Boost"},{"ShieldUntil","Shield"},{"DecoyUntil","Decoy"},{"VacuumUntil","Vacuum"},{"ImmuneUntil","Cleanse"}} do
            local name="ActiveItem"..entry[2]
            local visual=c:FindFirstChild(name)
            local enabled=(a:GetAttribute(entry[1]) or 0)>t
            if enabled and not visual then
                visual=Instance.new("Model",c)
                visual.Name=name
                if entry[2]=="Shield" then
                    local sphere=Instance.new("Part",visual)
                    sphere.Name="ShieldBubble"
                    sphere.Shape=Enum.PartType.Ball
                    sphere.Size=Vector3.new(6,7,6)
                    sphere.Material=Enum.Material.ForceField
                    sphere.Color=Art.Colors.Shield
                    sphere.Transparency=0.7
                    sphere.Anchored=true
                    sphere.CanCollide=false
                    sphere.CanTouch=false
                    sphere.CanQuery=false
                else
                    local icon=Art.Create(entry[2],visual)
                    icon:ScaleTo(entry[2]=="Decoy" and 1.6 or 0.75)
                end
            elseif not enabled and visual then
                visual:Destroy()
                visual=nil
            end
            if visual then
                local offset=entry[2]=="Shield" and Vector3.zero
                    or entry[2]=="Decoy" and Vector3.new(0,0,3)
                    or entry[2]=="Boost" and Vector3.new(0,0,1.5)
                    or Vector3.new(math.cos(t*3)*2.5,0.5,math.sin(t*3)*2.5)
                if entry[2]=="Shield" then visual.ShieldBubble.CFrame=r.CFrame
                else
                    local icon=visual:FindFirstChildOfClass("Model")
                    if icon then icon:PivotTo(r.CFrame*CFrame.new(offset)) end
                end
            end
        end
        local shield = (a:GetAttribute("ShieldUntil") or 0) > t
        local highlight = c:FindFirstChild("RaceShield")
        if shield and not highlight then
            highlight = Instance.new("Highlight", c)
            highlight.Name = "RaceShield"
            highlight.FillColor = Color3.fromRGB(65, 210, 255)
            highlight.FillTransparency = 0.65
        elseif not shield and highlight then
            highlight:Destroy()
        end
    end
    return { Update = update }
end
