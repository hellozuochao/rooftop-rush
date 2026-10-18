-- Shared tuning values. Server remains authoritative over validation and state.
return table.freeze({
    InventoryCapacity = 6,
    SupplyCooldown = 12,
    PunchRange = 5,
    PunchCooldown = 2.5,
    PunchSlowdown = 0.7,
    PunchRecovery = 0.25,
})
