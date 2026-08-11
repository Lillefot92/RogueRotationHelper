-- ============================================================
-- Rogue Rotation Helper - RotationCombat.lua
-- Pure Combat Rogue priority evaluator for MoP Classic 5.5.4.
-- ============================================================

local ADDON_NAME, ns = ...
local Shared = ns.RotationShared
local Value = Shared.Value
local Knows = Shared.Knows
local Cooldown = Shared.Cooldown
local Ready = Shared.Ready
local Decision = Shared.Decision

local function ShouldRefreshSliceAndDice(state)
    local comboPoints = Value(state, "comboPoints", 0)
    local remaining = Value(state, "sndRemaining", 0)
    if comboPoints <= 0 then return false end
    if remaining <= 0 then return true end
    if remaining <= ns.CONFIG.SND_EMERGENCY then return true end
    return comboPoints >= 5 and remaining <= ns.CONFIG.SND_FIVE_CP_REFRESH
end

local function ShouldRefreshRevealingStrike(state)
    return Value(state, "rvsRemaining", 0) <= ns.CONFIG.RVS_REFRESH
end

local function UseKillingSpree(state, cooldownsAllowed)
    if not cooldownsAllowed or not Ready(state, "KILLING_SPREE") then return false end
    if Value(state, "adrenalineRush", false)
        or Value(state, "shadowBlades", false)
        or Value(state, "killingSpree", false) then
        return false
    end
    if Value(state, "targetTTD", 999) < 3 then return false end
    return Value(state, "energy", 0) <= ns.CONFIG.KILLING_SPREE_MAX_ENERGY
end

local function UseAdrenalineRush(state, cooldownsAllowed)
    if not cooldownsAllowed or not Ready(state, "ADRENALINE_RUSH") then return false end
    if Value(state, "adrenalineRush", false) or Value(state, "killingSpree", false) then
        return false
    end
    if Value(state, "targetTTD", 999) < 8 then return false end
    return Value(state, "energy", 0) <= ns.CONFIG.ADRENALINE_RUSH_MAX_ENERGY
end

local function UseShadowBlades(state, cooldownsAllowed)
    if not cooldownsAllowed or not Ready(state, "SHADOW_BLADES") then return false end
    if Value(state, "shadowBlades", false) or Value(state, "killingSpree", false) then
        return false
    end
    if Value(state, "targetTTD", 999) < 8 then return false end
    if Value(state, "adrenalineRush", false) then return true end
    return Cooldown(state, "ADRENALINE_RUSH") > 10
end

local function MainBuilder(state)
    -- Phase 5 / client 5.5.4: Revealing Strike is the efficient default
    -- builder. Sinister Strike becomes preferable only while both Adrenaline
    -- Rush and a Heroism-family haste effect are active.
    if Value(state, "adrenalineRush", false) and Value(state, "heroism", false)
        and Knows(state, "SINISTER_STRIKE") then
        return "SINISTER_STRIKE",
            "Fast builder during Adrenaline Rush and Heroism/Bloodlust"
    end
    return "REVEALING_STRIKE",
        "40-Energy Phase 5 builder; also keeps its finisher bonus active"
end

local function Evaluate(state, settings)
    local mode = Shared.ResolveMode(state, settings)
    local cleaving = mode == "cleave" or mode == "aoe"
    local cooldownsAllowed = Shared.CooldownsAllowed(state, settings)
    local comboPoints = Value(state, "comboPoints", 0)
    local enemyCount = Value(state, "enemyCount", 1)

    -- Blade Flurry is a toggle. A manual branch never invents a second enemy.
    if Ready(state, "BLADE_FLURRY") then
        if cleaving and enemyCount >= ns.CONFIG.CLEAVE_THRESHOLD
            and not Value(state, "bladeFlurry", false) then
            return Decision(state, "BLADE_FLURRY", "Enable cleave for "
                .. enemyCount .. " nearby enemies",
                { mode = mode, toggle = "on" })
        elseif (mode == "single" or enemyCount < ns.CONFIG.CLEAVE_THRESHOLD)
            and Value(state, "bladeFlurry", false) then
            return Decision(state, "BLADE_FLURRY",
                "Disable Blade Flurry to restore full Energy regeneration",
                { mode = mode, toggle = "off" })
        end
    end

    if (Value(state, "stealthWindow", false) or Value(state, "stealthed", false))
        and Ready(state, "AMBUSH") then
        return Decision(state, "AMBUSH", "Open from Stealth", { mode = mode })
    end

    if comboPoints == 0 and Ready(state, "MARKED_FOR_DEATH")
        and Value(state, "targetTTD", 999) >= 4 then
        return Decision(state, "MARKED_FOR_DEATH", "Gain 5 Combo Points",
            { mode = mode, offGCD = true })
    end

    if ShouldRefreshSliceAndDice(state) and Ready(state, "SLICE_AND_DICE") then
        return Decision(state, "SLICE_AND_DICE",
            Value(state, "sndRemaining", 0) <= 0
                and "Start Slice and Dice" or "Refresh Slice and Dice before it falls",
            { mode = mode })
    end

    local ranged = Shared.RangedDecision(state, mode)
    if ranged then return ranged end

    if ShouldRefreshRevealingStrike(state) and Ready(state, "REVEALING_STRIKE") then
        return Decision(state, "REVEALING_STRIKE",
            "Maintain the 35% finisher bonus", { mode = mode })
    end

    if UseKillingSpree(state, cooldownsAllowed) then
        return Decision(state, "KILLING_SPREE",
            Value(state, "insight", 0) == 3
                and "Use Killing Spree during Deep Insight"
                or "Use Killing Spree at safe Energy; confirm positioning",
            { mode = mode, cooldown = true })
    end

    if UseAdrenalineRush(state, cooldownsAllowed) then
        return Decision(state, "ADRENALINE_RUSH",
            "Start the major cooldown window at safe Energy",
            { mode = mode, cooldown = true, offGCD = true })
    end

    if UseShadowBlades(state, cooldownsAllowed) then
        return Decision(state, "SHADOW_BLADES",
            Value(state, "adrenalineRush", false)
                and "Pair Shadow Blades with Adrenaline Rush"
                or "Use the desynchronized Shadow Blades cooldown",
            { mode = mode, cooldown = true, offGCD = true })
    end

    if settings.offensiveVanish == true
        and Value(state, "insight", 0) == 3
        and Value(state, "energy", 0) <= 50
        and comboPoints <= 3
        and not Value(state, "stealthed", false)
        and Ready(state, "VANISH") then
        return Decision(state, "VANISH",
            "Optional damage Vanish during Deep Insight; Ambush next",
            { mode = mode, cooldown = true, offGCD = true })
    end

    local prey = Shared.PreyOnWeakDecision(state, settings, mode)
    if prey then return prey end

    if mode == "aoe" then
        local forcedAoE = settings.mode == "aoe"
            and enemyCount < ns.CONFIG.AOE_THRESHOLD
        local aoeTargets = forcedAoE and "forced AoE mode" or "8+ enemies"
        if comboPoints >= 5 then
            if Value(state, "targetTTD", 999) >= ns.CONFIG.CRIMSON_TEMPEST_MIN_TTD
                and Ready(state, "CRIMSON_TEMPEST") then
                return Decision(state, "CRIMSON_TEMPEST",
                    "5-point finisher for long-lived enemies in " .. aoeTargets,
                    { mode = mode })
            end
            if Ready(state, "EVISCERATE") then
                return Decision(state, "EVISCERATE",
                    "Enemies are too short-lived for Crimson Tempest", { mode = mode })
            end
        end
        if Ready(state, "FAN_OF_KNIVES") then
            return Decision(state, "FAN_OF_KNIVES",
                "Build Combo Points in " .. aoeTargets, { mode = mode })
        end
    end

    if comboPoints >= 5 then
        if mode == "single"
            and Value(state, "ruptureRemaining", 0) <= ns.CONFIG.DOT_REFRESH
            and Value(state, "targetTTD", 999) >= ns.CONFIG.RUPTURE_MIN_TTD
            and Ready(state, "RUPTURE") then
            return Decision(state, "RUPTURE", "Maintain a 5-point Rupture",
                { mode = mode })
        end
        if Ready(state, "EVISCERATE") then
            return Decision(state, "EVISCERATE",
                cleaving and "Spend 5 Combo Points; Rupture does not cleave"
                    or "Spend 5 Combo Points",
                { mode = mode })
        end
    end

    local builder, reason = MainBuilder(state)
    if Ready(state, builder) then
        return Decision(state, builder, reason, { mode = mode })
    end
    if Ready(state, "SINISTER_STRIKE") then
        return Decision(state, "SINISTER_STRIKE", "Available Combo Point builder",
            { mode = mode })
    end
    if Ready(state, "REVEALING_STRIKE") then
        return Decision(state, "REVEALING_STRIKE", "Available Combo Point builder",
            { mode = mode })
    end
    return nil
end

ns.Rotation_Register(ns.COMBAT_SPEC_ID, Evaluate)
