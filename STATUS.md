# MeakAuras - Midnight (12.0) Secret Value Migration Status

> **MeakAuras** - A Midnight-compatible fork of WeakAuras
>
> *"It's not weak, it's meek - it knows when to stay quiet in combat!"*
>
> Name lineage: Power Auras → Weak Auras → Meak Auras

## Overview
WoW 12.0 "Midnight" introduces "secret values" - opaque userdata (`Secret<T>`) returned by APIs during combat in instanced content (M+, Raids, PvP). These cannot be compared, used in arithmetic, or passed to functions expecting concrete types.

WeakAuras will not support Retail after Midnight (they continue supporting Classic). MeakAuras is the Midnight-compatible fork for Retail players.

## Current State: PARTIALLY WORKING

### Files Modified

| File | Status | Changes |
|------|--------|---------|
| AuraEnvironment.lua | **SAFE** | Safe UnitAura wrapper using C_UnitAuras directly with type checking |
| BuffTrigger2.lua | **SAFE** | SafeForEachAura, safe C_UnitAuras calls, icon preservation |
| GenericTrigger.lua | **REVERTED** | Changes caused icon regression (question marks) |
| Prototypes.lua | Modified | Cooldown template comparisons with pcall |

### What's Working
- Icons display correctly (no question marks)
- AuraUtil.lua unpack error fixed (was Error #3: 113x occurrences)
- Aura iteration doesn't crash on secret values

### Remaining Errors
1. **Thunder Clap spellCount comparison** - GenericTrigger.lua code generator produces comparisons that error on secret values
2. **ADDON_ACTION_FORBIDDEN** - Coroutine taint issue, unrelated to secret values

## Lessons Learned

### GenericTrigger.lua is Sensitive
- The code generator at lines 454-462 produces state comparison code
- Modifying this affects icon rendering in unexpected ways
- Even "safe" pcall wrappers caused visual regression
- **Recommendation:** Leave GenericTrigger.lua alone or find alternative approach

### Safe Patterns That Work

```lua
-- Type check before using potentially secret aura data
local ok, auraData = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
if not ok or not auraData then return nil end
if type(auraData) ~= "table" then return nil end  -- Secret value check
return AuraUtil.UnpackAuraData(auraData)
```

```lua
-- Safe comparison pattern (use sparingly)
local ok, result = pcall(function() return oldValue ~= newValue end)
if ok and result then
  -- Values differ and comparison succeeded
end
```

### Patterns That Caused Regression

```lua
-- This broke icon rendering:
if ok and icon ~= nil then state.icon = icon end

-- Original worked better for initialization:
state.icon = ok and icon or nil
```

The difference: preserving existing values during state updates works differently than initial state setup.

## Next Steps

1. **Option A: Accept remaining errors** - Thunder Clap error is logged but doesn't break functionality
2. **Option B: Targeted fix** - Find specific comparison in generated trigger code without touching code generator
3. **Option C: Upstream contribution** - Work with WeakAuras team on proper Midnight support

## Test Configuration
- WoW Version: 12.0.1 (64914) Beta
- Test Character: Warrior (Protection)
- Test Pack: Luxthos Warrior WeakAuras

## Files Reference
- `SecretValueHelpers.lua` - Helper functions (untracked, may not be in use)
- `DegradedState.lua` - Degraded state handling (untracked)
- `MidnightAffectedTriggers.lua` - Trigger tracking (untracked)

---
*Last Updated: 2026-01-02*
