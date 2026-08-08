-- ============================================================
-- Rogue Rotation Helper - Simulator.lua
-- Deterministic checks for the same evaluator used in live play.
-- ============================================================

local ADDON_NAME, ns = ...

local function CopyTable(source)
    local result = {}
    for key, value in pairs(source or {}) do
        if type(value) == "table" then
            result[key] = CopyTable(value)
        else
            result[key] = value
        end
    end
    return result
end

local function BaseState()
    local known = {}
    for key in pairs(ns.ABILITIES) do known[key] = true end
    return {
        targetAttackable = true,
        playerLevel = 90,
        targetIsBoss = false,
        targetTTD = 120,
        energy = 70,
        maxEnergy = 100,
        comboPoints = 2,
        anticipation = 0,
        talents = { PREY_ON_THE_WEAK = true, ANTICIPATION = true },
        enemyCount = 1,
        stealthed = false,
        heroism = false,
        meleeRange = true,
        shurikenRange = true,
        insight = 1,
        sndRemaining = 20,
        rvsRemaining = 20,
        ruptureRemaining = 20,
        deadlyPoisonRemaining = 3500,
        utilityPoisonRemaining = 3500,
        utilityPoisonKey = "LEECHING_POISON",
        poisonsReady = true,
        kidneyShotRemaining = 0,
        bladeFlurry = false,
        adrenalineRush = false,
        shadowBlades = false,
        killingSpree = false,
        known = known,
        cooldowns = {
            AMBUSH = 0,
            SLICE_AND_DICE = 0,
            REVEALING_STRIKE = 0,
            SINISTER_STRIKE = 0,
            RUPTURE = 0,
            EVISCERATE = 0,
            KILLING_SPREE = 30,
            ADRENALINE_RUSH = 30,
            SHADOW_BLADES = 30,
            BLADE_FLURRY = 0,
            FAN_OF_KNIVES = 0,
            CRIMSON_TEMPEST = 0,
            MARKED_FOR_DEATH = 30,
            VANISH = 30,
            DEADLY_POISON = 0,
            WOUND_POISON = 0,
            CRIPPLING_POISON = 0,
            MIND_NUMBING_POISON = 0,
            LEECHING_POISON = 0,
            PARALYTIC_POISON = 0,
            SHURIKEN_TOSS = 0,
            DEADLY_THROW = 0,
            KIDNEY_SHOT = 0,
        },
    }
end

local function Scenario(name, expected, changes, settings, expectedPool,
    expectedReasonContains)
    return {
        name = name,
        expected = expected,
        changes = changes or {},
        settings = settings or { mode = "single", cooldowns = "off" },
        expectedPool = expectedPool,
        expectedReasonContains = expectedReasonContains,
    }
end

local scenarios = {
    Scenario("no hostile target", nil, { targetAttackable = false }),
    Scenario("warn for missing Deadly Poison without a target", "DEADLY_POISON",
        { targetAttackable = false, deadlyPoisonRemaining = 0, poisonsReady = false }),
    Scenario("warn for selected Leeching Poison", "LEECHING_POISON",
        { targetAttackable = false, utilityPoisonRemaining = 0,
            utilityPoisonKey = nil, poisonsReady = false }),
    Scenario("replace a generic utility poison with selected Leeching Poison",
        "LEECHING_POISON", { targetAttackable = false,
            utilityPoisonKey = "CRIPPLING_POISON", poisonsReady = false }),
    Scenario("do not refresh an active poison during combat", "REVEALING_STRIKE",
        { inCombat = true, deadlyPoisonRemaining = 30, poisonsReady = false }),
    Scenario("enable Blade Flurry in cleave", "BLADE_FLURRY",
        { enemyCount = 3 }, { mode = "cleave", cooldowns = "off" }),
    Scenario("disable Blade Flurry on one target", "BLADE_FLURRY",
        { bladeFlurry = true }, { mode = "single", cooldowns = "off" }),
    Scenario("auto mode enters cleave", "BLADE_FLURRY",
        { enemyCount = 2 }, { mode = "auto", cooldowns = "off" }),
    Scenario("auto mode exits cleave", "BLADE_FLURRY",
        { enemyCount = 1, bladeFlurry = true }, { mode = "auto", cooldowns = "off" }),
    Scenario("forced AoE never enables Blade Flurry on one target", "FAN_OF_KNIVES",
        { enemyCount = 1 }, { mode = "aoe", cooldowns = "off" }, nil,
        "forced AoE mode"),
    Scenario("forced AoE disables Blade Flurry when the pull shrinks", "BLADE_FLURRY",
        { enemyCount = 1, bladeFlurry = true }, { mode = "aoe", cooldowns = "off" }),
    Scenario("Stealth opener", "AMBUSH", { stealthed = true }),
    Scenario("Subterfuge stealth window", "AMBUSH", { stealthWindow = true }),
    Scenario("Marked for Death at zero points", "MARKED_FOR_DEATH",
        { comboPoints = 0, cooldowns = { MARKED_FOR_DEATH = 0 } }),
    Scenario("skip Marked for Death on dying target", "REVEALING_STRIKE",
        { comboPoints = 0, targetTTD = 2, cooldowns = { MARKED_FOR_DEATH = 0 } }),
    Scenario("start Slice and Dice", "SLICE_AND_DICE",
        { comboPoints = 2, sndRemaining = 0 }),
    Scenario("emergency Slice and Dice refresh", "SLICE_AND_DICE",
        { comboPoints = 2, sndRemaining = 1 }),
    Scenario("five-point Slice and Dice refresh", "SLICE_AND_DICE",
        { comboPoints = 5, sndRemaining = 2.5 }),
    Scenario("maintain Revealing Strike", "REVEALING_STRIKE",
        { rvsRemaining = 2 }),
    Scenario("Killing Spree at safe Energy", "KILLING_SPREE",
        { energy = 40, cooldowns = { KILLING_SPREE = 0 } },
        { mode = "single", cooldowns = "on" }),
    Scenario("Killing Spree during Deep Insight", "KILLING_SPREE",
        { energy = 40, insight = 3, cooldowns = { KILLING_SPREE = 0 } },
        { mode = "single", cooldowns = "on" }),
    Scenario("do not overlap Killing Spree and Adrenaline Rush", "REVEALING_STRIKE",
        { energy = 40, adrenalineRush = true, cooldowns = { KILLING_SPREE = 0 } },
        { mode = "single", cooldowns = "on" }),
    Scenario("Adrenaline Rush window", "ADRENALINE_RUSH",
        { energy = 40, cooldowns = { ADRENALINE_RUSH = 0, SHADOW_BLADES = 0 } },
        { mode = "single", cooldowns = "on" }),
    Scenario("pair Shadow Blades after Adrenaline Rush", "SHADOW_BLADES",
        { energy = 40, adrenalineRush = true,
            cooldowns = { ADRENALINE_RUSH = 30, SHADOW_BLADES = 0 } },
        { mode = "single", cooldowns = "on" }),
    Scenario("hold Shadow Blades for nearly-ready Adrenaline Rush", "REVEALING_STRIKE",
        { cooldowns = { ADRENALINE_RUSH = 5, SHADOW_BLADES = 0 } },
        { mode = "single", cooldowns = "on" }),
    Scenario("use substantially desynchronized Shadow Blades", "SHADOW_BLADES",
        { cooldowns = { ADRENALINE_RUSH = 20, SHADOW_BLADES = 0 } },
        { mode = "single", cooldowns = "on" }),
    Scenario("optional offensive Vanish during Deep Insight", "VANISH",
        { energy = 40, comboPoints = 2, insight = 3, cooldowns = { VANISH = 0 } },
        { mode = "single", cooldowns = "off", offensiveVanish = true }),
    Scenario("offensive Vanish remains opt-in", "REVEALING_STRIKE",
        { energy = 40, comboPoints = 2, insight = 3, cooldowns = { VANISH = 0 } },
        { mode = "single", cooldowns = "off", offensiveVanish = false }),
    Scenario("boss-only cooldowns on a boss", "KILLING_SPREE",
        { targetIsBoss = true, energy = 40, cooldowns = { KILLING_SPREE = 0 } },
        { mode = "single", cooldowns = "boss" }),
    Scenario("boss-only cooldowns held on trash", "REVEALING_STRIKE",
        { targetIsBoss = false, energy = 40, cooldowns = { KILLING_SPREE = 0 } },
        { mode = "single", cooldowns = "boss" }),
    Scenario("cooldowns disabled", "REVEALING_STRIKE",
        { targetIsBoss = true, energy = 40, cooldowns = { KILLING_SPREE = 0 } },
        { mode = "single", cooldowns = "off" }),
    Scenario("spend Energy before Killing Spree", "REVEALING_STRIKE",
        { energy = 90, cooldowns = { KILLING_SPREE = 0 } },
        { mode = "single", cooldowns = "on" }),
    Scenario("spend capped points before high-Energy Killing Spree", "EVISCERATE",
        { energy = 90, comboPoints = 5, cooldowns = { KILLING_SPREE = 0 } },
        { mode = "single", cooldowns = "on" }),
    Scenario("maintain 5-point Rupture", "RUPTURE",
        { comboPoints = 5, ruptureRemaining = 0, targetTTD = 60 }),
    Scenario("skip Rupture on a short-lived target", "EVISCERATE",
        { comboPoints = 5, ruptureRemaining = 0, targetTTD = 8 }),
    Scenario("Eviscerate at five points", "EVISCERATE",
        { comboPoints = 5 }),
    Scenario("optional Prey on the Weak prompt", "KIDNEY_SHOT",
        { comboPoints = 5, targetIsBoss = false, targetTTD = 30 },
        { mode = "single", cooldowns = "off", preyOnWeak = true }),
    Scenario("Prey on the Weak remains opt-in", "EVISCERATE",
        { comboPoints = 5, targetIsBoss = false, targetTTD = 30 },
        { mode = "single", cooldowns = "off", preyOnWeak = false }),
    Scenario("Rupture does not replace cleave finisher", "EVISCERATE",
        { comboPoints = 5, ruptureRemaining = 0, bladeFlurry = true, enemyCount = 4 },
        { mode = "cleave", cooldowns = "off" }),
    Scenario("Phase 5 default builder", "REVEALING_STRIKE",
        { comboPoints = 2 }),
    Scenario("Sinister Strike during AR plus Heroism", "SINISTER_STRIKE",
        { adrenalineRush = true, heroism = true }),
    Scenario("Revealing Strike during AR without Heroism", "REVEALING_STRIKE",
        { adrenalineRush = true, heroism = false }),
    Scenario("Shuriken Toss while outside melee range", "SHURIKEN_TOSS",
        { meleeRange = false, comboPoints = 2 }),
    Scenario("Deadly Throw spends capped points outside melee range", "DEADLY_THROW",
        { meleeRange = false, comboPoints = 5 }),
    Scenario("Shuriken Toss does not overcap at five points", "EVISCERATE",
        { meleeRange = false, comboPoints = 5,
            known = { DEADLY_THROW = false, SHURIKEN_TOSS = true } }),
    Scenario("level 86 safely ignores unavailable level 90 talents", "REVEALING_STRIKE",
        { playerLevel = 86, known = { SHURIKEN_TOSS = false,
            MARKED_FOR_DEATH = false }, talents = { ANTICIPATION = false } }),
    Scenario("level 90 Anticipation spends before charge overcap", "EVISCERATE",
        { playerLevel = 90, comboPoints = 5, anticipation = 5,
            talents = { ANTICIPATION = true } }),
    Scenario("forced AoE uses accurate Crimson Tempest wording", "CRIMSON_TEMPEST",
        { enemyCount = 4, bladeFlurry = true, comboPoints = 5, targetTTD = 30 },
        { mode = "aoe", cooldowns = "off" }, nil, "forced AoE mode"),
    Scenario("enable Blade Flurry before 8-target AoE", "BLADE_FLURRY",
        { enemyCount = 8 }, { mode = "auto", cooldowns = "off" }),
    Scenario("Crimson Tempest for long-lived 8-target AoE", "CRIMSON_TEMPEST",
        { enemyCount = 8, bladeFlurry = true, comboPoints = 5, targetTTD = 30 },
        { mode = "auto", cooldowns = "off" }),
    Scenario("Eviscerate for short-lived 8-target AoE", "EVISCERATE",
        { enemyCount = 8, bladeFlurry = true, comboPoints = 5, targetTTD = 6 },
        { mode = "auto", cooldowns = "off" }),
    Scenario("Fan of Knives builder for 8-target AoE", "FAN_OF_KNIVES",
        { enemyCount = 8, bladeFlurry = true, comboPoints = 2 },
        { mode = "auto", cooldowns = "off" }),
    Scenario("recommend pooling for an unaffordable builder", "REVEALING_STRIKE",
        { energy = 10 }, { mode = "single", cooldowns = "off" }, true),
    Scenario("fallback when Revealing Strike is not learned", "SINISTER_STRIKE",
        { known = { REVEALING_STRIKE = false } }),
    Scenario("unknown Blade Flurry does not block cleave", "REVEALING_STRIKE",
        { enemyCount = 3, known = { BLADE_FLURRY = false } },
        { mode = "cleave", cooldowns = "off" }),
    Scenario("unknown Ambush falls through safely", "REVEALING_STRIKE",
        { stealthed = true, known = { AMBUSH = false } }),
}

local function ApplyChanges(state, changes)
    for key, value in pairs(changes or {}) do
        if type(value) == "table" and type(state[key]) == "table" then
            for nestedKey, nestedValue in pairs(value) do
                state[key][nestedKey] = nestedValue
            end
        else
            state[key] = value
        end
    end
end

function ns.Simulator_RunSelfCheck()
    local passed = 0
    local failures = {}

    for _, scenario in ipairs(scenarios) do
        local state = BaseState()
        ApplyChanges(state, scenario.changes)
        local decision = ns.Rotation_Evaluate(state, CopyTable(scenario.settings))
        local actual = decision and decision.ability or nil
        local poolMatches = scenario.expectedPool == nil
            or (decision and decision.pool == scenario.expectedPool)
        local reasonMatches = scenario.expectedReasonContains == nil
            or (decision and decision.reason
                and string.find(decision.reason, scenario.expectedReasonContains, 1, true) ~= nil)

        if actual == scenario.expected and poolMatches and reasonMatches then
            passed = passed + 1
        else
            local message = scenario.name .. ": expected "
                .. tostring(scenario.expected) .. ", got " .. tostring(actual)
            if scenario.expectedPool ~= nil then
                message = message .. ", pool=" .. tostring(decision and decision.pool)
            end
            if scenario.expectedReasonContains ~= nil then
                message = message .. ", reason=" .. tostring(decision and decision.reason)
            end
            failures[#failures + 1] = message
        end
    end
    return passed, #scenarios, failures
end

function ns.Simulator_PrintSelfCheck()
    local passed, total, failures = ns.Simulator_RunSelfCheck()
    if passed == total then
        ns.Print("rotation self-check passed " .. passed .. "/" .. total)
    else
        ns.Print("rotation self-check failed " .. passed .. "/" .. total)
        for _, failure in ipairs(failures) do print("  " .. failure) end
    end
end

function ns.Simulator_GetPreview()
    local state = BaseState()
    state.targetIsBoss = true
    state.energy = 46
    state.comboPoints = 5
    state.enemyCount = 1
    state.insight = 3
    state.insightName = "Deep"
    state.insightRemaining = 11.4
    state.insightProgress = 0
    state.sndRemaining = 18.2
    state.rvsRemaining = 14.8
    state.ruptureRemaining = 0
    state.cooldowns.KILLING_SPREE = 27.3
    state.cooldowns.ADRENALINE_RUSH = 8.1
    state.cooldowns.SHADOW_BLADES = 8.1
    local settings = { mode = "single", cooldowns = "boss" }
    return state, ns.Rotation_Evaluate(state, settings)
end
