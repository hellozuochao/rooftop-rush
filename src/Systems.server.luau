local info = game:GetService("ReplicatedStorage"):WaitForChild("BuildInfo")
local platformVersion = Instance.new("StringValue")
platformVersion.Name = "RobloxVersion"
platformVersion.Value = tostring(game.PlaceVersion)
platformVersion.Parent = info

require(script.Parent:WaitForChild("ServerModules"):WaitForChild("GameplaySystems")).Start()
