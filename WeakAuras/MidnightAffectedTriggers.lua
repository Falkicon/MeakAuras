--[[ MidnightAffectedTriggers.lua
    Defines which trigger types are affected by Midnight (12.0+) secret values.
    
    These triggers may not update properly during instanced combat because they
    rely on APIs that return secret values.
    
    This module can be used by the Options UI to:
    - Add lock icons to affected trigger types
    - Show tooltips explaining the limitation
    - Warn users when creating affected auras
]]

if not WeakAuras then return end

---@class Private
local Private = select(2, ...)

-- Trigger types affected by secret values
-- Key: trigger type identifier
-- Value: { apis = list of affected APIs, severity = "high"|"medium" }
Private.MidnightAffectedTriggers = {
    -- High severity: Core display values become secret
    ["health"] = {
        apis = { "UnitHealth", "UnitHealthMax" },
        severity = "high",
        tooltip = "Health values become secret during instanced combat. Display will show degraded state.",
    },
    ["power"] = {
        apis = { "UnitPower", "UnitPowerMax" },
        severity = "high",
        tooltip = "Power values become secret during instanced combat. Display will show degraded state.",
    },
    ["Cooldown Progress (Spell)"] = {
        apis = { "C_Spell.GetSpellCooldown", "GetSpellCooldown" },
        severity = "high",
        tooltip = "Cooldown timing becomes secret during instanced combat. Display will show degraded state.",
    },
    ["Cooldown Progress (Item)"] = {
        apis = { "C_Container.GetItemCooldown" },
        severity = "high", 
        tooltip = "Cooldown timing becomes secret during instanced combat. Display will show degraded state.",
    },
    ["Spell Charges"] = {
        apis = { "C_Spell.GetSpellCharges", "GetSpellCharges" },
        severity = "high",
        tooltip = "Charge counts become secret during instanced combat. Display will show degraded state.",
    },
    
    -- Medium severity: Some data becomes secret but aura can still function
    ["aura"] = {
        apis = { "C_UnitAuras" },
        fields = { "expirationTime", "duration", "applications" },
        severity = "medium",
        tooltip = "Aura duration and stacks become secret during instanced combat. Timer text will show '...'.",
    },
    
    -- Combat log: Events don't fire at all in instances
    ["combat log"] = {
        apis = { "CombatLogGetCurrentEventInfo" },
        severity = "high",
        tooltip = "Combat log events do not fire in Midnight instances. This trigger will not work in dungeons/raids.",
    },
}

-- Check if a trigger type is affected by Midnight secret values
---@param triggerType string The trigger type identifier
---@return boolean isAffected
---@return string|nil severity ("high" or "medium")
---@return string|nil tooltip Explanation text
function Private.IsTriggerAffectedByMidnight(triggerType)
    local info = Private.MidnightAffectedTriggers[triggerType]
    if info then
        return true, info.severity, info.tooltip
    end
    return false, nil, nil
end

-- Get a display name with lock icon prefix if affected
---@param triggerType string The trigger type identifier
---@param displayName string The original display name
---@return string The display name, possibly with lock icon prefix
function Private.GetMidnightAwareTriggerName(triggerType, displayName)
    local isAffected = Private.IsTriggerAffectedByMidnight(triggerType)
    if isAffected then
        -- Use texture escape sequence for lock icon
        -- Note: This atlas may need to be adjusted based on what's available
        return "|A:communities-icon-lock:12:12|a " .. displayName
    end
    return displayName
end

-- Get tooltip text for a trigger explaining Midnight limitations
---@param triggerType string The trigger type identifier
---@return string|nil Tooltip text, or nil if not affected
function Private.GetMidnightTriggerTooltip(triggerType)
    local isAffected, severity, tooltip = Private.IsTriggerAffectedByMidnight(triggerType)
    if isAffected and tooltip then
        local prefix = severity == "high" 
            and "|cffff6600Midnight (12.0+) Warning:|r " 
            or "|cffffff00Midnight (12.0+) Note:|r "
        return prefix .. tooltip
    end
    return nil
end
