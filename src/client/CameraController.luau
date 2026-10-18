local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local Modal = require(script.Parent.Modal)
local Camera = {}
local lastTarget, hidden = nil, {}
local lower = 0
local cursorFree = false
UIS.InputBegan:Connect(function(input, consumed)
    if not consumed and input.KeyCode == Enum.KeyCode.Tab and not UIS:GetFocusedTextBox() then
        cursorFree = not cursorFree
    end
end)
function Camera.Direction(input)
    local look=workspace.CurrentCamera.CFrame.LookVector
    local forward=Vector3.new(look.X,0,look.Z)
    if forward.Magnitude<0.001 then forward=Vector3.new(0,0,1) else forward=forward.Unit end
    local right=forward:Cross(Vector3.yAxis)
    return right*input.X-forward*input.Z, forward
end
function Camera.Update(p, gui, root, h, running, dt)
    local cam=workspace.CurrentCamera
    local target, subject, actor=root,h,p
    local raceGui=p.PlayerGui:FindFirstChild("RaceHUD")
    local raceState=Storage:FindFirstChild("RaceState")
    local isWatching=not running and raceState and raceState:GetAttribute("Phase")=="Racing"
    if isWatching then
        local candidates={}
        for _,q in Players:GetPlayers() do
            if q:GetAttribute("Running") and not q:GetAttribute("Finished") and q.Character then
                table.insert(candidates,{Actor=q,Character=q.Character})
            end
        end
        local bots=workspace:FindFirstChild("RacersNPC")
        if bots then
            for _,bot in bots:GetChildren() do
                if bot:GetAttribute("Running") and not bot:GetAttribute("Finished") then
                    table.insert(candidates,{Actor=bot,Character=bot})
                end
            end
        end
        local selected=raceGui and raceGui:GetAttribute("SpectateName")
        local best,lead=nil,-math.huge
        for _,entry in candidates do
            local r=entry.Character:FindFirstChild("HumanoidRootPart")
            local hum=entry.Character:FindFirstChildOfClass("Humanoid")
            if r and hum and hum.Health>0 then
                if selected==entry.Character.Name then best=entry;break end
                if r.Position.Z>lead then best=entry;lead=r.Position.Z end
            end
        end
        if best then
            target=best.Character.HumanoidRootPart
            subject=best.Character:FindFirstChildOfClass("Humanoid")
            actor=best.Actor
            if selected~="All" and selected~=best.Character.Name and raceGui then
                raceGui:SetAttribute("SpectateName","All")
            end
        end
    end
    if target~=lastTarget then
        for part, value in hidden do
            if part.Parent then part.LocalTransparencyModifier=value end
        end
        table.clear(hidden)
        lastTarget=target
        lower=0
        cam.CFrame=CFrame.lookAt(target.Position+Vector3.new(0,1.5,0),target.Position+Vector3.new(0,1.5,10))
    end
    local unlocked=Modal.Get()~="" or cursorFree or UIS:GetFocusedTextBox()~=nil or subject.Health<=0
    p.CameraMode=Enum.CameraMode.LockFirstPerson
    cam.CameraSubject=subject
    -- Native Roblox camera supplies mouse, touch and controller look; menus freeze it and release the cursor.
    cam.CameraType=unlocked and Enum.CameraType.Scriptable or Enum.CameraType.Custom
    if unlocked then
        UIS.MouseBehavior=Enum.MouseBehavior.Default
        UIS.MouseIconEnabled=true
    else
        UIS.MouseIconEnabled=false
    end
    local t=workspace:GetServerTimeNow()
    local sliding=actor==p and (gui:GetAttribute("SlideBlend") or 0)
        or ((actor:GetAttribute("SlideUntil") or 0)>t and 1 or 0)
    lower+=(sliding-lower)*(1-math.exp(-dt*18))
    -- Root-relative eyes avoid inheriting the animated body roll during sliding.
    local eye=target.Position+Vector3.new(0,1.5-3.6*lower,0)
    cam.CFrame=CFrame.new(eye)*cam.CFrame.Rotation
    cam.Focus=CFrame.new(eye+cam.CFrame.LookVector*10)
    local fov=(actor:GetAttribute("SprintUntil") or 0)>t and 80 or 75
    cam.FieldOfView+=(fov-cam.FieldOfView)*(1-math.exp(-dt*6))
    for _,part in subject.Parent:GetDescendants() do
        if part:IsA("BasePart") then
            if hidden[part]==nil then hidden[part]=0 end
            part.LocalTransparencyModifier=1
        end
    end
    gui:SetAttribute("FollowingUserId",actor:IsA("Player") and actor.UserId or 0)
    gui:SetAttribute("CursorFree",unlocked)
end
return Camera
