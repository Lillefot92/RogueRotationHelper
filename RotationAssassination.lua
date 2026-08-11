-- ============================================================
-- Rogue Rotation Helper - RotationAssassination.lua
-- Assassination Rogue PvE priority evaluator for MoP 5.5.4.
-- ============================================================

local ADDON_NAME, ns = ...
local Shared = ns.RotationShared
local Value = Shared.Value
local Cooldown = Shared.Cooldown
local Ready = Shared.Ready
local Decision = Shared.Decision

local function EffectiveEnemyCount(state, settings)
    local actual = Value(state, "enemyCount", 1)
    if settings.mode == "aoe" and actual < ns.CONFIG.ASSASSINATION_AOE_THRESHOLD then
        return ns.CONFIG.ASSASSINATION_AOE_THRESHOLD
    end
    if settings.mode == "cleave" and actual < ns.CONFIG.CLEAVE_THRESHOLD then
        return ns.CONFIG.CLEAVE_THRESHOLD
    end
    return actual
end

local function AoEReason(state, settings, fallback)
    if settings.mode == "aoe"
        and Value(state, "enemyCount", 1) < ns.CONFIG.ASSASSINATION_AOE_THRESHOLD then
        return "forced AoE mode"
    end
    return fallback
end

local function EnvenomDecision(state, mode, reason)
    local poolTo = ns.CONFIG.ASSASSINATION_ENVENOM_POOL or 80
    if Value(state, "sndRemaining", 0) <= ns.CONFIG.SND_EMERGENCY
        or Value(state, "targetTTD", 999) < 5 then
        poolTo = Shared.AbilityCost("ENVENOM")
    end
    return Decision(state, "ENVENOM", reason or
        "Spend Combo Points after pooling Energy for the poison window",
        { mode = mode, poolTo = poolTo })
end

local function UseVendetta(state, cooldownsAllowed)
    if not cooldownsAllowed or not Ready(state, "VENDETTA") then return false end
    if Value(state, "vendettaRemaining", 0) > 0 then return false end
    if Value(state, "targetTTD", 999) < ns.CONFIG.ASSASSINATION_VENDETTA_MIN_TTD then
        return false
    end
    return Value(state, "sndRemaining", 0) > 0
        and Value(state, "ruptureRemaining", 0) > 0
end

local function UseShadowBlades(state, cooldownsAllowed)
    if not cooldownsAllowed or not Ready(state, "SHADOW_BLADES") then return false end
    if Value(state, "shadowBlades", false) then return false end
    if Value(state, "targetTTD", 999) < 8 then return false end
    if Value(state, "vendettaRemaining", 0) > 0 then return true end
    return Cooldown(state, "VENDETTA") > 10
end

local function RuptureDecision(state, mode, minimumPoints, reason)
    local comboPoints = Value(state, "comboPoints", 0)
    local remaining = Value(state, "ruptureRemaining", 0)
    if Value(state, "targetTTD", 999) < ns.CONFIG.ASSASSINATION_RUPTURE_MIN_TTD then
        return nil
    end
    if remaining <= 0 and comboPoints >= minimumPoints and Ready(state, "RUPTURE") then
        return Decision(state, "RUPTURE", reason or
            "Apply Rupture for Venomous Wounds Energy", { mode = mode })
    end
    if remaining <= ns.CONFIG.DOT_REFRESH and comboPoints >= 4
        and Ready(state, "RUPTURE") then
        return Decision(state, "RUPTURE",
            "Refresh Rupture before Venomous Wounds stops", { mode = mode })
    end
    return nil
end

local function GeneratorDecision(state, mode, useFan)
    if useFan and Ready(state, "FAN_OF_KNIVES") then
        return Decision(state, "FAN_OF_KNIVES",
            "Build Combo Points and spread Deadly Poison", { mode = mode })
    end
    if (Value(state, "blindside", false)
        or Value(state, "targetHPPercent", 100) <= 35)
        and Ready(state, "DISPATCH") then
        return Decision(state, "DISPATCH",
            Value(state, "blindside", false)
                and "Use the free Blindside Dispatch proc"
                or "Execute-phase Combo Point builder",
            { mode = mode })
    end
    if Ready(state, "MUTILATE") then
        return Decision(state, "MUTILATE", "Primary Combo Point builder",
            { mode = mode })
    end
    return nil
end

local function Evaluate(state, settings)
    local mode = Shared.ResolveMode(state, settings)
    local comboPoints = Value(state, "comboPoints", 0)
    local effectiveEnemies = EffectiveEnemyCount(state, settings)
    local massAoE = mode == "aoe"
        and effectiveEnemies >= ns.CONFIG.ASSASSINATION_MASS_AOE_THRESHOLD
    local fanBuilder = mode == "aoe"
        and effectiveEnemies >= ns.CONFIG.ASSASSINATION_AOE_THRESHOLD
    local cooldownsAllowed = Shared.CooldownsAllowed(state, settings)

    -- Assassination uses Mutilate from Stealth so Shadow Focus/Subterfuge
    -- improve the normal builder instead of changing the opener to Ambush.
    if (Value(state, "stealthWindow", false) or Value(state, "stealthed", false))
        and Ready(state, "MUTILATE") then
        return Decision(state, "MUTILATE", "Open from Stealth with Mutilate",
            { mode = mode })
    end

    if Value(state, "sndRemaining", 0) <= 0 and comboPoints > 0
        and Ready(state, "SLICE_AND_DICE") then
        return Decision(state, "SLICE_AND_DICE",
            "Establish Slice and Dice; Envenom will refresh it",
            { mode = mode })
    end

    local ranged = Shared.RangedDecision(state, mode)
    if ranged then return ranged end

    if not massAoE then
        local minimumRupturePoints = fanBuilder
            and ns.CONFIG.ASSASSINATION_RUPTURE_MULTI_CP or 2
        local ruptureReason = fanBuilder
            and "Apply a 3+ point Rupture; switch targets to spread it"
            or "Apply Rupture for Venomous Wounds Energy"
        local rupture = RuptureDecision(state, mode, minimumRupturePoints,
            ruptureReason)
        if rupture then return rupture end
    end

    if comboPoints == 0 and Value(state, "sndRemaining", 0) > 0
        and (massAoE or Value(state, "ruptureRemaining", 0) > 0)
        and Ready(state, "MARKED_FOR_DEATH")
        and Value(state, "targetTTD", 999) >= 4 then
        return Decision(state, "MARKED_FOR_DEATH", "Gain 5 Combo Points",
            { mode = mode, offGCD = true })
    end

    if UseVendetta(state, cooldownsAllowed) then
        return Decision(state, "VENDETTA",
            "Start the damage window after Slice and Dice and Rupture",
            { mode = mode, cooldown = true })
    end

    if UseShadowBlades(state, cooldownsAllowed) then
        return Decision(state, "SHADOW_BLADES",
            Value(state, "vendettaRemaining", 0) > 0
                and "Pair Shadow Blades with Vendetta"
                or "Use desynchronized Shadow Blades before losing a cast",
            { mode = mode, cooldown = true, offGCD = true })
    end

    if settings.offensiveVanish == true
        and not Value(state, "stealthed", false)
        and comboPoints <= 3
        and Value(state, "sndRemaining", 0) > 4
        and (massAoE or Value(state, "ruptureRemaining", 0) > 4)
        and Value(state, "targetTTD", 999) >= 8
        and Value(state, "energy", 0) <= 80
        and Ready(state, "VANISH") then
        return Decision(state, "VANISH",
            "Optional damage Vanish; use Mutilate from Stealth next",
            { mode = mode, cooldown = true, offGCD = true })
    end

    if settings.offensiveVanish == true
        and not Value(state, "stealthed", false)
        and Value(state, "sndRemaining", 0) > 4
        and (massAoE or Value(state, "ruptureRemaining", 0) > 4)
        and Value(state, "targetTTD", 999) >= 8
        and Cooldown(state, "VANISH") > 30
        and Ready(state, "PREPARATION") then
        return Decision(state, "PREPARATION",
            "Reset Vanish for another Shadow Focus/Subterfuge builder",
            { mode = mode, cooldown = true, offGCD = true })
    end

    local prey = Shared.PreyOnWeakDecision(state, settings, mode)
    if prey then return prey end

    -- Cut to the Chase refreshes Slice and Dice to full duration even from a
    -- low-point Envenom, so preserving the buff outranks damage efficiency.
    if Value(state, "sndRemaining", 0) <= ns.CONFIG.SND_EMERGENCY
        and comboPoints > 0 and Ready(state, "ENVENOM") then
        return EnvenomDecision(state, mode,
            "Refresh Slice and Dice through Cut to the Chase")
    end

    if massAoE then
        if comboPoints >= 5 and Ready(state, "ENVENOM") then
            return EnvenomDecision(state, mode,
                "Keep Envenom active while Deadly Poison handles 9+ targets")
        end
        local generator = GeneratorDecision(state, mode, true)
        if generator then
            generator.reason = "Build Combo Points and spread Deadly Poison on 9+ targets"
        end
        return generator
    end

    if comboPoints >= 5 and Ready(state, "ENVENOM") then
        local reason = fanBuilder
            and "Spend capped points; switch targets to spread more Ruptures"
            or "Spend 5 Combo Points and amplify poison applications"
        return EnvenomDecision(state, mode, reason)
    end

    if fanBuilder then
        local generator = GeneratorDecision(state, mode, true)
        if generator then
            generator.reason = "Use Fan of Knives for "
                .. AoEReason(state, settings, "4-8 targets")
        end
        return generator
    end

    return GeneratorDecision(state, mode, false)
end

ns.Rotation_Register(ns.ASSASSINATION_SPEC_ID, Evaluate)
