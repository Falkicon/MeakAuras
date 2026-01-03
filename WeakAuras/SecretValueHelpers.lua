--[[ SecretValueHelpers.lua
    Helper functions for handling Midnight (12.0) secret values.
    
    Secret values are API returns that become opaque during combat in instanced content.
    These helpers provide safe wrappers to prevent errors when values are secret.
]]

if not WeakAuras then return end

---@class Private
local Private = select(2, ...)

-- Detect Midnight (12.0+)
local IS_MIDNIGHT = (select(4, GetBuildInfo()) >= 120000)

--- Check if a value is a secret value (Midnight 12.0+)
--- Uses issecretvalue() if available, falls back to type check for userdata
---@param value any The value to check
---@return boolean True if the value is secret
function Private.IsValueSecret(value)
    if not IS_MIDNIGHT then return false end
    -- Primary check: use issecretvalue() global if available
    if issecretvalue then
        return issecretvalue(value) == true
    end
    -- Fallback: secret values are userdata that look like numbers/strings/booleans
    -- In M+/Raids, API returns become userdata instead of their normal types
    if type(value) == "userdata" then
        return true
    end
    return false
end

--- Check if any value in a list is secret
---@param ... any Values to check
---@return boolean True if any value is secret
function Private.AnyValueSecret(...)
    if not IS_MIDNIGHT then return false end
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if Private.IsValueSecret(v) then return true end
    end
    return false
end

--- Safe comparison that handles secret values
---@param a any First value
---@param b any Second value  
---@param operator string Comparison operator: ">", "<", ">=", "<=", "==", "~="
---@return boolean|nil Result of comparison, or nil if values are secret
function Private.SafeCompare(a, b, operator)
    if a == nil or b == nil then
        return nil
    end
    -- Use pcall to safely handle secret values (userdata that errors on comparison)
    local ok, result = pcall(function()
        if operator == ">" then return a > b
        elseif operator == "<" then return a < b
        elseif operator == ">=" then return a >= b
        elseif operator == "<=" then return a <= b
        elseif operator == "==" then return a == b
        elseif operator == "~=" then return a ~= b
        end
        return nil
    end)
    if ok then
        return result
    else
        return nil  -- Comparison failed (secret value or type error)
    end
end

--- Safe arithmetic that handles secret values
---@param a any First operand
---@param b any Second operand
---@param operator string Arithmetic operator: "+", "-", "*", "/", "%"
---@return number|nil Result, or nil if values are secret
function Private.SafeArithmetic(a, b, operator)
    if a == nil or b == nil then
        return nil
    end
    -- Use pcall to safely handle secret values (userdata that errors on arithmetic)
    local ok, result = pcall(function()
        if operator == "+" then return a + b
        elseif operator == "-" then return a - b
        elseif operator == "*" then return a * b
        elseif operator == "/" then return b ~= 0 and a / b or nil
        elseif operator == "%" then return b ~= 0 and a % b or nil
        end
        return nil
    end)
    if ok then
        return result
    else
        return nil  -- Arithmetic failed (secret value or type error)
    end
end

--- Safe string format that handles secret values
---@param format string Format string
---@param ... any Format arguments
---@return string Formatted string, or "..." if any argument is secret
function Private.SafeFormat(format, ...)
    local args = {...}
    for i, arg in ipairs(args) do
        if Private.IsValueSecret(arg) then
            return "..."  -- Degraded display
        end
    end
    return string.format(format, ...)
end

--- Get a safe value for table key usage
--- Returns nil if the value is secret (can't be used as key)
---@param value any The value to use as key
---@return any The value if safe, nil if secret
function Private.SafeTableKey(value)
    if Private.IsValueSecret(value) then
        return nil
    end
    return value
end

--- Safe tonumber that handles secret values
---@param value any Value to convert
---@return number|nil The number, or nil if secret/invalid
function Private.SafeToNumber(value)
    if Private.IsValueSecret(value) then
        return nil
    end
    return tonumber(value)
end

--- Safe math functions that handle secret values
---@param value number|nil The value to process
---@return number|nil The result, or nil if input is secret/nil
function Private.SafeFloor(value)
    if Private.IsValueSecret(value) or value == nil then return nil end
    return math.floor(value)
end

function Private.SafeCeil(value)
    if Private.IsValueSecret(value) or value == nil then return nil end
    return math.ceil(value)
end

function Private.SafeAbs(value)
    if Private.IsValueSecret(value) or value == nil then return nil end
    return math.abs(value)
end

--- Safe boolean test that handles secret values
--- Returns the boolean value, or the default if secret/nil
---@param value any The value to test as boolean
---@param default boolean|nil Default to return if value is secret (default: false)
---@return boolean The boolean result
function Private.SafeBool(value, default)
    if Private.IsValueSecret(value) then
        return default or false
    end
    if value == nil then
        return default or false
    end
    return value and true or false
end

--- Check if we're in a context where secret values are active
--- M+ = entire run secured (even between pulls)
--- Raids = during encounter (boss pull to wipe/kill)
--- PvP = entire match
---@return boolean True if secret values may be active
function Private.MayHaveSecretValues()
    if not IS_MIDNIGHT then return false end

    -- M+ (Challenge Mode): entire run is secured, even between pulls
    if C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive() then
        return true
    end

    -- Raid encounters: active during boss fights
    if IsEncounterInProgress and IsEncounterInProgress() then
        return true
    end

    -- PvP instances: entire match is secured
    local _, instanceType = IsInInstance()
    if instanceType == "pvp" or instanceType == "arena" then
        return true
    end

    -- Fallback: combat in instanced content
    if InCombatLockdown() then
        if instanceType == "party" or instanceType == "raid" then
            return true
        end
    end

    return false
end

--- Safe duration calculation for auras
--- Uses helper API when available, falls back to calculation when safe
---@param expirationTime number The expiration time from aura data
---@param duration number The total duration from aura data
---@return number|nil Remaining time, or nil if secret
function Private.SafeGetRemainingDuration(expirationTime, duration)
    if Private.IsValueSecret(expirationTime) or Private.IsValueSecret(duration) then
        return nil
    end
    if expirationTime == nil or duration == nil then
        return nil
    end
    local isZero = Private.SafeCompare(expirationTime, 0, "==")
    if isZero then
        return nil  -- No duration (permanent aura)
    end
    local remaining = Private.SafeArithmetic(expirationTime, GetTime(), "-")
    if remaining == nil then
        return nil  -- SafeArithmetic returned nil (secret value)
    end
    return remaining > 0 and remaining or 0
end

--- Get aura duration using safe helper API when possible
--- NOTE: C_UnitAuras.GetAuraDurationRemainingByAuraInstanceID was REMOVED in 12.0.1
--- Use C_UnitAuras.GetUnitAuraDuration() instead which returns a Duration Object
---@param unit string The unit to query
---@param auraInstanceID number The aura instance ID
---@return number|nil Remaining duration, or nil if unavailable/secret
function Private.SafeGetAuraDurationRemaining(unit, auraInstanceID)
    if Private.IsValueSecret(auraInstanceID) then
        return nil
    end
    -- Use the new Duration Object API (12.0+)
    if C_UnitAuras and C_UnitAuras.GetUnitAuraDuration then
        local durationObj = C_UnitAuras.GetUnitAuraDuration(unit, auraInstanceID)
        if durationObj then
            -- Duration Objects have passthrough methods for display
            -- For calculation we need readable value - may not be available in combat
            local readable = durationObj and durationObj.GetReadableValue and durationObj:GetReadableValue()
            if readable and not Private.IsValueSecret(readable) then
                return readable
            end
        end
    end
    return nil
end

-- Export IS_MIDNIGHT for other modules
Private.IS_MIDNIGHT = IS_MIDNIGHT

--- Safe wrapper for UnitHealth - returns 0 if secret
---@param unit string
---@return number
function Private.SafeUnitHealth(unit)
    local ok, value = pcall(UnitHealth, unit)
    if not ok then return 0 end
    local okCheck = pcall(function() return value + 0 end)
    if not okCheck then return 0 end
    return value or 0
end

--- Safe wrapper for UnitHealthMax - returns 1 if secret (avoid div by zero)
---@param unit string
---@return number
function Private.SafeUnitHealthMax(unit)
    local ok, value = pcall(UnitHealthMax, unit)
    if not ok then return 1 end
    local okCheck = pcall(function() return value + 0 end)
    if not okCheck then return 1 end
    return value or 1
end

--- Safe wrapper for UnitPower - returns 0 if secret
---@param unit string
---@param powerType number|nil
---@return number
function Private.SafeUnitPower(unit, powerType)
    local ok, value = pcall(UnitPower, unit, powerType)
    if not ok then return 0 end
    local okCheck = pcall(function() return value + 0 end)
    if not okCheck then return 0 end
    return value or 0
end

--- Safe wrapper for UnitPowerMax - returns 1 if secret (avoid div by zero)
---@param unit string
---@param powerType number|nil
---@return number
function Private.SafeUnitPowerMax(unit, powerType)
    local ok, value = pcall(UnitPowerMax, unit, powerType)
    if not ok then return 1 end
    local okCheck = pcall(function() return value + 0 end)
    if not okCheck then return 1 end
    return value or 1
end

--- Safe wrapper for GetSpellCooldown - returns safe defaults if secret
---@param spell number|string
---@return number startTime, number duration, number enabled
function Private.SafeGetSpellCooldown(spell)
    local ok, startTime, duration, enabled
    if GetSpellCooldown then
        ok, startTime, duration, enabled = pcall(GetSpellCooldown, spell)
    elseif C_Spell and C_Spell.GetSpellCooldown then
        local okInfo, info = pcall(C_Spell.GetSpellCooldown, spell)
        if okInfo and info then
            startTime, duration, enabled = info.startTime, info.duration, info.isEnabled and 1 or 0
            ok = true
        end
    end
    if not ok then return 0, 0, 1 end
    -- Check if values are usable
    local okStart = pcall(function() return (startTime or 0) + 0 end)
    local okDur = pcall(function() return (duration or 0) + 0 end)
    if not okStart or not okDur then return 0, 0, 1 end
    return startTime or 0, duration or 0, enabled or 1
end

-- Expose safety helpers to ExecEnv for generated code and custom scripts
if Private.ExecEnv then
    Private.ExecEnv.IsValueSecret = Private.IsValueSecret
    Private.ExecEnv.SafeCompare = Private.SafeCompare
    Private.ExecEnv.SafeArithmetic = Private.SafeArithmetic
    Private.ExecEnv.SafeFormat = Private.SafeFormat
    Private.ExecEnv.SafeTableKey = Private.SafeTableKey
    Private.ExecEnv.SafeToNumber = Private.SafeToNumber
    Private.ExecEnv.SafeFloor = Private.SafeFloor
    Private.ExecEnv.SafeCeil = Private.SafeCeil
    Private.ExecEnv.SafeAbs = Private.SafeAbs
    -- Safe unit API wrappers
    Private.ExecEnv.SafeUnitHealth = Private.SafeUnitHealth
    Private.ExecEnv.SafeUnitHealthMax = Private.SafeUnitHealthMax
    Private.ExecEnv.SafeUnitPower = Private.SafeUnitPower
    Private.ExecEnv.SafeUnitPowerMax = Private.SafeUnitPowerMax
    Private.ExecEnv.SafeGetSpellCooldown = Private.SafeGetSpellCooldown
end

