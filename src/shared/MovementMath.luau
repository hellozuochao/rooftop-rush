--!strict
local Motion = {}
function Motion.Approach(value: number, target: number, rate: number, dt: number): number
    return value + math.clamp(target - value, -rate * dt, rate * dt)
end
function Motion.Step(
    x: number,
    z: number,
    targetX: number,
    targetZ: number,
    dt: number,
    acceleration: number,
    braking: number
): (number, number)
    local rate = targetZ == 0 and braking or z * targetZ < 0 and 48 or acceleration
    local lateralRate = targetX == 0 and braking or x * targetX < 0 and 56 or 44
    return Motion.Approach(x, targetX, lateralRate, dt), Motion.Approach(z, targetZ, rate, dt)
end
function Motion.IsSlot(value: any, count: number): boolean
    return type(value) == "number" and value == value and value % 1 == 0 and value >= 1 and value <= count
end
return Motion
