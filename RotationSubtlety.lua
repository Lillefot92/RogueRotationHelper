-- ============================================================
-- Rogue Rotation Helper - RotationSubtlety.lua
-- Subtlety Rogue PvE priority evaluator for MoP 5.5.4.
-- ============================================================

local ADDON_NAME, ns = ...
local Shared = ns.RotationShared
local Value = Shared.Value
local Cooldown = Shared.Cooldown
local Ready = Shared.Ready
local Decision = Shared.Decision

local function EffectiveEnemyCount(state, settings)
    local actual = Value(state, "enemyCount", 1)
    if settings.mode == "aoe" and actual < ns.CONFIG.SUBTLETY_AOE_THRESHOLD then
        return ns.CONFIG.SUBTLETY_AOE_THRESHOLD
    end
    if settings.mode == "cleave" and actual < ns.CONFIG.CLEAVE_THRESHOLD then
        return ns.CONFIG.CLEAVE_THRESHOLD
    end
    return actual
end

local function MaintenanceSafe(state, aoe)
    local safe = ns.CONFIG.SUBTLETY_MAINTENANCE_SAFE or 4
    if Value(state, "sndRemaining", 0) <= safe then return false end
    if aoe then
        return Value(state, "crimsonTempestRemaining", 0) > safe
    end
    return Value(state, "ruptureRemaining", 0) > safe
        and Value(state, "hemorrhageRemaining", 0)
            > (ns.CONFIG.SUBTLETY_HEMORRHAGE_REFRESH or 3)
end

local function FivePointMaintenance(state, mode, aoe)
    if Value(state, "comboPoints", 0) < 5 then return nil end
    if Value(state, "sndRemaining", 0) <= 2 and Ready(state, "SLICE_AND_DICE") then
        return Decision(state, "SLICE_AND_DICE",
            "Refresh Slice and Dice before it expires", { mode = mode })
    end

    if aoe then
        if Value(state, "targetTTD", 999)
                >= (ns.CONFIG.SUBTLETY_CRIMSON_TEMPEST_MIN_TTD or 8)
            and Value(state, "crimsonTempestRemaining", 0) <= 2
            and Ready(state, "CRIMSON_TEMPEST") then
            return Decision(state, "CRIMSON_TEMPEST",
                "Maintain the AoE bleed for Sanguinary Vein", { mode = mode })
        end
    elseif Value(state, "targetTTD", 999)
            >= (ns.CONFIG.SUBTLETY_RUPTURE_MIN_TTD or 8)
        and Value(state, "ruptureRemaining", 0) <= 2
        and Ready(state, "RUPTURE") then
        return Decision(state, "RUPTURE",
            "Maintain the five-point Rupture for Sanguinary Vein",
            { mode = mode })
    end
    return nil
end

local function DanceDecision(state, mode, cooldownsAllowed, fanAlways, aoe)
    if not cooldownsAllowed or fanAlways or not Ready(state, "SHADOW_DANCE") then
        return nil
    end
    if Value(state, "shadowDance", false)
        or Value(state, "shadowDanceRemaining", 0) > 0 then
        return nil
    end
    if Value(state, "targetTTD", 999) < (ns.CONFIG.SUBTLETY_BURST_MIN_TTD or 8)
        or Value(state, "comboPoints", 0) > 3
        or not MaintenanceSafe(state, aoe) then
        return nil
    end
    return Decision(state, "SHADOW_DANCE",
        "Start the Ambush burst window with maintenance safely covered",
        { mode = mode, poolTo = ns.CONFIG.SUBTLETY_BURST_POOL or 80,
            offGCD = true })
end

local function VanishDecision(state, mode, cooldownsAllowed, fanAlways, aoe)
    if not cooldownsAllowed or fanAlways or not Ready(state, "VANISH") then
        return nil
    end
    if Value(state, "shadowDance", false)
        or Value(state, "stealthWindow", false)
        or Cooldown(state, "SHADOW_DANCE") < 5
        or Value(state, "findWeaknessRemaining", 0)
            > (ns.CONFIG.SUBTLETY_FIND_WEAKNESS_REFRESH or 1.5)
        or Value(state, "comboPoints", 0) >= 3
        or Value(state, "targetTTD", 999) < (ns.CONFIG.SUBTLETY_BURST_MIN_TTD or 8)
        or not MaintenanceSafe(state, aoe) then
        return nil
    end
    return Decision(state, "VANISH",
        "Refresh Find Weakness with a new Ambush window",
        { mode = mode, poolTo = ns.CONFIG.SUBTLETY_BURST_POOL or 80,
            offGCD = true })
end

local function ShadowBladesDecision(state, mode, cooldownsAllowed, fanAlways)
    if not cooldownsAllowed or not Ready(state, "SHADOW_BLADES")
        or Value(state, "shadowBlades", false)
        or Value(state, "targetTTD", 999) < (ns.CONFIG.SUBTLETY_BURST_MIN_TTD or 8) then
        return nil
    end
    local danceActive = Value(state, "shadowDance", false)
        or Value(state, "shadowDanceRemaining", 0) > 0
    if danceActive or fanAlways
        or (Cooldown(state, "SHADOW_DANCE") > 10
            and Value(state, "findWeaknessRemaining", 0) > 0) then
        return Decision(state, "SHADOW_BLADES",
            danceActive and "Pair Shadow Blades with Shadow Dance"
                or "Use Shadow Blades in the active damage window",
            { mode = mode, offGCD = true })
    end
    return nil
end

local function Evaluate(state, settings)
    local mode = Shared.ResolveMode(state, settings)
    local enemies = EffectiveEnemyCount(state, settings)
    local aoe = mode == "aoe"
        and enemies >= (ns.CONFIG.SUBTLETY_AOE_THRESHOLD or 3)
    local fanAlways = aoe
        and enemies >= (ns.CONFIG.SUBTLETY_FAN_ALWAYS_THRESHOLD or 5)
    local comboPoints = Value(state, "comboPoints", 0)
    local danceActive = Value(state, "shadowDance", false)
        or Value(state, "shadowDanceRemaining", 0) > 0
    local stealthAccess = Value(state, "stealthWindow", false) or danceActive
    local cooldownsAllowed = Shared.CooldownsAllowed(state, settings)

    -- Premeditation is off the global cooldown. It prepares Slice and Dice in
    -- the opener and adds points inside Dance without overcapping five points.
    if stealthAccess and comboPoints <= 3 and Ready(state, "PREMEDITATION") then
        return Decision(state, "PREMEDITATION",
            comboPoints == 0 and "Prepare Combo Points for the stealth opener"
                or "Add Combo Points during the stealth window",
            { mode = mode, offGCD = true })
    end

    if Value(state, "sndRemaining", 0) <= 0 and comboPoints > 0
        and Ready(state, "SLICE_AND_DICE") then
        return Decision(state, "SLICE_AND_DICE",
            "Start Slice and Dice", { mode = mode })
    end

    local ranged = Shared.RangedDecision(state, mode)
    if ranged then return ranged end

    local maintenance = FivePointMaintenance(state, mode, aoe)
    if maintenance then return maintenance end

    -- The Hemorrhage bleed is refreshed outside Shadow Dance. Dance time is
    -- reserved for Ambush unless the primary Sanguinary Vein bleed is unsafe.
    if not aoe and not danceActive
        and Value(state, "hemorrhageRemaining", 0)
            <= (ns.CONFIG.SUBTLETY_HEMORRHAGE_REFRESH or 3)
        and Ready(state, "HEMORRHAGE") then
        return Decision(state, "HEMORRHAGE",
            "Maintain Hemorrhage before the burst window", { mode = mode })
    end

    if danceActive then
        local blades = ShadowBladesDecision(state, mode, cooldownsAllowed,
            fanAlways)
        if blades then return blades end
        local danceSpendAt = 5
        if not (state.talents and state.talents.ANTICIPATION == true) then
            -- Ambush normally adds two points and adds another under Shadow
            -- Blades. Spend early when necessary so non-Anticipation builds do
            -- not throw away Combo Points during their shortest damage window.
            danceSpendAt = Value(state, "shadowBlades", false) and 3 or 4
        end
        if comboPoints >= danceSpendAt and Ready(state, "EVISCERATE") then
            return Decision(state, "EVISCERATE",
                "Spend Combo Points before the next Dance builder", { mode = mode })
        end
        if fanAlways and Ready(state, "FAN_OF_KNIVES") then
            return Decision(state, "FAN_OF_KNIVES",
                "Five or more targets make Fan of Knives the best Dance builder",
                { mode = mode })
        end
        if Ready(state, "AMBUSH") then
            return Decision(state, "AMBUSH",
                "Use Ambush throughout Shadow Dance", { mode = mode })
        end
    end

    local dance = DanceDecision(state, mode, cooldownsAllowed, fanAlways, aoe)
    if dance then return dance end

    local vanish = VanishDecision(state, mode, cooldownsAllowed, fanAlways, aoe)
    if vanish then return vanish end

    local blades = ShadowBladesDecision(state, mode, cooldownsAllowed, fanAlways)
    if blades then return blades end

    local prey = Shared.PreyOnWeakDecision(state, settings, mode)
    if prey then return prey end

    if comboPoints >= 5 and Ready(state, "EVISCERATE") then
        return Decision(state, "EVISCERATE",
            "Spend five Combo Points after maintenance", { mode = mode })
    end

    if comboPoints == 0 and state.talents
        and state.talents.MARKED_FOR_DEATH == true
        and Ready(state, "MARKED_FOR_DEATH")
        and Value(state, "targetTTD", 999) >= 5 then
        return Decision(state, "MARKED_FOR_DEATH",
            "Generate five Combo Points on a healthy target", { mode = mode })
    end

    if fanAlways and Ready(state, "FAN_OF_KNIVES") then
        return Decision(state, "FAN_OF_KNIVES",
            "Build Combo Points on five or more targets", { mode = mode })
    end
    if stealthAccess and Ready(state, "AMBUSH") then
        return Decision(state, "AMBUSH",
            "Use the stealth window to apply Find Weakness", { mode = mode })
    end

    -- Preparation exists primarily to create a second Vanish/Find Weakness
    -- window for Subtlety. It must come after the stealth Ambush so it can
    -- never consume the recommendation slot during Vanish itself.
    if cooldownsAllowed and not fanAlways and Ready(state, "PREPARATION")
        and Cooldown(state, "VANISH") > 30
        and Cooldown(state, "SHADOW_DANCE") > 10
        and comboPoints < 3 and MaintenanceSafe(state, aoe)
        and Value(state, "targetTTD", 999) >= 15 then
        return Decision(state, "PREPARATION",
            "Reset Vanish after applying Find Weakness with Ambush",
            { mode = mode, offGCD = true })
    end

    if aoe and Ready(state, "FAN_OF_KNIVES") then
        return Decision(state, "FAN_OF_KNIVES",
            "Build Combo Points on three or more targets", { mode = mode })
    end
    if Value(state, "backstabUsable", true) and Ready(state, "BACKSTAB") then
        return Decision(state, "BACKSTAB",
            "Primary builder while behind the target", { mode = mode })
    end
    if Ready(state, "HEMORRHAGE") then
        return Decision(state, "HEMORRHAGE",
            "Use Hemorrhage when Backstab is not available", { mode = mode })
    end
    return nil
end

ns.Rotation_Register(ns.SUBTLETY_SPEC_ID, Evaluate)
