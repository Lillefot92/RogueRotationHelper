-- ============================================================
-- Rogue Rotation Helper - Core.lua
-- MoP Classic 5.5.4 state collection and compatibility helpers.
--
-- This addon only recommends actions. It never casts spells,
-- presses protected buttons, sends chat, or communicates online.
-- ============================================================

local ADDON_NAME, ns = ...

ns.VERSION = "0.3.0-beta.1"
ns.INTERFACE = 50504
ns.ROGUE_CLASS_FILE = "ROGUE"
ns.ASSASSINATION_SPEC_ID = 259
ns.COMBAT_SPEC_ID = 260
ns.SUBTLETY_SPEC_ID = 261

ns.SPEC_NAMES = {
    [ns.ASSASSINATION_SPEC_ID] = "Assassination",
    [ns.COMBAT_SPEC_ID] = "Combat",
    [ns.SUBTLETY_SPEC_ID] = "Subtlety",
}

local ENERGY_POWER_TYPE = (Enum and Enum.PowerType and Enum.PowerType.Energy) or 3
local COMBO_POWER_TYPE = (Enum and Enum.PowerType and Enum.PowerType.ComboPoints) or 4

ns.ABILITIES = {
    DEADLY_POISON     = { id = 2823,   cost = 0 },
    WOUND_POISON      = { id = 8679,   cost = 0 },
    CRIPPLING_POISON  = { id = 3408,   cost = 0 },
    MIND_NUMBING_POISON = { id = 5761, cost = 0 },
    LEECHING_POISON   = { id = 108211, cost = 0 },
    PARALYTIC_POISON  = { id = 108215, cost = 0 },
    AMBUSH            = { id = 8676,   cost = 60, target = true },
    BACKSTAB          = { id = 53,     cost = 35, target = true },
    HEMORRHAGE        = { id = 16511,  cost = 30, target = true },
    PREMEDITATION     = { id = 14183,  cost = 0,  target = true },
    SHADOW_DANCE      = { id = 51713,  cost = 0 },
    MUTILATE          = { id = 1329,   cost = 55, target = true },
    DISPATCH          = { id = 111240, cost = 30, target = true },
    ENVENOM           = { id = 32645,  cost = 35, target = true },
    VENDETTA          = { id = 79140,  cost = 0,  target = true },
    PREPARATION       = { id = 14185,  cost = 0 },
    SLICE_AND_DICE    = { id = 5171,   cost = 25 },
    REVEALING_STRIKE  = { id = 84617,  cost = 40, target = true },
    SINISTER_STRIKE   = { id = 1752,   cost = 50, target = true },
    RUPTURE           = { id = 1943,   cost = 25, target = true },
    EVISCERATE        = { id = 2098,   cost = 35, target = true },
    KILLING_SPREE     = { id = 51690,  cost = 0,  target = true },
    ADRENALINE_RUSH   = { id = 13750,  cost = 0 },
    SHADOW_BLADES     = { id = 121471, cost = 0 },
    BLADE_FLURRY      = { id = 13877,  cost = 0 },
    FAN_OF_KNIVES     = { id = 51723,  cost = 35 },
    CRIMSON_TEMPEST   = { id = 121411, cost = 35 },
    MARKED_FOR_DEATH  = { id = 137619, cost = 0,  target = true },
    SHURIKEN_TOSS     = { id = 114014, cost = 40, target = true },
    DEADLY_THROW      = { id = 26679,  cost = 35, target = true },
    KIDNEY_SHOT       = { id = 408,    cost = 25, target = true },
    VANISH            = { id = 1856,   cost = 0 },
}

ns.AURAS = {
    DEADLY_POISON      = 2823,
    WOUND_POISON       = 8679,
    CRIPPLING_POISON   = 3408,
    MIND_NUMBING_POISON = 5761,
    LEECHING_POISON    = 108211,
    PARALYTIC_POISON   = 108215,
    STEALTH            = 1784,
    SLICE_AND_DICE     = 5171,
    REVEALING_STRIKE   = 84617,
    RUPTURE            = 1943,
    -- Hemorrhage is cast as 16511, but its 24-second target DoT is 89775.
    HEMORRHAGE         = 89775,
    CRIMSON_TEMPEST    = 121411,
    -- 91023 is the passive; Ambush/Garrote apply target debuff 91021.
    FIND_WEAKNESS      = 91021,
    SHADOW_DANCE       = 51713,
    KILLING_SPREE      = 51690,
    ADRENALINE_RUSH    = 13750,
    SHADOW_BLADES      = 121471,
    BLADE_FLURRY       = 13877,
    ANTICIPATION       = 115189,
    ANTICIPATION_LEGACY = 114015,
    SUBTERFUGE         = 115192,
    BLINDSIDE          = 121153,
    ENVENOM            = 32645,
    VENDETTA           = 79140,
    KIDNEY_SHOT        = 408,
    SHALLOW_INSIGHT    = 84745,
    MODERATE_INSIGHT   = 84746,
    DEEP_INSIGHT       = 84747,
}

ns.TALENTS = {
    NIGHTSTALKER       = 14062,
    SUBTERFUGE         = 108208,
    SHADOW_FOCUS       = 108209,
    DEADLY_THROW       = 26679,
    NERVE_STRIKE       = 108210,
    COMBAT_READINESS   = 74001,
    CHEAT_DEATH        = 31230,
    LEECHING_POISON    = 108211,
    ELUSIVENESS        = 79008,
    CLOAK_AND_DAGGER   = 138106,
    SHADOWSTEP         = 36554,
    BURST_OF_SPEED     = 108212,
    PREY_ON_THE_WEAK   = 131511,
    PARALYTIC_POISON   = 108215,
    DIRTY_TRICKS       = 108216,
    SHURIKEN_TOSS      = 114014,
    MARKED_FOR_DEATH   = 137619,
    ANTICIPATION       = 114015,
}

local HEROISM_AURAS = {
    2825,   -- Bloodlust
    32182,  -- Heroism
    80353,  -- Time Warp
    90355,  -- Ancient Hysteria
}

ns.CONFIG = {
    UPDATE_INTERVAL = 0.08,
    ENEMY_MEMORY = 5.0,
    AREA_HIT_WINDOW = 1.25,
    MELEE_RANGE_SPELL = 1752,
    CLEAVE_THRESHOLD = 2,
    AOE_THRESHOLD = 8,
    ASSASSINATION_AOE_THRESHOLD = 4,
    ASSASSINATION_MASS_AOE_THRESHOLD = 9,
    ASSASSINATION_RUPTURE_MULTI_CP = 3,
    ASSASSINATION_ENVENOM_POOL = 80,
    ASSASSINATION_RUPTURE_MIN_TTD = 8,
    ASSASSINATION_VENDETTA_MIN_TTD = 20,
    SUBTLETY_AOE_THRESHOLD = 3,
    SUBTLETY_FAN_ALWAYS_THRESHOLD = 5,
    SUBTLETY_BURST_POOL = 80,
    SUBTLETY_MAINTENANCE_SAFE = 4,
    SUBTLETY_FIND_WEAKNESS_REFRESH = 1.5,
    SUBTLETY_HEMORRHAGE_REFRESH = 3,
    SUBTLETY_RUPTURE_MIN_TTD = 8,
    SUBTLETY_CRIMSON_TEMPEST_MIN_TTD = 8,
    SUBTLETY_BURST_MIN_TTD = 8,
    SND_EMERGENCY = 1.5,
    SND_FIVE_CP_REFRESH = 3.0,
    RVS_REFRESH = 3.0,
    POISON_REFRESH = 60,
    DOT_REFRESH = 2.0,
    RUPTURE_MIN_TTD = 12,
    CRIMSON_TEMPEST_MIN_TTD = 12,
    KILLING_SPREE_MAX_ENERGY = 60,
    ADRENALINE_RUSH_MAX_ENERGY = 60,
    GCD_SPELL_ID = 61304,
}

ns.state = {
    now = 0,
    playerGUID = nil,
    playerLevel = 0,
    isRogue = false,
    specID = 0,
    isAssassinationSpec = false,
    isCombatSpec = false,
    isSubtletySpec = false,
    isSupportedSpec = false,
    inCombat = false,
    inRaid = false,
    energy = 0,
    maxEnergy = 100,
    comboPoints = 0,
    anticipation = 0,
    talents = {},
    targetExists = false,
    targetAttackable = false,
    targetDead = false,
    targetGUID = nil,
    targetHealth = 0,
    targetHealthMax = 0,
    targetHPPercent = 100,
    targetTTD = 999,
    targetIsBoss = false,
    enemyCount = 1,
    mode = "single",
    stealthed = false,
    stealthWindow = false,
    heroism = false,
    meleeRange = true,
    shurikenRange = true,
    insight = 0,
    insightName = "None",
    insightRemaining = 0,
    insightProgress = 0,
    sndRemaining = 0,
    rvsRemaining = 0,
    ruptureRemaining = 0,
    hemorrhageRemaining = 0,
    crimsonTempestRemaining = 0,
    findWeaknessRemaining = 0,
    shadowDanceRemaining = 0,
    envenomRemaining = 0,
    vendettaRemaining = 0,
    blindside = false,
    deadlyPoisonRemaining = 0,
    utilityPoisonRemaining = 0,
    utilityPoisonKey = nil,
    poisonsReady = false,
    kidneyShotRemaining = 0,
    bladeFlurry = false,
    adrenalineRush = false,
    shadowBlades = false,
    killingSpree = false,
    shadowDance = false,
    backstabUsable = true,
    nearbyEnemies = {},
    nearbyAreaCastUntil = 0,
    debugNameplateCount = 0,
    debugMemoryCount = 0,
    debugTargetAdded = 0,
    debugPlayerCombatEvents = 0,
    debugMarkedEvents = 0,
    debugLastPlayerSubevent = "none",
    debugLastPlayerSpellID = 0,
    debugLastPlayerMatch = "none",
    debugLastAreaSpellID = 0,
    debugLastAreaCastAt = 0,
    cooldowns = {},
    known = {},
}

-- ------------------------------------------------------------
-- Saved settings
-- ------------------------------------------------------------

local function InitDB()
    RogueRotationHelperDB = RogueRotationHelperDB or {}
    local db = RogueRotationHelperDB

    if db.schemaVersion == nil then db.schemaVersion = 1 end
    if db.point == nil then db.point = "CENTER" end
    if db.x == nil then db.x = 0 end
    if db.y == nil then db.y = 220 end
    if db.scale == nil then db.scale = 1.0 end
    if db.locked == nil then db.locked = true end
    if db.enabled == nil then db.enabled = true end
    if db.glow == nil then db.glow = true end
    if db.mode == nil then db.mode = "auto" end
    if db.cooldowns == nil then db.cooldowns = "boss" end
    if db.showCooldownRow == nil then db.showCooldownRow = true end
    if db.offensiveVanish == nil then db.offensiveVanish = false end
    if db.preyOnWeak == nil then db.preyOnWeak = false end
    if db.testMode == nil then db.testMode = false end
    if db.debugTracker == nil then db.debugTracker = false end

    local validModes = { auto = true, single = true, cleave = true, aoe = true }
    local validCooldowns = { on = true, boss = true, off = true }
    if not validModes[db.mode] then db.mode = "auto" end
    if not validCooldowns[db.cooldowns] then db.cooldowns = "boss" end

    ns.db = db
end

local printedErrors = {}

function ns.ReportOnce(context, err)
    local key = tostring(context) .. ":" .. tostring(err)
    if printedErrors[key] then return end
    printedErrors[key] = true
    print("|cffff7a45Rogue Rotation Helper|r: " .. tostring(context)
        .. " failed safely (" .. tostring(err) .. "). Please report this text.")
end

function ns.Print(message)
    print("|cff33d6c5Rogue Rotation Helper|r: " .. tostring(message))
end

-- ------------------------------------------------------------
-- WoW API helpers
-- ------------------------------------------------------------

function ns.GetSpellInfo(spellID)
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
        if ok then return info end
    end
    if GetSpellInfo then
        local name, _, icon, castTime, minRange, maxRange, returnedID = GetSpellInfo(spellID)
        if name then
            return {
                name = name,
                iconID = icon,
                castTime = castTime,
                minRange = minRange,
                maxRange = maxRange,
                spellID = returnedID or spellID,
            }
        end
    end
    return nil
end

function ns.GetAbilityName(key)
    local ability = ns.ABILITIES[key]
    local info = ability and ns.GetSpellInfo(ability.id)
    return (info and info.name) or key or ""
end

function ns.GetAbilityIcon(key)
    local ability = ns.ABILITIES[key]
    local info = ability and ns.GetSpellInfo(ability.id)
    return info and info.iconID or 134400
end

function ns.GetSpecName(specID)
    return ns.SPEC_NAMES[specID] or "Unsupported"
end

function ns.IsSupportedSpec(specID)
    return specID == ns.ASSASSINATION_SPEC_ID
        or specID == ns.COMBAT_SPEC_ID
        or specID == ns.SUBTLETY_SPEC_ID
end

function ns.PlayerKnowsSpell(spellID)
    if not spellID then return false end
    if IsPlayerSpell then
        local ok, known = pcall(IsPlayerSpell, spellID)
        if ok then return known == true end
    end
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        local ok, known = pcall(C_SpellBook.IsSpellKnown, spellID)
        if ok then return known == true end
    end
    return ns.GetSpellInfo(spellID) ~= nil
end

function ns.PlayerKnowsAbility(key)
    local ability = ns.ABILITIES[key]
    return ability and ns.PlayerKnowsSpell(ability.id) or false
end

function ns.GetAbilityCost(key)
    local ability = ns.ABILITIES[key]
    if not ability then return 0 end
    if C_Spell and C_Spell.GetSpellPowerCost then
        local ok, costs = pcall(C_Spell.GetSpellPowerCost, ability.id)
        if ok and type(costs) == "table" then
            for _, entry in ipairs(costs) do
                if entry.type == ENERGY_POWER_TYPE or entry.name == "ENERGY" then
                    return entry.cost or ability.cost or 0
                end
            end
        end
    end
    return ability.cost or 0
end

local function RawCooldown(spellID)
    if C_Spell and C_Spell.GetSpellCooldown then
        local ok, info = pcall(C_Spell.GetSpellCooldown, spellID)
        if ok and info then
            return info.startTime or 0, info.duration or 0,
                info.isEnabled ~= false, info.modRate or 1
        end
    end
    if GetSpellCooldown then
        local startTime, duration, enabled, modRate = GetSpellCooldown(spellID)
        return startTime or 0, duration or 0, enabled ~= 0, modRate or 1
    end
    return 0, 0, true, 1
end

function ns.GetAbilityCooldownInfo(key)
    local ability = ns.ABILITIES[key]
    if not ability then return 0, 0, false, 1 end
    return RawCooldown(ability.id)
end

function ns.GetGCDInfo()
    return RawCooldown(ns.CONFIG.GCD_SPELL_ID)
end

function ns.GetGCDRemaining()
    local startTime, duration, enabled, modRate = RawCooldown(ns.CONFIG.GCD_SPELL_ID)
    if not enabled or startTime == 0 or duration == 0 then return 0 end
    return math.max(0, startTime + (duration / math.max(0.01, modRate)) - GetTime())
end

function ns.GetAbilityCooldownRemaining(key, ignoreGCD)
    local ability = ns.ABILITIES[key]
    if not ability then return 999 end
    local startTime, duration, enabled, modRate = RawCooldown(ability.id)
    if not enabled then return 999 end
    if startTime == 0 or duration == 0 then return 0 end

    if ignoreGCD then
        local gcdStart, gcdDuration = RawCooldown(ns.CONFIG.GCD_SPELL_ID)
        if math.abs(startTime - gcdStart) < 0.02
            and math.abs(duration - gcdDuration) < 0.02 then
            return 0
        end
    end

    return math.max(0, startTime + (duration / math.max(0.01, modRate)) - GetTime())
end

function ns.IsAbilityInRange(key, unit)
    local ability = ns.ABILITIES[key]
    if not ability or not ability.target then return true end
    unit = unit or "target"
    if C_Spell and C_Spell.IsSpellInRange then
        local ok, inRange = pcall(C_Spell.IsSpellInRange, ability.id, unit)
        if ok and inRange ~= nil then return inRange == true end
    end
    if IsSpellInRange then
        local info = ns.GetSpellInfo(ability.id)
        local result = info and IsSpellInRange(info.name, unit)
        if result ~= nil then return result == 1 end
    end
    return true
end

-- IsUsableSpell reports positional failures such as trying Backstab from the
-- front. A lack of Energy is deliberately treated as usable because pooling is
-- handled by the evaluator and should not change the recommended builder.
function ns.IsAbilityUsable(key)
    local ability = ns.ABILITIES[key]
    if not ability then return false end
    if C_Spell and C_Spell.IsSpellUsable then
        local ok, usable, noEnergy = pcall(C_Spell.IsSpellUsable, ability.id)
        if ok and usable ~= nil then
            return usable == true or noEnergy == true
        end
    end
    if IsUsableSpell then
        local info = ns.GetSpellInfo(ability.id)
        local usable, noEnergy = IsUsableSpell((info and info.name) or ability.id)
        if usable ~= nil then
            return usable == true or usable == 1
                or noEnergy == true or noEnergy == 1
        end
    end
    return true
end

local function AuraRemaining(aura, now)
    if not aura then return 0 end
    if not aura.expirationTime or aura.expirationTime == 0 then return 999 end
    return math.max(0, aura.expirationTime - (now or GetTime()))
end

function ns.FindAura(unit, spellID, filter, playerOnly)
    if unit == "player" and C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellID)
        if ok and aura and (not playerOnly or aura.sourceUnit == "player") then
            return aura
        end
    end

    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for index = 1, 40 do
            local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
            if not ok or not aura then break end
            if aura.spellId == spellID
                and (not playerOnly or aura.sourceUnit == "player") then
                return aura
            end
        end
    elseif UnitAura then
        for index = 1, 40 do
            local name, icon, applications, _, duration, expirationTime,
                sourceUnit, _, _, auraSpellID = UnitAura(unit, index, filter)
            if not name then break end
            if auraSpellID == spellID
                and (not playerOnly or sourceUnit == "player") then
                return {
                    name = name,
                    icon = icon,
                    applications = applications,
                    duration = duration,
                    expirationTime = expirationTime,
                    sourceUnit = sourceUnit,
                    spellId = auraSpellID,
                }
            end
        end
    end
    return nil
end

local function HasAnyPlayerAura(ids)
    for _, spellID in ipairs(ids) do
        if ns.FindAura("player", spellID, "HELPFUL") then return true end
    end
    return false
end

-- ------------------------------------------------------------
-- Enemy counting and target time-to-die
-- ------------------------------------------------------------

local targetSample = {
    guid = nil,
    lastAt = 0,
    lastHealth = 0,
    smoothedDPS = 0,
}

local function ResetTargetSample(guid, health, now)
    targetSample.guid = guid
    targetSample.lastAt = now
    targetSample.lastHealth = health or 0
    targetSample.smoothedDPS = 0
end

local function EstimateTargetTTD(guid, health, now, isBoss)
    if not guid or health <= 0 then return 999 end
    if targetSample.guid ~= guid then
        ResetTargetSample(guid, health, now)
        return isBoss and 999 or 20
    end

    local elapsed = now - targetSample.lastAt
    if elapsed >= 0.25 then
        local damage = targetSample.lastHealth - health
        if damage > 0 then
            local instantDPS = damage / elapsed
            if targetSample.smoothedDPS <= 0 then
                targetSample.smoothedDPS = instantDPS
            else
                targetSample.smoothedDPS = targetSample.smoothedDPS * 0.70 + instantDPS * 0.30
            end
        end
        targetSample.lastAt = now
        targetSample.lastHealth = health
    end

    if targetSample.smoothedDPS > 0 then
        return math.min(999, health / targetSample.smoothedDPS)
    end
    return isBoss and 999 or 20
end

local function IsEnemyFlags(flags)
    if not flags or not bit then return true end

    local hostile = COMBATLOG_OBJECT_REACTION_HOSTILE
    local neutral = COMBATLOG_OBJECT_REACTION_NEUTRAL
    if not hostile and not neutral then return true end
    return (hostile and bit.band(flags, hostile) ~= 0)
        or (neutral and bit.band(flags, neutral) ~= 0)
end

function ns.MarkEnemy(guid, flags, confirmedHit)
    if not guid or (not confirmedHit and not IsEnemyFlags(flags)) then return end
    ns.state.nearbyEnemies[guid] = GetTime()
end

local function CountNameplateEnemies(seen)
    local count = 0
    for index = 1, 40 do
        local unit = "nameplate" .. index
        if UnitExists(unit) and UnitCanAttack("player", unit) and not UnitIsDead(unit) then
            local inRange = true
            if C_Spell and C_Spell.IsSpellInRange then
                local ok, result = pcall(C_Spell.IsSpellInRange,
                    ns.CONFIG.MELEE_RANGE_SPELL, unit)
                inRange = ok and result == true
            end
            if inRange then
                local guid = UnitGUID(unit) or unit
                if not seen[guid] then
                    seen[guid] = true
                    count = count + 1
                end
            end
        end
    end
    return count
end

function ns.CountNearbyEnemies()
    local now = GetTime()
    local seen = {}
    local count = CountNameplateEnemies(seen)
    local nameplateCount = count
    local memoryCount = 0

    for guid, lastSeen in pairs(ns.state.nearbyEnemies) do
        if now - lastSeen > ns.CONFIG.ENEMY_MEMORY then
            ns.state.nearbyEnemies[guid] = nil
        elseif not seen[guid] then
            seen[guid] = true
            count = count + 1
            memoryCount = memoryCount + 1
        end
    end

    local targetAdded = 0
    if ns.state.targetAttackable and ns.state.targetGUID
        and not seen[ns.state.targetGUID] then
        seen[ns.state.targetGUID] = true
        count = count + 1
        targetAdded = 1
    end
    ns.state.debugNameplateCount = nameplateCount
    ns.state.debugMemoryCount = memoryCount
    ns.state.debugTargetAdded = targetAdded
    return math.max(ns.state.targetAttackable and 1 or 0, count)
end

-- ------------------------------------------------------------
-- Live state refresh
-- ------------------------------------------------------------

local function GetSpecID()
    local getSpec = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization
        or GetSpecialization
    local getInfo = C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo
        or GetSpecializationInfo
    if not getSpec or not getInfo then return 0 end
    local index = getSpec()
    if not index then return 0 end
    return getInfo(index) or 0
end

local function RefreshKnownAbilities()
    for key in pairs(ns.ABILITIES) do
        ns.state.known[key] = ns.PlayerKnowsAbility(key)
    end
end

local function RefreshKnownTalents()
    for key, spellID in pairs(ns.TALENTS) do
        ns.state.talents[key] = ns.PlayerKnowsSpell(spellID)
    end
end

local TALENT_ORDER = {
    "NIGHTSTALKER", "SUBTERFUGE", "SHADOW_FOCUS",
    "DEADLY_THROW", "NERVE_STRIKE", "COMBAT_READINESS",
    "CHEAT_DEATH", "LEECHING_POISON", "ELUSIVENESS",
    "CLOAK_AND_DAGGER", "SHADOWSTEP", "BURST_OF_SPEED",
    "PREY_ON_THE_WEAK", "PARALYTIC_POISON", "DIRTY_TRICKS",
    "SHURIKEN_TOSS", "MARKED_FOR_DEATH", "ANTICIPATION",
}

function ns.GetTalentSummary()
    local names = {}
    for _, key in ipairs(TALENT_ORDER) do
        if ns.state.talents[key] then
            local info = ns.GetSpellInfo(ns.TALENTS[key])
            names[#names + 1] = (info and info.name) or key
        end
    end
    return #names > 0 and table.concat(names, ", ") or "none detected"
end

local function RefreshCooldowns()
    for key in pairs(ns.ABILITIES) do
        ns.state.cooldowns[key] = ns.GetAbilityCooldownRemaining(key, true)
    end
end

local function RefreshInsight(now)
    local previous = ns.state.insight
    local deep = ns.FindAura("player", ns.AURAS.DEEP_INSIGHT, "HELPFUL")
    local moderate = ns.FindAura("player", ns.AURAS.MODERATE_INSIGHT, "HELPFUL")
    local shallow = ns.FindAura("player", ns.AURAS.SHALLOW_INSIGHT, "HELPFUL")
    local aura

    if deep then
        ns.state.insight = 3
        ns.state.insightName = "Deep"
        aura = deep
    elseif moderate then
        ns.state.insight = 2
        ns.state.insightName = "Moderate"
        aura = moderate
    elseif shallow then
        ns.state.insight = 1
        ns.state.insightName = "Shallow"
        aura = shallow
    else
        ns.state.insight = 0
        ns.state.insightName = "None"
    end

    if ns.state.insight ~= previous then
        ns.state.insightProgress = 0
    end
    ns.state.insightRemaining = AuraRemaining(aura, now)
end

function ns.ResolveMode(requestedMode, enemyCount, specID)
    if requestedMode == "single" then return "single" end
    if requestedMode == "cleave" then return "cleave" end
    if requestedMode == "aoe" then return "aoe" end
    local aoeThreshold = ns.CONFIG.AOE_THRESHOLD
    if specID == ns.ASSASSINATION_SPEC_ID then
        aoeThreshold = ns.CONFIG.ASSASSINATION_AOE_THRESHOLD or 4
    elseif specID == ns.SUBTLETY_SPEC_ID then
        aoeThreshold = ns.CONFIG.SUBTLETY_AOE_THRESHOLD or 3
    end
    if enemyCount >= aoeThreshold then return "aoe" end
    if enemyCount >= ns.CONFIG.CLEAVE_THRESHOLD then return "cleave" end
    return "single"
end

function ns.RefreshState()
    local s = ns.state
    local now = GetTime()
    s.now = now
    s.playerGUID = s.playerGUID or UnitGUID("player")
    s.playerLevel = UnitLevel("player") or 0
    local _, classFile = UnitClass("player")
    s.isRogue = classFile == ns.ROGUE_CLASS_FILE
    s.specID = GetSpecID()
    s.isAssassinationSpec = s.isRogue and s.specID == ns.ASSASSINATION_SPEC_ID
    s.isCombatSpec = s.isRogue and s.specID == ns.COMBAT_SPEC_ID
    s.isSubtletySpec = s.isRogue and s.specID == ns.SUBTLETY_SPEC_ID
    s.isSupportedSpec = s.isRogue and ns.IsSupportedSpec(s.specID)
    s.inCombat = UnitAffectingCombat("player") == true
    s.inRaid = IsInRaid and IsInRaid() == true
    s.energy = UnitPower("player", ENERGY_POWER_TYPE) or 0
    s.maxEnergy = UnitPowerMax("player", ENERGY_POWER_TYPE) or 100
    s.comboPoints = UnitPower("player", COMBO_POWER_TYPE) or 0

    local anticipation = ns.FindAura("player", ns.AURAS.ANTICIPATION, "HELPFUL")
        or ns.FindAura("player", ns.AURAS.ANTICIPATION_LEGACY, "HELPFUL")
    s.anticipation = anticipation and (anticipation.applications or 0) or 0
    s.stealthed = (IsStealthed and IsStealthed()) == true
        or ns.FindAura("player", ns.AURAS.STEALTH, "HELPFUL") ~= nil
    s.stealthWindow = s.stealthed
        or ns.FindAura("player", ns.AURAS.SUBTERFUGE, "HELPFUL") ~= nil
    s.heroism = HasAnyPlayerAura(HEROISM_AURAS)

    s.targetExists = UnitExists("target") == true
    s.targetAttackable = s.targetExists
        and UnitCanAttack("player", "target") == true
        and UnitIsDead("target") ~= true
    s.targetDead = s.targetExists and UnitIsDead("target") == true
    s.targetGUID = s.targetExists and UnitGUID("target") or nil
    s.targetHealth = s.targetExists and (UnitHealth("target") or 0) or 0
    s.targetHealthMax = s.targetExists and (UnitHealthMax("target") or 0) or 0
    if s.targetHealthMax > 0 then
        s.targetHPPercent = 100 * s.targetHealth / s.targetHealthMax
    else
        s.targetHPPercent = 100
    end
    local classification = s.targetExists and UnitClassification("target") or "normal"
    s.targetIsBoss = s.targetExists
        and (classification == "worldboss" or (UnitLevel("target") or 0) == -1)
    s.targetTTD = EstimateTargetTTD(s.targetGUID, s.targetHealth, now, s.targetIsBoss)
    local meleeAbility = s.isAssassinationSpec and "MUTILATE"
        or (s.isSubtletySpec and "BACKSTAB") or "SINISTER_STRIKE"
    s.meleeRange = s.targetAttackable
        and ns.IsAbilityInRange(meleeAbility, "target") or false
    s.shurikenRange = s.targetAttackable
        and ns.IsAbilityInRange("SHURIKEN_TOSS", "target") or false

    local deadlyPoison = ns.FindAura("player", ns.AURAS.DEADLY_POISON, "HELPFUL")
    local snd = ns.FindAura("player", ns.AURAS.SLICE_AND_DICE, "HELPFUL")
    local rvs = ns.FindAura("target", ns.AURAS.REVEALING_STRIKE, "HARMFUL", true)
    local rupture = ns.FindAura("target", ns.AURAS.RUPTURE, "HARMFUL", true)
    local hemorrhage = ns.FindAura("target", ns.AURAS.HEMORRHAGE, "HARMFUL", true)
    local crimsonTempest = ns.FindAura("target", ns.AURAS.CRIMSON_TEMPEST,
        "HARMFUL", true)
    local findWeakness = ns.FindAura("target", ns.AURAS.FIND_WEAKNESS,
        "HARMFUL", true)
    local shadowDance = ns.FindAura("player", ns.AURAS.SHADOW_DANCE, "HELPFUL")
    local envenom = ns.FindAura("player", ns.AURAS.ENVENOM, "HELPFUL")
    local vendetta = ns.FindAura("target", ns.AURAS.VENDETTA, "HARMFUL", true)
    local blindside = ns.FindAura("player", ns.AURAS.BLINDSIDE, "HELPFUL")
    local bladeFlurry = ns.FindAura("player", ns.AURAS.BLADE_FLURRY, "HELPFUL")
    local adrenalineRush = ns.FindAura("player", ns.AURAS.ADRENALINE_RUSH, "HELPFUL")
    local shadowBlades = ns.FindAura("player", ns.AURAS.SHADOW_BLADES, "HELPFUL")
    local killingSpree = ns.FindAura("player", ns.AURAS.KILLING_SPREE, "HELPFUL")
    local kidneyShot = ns.FindAura("target", ns.AURAS.KIDNEY_SHOT, "HARMFUL", true)

    local utilityAuras = {
        LEECHING_POISON = ns.AURAS.LEECHING_POISON,
        PARALYTIC_POISON = ns.AURAS.PARALYTIC_POISON,
        CRIPPLING_POISON = ns.AURAS.CRIPPLING_POISON,
        MIND_NUMBING_POISON = ns.AURAS.MIND_NUMBING_POISON,
    }
    local utilityPoison, utilityPoisonKey
    for key, spellID in pairs(utilityAuras) do
        local aura = ns.FindAura("player", spellID, "HELPFUL")
        if aura then
            utilityPoison, utilityPoisonKey = aura, key
            break
        end
    end

    s.deadlyPoisonRemaining = AuraRemaining(deadlyPoison, now)
    s.utilityPoisonRemaining = AuraRemaining(utilityPoison, now)
    s.utilityPoisonKey = utilityPoisonKey
    local preferredUtility = s.known.LEECHING_POISON and "LEECHING_POISON"
        or (s.known.PARALYTIC_POISON and "PARALYTIC_POISON") or nil
    s.poisonsReady = s.deadlyPoisonRemaining > ns.CONFIG.POISON_REFRESH
        and s.utilityPoisonRemaining > ns.CONFIG.POISON_REFRESH
        and (not preferredUtility or utilityPoisonKey == preferredUtility)
    s.sndRemaining = AuraRemaining(snd, now)
    s.rvsRemaining = AuraRemaining(rvs, now)
    s.ruptureRemaining = AuraRemaining(rupture, now)
    s.hemorrhageRemaining = AuraRemaining(hemorrhage, now)
    s.crimsonTempestRemaining = AuraRemaining(crimsonTempest, now)
    s.findWeaknessRemaining = AuraRemaining(findWeakness, now)
    s.shadowDanceRemaining = AuraRemaining(shadowDance, now)
    s.envenomRemaining = AuraRemaining(envenom, now)
    s.vendettaRemaining = AuraRemaining(vendetta, now)
    s.blindside = blindside ~= nil
    s.bladeFlurry = bladeFlurry ~= nil
    s.adrenalineRush = adrenalineRush ~= nil
    s.shadowBlades = shadowBlades ~= nil
    s.killingSpree = killingSpree ~= nil
    s.shadowDance = shadowDance ~= nil
    s.backstabUsable = ns.IsAbilityUsable("BACKSTAB")
    s.kidneyShotRemaining = AuraRemaining(kidneyShot, now)

    if s.isCombatSpec then
        RefreshInsight(now)
    else
        s.insight = 0
        s.insightName = "None"
        s.insightRemaining = 0
        s.insightProgress = 0
    end
    RefreshCooldowns()
    s.enemyCount = ns.CountNearbyEnemies()
    s.mode = ns.ResolveMode(ns.db and ns.db.mode or "auto", s.enemyCount, s.specID)
    return s
end

-- ------------------------------------------------------------
-- Combat log: nearby-enemy memory and Bandit's Guile progress
-- ------------------------------------------------------------

-- Only events that prove melee/AoE proximity may refresh the nearby-enemy
-- memory. This avoids counting a distant enemy because a poison or bleed is
-- still ticking, while Fan of Knives and Blade Flurry reliably confirm packs.
local BLADE_FLURRY_DAMAGE_ID = 22482
local AREA_CAST_SPELLS = {
    [ns.ABILITIES.FAN_OF_KNIVES.id] = true,
    [ns.ABILITIES.CRIMSON_TEMPEST.id] = true,
}
local NEARBY_DAMAGE_SPELLS = {
    [ns.ABILITIES.AMBUSH.id] = true,
    [ns.ABILITIES.BACKSTAB.id] = true,
    [ns.ABILITIES.HEMORRHAGE.id] = true,
    [ns.ABILITIES.MUTILATE.id] = true,
    [ns.ABILITIES.DISPATCH.id] = true,
    [ns.ABILITIES.ENVENOM.id] = true,
    [ns.ABILITIES.REVEALING_STRIKE.id] = true,
    [ns.ABILITIES.SINISTER_STRIKE.id] = true,
    [ns.ABILITIES.EVISCERATE.id] = true,
    [ns.ABILITIES.KILLING_SPREE.id] = true,
    [ns.ABILITIES.FAN_OF_KNIVES.id] = true,
    [ns.ABILITIES.CRIMSON_TEMPEST.id] = true,
    [BLADE_FLURRY_DAMAGE_ID] = true,
}

local function MarkAreaCast(spellID)
    if AREA_CAST_SPELLS[spellID] then
        ns.state.nearbyAreaCastUntil = GetTime() + ns.CONFIG.AREA_HIT_WINDOW
        ns.state.debugLastAreaSpellID = spellID
        ns.state.debugLastAreaCastAt = GetTime()
    end
end

local function SourceBelongsToPlayer(sourceGUID, sourceFlags)
    if sourceGUID and sourceGUID == ns.state.playerGUID then
        return true, "guid"
    end

    local mine = COMBATLOG_OBJECT_AFFILIATION_MINE
    if mine and bit and sourceFlags and bit.band(sourceFlags, mine) ~= 0 then
        return true, "mine flag"
    end
    return false, "no match"
end

local function IsNearbyDamageEvent(subevent, spellID)
    if subevent == "SWING_DAMAGE" or subevent == "SWING_MISSED" then
        return true
    end
    if subevent == "SPELL_DAMAGE" or subevent == "SPELL_MISSED" then
        return NEARBY_DAMAGE_SPELLS[spellID] == true
    end
    return false
end

local function HandleCombatLog()
    local _, subevent, _, sourceGUID, _, sourceFlags, _, destGUID, _, destFlags,
        _, spellID = CombatLogGetCurrentEventInfo()
    local s = ns.state
    local sourceIsPlayer, sourceMatch = SourceBelongsToPlayer(sourceGUID, sourceFlags)

    if sourceIsPlayer then
        s.debugPlayerCombatEvents = (s.debugPlayerCombatEvents or 0) + 1
        s.debugLastPlayerSubevent = subevent or "unknown"
        s.debugLastPlayerSpellID = spellID or 0
        s.debugLastPlayerMatch = sourceMatch
    end

    if sourceIsPlayer and subevent == "SPELL_CAST_SUCCESS" then
        MarkAreaCast(spellID)
    end

    local recentAreaCast = GetTime() <= (s.nearbyAreaCastUntil or 0)

    if subevent == "UNIT_DIED" or subevent == "UNIT_DESTROYED" then
        if destGUID then s.nearbyEnemies[destGUID] = nil end
        return
    end

    if sourceIsPlayer and destGUID
        and (IsNearbyDamageEvent(subevent, spellID)
            or (recentAreaCast and (subevent == "SPELL_DAMAGE"
                or subevent == "SPELL_MISSED"))) then
        -- A successful outgoing melee/AoE event already proves that its
        -- destination is a valid nearby damage target. Some training dummies
        -- report friendly or incomplete reaction flags, so do not discard a
        -- confirmed hit based on those flags. The short area-cast window also
        -- catches MoP clients that report a separate damage-effect spell ID
        -- for Fan of Knives or Crimson Tempest.
        ns.MarkEnemy(destGUID, destFlags, true)
        s.debugMarkedEvents = (s.debugMarkedEvents or 0) + 1
    elseif destGUID == s.playerGUID and sourceGUID
        and (subevent == "SWING_DAMAGE" or subevent == "SWING_MISSED")
        and IsEnemyFlags(sourceFlags) then
        ns.MarkEnemy(sourceGUID, sourceFlags)
    end

    if sourceIsPlayer and subevent == "SPELL_DAMAGE"
        and (spellID == ns.ABILITIES.SINISTER_STRIKE.id
            or spellID == ns.ABILITIES.REVEALING_STRIKE.id) then
        if s.insight < 3 then
            s.insightProgress = (s.insightProgress + 1) % 4
        end
    end
end

-- ------------------------------------------------------------
-- Commands and lifecycle
-- ------------------------------------------------------------

local function OnOff(value)
    return value and "on" or "off"
end

function ns.CycleMode()
    local order = { "auto", "single", "cleave", "aoe" }
    local current = ns.db.mode
    for index, mode in ipairs(order) do
        if mode == current then
            ns.db.mode = order[(index % #order) + 1]
            ns.Print("mode: " .. ns.db.mode)
            if ns.Settings_Refresh then ns.Settings_Refresh() end
            return
        end
    end
    ns.db.mode = "auto"
    if ns.Settings_Refresh then ns.Settings_Refresh() end
end

local function PrintHelp()
    ns.Print("commands:")
    print("  /rrh or /rrh options (open the settings panel)")
    print("  /rrh mode auto|single|cleave|aoe")
    print("  /rrh cooldowns on|boss|off")
    print("  /rrh vanish on|off (optional offensive Vanish advice)")
    print("  /rrh prey on|off (optional Prey on the Weak advice)")
    print("  /rrh glow on|off")
    print("  /rrh debug on|off (target-tracker diagnostics in the icon tooltip)")
    print("  /rrh lock | unlock | scale 1.2 | reset")
    print("  /rrh test | sim | status | talents | on | off")
end

local function SplitCommand(text)
    text = tostring(text or ""):lower():match("^%s*(.-)%s*$")
    local command, value = text:match("^(%S+)%s*(.-)$")
    return command or "", value or ""
end

local function SlashHandler(text)
    local command, value = SplitCommand(text)
    if command == "" or command == "options" or command == "settings" then
        if ns.Settings_Open then ns.Settings_Open() else PrintHelp() end
    elseif command == "help" then
        PrintHelp()
    elseif command == "mode" then
        if value == "auto" or value == "single" or value == "cleave" or value == "aoe" then
            ns.db.mode = value
            ns.Print("mode: " .. value)
        else
            ns.Print("choose auto, single, cleave, or aoe")
        end
    elseif command == "cooldowns" or command == "cd" then
        if value == "on" or value == "boss" or value == "off" then
            ns.db.cooldowns = value
            ns.Print("cooldowns: " .. value)
        else
            ns.Print("choose on, boss, or off")
        end
    elseif command == "glow" then
        if value == "on" or value == "off" then
            ns.db.glow = value == "on"
            ns.Print("action-bar glow: " .. value)
            if not ns.db.glow and ns.Display_HideGlow then ns.Display_HideGlow() end
        else
            ns.Print("action-bar glow is " .. OnOff(ns.db.glow))
        end
    elseif command == "vanish" then
        if value == "on" or value == "off" then
            ns.db.offensiveVanish = value == "on"
            ns.Print("offensive Vanish advice: " .. value)
        else
            ns.Print("offensive Vanish advice is " .. OnOff(ns.db.offensiveVanish))
        end
    elseif command == "prey" then
        if value == "on" or value == "off" then
            ns.db.preyOnWeak = value == "on"
            ns.Print("Prey on the Weak advice: " .. value)
        else
            ns.Print("Prey on the Weak advice is " .. OnOff(ns.db.preyOnWeak))
        end
    elseif command == "debug" then
        if value == "on" or value == "off" then
            ns.db.debugTracker = value == "on"
            ns.Print("target-tracker diagnostics: " .. value)
        else
            ns.Print("target-tracker diagnostics are " .. OnOff(ns.db.debugTracker))
        end
    elseif command == "lock" or command == "unlock" then
        ns.db.locked = command == "lock"
        ns.Print(ns.db.locked and "display locked" or "display unlocked; drag it with the mouse")
        if ns.Display_ApplySettings then ns.Display_ApplySettings() end
    elseif command == "scale" then
        local scale = tonumber(value)
        if scale and scale >= 0.5 and scale <= 2.0 then
            ns.db.scale = scale
            ns.Print(string.format("scale: %.2f", scale))
            if ns.Display_ApplySettings then ns.Display_ApplySettings() end
        else
            ns.Print("scale must be between 0.5 and 2.0")
        end
    elseif command == "test" then
        ns.db.testMode = not ns.db.testMode
        ns.Print("preview: " .. OnOff(ns.db.testMode))
    elseif command == "sim" then
        if ns.Simulator_PrintSelfCheck then ns.Simulator_PrintSelfCheck() end
    elseif command == "status" then
        ns.Print("v" .. ns.VERSION .. ", level=" .. tostring(ns.state.playerLevel or 0)
            .. ", spec=" .. ns.GetSpecName(ns.state.specID)
            .. ", mode=" .. ns.db.mode
            .. ", active=" .. tostring(ns.state.mode or "single")
            .. ", targets=" .. tostring(ns.state.enemyCount or 1)
            .. ", cooldowns=" .. ns.db.cooldowns
            .. ", vanish=" .. OnOff(ns.db.offensiveVanish)
            .. ", prey=" .. OnOff(ns.db.preyOnWeak)
            .. ", glow=" .. OnOff(ns.db.glow))
        ns.Print("poisons: " .. (ns.state.poisonsReady and "ready" or "attention needed"))
    elseif command == "talents" then
        ns.Print("detected talents: " .. ns.GetTalentSummary())
    elseif command == "reset" then
        ns.db.point, ns.db.x, ns.db.y, ns.db.scale = "CENTER", 0, 220, 1.0
        if ns.Display_ApplySettings then ns.Display_ApplySettings() end
        ns.Print("position and scale reset")
    elseif command == "on" or command == "off" then
        ns.db.enabled = command == "on"
        ns.Print("addon: " .. command)
        if not ns.db.enabled and ns.Display_HideGlow then ns.Display_HideGlow() end
    else
        PrintHelp()
    end
    if ns.Settings_Refresh then ns.Settings_Refresh() end
end

local updateElapsed = 0

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
eventFrame:RegisterEvent("UPDATE_BINDINGS")

eventFrame:SetScript("OnEvent", function(_, event, ...)
    local arg1 = ...
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        InitDB()
        RefreshKnownAbilities()
        RefreshKnownTalents()
        if ns.Display_Create then ns.Display_Create() end
        if ns.Settings_Create then ns.Settings_Create() end
        SLASH_ROGUEROTATIONHELPER1 = "/rrh"
        SLASH_ROGUEROTATIONHELPER2 = "/roguehelper"
        SlashCmdList.ROGUEROTATIONHELPER = SlashHandler
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        HandleCombatLog()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and arg1 == "player" then
        local spellID = tonumber(select(3, ...)) or tonumber(select(5, ...))
        MarkAreaCast(spellID)
    elseif event == "SPELLS_CHANGED" or event == "PLAYER_SPECIALIZATION_CHANGED"
        or event == "PLAYER_TALENT_UPDATE" or event == "PLAYER_LEVEL_UP" then
        RefreshKnownAbilities()
        RefreshKnownTalents()
        if ns.Settings_Refresh then ns.Settings_Refresh() end
    elseif event == "ACTIONBAR_SLOT_CHANGED" or event == "UPDATE_BINDINGS" then
        if ns.Display_RebuildActionCache then ns.Display_RebuildActionCache() end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
        ns.state.playerGUID = UnitGUID("player")
        RefreshKnownAbilities()
        RefreshKnownTalents()
        if ns.Settings_Refresh then ns.Settings_Refresh() end
    end
end)

eventFrame:SetScript("OnUpdate", function(_, elapsed)
    if not ns.db then return end
    updateElapsed = updateElapsed + elapsed
    if updateElapsed < ns.CONFIG.UPDATE_INTERVAL then return end
    updateElapsed = 0

    local ok, err = pcall(function()
        local state = ns.RefreshState()
        local decision = ns.Rotation_GetDecision and ns.Rotation_GetDecision(state) or nil
        if ns.Display_Update then ns.Display_Update(state, decision) end
    end)
    if not ok then ns.ReportOnce("live update", err) end
end)
