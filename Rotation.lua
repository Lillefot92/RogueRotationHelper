-- ============================================================
-- Rogue Rotation Helper - Rotation.lua
-- Pure Combat Rogue priority evaluator for MoP Classic 5.5.4.
-- ============================================================

local ADDON_NAME, ns = ...

local function Value(state, key, fallback)
    local value = state[key]
    if value == nil then return fallback end
    return value
end

local function Knows(state, key)
    if not ns.ABILITIES[key] then return false end
    if not state.known then return true end
    return state.known[key] ~= false
end

local function Cooldown(state, key)
    if not state.cooldowns then return 0 end
    return state.cooldowns[key] or 0
end

local function Ready(state, key)
    return Knows(state, key) and Cooldown(state, key) <= 0.10
end

local function AbilityCost(key)
    local ability = ns.ABILITIES[key]
    return ability and (ability.cost or 0) or 0
end

local function Decision(state, key, reason, extra)
    if not key then return nil end
    local cost = AbilityCost(key)
    local decision = {
        ability = key,
        reason = reason or "",
        cost = cost,
        pool = Value(state, "energy", 0) < cost,
        offGCD = key == "ADRENALINE_RUSH" or key == "SHADOW_BLADES",
    }
    if extra then
        for field, value in pairs(extra) do decision[field] = value end
    end
    return decision
end

local function ResolveMode(state, settings)
    local requested = settings.mode or "auto"
    if requested == "single" or requested == "cleave" or requested == "aoe" then
        return requested
    end
    local enemies = Value(state, "enemyCount", 1)
    if enemies >= ns.CONFIG.AOE_THRESHOLD then return "aoe" end
    if enemies >= ns.CONFIG.CLEAVE_THRESHOLD then return "cleave" end
    return "single"
end

local function CooldownsAllowed(state, settings)
    local policy = settings.cooldowns or "boss"
    if policy == "off" then return false end
    if policy == "on" then return true end
    return Value(state, "targetIsBoss", false) == true
end

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

    -- Keep the two three-minute cooldowns paired when Adrenaline Rush is
    -- nearly ready. If they drift substantially, use Shadow Blades alone.
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

local function PoisonDecision(state)
    local threshold = ns.CONFIG.POISON_REFRESH or 0
    local deadlyRemaining = Value(state, "deadlyPoisonRemaining", 999)
    local inCombat = Value(state, "inCombat", false)
    local deadlyNeedsAttention = deadlyRemaining <= 0
        or (not inCombat and deadlyRemaining <= threshold)
    if deadlyNeedsAttention and Ready(state, "DEADLY_POISON") then
        return Decision(state, "DEADLY_POISON",
            deadlyRemaining > 0 and "Refresh lethal poison before it expires"
                or "Apply your required PvE lethal poison",
            { preparation = true, warning = "poison" })
    end

    local preferredUtility
    if Knows(state, "LEECHING_POISON") then
        preferredUtility = "LEECHING_POISON"
    elseif Knows(state, "PARALYTIC_POISON") then
        preferredUtility = "PARALYTIC_POISON"
    end

    local utilityRemaining = Value(state, "utilityPoisonRemaining", 999)
    local activeUtility = Value(state, "utilityPoisonKey", nil)
    local utilityMissing = utilityRemaining <= 0
    local utilityNeedsRefresh = not inCombat and utilityRemaining <= threshold
    local utilityIsWrong = not inCombat and activeUtility ~= preferredUtility
    if preferredUtility and (utilityMissing or utilityNeedsRefresh
        or utilityIsWrong) and Ready(state, preferredUtility) then
        return Decision(state, preferredUtility,
            "Apply your selected non-lethal poison talent",
            { preparation = true, warning = "poison" })
    end
    if not preferredUtility and (utilityMissing or utilityNeedsRefresh)
        and Ready(state, "CRIPPLING_POISON") then
        return Decision(state, "CRIPPLING_POISON",
            "Apply a non-lethal poison; swap it per encounter if needed",
            { preparation = true, warning = "poison" })
    end
    return nil
end

function ns.Rotation_Evaluate(state, settings)
    state = state or {}
    settings = settings or {}

    -- Poisons are raid preparation, so warn even without a hostile target.
    local poison = PoisonDecision(state)
    if poison then return poison end

    if not Value(state, "targetAttackable", false) then return nil end

    local mode = ResolveMode(state, settings)
    local cleaving = mode == "cleave" or mode == "aoe"
    local cooldownsAllowed = CooldownsAllowed(state, settings)
    local comboPoints = Value(state, "comboPoints", 0)
    local enemyCount = Value(state, "enemyCount", 1)

    -- Blade Flurry is a toggle. Leaving it on against one target costs Energy;
    -- leaving it off in cleave loses Combat's defining advantage. Manual mode
    -- overrides may select a rotation branch, but must never invent a second
    -- enemy for Blade Flurry.
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

    if Value(state, "stealthWindow", Value(state, "stealthed", false))
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

    -- Level-90 Shuriken Toss and the level-30 Deadly Throw talent preserve
    -- useful damage when encounter movement forces the Rogue out of melee.
    if Value(state, "meleeRange", true) == false then
        if comboPoints >= 5 and Ready(state, "DEADLY_THROW") then
            return Decision(state, "DEADLY_THROW",
                "Spend Combo Points while outside melee range", { mode = mode })
        end
        if comboPoints < 5 and Ready(state, "SHURIKEN_TOSS")
            and Value(state, "shurikenRange", true) then
            return Decision(state, "SHURIKEN_TOSS",
                "Ranged Combo Point builder while disconnected", { mode = mode })
        end
        if comboPoints > 0 and Ready(state, "DEADLY_THROW") then
            return Decision(state, "DEADLY_THROW",
                "Use the ranged finisher while disconnected", { mode = mode })
        end
    end

    -- Establish Revealing Strike before finishers and before entering the
    -- cooldown-heavy part of the priority.
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

    if settings.preyOnWeak == true
        and state.talents and state.talents.PREY_ON_THE_WEAK == true
        and not Value(state, "targetIsBoss", false)
        and Value(state, "kidneyShotRemaining", 0) <= 0
        and Value(state, "targetTTD", 999) >= 8
        and comboPoints >= 5 and mode ~= "aoe"
        and Ready(state, "KIDNEY_SHOT") then
        return Decision(state, "KIDNEY_SHOT",
            "Prey on the Weak: only use if this target can be stunned",
            { mode = mode, warning = "conditional" })
    end

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

    -- Leveling-safe fallbacks if the phase-specific preferred spell is not
    -- learned yet.
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

function ns.Rotation_GetDecision(state)
    local decision = ns.Rotation_Evaluate(state, ns.db or {})
    if not decision then return nil end

    -- Query the live cost so hotfixes and unusual effects override fallbacks.
    decision.cost = ns.GetAbilityCost(decision.ability)
    decision.pool = Value(state, "energy", 0) < decision.cost
    decision.outOfRange = not ns.IsAbilityInRange(decision.ability, "target")
    if decision.pool then
        decision.reason = "Pool to " .. math.floor(decision.cost + 0.5)
            .. " Energy - " .. decision.reason
    elseif decision.outOfRange then
        decision.reason = "Move into range - " .. decision.reason
    end
    return decision
end
