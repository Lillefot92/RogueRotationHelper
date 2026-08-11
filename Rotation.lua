-- ============================================================
-- Rogue Rotation Helper - Rotation.lua
-- Shared Rogue helpers and specialization dispatch for MoP 5.5.4.
-- ============================================================

local ADDON_NAME, ns = ...

local Shared = {}
ns.RotationShared = Shared
ns.RotationEvaluators = ns.RotationEvaluators or {}

function Shared.Value(state, key, fallback)
    local value = state[key]
    if value == nil then return fallback end
    return value
end

function Shared.Knows(state, key)
    if not ns.ABILITIES[key] then return false end
    if not state.known then return true end
    return state.known[key] ~= false
end

function Shared.Cooldown(state, key)
    if not state.cooldowns then return 0 end
    return state.cooldowns[key] or 0
end

function Shared.Ready(state, key)
    return Shared.Knows(state, key) and Shared.Cooldown(state, key) <= 0.10
end

function Shared.AbilityCost(key)
    local ability = ns.ABILITIES[key]
    return ability and (ability.cost or 0) or 0
end

function Shared.Decision(state, key, reason, extra)
    if not key then return nil end
    local cost = Shared.AbilityCost(key)
    local decision = {
        ability = key,
        reason = reason or "",
        cost = cost,
        offGCD = key == "ADRENALINE_RUSH" or key == "SHADOW_BLADES",
    }
    if extra then
        for field, value in pairs(extra) do decision[field] = value end
    end
    decision.pool = Shared.Value(state, "energy", 0)
        < (decision.poolTo or cost)
    return decision
end

function Shared.ResolveMode(state, settings)
    local requested = settings.mode or "auto"
    if requested == "single" or requested == "cleave" or requested == "aoe" then
        return requested
    end
    local enemies = Shared.Value(state, "enemyCount", 1)
    local aoeThreshold = ns.CONFIG.AOE_THRESHOLD
    if state.specID == ns.ASSASSINATION_SPEC_ID then
        aoeThreshold = ns.CONFIG.ASSASSINATION_AOE_THRESHOLD or 4
    elseif state.specID == ns.SUBTLETY_SPEC_ID then
        aoeThreshold = ns.CONFIG.SUBTLETY_AOE_THRESHOLD or 3
    end
    if enemies >= aoeThreshold then return "aoe" end
    if enemies >= ns.CONFIG.CLEAVE_THRESHOLD then return "cleave" end
    return "single"
end

function Shared.CooldownsAllowed(state, settings)
    local policy = settings.cooldowns or "boss"
    if policy == "off" then return false end
    if policy == "on" then return true end
    return Shared.Value(state, "targetIsBoss", false) == true
end

function Shared.PoisonDecision(state)
    local threshold = ns.CONFIG.POISON_REFRESH or 0
    local deadlyRemaining = Shared.Value(state, "deadlyPoisonRemaining", 999)
    local inCombat = Shared.Value(state, "inCombat", false)
    local deadlyNeedsAttention = deadlyRemaining <= 0
        or (not inCombat and deadlyRemaining <= threshold)
    if deadlyNeedsAttention and Shared.Ready(state, "DEADLY_POISON") then
        return Shared.Decision(state, "DEADLY_POISON",
            deadlyRemaining > 0 and "Refresh lethal poison before it expires"
                or "Apply your required PvE lethal poison",
            { preparation = true, warning = "poison" })
    end

    local preferredUtility
    if Shared.Knows(state, "LEECHING_POISON") then
        preferredUtility = "LEECHING_POISON"
    elseif Shared.Knows(state, "PARALYTIC_POISON") then
        preferredUtility = "PARALYTIC_POISON"
    end

    local utilityRemaining = Shared.Value(state, "utilityPoisonRemaining", 999)
    local activeUtility = Shared.Value(state, "utilityPoisonKey", nil)
    local utilityMissing = utilityRemaining <= 0
    local utilityNeedsRefresh = not inCombat and utilityRemaining <= threshold
    local utilityIsWrong = not inCombat and activeUtility ~= preferredUtility
    if preferredUtility and (utilityMissing or utilityNeedsRefresh
        or utilityIsWrong) and Shared.Ready(state, preferredUtility) then
        return Shared.Decision(state, preferredUtility,
            "Apply your selected non-lethal poison talent",
            { preparation = true, warning = "poison" })
    end
    if not preferredUtility and (utilityMissing or utilityNeedsRefresh)
        and Shared.Ready(state, "CRIPPLING_POISON") then
        return Shared.Decision(state, "CRIPPLING_POISON",
            "Apply a non-lethal poison; swap it per encounter if needed",
            { preparation = true, warning = "poison" })
    end
    return nil
end

function Shared.RangedDecision(state, mode)
    if Shared.Value(state, "meleeRange", true) ~= false then return nil end
    local comboPoints = Shared.Value(state, "comboPoints", 0)
    if comboPoints >= 5 and Shared.Ready(state, "DEADLY_THROW") then
        return Shared.Decision(state, "DEADLY_THROW",
            "Spend Combo Points while outside melee range", { mode = mode })
    end
    if comboPoints < 5 and Shared.Ready(state, "SHURIKEN_TOSS")
        and Shared.Value(state, "shurikenRange", true) then
        return Shared.Decision(state, "SHURIKEN_TOSS",
            "Ranged Combo Point builder while disconnected", { mode = mode })
    end
    if comboPoints > 0 and Shared.Ready(state, "DEADLY_THROW") then
        return Shared.Decision(state, "DEADLY_THROW",
            "Use the ranged finisher while disconnected", { mode = mode })
    end
    return nil
end

function Shared.PreyOnWeakDecision(state, settings, mode)
    local comboPoints = Shared.Value(state, "comboPoints", 0)
    if settings.preyOnWeak == true
        and state.talents and state.talents.PREY_ON_THE_WEAK == true
        and not Shared.Value(state, "targetIsBoss", false)
        and Shared.Value(state, "kidneyShotRemaining", 0) <= 0
        and Shared.Value(state, "targetTTD", 999) >= 8
        and comboPoints >= 5 and mode ~= "aoe"
        and Shared.Ready(state, "KIDNEY_SHOT") then
        return Shared.Decision(state, "KIDNEY_SHOT",
            "Prey on the Weak: only use if this target can be stunned",
            { mode = mode, warning = "conditional" })
    end
    return nil
end

function ns.Rotation_Register(specID, evaluator)
    ns.RotationEvaluators[specID] = evaluator
end

local COOLDOWN_KEYS = {
    [ns.ASSASSINATION_SPEC_ID] = { "VENDETTA", "SHADOW_BLADES", "VANISH" },
    [ns.COMBAT_SPEC_ID] = { "KILLING_SPREE", "ADRENALINE_RUSH", "SHADOW_BLADES" },
    [ns.SUBTLETY_SPEC_ID] = { "SHADOW_DANCE", "SHADOW_BLADES", "VANISH" },
}

function ns.Rotation_GetCooldownKeys(specID)
    return COOLDOWN_KEYS[specID] or {}
end

function ns.Rotation_Evaluate(state, settings)
    state = state or {}
    settings = settings or {}

    local specID = state.specID
    if not specID or specID == 0 then
        if state.isAssassinationSpec then
            specID = ns.ASSASSINATION_SPEC_ID
        elseif state.isSubtletySpec then
            specID = ns.SUBTLETY_SPEC_ID
        elseif state.isCombatSpec ~= false then
            specID = ns.COMBAT_SPEC_ID
        end
    end

    local evaluator = ns.RotationEvaluators[specID]
    if not evaluator then return nil end

    -- Poisons are shared raid preparation, so warn even without a target.
    local poison = Shared.PoisonDecision(state)
    if poison then return poison end
    if not Shared.Value(state, "targetAttackable", false) then return nil end

    return evaluator(state, settings)
end

function ns.Rotation_GetDecision(state)
    local decision = ns.Rotation_Evaluate(state, ns.db or {})
    if not decision then return nil end

    -- Live spell costs override fallbacks, while a specialization may request
    -- strategic pooling above the actual cost (for example before Envenom).
    decision.cost = ns.GetAbilityCost(decision.ability)
    local poolThreshold = decision.poolTo or decision.cost
    decision.pool = Shared.Value(state, "energy", 0) < poolThreshold
    decision.outOfRange = not ns.IsAbilityInRange(decision.ability, "target")
    if decision.pool then
        decision.reason = "Pool to " .. math.floor(poolThreshold + 0.5)
            .. " Energy - " .. decision.reason
    elseif decision.outOfRange then
        decision.reason = "Move into range - " .. decision.reason
    end
    return decision
end
