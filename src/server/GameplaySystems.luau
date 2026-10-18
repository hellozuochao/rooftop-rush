local Module = {}
local runtime
function Module.Get()
    return assert(runtime, "Gameplay systems have not started")
end
function Module.Start()
    if runtime then
        return runtime
    end
    local P = game:GetService("Players")
    local S = game:GetService("ReplicatedStorage")
    local Run = game:GetService("RunService")
    local Debris = game:GetService("Debris")
    local C = require(S:WaitForChild("RunnerConfig"))
    local InputMath = require(S:WaitForChild("SharedModules"):WaitForChild("MovementMath"))
    local map = workspace.NeonObby
    local markImpact = S:WaitForChild("MarkImpactRespawn")
    local remote = Instance.new("RemoteEvent", S)
    remote.Name = "SkylineAction"
    local spawnBots = Instance.new("BindableFunction", S)
    spawnBots.Name = "SpawnBots"
    local stopBots = Instance.new("BindableEvent", S)
    stopBots.Name = "StopBots"
    local bots = Instance.new("Folder", workspace)
    bots.Name = "RacersNPC"
    local actors, profiles = {}, {}
    local storeOK, store = pcall(function()
        return game:GetService("DataStoreService"):GetDataStore("FreeRunnerLooks_v1")
    end)
    if not storeOK then
        store = nil
    end
    local function now()
        return workspace:GetServerTimeNow()
    end
    local function model(a)
        return a:IsA("Player") and a.Character or a
    end
    local function rig(a)
        local c = model(a)
        local h = c and c:FindFirstChildOfClass("Humanoid")
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if h and r and h.Health > 0 then
            return c, h, r
        end
    end
    local function active(a)
        return a:GetAttribute("Running") and not a:GetAttribute("Finished")
    end
    local function notice(a, t)
        a:SetAttribute("ActionNotice", t)
        a:SetAttribute("ActionNoticeUntil", now() + 3)
    end
    local function effect(pos, color, size)
        local v = Instance.new("Part", workspace)
        v.Shape = Enum.PartType.Ball
        v.Size = Vector3.new(size, size, size)
        v.Position = pos
        v.Anchored = true
        v.CanCollide = false
        v.CanTouch = false
        v.Material = Enum.Material.Neon
        v.Color = color
        v.Transparency = 0.65
        v.CanQuery = false
        game:GetService("TweenService")
            :Create(v, TweenInfo.new(0.45), { Size = v.Size * 1.6, Transparency = 1 })
            :Play()
        Debris:AddItem(v, 0.45)
    end
    local function same(a, b)
        return a ~= b
            and active(a)
            and active(b)
            and a:GetAttribute("RaceRound") == b:GetAttribute("RaceRound")
    end
    local function opponents(a)
        local t = {}
        for b in actors do
            if same(a, b) then
                local _, _, r = rig(b)
                if r then
                    table.insert(t, b)
                end
            end
        end
        table.sort(t, function(x, y)
            return model(x).HumanoidRootPart.Position.Z > model(y).HumanoidRootPart.Position.Z
        end)
        return t
    end

    local modules = script.Parent
    local deps = {
        actors = actors,
        C = C,
        map = map,
        rig = rig,
        model = model,
        active = active,
        now = now,
        notice = notice,
        effect = effect,
        same = same,
        opponents = opponents,
        markImpact = markImpact,
        S = S,
        Run = Run,
        Debris = Debris,
        bots = bots,
    }
    local collision = require(modules.CollisionService)(deps)
    deps.knock = collision.Knock
    local combat = require(modules.CombatService)(deps)
    local punch = combat.Punch
    deps.punch = punch
    deps.strike = combat.Strike
    local wardrobe = require(modules.WardrobeService)(deps)
    local dress = wardrobe.Dress
    deps.dress = dress
    local inventory = require(modules.InventoryService)(deps)
    local syncBag = inventory.Sync
    deps.syncBag = syncBag
    deps.addItem = inventory.Add
    deps.removeItem = inventory.Remove
    local items = require(modules.ItemService)(deps)
    local use = items.Use
    deps.use = use
    local npc = require(modules.NpcService)(deps)
    local rewards = require(modules.CourseRewards)(deps)
    local function reset(a)
        local st = actors[a]
        if not st then
            return
        end
        st.Picked = {}
        st.Walls = {}
        st.Items = {}
        st.Speed = 0
        st.SprintAt = nil
        st.UseAt = nil
        st.ContactAt = nil
        st.PreviousVelocity = nil
        a:SetAttribute("SprintReadyAt", 0)
        st.Decisions = {}
        st.Inventory = {}
        st.Selected = 1
        syncBag(a)
        for _, key in
            {
                "SlowUntil",
                "SprintUntil",
                "ShieldUntil",
                "SlideUntil",
                "RollUntil",
                "IncomingUntil",
                "ImmuneUntil",
                "DecoyUntil",
                "VacuumUntil",
                "PunchReadyAt",
                "PunchUntil",
                "StaggerUntil",
            }
        do
            a:SetAttribute(key, 0)
        end
        a:SetAttribute("HeldItem", nil)
        a:SetAttribute("Collected", 0)
        a:SetAttribute("ActionCount", 0)
        a:SetAttribute("Combo", 0)
        a:SetAttribute("Hanging", false)
        for _, supply in map.Pickups:GetChildren() do
            a:SetAttribute("SupplyReady" .. supply.Name, 0)
        end
        for _, key in { "ContactUntil", "ContactX", "ContactScale" } do
            a:SetAttribute(key, 0)
        end
        for _, coin in map.Collectibles:GetChildren() do
            a:SetAttribute("Picked" .. coin.Name, false)
        end
    end
    local function save(p)
        local d = profiles[p]
        if not d or not d.Loaded then
            return
        end
        local ok = pcall(function()
            store:SetAsync(
                tostring(p.UserId),
                { Outfit = p:GetAttribute("Outfit"), Skin = p:GetAttribute("Skin") }
            )
        end)
        if p.Parent then
            p:SetAttribute("WardrobeSave", ok and "Saved" or "SessionOnly")
        end
    end
    local function joined(p)
        actors[p] = { Picked = {}, Walls = {}, Items = {}, Decisions = {} }
        profiles[p] = { Loaded = false }
        p:SetAttribute("Outfit", 1)
        p:SetAttribute("Skin", 1)
        p:SetAttribute("ProfileReady", true)
        p.CharacterAdded:Connect(function(c)
            c:WaitForChild("HumanoidRootPart")
            task.wait(0.2)
            dress(p)
            p:SetAttribute("Hanging", false)
        end)
        p.CharacterAppearanceLoaded:Connect(function()
            dress(p)
        end)
        p:GetAttributeChangedSignal("StartedAt"):Connect(function()
            reset(p)
        end)
        task.spawn(function()
            local ok, d = pcall(function()
                return store:GetAsync(tostring(p.UserId))
            end)
            if not p.Parent then
                return
            end
            profiles[p].Loaded = ok
            if ok and type(d) == "table" and not profiles[p].Changed then
                p:SetAttribute("Outfit", math.clamp(math.floor(tonumber(d.Outfit) or 1), 1, 24))
                p:SetAttribute("Skin", math.clamp(math.floor(tonumber(d.Skin) or 1), 1, 8))
            end
            p:SetAttribute("WardrobeSave", ok and "Saved" or "SessionOnly")
            dress(p)
        end)
    end
    P.PlayerAdded:Connect(joined)
    for _, p in P:GetPlayers() do
        joined(p)
    end
    P.PlayerRemoving:Connect(function(p)
        save(p)
        actors[p] = nil
        profiles[p] = nil
    end)
    remote.OnServerEvent:Connect(function(p, kind, value)
        local st = actors[p]
        if not st then
            return
        end
        if kind == "Outfit" or kind == "Skin" then
            local limit = kind == "Outfit" and 24 or 8
            if
                type(value) ~= "number"
                or value % 1 ~= 0
                or value < 1
                or value > limit
                or now() - (st.DressAt or 0) < 0.2
            then
                return
            end
            st.DressAt = now()
            profiles[p].Changed = true
            p:SetAttribute(kind, value)
            dress(p)
            return
        end
        if kind == "SelectSlot" then
            if InputMath.IsSlot(value, #(st.Inventory or {})) then
                st.Selected = value
                syncBag(p)
            end
            return
        end
        local _, _, r = rig(p)
        if not r or not active(p) then
            return
        end
        if kind == "UseSlot" then
            if InputMath.IsSlot(value, #(st.Inventory or {})) and now() - (st.UseAt or 0) >= 0.5 then
                st.Selected = value
                syncBag(p)
                use(p)
            end
        elseif kind == "Punch" then
            punch(p)
        elseif kind == "Item" then
            use(p)
        end
    end)
    spawnBots.OnInvoke = function(owner, difficulty, round)
        npc.Clear()
        for i = 1, 3 do
            npc.Create(i, owner, difficulty, round)
        end
    end
    stopBots.Event:Connect(function()
        npc.Clear()
        items.Clear()
    end)
    Run.Heartbeat:Connect(function(dt)
        local t = now()
        collision.Update(dt)
        items.Update(t)
        for a, st in actors do
            rewards.Update(a, st, t)
            if st.Bot then
                npc.Update(a, st, dt, t)
            end
        end
    end)
    task.spawn(function()
        while task.wait(30) do
            for p, d in profiles do
                if d.Changed then
                    d.Changed = false
                    task.spawn(save, p)
                end
            end
        end
    end)
    game:BindToClose(function()
        for p in profiles do
            task.spawn(save, p)
        end
        task.wait(2)
    end)

    runtime = {
        Inventory = inventory,
        Items = items,
        Combat = combat,
        Collision = collision,
        NPC = npc,
        Actors = actors,
    }
    return runtime
end
return Module
