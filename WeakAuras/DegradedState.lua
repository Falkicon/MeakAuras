--[[ DegradedState.lua
    Shared functions for applying/removing degraded visual state
    when auras cannot update due to Midnight (12.0+) secret values.
    
    When an aura's trigger or display values become secret during instanced combat,
    the aura enters a "degraded" state:
    - Values freeze at their last known state
    - Visual opacity is reduced (dimmed)
    - A lock icon appears in the corner
    
    This provides clear visual feedback that the aura is not updating
    without causing errors or hiding information entirely.
]]

if not WeakAuras then return end

---@class Private
local Private = select(2, ...)

-- Configuration
local DEGRADED_OPACITY_MULTIPLIER = 0.5  -- 50% opacity when degraded
local LOCK_ICON_SIZE = 14
local LOCK_ICON_ATLAS = "communities-icon-lock"  -- Built-in atlas, no custom asset needed

---Apply degraded visual state to a region.
---Call this when a region's values become secret and cannot update.
---@param region table The WeakAuras region frame
function Private.ApplyDegradedState(region)
    if not region then return end
    if region.isDegraded then return end  -- Already degraded
    
    region.isDegraded = true
    
    -- Store original alpha and dim
    region.preDegradedAlpha = region.preDegradedAlpha or region:GetAlpha()
    region:SetAlpha(region.preDegradedAlpha * DEGRADED_OPACITY_MULTIPLIER)
    
    -- Create lock icon overlay (once per region)
    if not region.combatLockIcon then
        region.combatLockIcon = region:CreateTexture(nil, "OVERLAY", nil, 7)
        region.combatLockIcon:SetAtlas(LOCK_ICON_ATLAS)
        region.combatLockIcon:SetSize(LOCK_ICON_SIZE, LOCK_ICON_SIZE)
        region.combatLockIcon:SetPoint("TOPRIGHT", region, "TOPRIGHT", -2, -2)
        region.combatLockIcon:SetAlpha(0.8)  -- Slightly transparent so it's not too harsh
    end
    region.combatLockIcon:Show()
    
    -- Fire event for any listeners (with safety check for Fire method)
    if region.callbacks and region.callbacks.Fire then
        region.callbacks:Fire("OnDegradedStateChanged", true)
    end
end

---Apply degraded state to a group and all its children.
---@param group table The WeakAuras group/dynamic group frame
function Private.ApplyDegradedStateToGroup(group)
    if not group then return end
    Private.ApplyDegradedState(group)
    -- Apply to children if this is a group
    if group.controlledChildren then
        for _, childId in ipairs(group.controlledChildren) do
            local childRegion = WeakAuras.GetRegion(childId)
            if childRegion then
                Private.ApplyDegradedState(childRegion)
            end
        end
    end
end

---Remove degraded state from a group and all its children.
---@param group table The WeakAuras group/dynamic group frame
function Private.RemoveDegradedStateFromGroup(group)
    if not group then return end
    Private.RemoveDegradedState(group)
    -- Remove from children if this is a group
    if group.controlledChildren then
        for _, childId in ipairs(group.controlledChildren) do
            local childRegion = WeakAuras.GetRegion(childId)
            if childRegion then
                Private.RemoveDegradedState(childRegion)
            end
        end
    end
end

---Remove degraded visual state from a region.
---Call this when values become available again (e.g., leaving instanced combat).
---@param region table The WeakAuras region frame
function Private.RemoveDegradedState(region)
    if not region then return end
    if not region.isDegraded then return end  -- Not degraded
    
    region.isDegraded = false
    
    -- Restore original alpha
    if region.preDegradedAlpha then
        region:SetAlpha(region.preDegradedAlpha)
    end
    
    -- Hide lock icon (don't destroy, may need again)
    if region.combatLockIcon then
        region.combatLockIcon:Hide()
    end
    
    -- Fire event for any listeners (with safety check for Fire method)
    if region.callbacks and region.callbacks.Fire then
        region.callbacks:Fire("OnDegradedStateChanged", false)
    end
end

---Check if a region is currently in degraded state.
---@param region table The WeakAuras region frame
---@return boolean True if the region is degraded
function Private.IsDegraded(region)
    return region and region.isDegraded == true
end

---Update degraded state based on current secret value context.
---Call this during region updates to automatically manage degraded state.
---@param region table The WeakAuras region frame
---@param hasSecretValue boolean Whether any relevant value is currently secret
function Private.UpdateDegradedState(region, hasSecretValue)
    if hasSecretValue then
        Private.ApplyDegradedState(region)
    else
        Private.RemoveDegradedState(region)
    end
end

---Helper to check if we should enter degraded state for a set of values.
---Returns true if ANY of the values are secret.
---@param ... any Values to check
---@return boolean True if degraded state should be applied
function Private.ShouldDegrade(...)
    if not Private.MayHaveSecretValues() then
        return false
    end
    return Private.AnyValueSecret(...)
end

---Convenience function to handle region update with degradation.
---Use this pattern in region UpdateTime/UpdateValue functions:
---
---  if Private.HandleDegradedUpdate(self, self.duration, self.expirationTime) then
---      return  -- Degraded, skip normal update
---  end
---  -- Normal update logic here...
---
---@param region table The WeakAuras region frame
---@param ... any Values that would be used in the update
---@return boolean True if degraded (caller should skip update), false if normal
function Private.HandleDegradedUpdate(region, ...)
    if Private.ShouldDegrade(...) then
        Private.ApplyDegradedState(region)
        return true  -- Skip normal update
    end
    
    Private.RemoveDegradedState(region)
    return false  -- Proceed with normal update
end

-- Log module loaded
if WeakAuras.IsLibsOK and WeakAuras.IsLibsOK() then
    -- Only log if debug system is available
    if Private.Debug then
        Private.Debug("DegradedState module loaded")
    end
end
