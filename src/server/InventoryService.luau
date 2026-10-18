-- Dependencies are supplied by Systems.server; requiring this module has no side effects.
return function(deps)
    local actors = deps.actors
    local C = deps.C
    local function syncBag(a)
        local st = actors[a]
        st.Inventory = st.Inventory or {}
        st.Selected = math.clamp(st.Selected or 1, 1, math.max(1, #st.Inventory))
        for i = 1, C.Rules.InventoryCapacity do
            a:SetAttribute("Inv" .. i, st.Inventory[i])
        end
        a:SetAttribute("SelectedSlot", st.Selected)
        a:SetAttribute("InventoryCount", #st.Inventory)
        a:SetAttribute("HeldItem", st.Inventory[st.Selected])
    end
    local function addItem(a, item)
        if not C.Items[item] then
            return false
        end
        local st = actors[a]
        st.Inventory = st.Inventory or {}
        if #st.Inventory >= C.Rules.InventoryCapacity then
            return false
        end
        table.insert(st.Inventory, item)
        syncBag(a)
        return true
    end
    local function removeItem(a)
        local st = actors[a]
        local result = table.remove(st.Inventory, st.Selected)
        syncBag(a)
        return result
    end

    return { Sync = syncBag, Add = addItem, Remove = removeItem }
end
