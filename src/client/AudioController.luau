local Audio = {}
function Audio.Start(p, gui)
    local SoundService = game:GetService("SoundService")
    local Tween = game:GetService("TweenService")
    local Debris = game:GetService("Debris")
    local musicGroup = Instance.new("SoundGroup", SoundService)
    musicGroup.Name = "RaceMusic"
    local sfxGroup = Instance.new("SoundGroup", SoundService)
    sfxGroup.Name = "RaceSFX"
    local function volumes()
        musicGroup.Volume = gui:GetAttribute("MusicVolume") or 0.15
        sfxGroup.Volume = gui:GetAttribute("SFXVolume") or 0.75
    end
    gui:GetAttributeChangedSignal("MusicVolume"):Connect(volumes)
    gui:GetAttributeChangedSignal("SFXVolume"):Connect(volumes)
    volumes()
    local function sound(name, id, group, volume)
        local s = Instance.new("Sound", SoundService)
        s.Name = name
        s.SoundId = id
        s.SoundGroup = group
        s.Volume = volume
        return s
    end
    -- Roblox Creator Store / APM Music: Spirit Warmth: soft piano, pads and gentle drums.
    local music = sound("RooftopChaser", "rbxassetid://9042295159", musicGroup, 0)
    music.Looped = true
    music:Play()
    local function cue(file, pitch, volume)
        local s = sound("RaceCue", "rbxasset://sounds/" .. file, sfxGroup, volume or 0.3)
        s.PlaybackSpeed = pitch or 1
        s:Play()
        Debris:AddItem(s, 3)
    end
    local state = game.ReplicatedStorage:WaitForChild("RaceState")
    local function phase()
        local racing = state:GetAttribute("Phase") == "Racing"
        Tween:Create(music, TweenInfo.new(1.2), { Volume = racing and 0.22 or 0.12 }):Play()
        if racing then
            cue("volume_slider.ogg", 1.6, 0.4)
        end
    end
    state:GetAttributeChangedSignal("Phase"):Connect(phase)
    phase()
    for _, entry in
        {
            { "PickupSerial", "volume_slider.ogg", 1.5, 0.4 },
            { "UsedItemSerial", "action_get_up.mp3", 1.35, 0.35 },
            { "SlowUntil", "impact_water.mp3", 1.4, 0.3 },
            { "PunchUntil", "action_get_up.mp3", 1.8, 0.3 },
            { "SlideUntil", "action_footsteps_plastic.mp3", 0.7, 0.2 },
        }
    do
        p:GetAttributeChangedSignal(entry[1]):Connect(function()
            local v = p:GetAttribute(entry[1]) or 0
            if v > 0 and (entry[1]:find("Serial") or v > workspace:GetServerTimeNow()) then
                cue(entry[2], entry[3], entry[4])
            end
        end)
    end
    p:GetAttributeChangedSignal("Finished"):Connect(function()
        if p:GetAttribute("Finished") then
            for i = 1, 3 do
                task.delay((i - 1) * 0.15, function()
                    cue("volume_slider.ogg", 1 + i * 0.25, 0.35)
                end)
            end
        end
    end)
    -- Native avatar jump/landing/footsteps use the same effects-volume setting.
    local function character(c)
        local function attach(v)
            if v:IsA("Sound") then
                v.SoundGroup = sfxGroup
            end
        end
        for _, v in c:GetDescendants() do
            attach(v)
        end
        c.DescendantAdded:Connect(attach)
    end
    p.CharacterAdded:Connect(character)
    if p.Character then
        character(p.Character)
    end
end
return Audio
