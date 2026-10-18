local Art = require(game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("ItemArt"))
local Visuals = {}
function Visuals.Start()
    local Run=game:GetService("RunService")
    local Players=game:GetService("Players")
    local player=Players.LocalPlayer
    local folder=Instance.new("Folder",workspace)
    folder.Name="LocalSupplyArt"
    local supplies={}
    for i,source in workspace.NeonObby.Pickups:GetChildren() do
        local identity=source:FindFirstChild("ItemKey")
        if identity and Art.Colors[identity.Value] then
            local model=Art.Create(identity.Value,folder)
            local parts={}
            for _,part in model:GetChildren() do
                if part:IsA("BasePart") then parts[part]=part.Transparency end
            end
            source.LocalTransparencyModifier=1
            table.insert(supplies,{Source=source,Model=model,Parts=parts,Phase=i})
        end
    end
    -- A compact first-person status strip keeps buffs readable without filling the view with particles.
    local gui=Instance.new("ScreenGui",player.PlayerGui)
    gui.Name="ItemEffectsHUD"
    gui.ResetOnSpawn=false
    gui.DisplayOrder=2
    local strip=Instance.new("Frame",gui)
    strip.AnchorPoint=Vector2.new(0.5,0)
    strip.Position=UDim2.new(0.5,0,0,76)
    strip.Size=UDim2.fromOffset(270,46)
    strip.BackgroundTransparency=1
    local layout=Instance.new("UIListLayout",strip)
    layout.FillDirection=Enum.FillDirection.Horizontal
    layout.HorizontalAlignment=Enum.HorizontalAlignment.Center
    layout.Padding=UDim.new(0,5)
    local statuses={
        {Key="Boost",Attribute="SprintUntil"}, {Key="Shield",Attribute="ShieldUntil"},
        {Key="Cleanse",Attribute="ImmuneUntil"}, {Key="Decoy",Attribute="DecoyUntil"},
        {Key="Vacuum",Attribute="VacuumUntil"},
    }
    for _,entry in statuses do
        local frame=Instance.new("Frame",strip)
        frame.Size=UDim2.fromOffset(46,46)
        frame.BackgroundColor3=Color3.fromRGB(15,24,38)
        frame.BackgroundTransparency=0.18
        Instance.new("UICorner",frame).CornerRadius=UDim.new(0,8)
        Art.Icon(entry.Key,frame)
        local duration=Instance.new("TextLabel",frame)
        duration.Size=UDim2.fromOffset(44,14)
        duration.Position=UDim2.fromOffset(0,32)
        duration.BackgroundTransparency=1
        duration.TextColor3=Color3.new(1,1,1)
        duration.Font=Enum.Font.GothamBold
        duration.TextSize=12
        entry.Frame=frame
        entry.Duration=duration
    end
    local warning=Instance.new("TextLabel",gui)
    warning.AnchorPoint=Vector2.new(0.5,0)
    warning.Position=UDim2.new(0.5,0,0,126)
    warning.Size=UDim2.fromOffset(180,26)
    warning.BackgroundColor3=Color3.fromRGB(125,32,20)
    warning.BackgroundTransparency=0.2
    warning.TextColor3=Color3.fromRGB(255,220,180)
    warning.Font=Enum.Font.GothamBold
    warning.TextSize=15
    warning.Text="⚠ 飞弹接近 · 护盾可拦截"
    -- Temporary world effects are keyed by the server's successful-use event.
    local seen={}
    local bursts={}
    local function burst(actor,key,root,t)
        local model=Art.Create(key,folder)
        local parts={}
        for _,part in model:GetChildren() do
            if part:IsA("BasePart") then parts[part]=part.Transparency end
        end
        table.insert(bursts,{Model=model,Parts=parts,Root=root,Actor=actor,Key=key,Start=t})
    end
    Run.RenderStepped:Connect(function()
        local t=workspace:GetServerTimeNow()
        local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        -- ActivePanel is an empty string when all panels are closed.
        local panel=player.PlayerGui:GetAttribute("ActivePanel")
        local visibleHUD=player:GetAttribute("Running") and (panel==nil or panel=="")
        strip.Visible=visibleHUD
        warning.Visible=visibleHUD and (player:GetAttribute("IncomingUntil") or 0)>t
        warning.Text=player:GetAttribute("IncomingItem")=="Steal" and "⚠ 道具夺取 · 护盾可拦截" or "⚠ 飞弹接近 · 护盾可拦截"
        for _,entry in statuses do
            if entry.Attribute=="SprintUntil" then
                local key=player:GetAttribute("SprintItem")=="Magnet" and "Magnet" or "Boost"
                if entry.Key~=key then
                    entry.Frame.ItemIcon:Destroy()
                    Art.Icon(key,entry.Frame)
                    entry.Key=key
                end
            end
            local remaining=(player:GetAttribute(entry.Attribute) or 0)-t
            entry.Frame.Visible=remaining>0
            entry.Duration.Text=string.format("%.1fs",math.max(0,remaining))
        end
        for _,art in supplies do
            local source=art.Source
            source.LocalTransparencyModifier=1
            local near=root and (source.Position-root.Position).Magnitude<100
            local ready=(player:GetAttribute("SupplyReady"..source.Name) or 0)<=t
            for part,alpha in art.Parts do part.Transparency=near and ready and alpha or 1 end
            if near then
                art.Model:PivotTo(CFrame.new(source.Position+Vector3.new(0,0.45+math.sin(t*2+art.Phase)*0.2,0))
                    *CFrame.Angles(0,t*0.7+art.Phase,0))
            end
        end
        local actors=Players:GetPlayers()
        local bots=workspace:FindFirstChild("RacersNPC")
        if bots then for _,bot in bots:GetChildren() do table.insert(actors,bot) end end
        local alive={}
        for _,actor in actors do
            alive[actor]=true
            local serial=actor:GetAttribute("UsedItemSerial") or 0
            local key=actor:GetAttribute("LastUsedItem")
            local char=actor:IsA("Player") and actor.Character or actor
            local ar=char and char:FindFirstChild("HumanoidRootPart")
            if seen[actor]~=nil and serial~=seen[actor] and key and Art.Colors[key] and ar and root
                and (ar.Position-root.Position).Magnitude<100 then burst(actor,key,ar,t) end
            seen[actor]=serial
        end
        for actor in seen do if not alive[actor] then seen[actor]=nil end end
        for i=#bursts,1,-1 do
            local b=bursts[i]
            local age=t-b.Start
            if age>0.85 or not b.Root.Parent then
                b.Model:Destroy();table.remove(bursts,i)
            else
                local pos=b.Root.Position+Vector3.new(0,3+age,0)
                -- Local player sees the same silhouette briefly at the lower edge of the view.
                if b.Actor==player then
                    b.Model:PivotTo(workspace.CurrentCamera.CFrame*CFrame.new(-1,-0.8,-3.5)*CFrame.Angles(0,age,0))
                else b.Model:PivotTo(CFrame.new(pos)*CFrame.Angles(0,age*2,0)) end
                for part,alpha in b.Parts do part.Transparency=math.max(alpha,age/0.85) end
            end
        end
    end)
end
return Visuals
