if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class OptionsPrivate
local OptionsPrivate = select(2, ...)

-- Lua APIs
local pairs, error, coroutine = pairs, error, coroutine

-- WoW APIs
local IsSpellKnown = IsSpellKnown

---@class WeakAuras
local WeakAuras = WeakAuras

local spellCache = {}
WeakAuras.spellCache = spellCache

local cache
local metaData
local bestIcon = {}

-- =============================================================================
-- MIDNIGHT (12.0) SAFE SPELL CACHE
-- =============================================================================
-- PROBLEM: In WoW 12.0+, certain spell IDs reference broken PlayerConditions
-- in the client's DBC data. Querying these IDs via GetSpellInfo/GetSpellName
-- causes a C++ client crash (not a Lua error - pcall cannot catch it).
--
-- Known crash-causing spells (as of 12.0 beta):
--   - Spell 257321 -> PlayerCondition 53723
--   - Spell 1261435 -> PlayerCondition 151037
--
-- SOLUTION: Use brute-force iteration with:
--   1. "Holes" to skip large gaps of invalid spell IDs (performance)
--   2. Blacklist of known crash-causing spell IDs (safety)
--   If crashes persist, fall back to spellbook-only approach.
--
-- To find more crash IDs: If client crashes during cache build, check the
-- crash log for the last spell ID being processed and add it to the blacklist.
-- =============================================================================

-- Blacklist of spell IDs known to crash the client in 12.0+
-- These reference broken PlayerConditions in Blizzard's DBC data
-- DO NOT query these IDs - it will crash the game client (C++ level, not Lua)
-- Add new crash IDs here as they are discovered
local CRASH_SPELL_BLACKLIST = {
  [257321] = true,   -- PlayerCondition 53723 (confirmed crash)
  [257322] = true,   -- Adjacent IDs may also be affected
  [257323] = true,
  [257324] = true,
  [1261435] = true,  -- PlayerCondition 151037 (confirmed crash in Silvermoon)
}

-- Holes in spell ID space - skip from key to value (speeds up iteration)
-- These are large gaps where no valid spells exist
-- Format: [start_of_gap] = end_of_gap (will skip from start+1 to end)
local holes = {
  -- Standard holes from original WeakAuras (large gaps in spell database)
  [45085] = 52999,
  [55740] = 56999,
  [59999] = 60999,
  [67999] = 68999,
  [72999] = 73999,
  [76099] = 78999,
  [81099] = 81999,
  [84999] = 85999,
  [89999] = 90999,
  [96999] = 99999,
  [103999] = 106999,
  [115999] = 117999,
  [126999] = 130999,
  [137999] = 140999,
  [159999] = 161999,
  [199999] = 201999,
  [227999] = 229999,
  -- MIDNIGHT CRASH RANGES: Skip ranges around known crash spell IDs
  -- These are C++ crashes, not Lua errors - must skip entirely
  [257320] = 257330,   -- Range around spell 257321 (PlayerCondition 53723)
  [1261430] = 1261440, -- Range around spell 1261435 (PlayerCondition 151037)
}

-- Check if a spell ID is safe to query
local function IsSpellIdSafe(spellId)
  if type(spellId) ~= "number" or spellId <= 0 then
    return false
  end
  if CRASH_SPELL_BLACKLIST[spellId] then
    return false
  end
  return true
end

-- Safely query a spell - returns name, icon or nil if unsafe/missing
local function SafeGetSpellInfo(spellId)
  if not IsSpellIdSafe(spellId) then
    return nil, nil
  end
  local name = OptionsPrivate.Private.ExecEnv.GetSpellName(spellId)
  local icon = OptionsPrivate.Private.ExecEnv.GetSpellIcon(spellId)
  if name and name ~= "" and icon and icon ~= 136243 then -- 136243 is generic gear icon
    return name, icon
  end
  return nil, nil
end

-- Add a single spell to the cache (used for on-demand additions)
local function AddSpellToCache(spellId)
  local name, icon = SafeGetSpellInfo(spellId)
  if name and icon then
    cache[name] = cache[name] or {}
    if not cache[name].spells or cache[name].spells == "" then
      cache[name].spells = spellId .. "=" .. icon
    elseif not cache[name].spells:find(tostring(spellId) .. "=") then
      cache[name].spells = cache[name].spells .. "," .. spellId .. "=" .. icon
    end
    return true
  end
  return false
end

-- Builds a cache of name/icon pairs from existing spell data
-- MIDNIGHT: Uses brute-force iteration with holes + crash ID blacklist
function spellCache.Build()
  if not cache then
    error("spellCache has not been loaded. Call WeakAuras.spellCache.Load(...) first.")
  end

  if not metaData.needsRebuild then
    return
  end

  wipe(cache)
  local co = coroutine.create(function()
    metaData.rebuilding = true

    -- Phase 1: Iterate through all spell IDs (with holes for performance)
    local id = 0
    local misses = 0
    while misses < 80000 do
      id = id + 1

      -- MIDNIGHT CRITICAL: Skip ranges around crash-causing spell IDs
      -- These cause C++ crashes (not Lua errors) - must skip before querying
      -- Using small ranges as safety buffer around known crash points
      if id >= 257320 and id <= 257325 then
        id = 257326
      elseif id >= 1261430 and id <= 1261440 then
        id = 1261441
      end

      -- Skip holes (large gaps in spell ID space)
      if holes[id] then
        id = holes[id]
      end

      -- Skip blacklisted crash IDs (safety check)
      if not CRASH_SPELL_BLACKLIST[id] then
        -- Query spell info safely
        local name, icon = SafeGetSpellInfo(id)
        if name and icon then
          cache[name] = cache[name] or {}
          if not cache[name].spells or cache[name].spells == "" then
            cache[name].spells = id .. "=" .. icon
          else
            cache[name].spells = cache[name].spells .. "," .. id .. "=" .. icon
          end
          misses = 0
        else
          misses = misses + 1
        end
      end

      coroutine.yield(0.1, "spells")
    end

    -- Phase 2: Build from achievements
    if WeakAuras.IsCataOrMistsOrRetail() then
      for _, category in pairs(GetCategoryList()) do
        local total = GetCategoryNumAchievements(category, true)
        for i = 1, total do
          local id,name,_,_,_,_,_,_,_,iconID = GetAchievementInfo(category, i)
          if name and iconID then
            cache[name] = cache[name] or {}
            if not cache[name].achievements or cache[name].achievements == "" then
              cache[name].achievements = id .. "=" .. iconID
            else
              cache[name].achievements = cache[name].achievements .. "," .. id .. "=" .. iconID
            end
          end
          coroutine.yield(0.1, "achievements")
        end
        coroutine.yield(0.1, "categories")
      end
    end

    metaData.needsRebuild = false
    metaData.rebuilding = false
  end)
  OptionsPrivate.Private.Threads:Add("spellCache", co, 'background')
end

--[[ function to help find big holes in spellIds to help speedup Build()

local id = 0
local misses = 0
local lastId
print("####")
while misses < 4000000 do
   id = id + 1
   local spellInfo = C_Spell.GetSpellInfo(id)
   local name = spellInfo and spellInfo.name
   local icon = C_Spell.GetSpellTexture(id)
   if icon == 136243 then -- 136243 is the a gear icon, we can ignore those spells
      misses = 0
   elseif name and name ~= "" and icon then
      if misses > 10000 then
         print(("holes[%s] = %s"):format(lastId, id - 1))
      end
      lastId = id
      misses = 0
   else
      misses = misses + 1
   end
end
print("lastId", lastId)
]]

function spellCache.GetIcon(name)
  if (name == nil) then
    return nil;
  end
  if cache then
    if (bestIcon[name]) then
      return bestIcon[name]
    end

    local icons = cache[name]
    local bestMatch = nil
    if (icons) then
      if (icons.spells) then
        for spell, icon in icons.spells:gmatch("(%d+)=(%d+)") do
          local spellId = tonumber(spell)

          if not bestMatch or (spellId and spellId ~= 0 and IsSpellKnown(spellId)) then
            bestMatch = tonumber(icon)
          end
        end
      end
    elseif metaData.rebuilding then
      OptionsPrivate.Private.Threads:SetPriority('spellCache', 'normal')
    end

    bestIcon[name] = bestMatch
    return bestIcon[name]
  else
    error("spellCache has not been loaded. Call WeakAuras.spellCache.Load(...) first.")
  end
end

function spellCache.GetSpellsMatching(name)
  if cache[name] then
    if cache[name].spells then
      local result = {}
      for spell, icon in cache[name].spells:gmatch("(%d+)=(%d+)") do
        local spellId = tonumber(spell)
        local iconId = tonumber(icon)
        result[spellId] = icon
      end
      return result
    end
  elseif metaData.rebuilding then
    OptionsPrivate.Private.Threads:SetPriority('spellCache', 'normal')
  end
end

function spellCache.AddIcon(name, id, icon)
  if not cache then
    error("spellCache has not been loaded. Call WeakAuras.spellCache.Load(...) first.")
    return
  end

  if name and id and icon then
    cache[name] = cache[name] or {}
    if not cache[name].spells or cache[name].spells == "" then
      cache[name].spells = id .. "=" .. icon
    else
      cache[name].spells = cache[name].spells .. "," .. id .. "=" .. icon
    end
  end
end

function spellCache.Get()
  if cache then
    return cache
  else
    error("spellCache has not been loaded. Call WeakAuras.spellCache.Load(...) first.")
  end
end

function spellCache.Load(data)
  metaData = data
  cache = metaData.spellCache

  local _, build = GetBuildInfo();
  local locale = GetLocale();
  local version = WeakAuras.versionString

  local num = 0;
  for i,v in pairs(cache) do
    num = num + 1;
  end

  if(num < 39000 or metaData.locale ~= locale or metaData.build ~= build
     or metaData.version ~= version or not metaData.spellCacheStrings)
  then
    metaData.build = build;
    metaData.locale = locale;
    metaData.version = version;
    metaData.spellCacheAchievements = true
    metaData.spellCacheStrings = true
    metaData.needsRebuild = true
    wipe(cache)
  end
end

-- This function computes the Levenshtein distance between two strings
-- It is used in this program to match spell icon textures with "good" spell names; i.e.,
-- spell names that are very similar to the name of the texture
local function Lev(str1, str2)
  local matrix = {};
  for i=0, str1:len() do
    matrix[i] = {[0] = i};
  end
  for j=0, str2:len() do
    matrix[0][j] = j;
  end
  for j=1, str2:len() do
    for i =1, str1:len() do
      if(str1:sub(i, i) == str2:sub(j, j)) then
        matrix[i][j] = matrix[i-1][j-1];
      else
        matrix[i][j] = math.min(matrix[i-1][j], matrix[i][j-1], matrix[i-1][j-1]) + 1;
      end
    end
  end

  return matrix[str1:len()][str2:len()];
end

function spellCache.BestKeyMatch(nearkey)
  local bestKey = "";
  local bestDistance = math.huge;
  local partialMatches = {};
  if cache[nearkey] then
    return nearkey
  end
  for key, value in pairs(cache) do
    if key:lower() == nearkey:lower() then
      return key
    end
    if(key:lower():find(nearkey:lower(), 1, true)) then
      partialMatches[key] = value;
    end
  end
  for key, value in pairs(partialMatches) do
    local distance = Lev(nearkey, key);
    if(distance < bestDistance) then
      bestKey = key;
      bestDistance = distance;
    end
  end

  return bestKey;
end

---@param input string | number
---@return string name, number? id
function spellCache.CorrectAuraName(input)
  if (not cache) then
    error("spellCache has not been loaded. Call WeakAuras.spellCache.Load(...) first.")
  end

  local spellId = WeakAuras.SafeToNumber(input)
  if type(input) == "string" and input:find("|", nil, true) then
    spellId = WeakAuras.SafeToNumber(input:match("|Hspell:(%d+)"))
  end
  if(spellId) then
    -- MIDNIGHT SAFE: Check blacklist before querying spell ID
    if CRASH_SPELL_BLACKLIST[spellId] then
      return "Blocked Spell ID (client crash)", spellId;
    end
    local name, _, icon = OptionsPrivate.Private.ExecEnv.GetSpellInfo(spellId);
    if(name) then
      spellCache.AddIcon(name, spellId, icon)
      return name, spellId;
    else
      return "Invalid Spell ID", spellId;
    end
  else
    local ret = spellCache.BestKeyMatch(input);
    if(ret == "") then
      return "No Match Found", nil;
    else
      return ret, nil;
    end
  end
end
