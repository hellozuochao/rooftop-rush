local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local Camera = {}
function Camera.Update(p, gui, root, h, running, dt)
    local cam = workspace.CurrentCamera
    local target, subject = root, h
    local raceGui = p.PlayerGui:FindFirstChild("RaceHUD")
    local spectate = raceGui and raceGui:GetAttribute("SpectateName")
    local isWatching = not running and Storage.RaceState:GetAttribute("Phase") == "Racing"
    local overviewDistance = 50
    if isWatching then
        local list = {}
        for _, q in Players:GetPlayers() do
            if q:GetAttribute("Running") and q.Character then
                table.insert(list, q.Character)
            end
        end
        local bots = workspace:FindFirstChild("RacersNPC")
        if bots then
            for _, bot in bots:GetChildren() do
                if bot:GetAttribute("Running") then
                    table.insert(list, bot)
                end
            end
        end
        local found = false
        if spectate and spectate ~= "All" then
            for _, c in list do
                if c.Name == spectate then
                    found = true
                    break
                end
            end
            if not found then
                spectate = "All"
                raceGui:SetAttribute("SpectateName", "All")
            end
        end
        if spectate and spectate ~= "All" then
            for _, c in list do
                if c.Name == spectate then
                    target = c:FindFirstChild("HumanoidRootPart") or root
                    subject = c:FindFirstChildOfClass("Humanoid") or h
                end
            end
        elseif #list > 0 then
            local lo, hi = math.huge, -math.huge
            for _, c in list do
                local r = c:FindFirstChild("HumanoidRootPart")
                if r then
                    lo = math.min(lo, r.Position.Z)
                    hi = math.max(hi, r.Position.Z)
                end
            end
            if hi > lo - 1 then
                overviewDistance = math.max(65, (hi - lo) * 0.8)
                target = { Position = Vector3.new(0, 5, (hi + lo) / 2) }
            end
        end
    end
    cam.CameraSubject = subject
    cam.CameraType = Enum.CameraType.Scriptable
    cam.FieldOfView = 55
    local distance = overviewDistance * (gui:GetAttribute("CameraDistance") or 1)
    local look = target.Position + Vector3.new(0, 1, isWatching and 0 or 10)
    local desired = CFrame.lookAt(look + Vector3.new(-distance, distance * 0.65, -distance * 0.25), look)
    cam.CFrame = cam.CFrame:Lerp(desired, 1 - math.exp(-dt * 8))
    gui:SetAttribute("FollowingUserId", subject == h and p.UserId or 0)
end
return Camera
