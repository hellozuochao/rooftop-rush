local Module = {}
function Module.Start()
    local P = game:GetService("Players")
    local Run = game:GetService("RunService")
    -- Motor6D.Transform is local: every client animates NPCs from replicated physical velocity.
    local botPoses = setmetatable({}, { __mode = "k" })
    local punchRestores = {}
    Run.PreAnimation:Connect(function()
        for joint, pose in punchRestores do
            if joint.Parent then
                joint.Transform = pose
            end
        end
        table.clear(punchRestores)
    end)
    Run.PreSimulation:Connect(function(dt)
        local t = workspace:GetServerTimeNow()
        local folder = workspace:FindFirstChild("RacersNPC")
        local list = {}
        for _, q in P:GetPlayers() do
            table.insert(list, { q, q.Character })
        end
        if folder then
            for _, b in folder:GetChildren() do
                table.insert(list, { b, b })
            end
        end
        for _, entry in list do
            local actor, c = entry[1], entry[2]
            local left = (actor:GetAttribute("PunchUntil") or 0) - t
            if c and left > 0 then
                for _, j in c:GetDescendants() do
                    if
                        j:IsA("Motor6D")
                        and j.Part1
                        and (j.Part1.Name == "RightUpperArm" or j.Part1.Name == "Right Arm")
                    then
                        punchRestores[j] = j.Transform
                        local basis = j.C0.Rotation
                        local weight = math.sin(math.clamp(left / 0.32, 0, 1) * math.pi)
                        j.Transform = j.Transform
                            * basis:Inverse()
                            * CFrame.Angles(-1.65 * weight, 0, -0.15 * weight)
                            * basis
                    end
                end
            end
        end
    end)
end
return Module
