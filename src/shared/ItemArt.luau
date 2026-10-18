-- Shared, asset-free silhouettes for pickups, inventory previews and active items.
local Art = {}
Art.Colors = {
    Boost = Color3.fromRGB(255, 175, 45), Shield = Color3.fromRGB(45, 190, 255),
    Rocket = Color3.fromRGB(255, 90, 55), Leader = Color3.fromRGB(255, 205, 50),
    EMP = Color3.fromRGB(180, 90, 255), Trap = Color3.fromRGB(255, 65, 150),
    Magnet = Color3.fromRGB(255, 110, 70), Steal = Color3.fromRGB(235, 100, 230),
    Cleanse = Color3.fromRGB(90, 255, 170), Decoy = Color3.fromRGB(80, 235, 245),
    Spring = Color3.fromRGB(145, 255, 75), Vacuum = Color3.fromRGB(75, 150, 255),
    Smoke = Color3.fromRGB(165, 135, 200), Shockwave = Color3.fromRGB(80, 220, 255),
}
function Art.Create(key, parent)
    assert(Art.Colors[key], "Unknown item silhouette: " .. tostring(key))
    local model = Instance.new("Model")
    model.Name = key .. "Art"
    local tint = Art.Colors[key]
    local function part(name, size, pos, shape, color, rotation)
        local p = Instance.new("Part")
        p.Name = name
        p.Size = size
        p.Shape = shape or Enum.PartType.Block
        p.Color = color or tint
        p.Material = Enum.Material.SmoothPlastic
        p.Anchored = true
        p.CanCollide = false
        p.CanTouch = false
        p.CanQuery = false
        p.CastShadow = false
        p.CFrame = CFrame.new(pos) * (rotation or CFrame.identity)
        p.Parent = model
        return p
    end
    local function line(name, a, b, thickness, color)
        return part(name, Vector3.new(thickness, thickness, (b-a).Magnitude), (a+b)/2,
            nil, color, CFrame.lookAt(a,b).Rotation)
    end
    local function ring(name, radius, y)
        for i = 1, 12 do
            local a, b = (i-1)*math.pi/6, i*math.pi/6
            line(name, Vector3.new(math.cos(a)*radius,y,math.sin(a)*radius),
                Vector3.new(math.cos(b)*radius,y,math.sin(b)*radius),0.12)
        end
    end
    local white = Color3.fromRGB(230, 242, 250)
    local dark = Color3.fromRGB(30, 42, 60)
    if key == "Boost" then
        for _, x in {-0.45,0.45} do
            part("Turbine",Vector3.new(0.55,1.45,0.65),Vector3.new(x,0.1,0),nil,dark)
            part("Intake",Vector3.new(0.6,0.2,0.7),Vector3.new(x,0.85,0))
            part("Exhaust",Vector3.new(0.3,0.7,0.35),Vector3.new(x,-0.9,0),Enum.PartType.Ball).Material=Enum.Material.Neon
        end
    elseif key == "Shield" then
        part("ShieldFace",Vector3.new(1.5,1.35,0.25),Vector3.new(0,0.3,0))
        part("ShieldPoint",Vector3.new(0.95,0.95,0.25),Vector3.new(0,-0.55,0),nil,nil,CFrame.Angles(0,0,math.pi/4))
        part("ShieldStripe",Vector3.new(0.15,1.4,0.3),Vector3.new(0,0.2,0.05),nil,white)
    elseif key == "Rocket" or key == "Leader" then
        part("RocketBody",Vector3.new(0.65,1.5,0.65),Vector3.zero,Enum.PartType.Ball,white)
        part("Nose",Vector3.new(0.55,0.75,0.55),Vector3.new(0,0.85,0),Enum.PartType.Ball)
        for _, x in {-0.5,0.5} do
            part("Fin",Vector3.new(0.22,0.65,0.7),Vector3.new(x,-0.55,0),nil,nil,CFrame.Angles(0,0,-x*0.6))
        end
        part("Exhaust",Vector3.new(0.3,0.65,0.3),Vector3.new(0,-1,0),Enum.PartType.Ball).Material=Enum.Material.Neon
        if key == "Leader" then
            for _, x in {-0.45,0,0.45} do
                part("CrownPoint",Vector3.new(0.2,0.5,0.25),Vector3.new(x,1.45,0))
            end
            part("CrownBand",Vector3.new(1.1,0.2,0.25),Vector3.new(0,1.2,0))
        end
    elseif key == "EMP" then
        part("Capacitor",Vector3.one*0.8,Vector3.zero,Enum.PartType.Ball,dark)
        for _, x in {-0.6,0.6} do
            line("Bolt",Vector3.new(x,0.9,0),Vector3.new(x-0.25,0,0),0.2)
            line("Bolt",Vector3.new(x-0.25,0,0),Vector3.new(x+0.25,0.1,0),0.2)
            line("Bolt",Vector3.new(x+0.25,0.1,0),Vector3.new(x,-0.9,0),0.2)
        end
    elseif key == "Trap" then
        part("FieldPlate",Vector3.new(1.9,0.2,1.9),Vector3.new(0,-0.5,0),nil,dark)
        for _, x in {-0.6,0,0.6} do
            part("WarningRib",Vector3.new(0.15,0.65,1.6),Vector3.new(x,-0.1,0))
        end
    elseif key == "Magnet" or key == "Vacuum" then
        part("MagnetBridge",Vector3.new(1.4,0.4,0.45),Vector3.new(0,-0.55,0))
        for _, x in {-0.5,0.5} do
            part("MagnetArm",Vector3.new(0.4,1.15,0.45),Vector3.new(x,0.15,0))
            part("MagnetPole",Vector3.new(0.42,0.3,0.5),Vector3.new(x,0.8,0),nil,white)
        end
        if key == "Vacuum" then
            for _, x in {-0.65,0,0.65} do
                part("Collectible",Vector3.one*0.25,Vector3.new(x,1.3,0),Enum.PartType.Ball,white)
            end
        else
            for _, x in {-0.22,0.22} do
                line("PullArrow",Vector3.new(x,1.3,0),Vector3.new(0,1,0),0.12,white)
            end
        end
    elseif key == "Steal" then
        part("ClawPalm",Vector3.new(0.9,0.65,0.45),Vector3.new(0,-0.3,0))
        for _, x in {-0.5,0,0.5} do
            line("Finger",Vector3.new(x,-0.1,0),Vector3.new(x,0.8,0),0.18)
            line("Hook",Vector3.new(x,0.8,0),Vector3.new(x,0.8,0.45),0.18,white)
        end
    elseif key == "Cleanse" then
        part("CrossVertical",Vector3.new(0.4,1.7,0.4),Vector3.zero)
        part("CrossHorizontal",Vector3.new(1.4,0.4,0.4),Vector3.new(0,0.1,0))
        ring("CleanRing",0.95,-0.9)
    elseif key == "Decoy" then
        part("HoloHead",Vector3.one*0.55,Vector3.new(0,0.8,0),Enum.PartType.Ball)
        part("HoloBody",Vector3.new(0.65,0.8,0.3),Vector3.new(0,0.1,0))
        for _, x in {-0.45,0.45} do
            part("HoloArm",Vector3.new(0.2,0.7,0.25),Vector3.new(x,0.1,0))
            part("HoloLeg",Vector3.new(0.2,0.6,0.25),Vector3.new(x*0.5,-0.6,0))
        end
    elseif key == "Spring" then
        part("SpringBase",Vector3.new(1.6,0.2,1.1),Vector3.new(0,-0.8,0),nil,dark)
        for i=0,3 do ring("Coil",0.5,-0.5+i*0.35) end
        part("SpringTop",Vector3.new(1.6,0.2,1.1),Vector3.new(0,0.8,0))
    elseif key == "Smoke" then
        part("Canister",Vector3.new(0.75,1.2,0.75),Vector3.new(0,-0.3,0))
        part("Cap",Vector3.new(0.55,0.2,0.55),Vector3.new(0,0.4,0),nil,dark)
        for i=1,3 do
            local puff=part("SmokePuff",Vector3.one*(0.3+i*0.2),Vector3.new((i%2-0.5)*0.4,0.4+i*0.35,0),Enum.PartType.Ball)
            puff.Transparency=0.25
        end
    elseif key == "Shockwave" then
        ring("WaveInner",0.4,-0.4)
        ring("WaveMiddle",0.75,0)
        ring("WaveOuter",1.1,0.4)
    end
    model.WorldPivot=CFrame.identity
    model.Parent=parent
    return model
end
function Art.Icon(key, parent)
    local viewport=Instance.new("ViewportFrame")
    viewport.Name="ItemIcon"
    viewport.BackgroundTransparency=1
    viewport.Size=UDim2.fromOffset(42,42)
    viewport.Position=UDim2.fromOffset(2,1)
    viewport.Ambient=Color3.fromRGB(190,190,190)
    viewport.LightColor=Color3.new(1,1,1)
    viewport.Active=false
    local camera=Instance.new("Camera",viewport)
    camera.CFrame=CFrame.lookAt(Vector3.new(0,1.5,5.6),Vector3.new(0,0.15,0))
    camera.FieldOfView=38
    viewport.CurrentCamera=camera
    Art.Create(key,viewport)
    viewport.Parent=parent
    return viewport
end
return Art
