local Motion = require("../src/shared/MovementMath")
local Rules = require("../src/shared/Rules")
local checks = 0
local function check(value, message)
    assert(value, message)
    checks += 1
end
local function near(a, b)
    return math.abs(a - b) < 0.001
end
for _, hz in { 30, 60, 120 } do
    local x, z = 0, 0
    for i = 1, hz do
        x, z = Motion.Step(x, z, 17, 32, 1 / hz, 16, 24)
    end
    check(near(x, 17) and near(z, 16), "frame-independent acceleration/diagonal")
    for i = 1, hz * 2 do
        x, z = Motion.Step(x, z, 0, 0, 1 / hz, 16, 24)
    end
    check(x == 0 and z == 0, "braking must settle without oscillation")
    x, z = 0, 32
    for i = 1, hz * 3 do
        x, z = Motion.Step(x, z, 0, -32, 1 / hz, 16, 24)
    end
    check(z < 0 and z >= -32, "reverse remains bounded")
end
for _, hz in { 30, 60, 120 } do
    local x, z = 17, 32
    for i = 1, hz / 2 do
        x, z = Motion.Step(x, z, -17, 32, 1 / hz, 16, 24)
    end
    check(near(z, 32), "steering never steals forward speed")
    check(x < 0 and x >= -17, "lateral reversal smooth and bounded")
    local nextX = Motion.Step(17, 32, 0, 32, 1 / hz, 16, 24)
    check(nextX > 0 and nextX < 17, "lateral release decelerates instead of snapping")
end
for _, bad in { 0, -1, 7, 1.5, math.huge, -math.huge, 0 / 0, "1", {} } do
    check(not Motion.IsSlot(bad, 6), "invalid slot accepted")
end
check(Motion.IsSlot(6, 6), "last slot valid")
local actor = { Attributes = {} }
function actor:SetAttribute(k, v)
    self.Attributes[k] = v
end
local states = { [actor] = {} }
local bag = require("../src/server/InventoryService")({
    actors = states,
    C = { Rules = Rules, Items = { Boost = true, Shield = true } },
})
check(not bag.Add(actor, "Unknown"), "unknown item accepted")
for i = 1, 6 do
    check(bag.Add(actor, i % 2 == 0 and "Shield" or "Boost"), "could not fill inventory")
end
check(not bag.Add(actor, "Boost"), "bag overflow")
check(actor.Attributes.InventoryCount == 6, "replicated count")
states[actor].Selected = 6
bag.Sync(actor)
check(bag.Remove(actor) == "Shield", "selected item not used")
check(actor.Attributes.Inv6 == nil and actor.Attributes.SelectedSlot == 5, "stale final slot")
for i = 1, 5 do
    bag.Remove(actor)
end
check(actor.Attributes.InventoryCount == 0 and actor.Attributes.HeldItem == nil, "empty bag state")
print("CORE_PASS", checks)
