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
        specID = ns.COMBAT_SPEC_ID,
        isRogue = true,
        isAssassinationSpec = false,
        isCombatSpec = true,
        isSubtletySpec = false,
        isSupportedSpec = true,
        targetAttackable = true,
        playerLevel = 90,
        targetIsBoss = false,
        targetTTD = 120,
        targetHPPercent = 100,
        energy = 70,
        maxEnergy = 100,
        comboPoints = 2,
        anticipation = 0,
        talents = { PREY_ON_THE_WEAK = true, ANTICIPATION = true },
        enemyCount = 1,
        stealthed = false,
        stealthWindow = false,
        heroism = false,
        meleeRange = true,
        shurikenRange = true,
        insight = 1,
        sndRemaining = 20,
        rvsRemaining = 20,
        ruptureRemaining = 20,
        hemorrhageRemaining = 20,
        crimsonTempestRemaining = 20,
        findWeaknessRemaining = 0,
        shadowDanceRemaining = 0,
        envenomRemaining = 0,
        vendettaRemaining = 0,
        blindside = false,
        deadlyPoisonRemaining = 3500,
        utilityPoisonRemaining = 3500,
        utilityPoisonKey = "LEECHING_POISON",
        poisonsReady = true,
        kidneyShotRemaining = 0,
        bladeFlurry = false,
        adrenalineRush = false,
        shadowBlades = false,
        killingSpree = false,
        shadowDance = false,
        backstabUsable = true,
        known = known,
        cooldowns = {
            AMBUSH = 0,
            BACKSTAB = 0,
            HEMORRHAGE = 0,
            PREMEDITATION = 30,
            SHADOW_DANCE = 30,
            MUTILATE = 0,
            DISPATCH = 0,
            ENVENOM = 0,
            VENDETTA = 30,
            PREPARATION = 30,
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

local function AssassinationScenario(name, expected, changes, settings,
    expectedPool, expectedReasonContains)
    changes = changes or {}
    changes.specID = ns.ASSASSINATION_SPEC_ID
    changes.isAssassinationSpec = true
    changes.isCombatSpec = false
    changes.isSubtletySpec = false
    changes.isSupportedSpec = true
    return Scenario(name, expected, changes, settings, expectedPool,
        expectedReasonContains)
end

local function SubtletyScenario(name, expected, changes, settings,
    expectedPool, expectedReasonContains)
    changes = changes or {}
    changes.specID = ns.SUBTLETY_SPEC_ID
    changes.isAssassinationSpec = false
    changes.isCombatSpec = false
    changes.isSubtletySpec = true
    changes.isSupportedSpec = true
    return Scenario(name, expected, changes, settings, expectedPool,
        expectedReasonContains)
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

    AssassinationScenario("Assassination opens with Mutilate", "MUTILATE",
        { stealthed = true, stealthWindow = true }),
    AssassinationScenario("Assassination establishes Slice and Dice",
        "SLICE_AND_DICE", { comboPoints = 2, sndRemaining = 0 }),
    AssassinationScenario("Assassination builds before initial Slice and Dice",
        "MUTILATE", { comboPoints = 0, sndRemaining = 0 }),
    AssassinationScenario("Assassination establishes Rupture at two points",
        "RUPTURE", { comboPoints = 2, ruptureRemaining = 0 }),
    AssassinationScenario("Assassination refreshes Rupture at four points",
        "RUPTURE", { comboPoints = 4, ruptureRemaining = 1 }),
    AssassinationScenario("Assassination uses Marked for Death after setup",
        "MARKED_FOR_DEATH", { comboPoints = 0,
            cooldowns = { MARKED_FOR_DEATH = 0 } }),
    AssassinationScenario("Assassination starts Vendetta after setup", "VENDETTA",
        { cooldowns = { VENDETTA = 0 } },
        { mode = "single", cooldowns = "on" }),
    AssassinationScenario("Assassination establishes Rupture before Vendetta",
        "RUPTURE", { comboPoints = 5, ruptureRemaining = 0,
            cooldowns = { VENDETTA = 0 } },
        { mode = "single", cooldowns = "on" }),
    AssassinationScenario("Assassination pairs Shadow Blades with Vendetta",
        "SHADOW_BLADES", { vendettaRemaining = 12,
            cooldowns = { VENDETTA = 30, SHADOW_BLADES = 0 } },
        { mode = "single", cooldowns = "on" }),
    AssassinationScenario("Assassination holds Shadow Blades for Vendetta",
        "MUTILATE", { cooldowns = { VENDETTA = 5, SHADOW_BLADES = 0 } },
        { mode = "single", cooldowns = "on" }),
    AssassinationScenario("Assassination uses desynchronized Shadow Blades",
        "SHADOW_BLADES", { cooldowns = { VENDETTA = 20, SHADOW_BLADES = 0 } },
        { mode = "single", cooldowns = "on" }),
    AssassinationScenario("Assassination offensive Vanish is opt-in", "VANISH",
        { cooldowns = { VANISH = 0 } },
        { mode = "single", cooldowns = "off", offensiveVanish = true }),
    AssassinationScenario("Assassination offensive Vanish remains disabled",
        "MUTILATE", { cooldowns = { VANISH = 0 } },
        { mode = "single", cooldowns = "off", offensiveVanish = false }),
    AssassinationScenario("Assassination Preparation resets a used Vanish",
        "PREPARATION", { cooldowns = { VANISH = 60, PREPARATION = 0 } },
        { mode = "single", cooldowns = "off", offensiveVanish = true }),
    AssassinationScenario("Blindside uses Dispatch above execute range", "DISPATCH",
        { blindside = true, targetHPPercent = 80 }),
    AssassinationScenario("Dispatch replaces Mutilate below 35 percent", "DISPATCH",
        { blindside = false, targetHPPercent = 30 }),
    AssassinationScenario("Mutilate remains the normal builder", "MUTILATE",
        { blindside = false, targetHPPercent = 80 }),
    AssassinationScenario("Assassination pools before a five-point Envenom",
        "ENVENOM", { comboPoints = 5, energy = 70 },
        { mode = "single", cooldowns = "off" }, true),
    AssassinationScenario("Assassination casts Envenom after pooling", "ENVENOM",
        { comboPoints = 5, energy = 90 },
        { mode = "single", cooldowns = "off" }, false),
    AssassinationScenario("Envenom rescues expiring Slice and Dice", "ENVENOM",
        { comboPoints = 2, sndRemaining = 1, energy = 40 },
        { mode = "single", cooldowns = "off" }, false,
        "Cut to the Chase"),
    AssassinationScenario("two-target cleave spreads Rupture", "RUPTURE",
        { enemyCount = 2, comboPoints = 2, ruptureRemaining = 0 },
        { mode = "auto", cooldowns = "off" }),
    AssassinationScenario("two-target cleave resumes the normal builder",
        "MUTILATE", { enemyCount = 2, comboPoints = 2, ruptureRemaining = 20 },
        { mode = "auto", cooldowns = "off" }),
    AssassinationScenario("four-target AoE applies a three-point Rupture",
        "RUPTURE", { enemyCount = 4, comboPoints = 3, ruptureRemaining = 0 },
        { mode = "auto", cooldowns = "off" }),
    AssassinationScenario("four-target AoE builds with Fan of Knives",
        "FAN_OF_KNIVES", { enemyCount = 4, comboPoints = 2 },
        { mode = "auto", cooldowns = "off" }),
    AssassinationScenario("four-target AoE spends capped points with Envenom",
        "ENVENOM", { enemyCount = 4, comboPoints = 5, energy = 90 },
        { mode = "auto", cooldowns = "off" }),
    AssassinationScenario("nine-target AoE skips Rupture for Envenom", "ENVENOM",
        { enemyCount = 9, comboPoints = 5, energy = 90, ruptureRemaining = 0 },
        { mode = "auto", cooldowns = "off" }),
    AssassinationScenario("nine-target AoE builds with Fan of Knives",
        "FAN_OF_KNIVES", { enemyCount = 9, comboPoints = 2,
            ruptureRemaining = 0 }, { mode = "auto", cooldowns = "off" }),
    AssassinationScenario("forced Assassination AoE uses accurate wording",
        "FAN_OF_KNIVES", { enemyCount = 1, comboPoints = 2 },
        { mode = "aoe", cooldowns = "off" }, nil, "forced AoE mode"),
    AssassinationScenario("Assassination uses Shuriken Toss while disconnected",
        "SHURIKEN_TOSS", { meleeRange = false, comboPoints = 2 }),
    AssassinationScenario("Assassination uses Deadly Throw at capped points",
        "DEADLY_THROW", { meleeRange = false, comboPoints = 5 }),
    SubtletyScenario("Subtlety default builder", "BACKSTAB"),
    SubtletyScenario("Subtlety uses Hemorrhage from the front", "HEMORRHAGE",
        { backstabUsable = false }),
    SubtletyScenario("Subtlety opens with Premeditation", "PREMEDITATION",
        { comboPoints = 0, stealthed = true, stealthWindow = true,
            cooldowns = { PREMEDITATION = 0 } }),
    SubtletyScenario("Subtlety starts Slice and Dice after Premeditation",
        "SLICE_AND_DICE", { comboPoints = 2, stealthed = true,
            stealthWindow = true, sndRemaining = 0 }),
    SubtletyScenario("Subtlety stealth opener uses Ambush", "AMBUSH",
        { comboPoints = 0, stealthed = true, stealthWindow = true }),
    SubtletyScenario("Subtlety maintains Hemorrhage", "HEMORRHAGE",
        { hemorrhageRemaining = 2 }),
    SubtletyScenario("Subtlety maintains five-point Rupture", "RUPTURE",
        { comboPoints = 5, ruptureRemaining = 1 }),
    SubtletyScenario("Subtlety refreshes Slice and Dice first", "SLICE_AND_DICE",
        { comboPoints = 5, sndRemaining = 1, ruptureRemaining = 1 }),
    SubtletyScenario("Subtlety spends maintained five points", "EVISCERATE",
        { comboPoints = 5 }),
    SubtletyScenario("Subtlety pools to 80 before Shadow Dance", "SHADOW_DANCE",
        { energy = 70, cooldowns = { SHADOW_DANCE = 0 } },
        { mode = "single", cooldowns = "on" }, true),
    SubtletyScenario("Subtlety starts Shadow Dance at 80 Energy", "SHADOW_DANCE",
        { energy = 85, cooldowns = { SHADOW_DANCE = 0 } },
        { mode = "single", cooldowns = "on" }, false),
    SubtletyScenario("Subtlety pairs Shadow Blades inside Dance", "SHADOW_BLADES",
        { energy = 85, shadowDance = true, shadowDanceRemaining = 7,
            cooldowns = { SHADOW_DANCE = 30, SHADOW_BLADES = 0 } },
        { mode = "single", cooldowns = "on" }),
    SubtletyScenario("Subtlety uses Ambush throughout Dance", "AMBUSH",
        { shadowDance = true, shadowDanceRemaining = 7,
            cooldowns = { SHADOW_DANCE = 30 } },
        { mode = "single", cooldowns = "off" }),
    SubtletyScenario("Subtlety spends five points during Dance", "EVISCERATE",
        { comboPoints = 5, shadowDance = true, shadowDanceRemaining = 7,
            cooldowns = { SHADOW_DANCE = 30 } },
        { mode = "single", cooldowns = "off" }),
    SubtletyScenario("Subtlety avoids Ambush overcap without Anticipation",
        "EVISCERATE", { comboPoints = 4, shadowDance = true,
            shadowDanceRemaining = 7, talents = { ANTICIPATION = false },
            cooldowns = { SHADOW_DANCE = 30 } },
        { mode = "single", cooldowns = "off" }),
    SubtletyScenario("Subtlety avoids Shadow Blades overcap without Anticipation",
        "EVISCERATE", { comboPoints = 3, shadowDance = true,
            shadowDanceRemaining = 7, shadowBlades = true,
            talents = { ANTICIPATION = false },
            cooldowns = { SHADOW_DANCE = 30, SHADOW_BLADES = 30 } },
        { mode = "single", cooldowns = "off" }),
    SubtletyScenario("Subtlety pools to 80 before Vanish", "VANISH",
        { energy = 70, comboPoints = 2, findWeaknessRemaining = 1,
            cooldowns = { SHADOW_DANCE = 10, VANISH = 0 } },
        { mode = "single", cooldowns = "on" }, true),
    SubtletyScenario("Subtlety holds Vanish during Find Weakness", "BACKSTAB",
        { comboPoints = 2, findWeaknessRemaining = 6,
            cooldowns = { SHADOW_DANCE = 10, VANISH = 0 } },
        { mode = "single", cooldowns = "on" }),
    SubtletyScenario("Subtlety Ambushes before Preparation after Vanish",
        "AMBUSH", { comboPoints = 2, stealthWindow = true,
            cooldowns = { SHADOW_DANCE = 20, VANISH = 40, PREPARATION = 0 } },
        { mode = "single", cooldowns = "on" }),
    SubtletyScenario("Subtlety uses Preparation for another Vanish", "PREPARATION",
        { comboPoints = 2,
            cooldowns = { SHADOW_DANCE = 20, VANISH = 40, PREPARATION = 0 } },
        { mode = "single", cooldowns = "on" }),
    SubtletyScenario("Subtlety auto AoE starts at three targets", "FAN_OF_KNIVES",
        { enemyCount = 3 }, { mode = "auto", cooldowns = "off" }),
    SubtletyScenario("Subtlety keeps Ambush in Dance at three targets", "AMBUSH",
        { enemyCount = 3, shadowDance = true, shadowDanceRemaining = 7,
            cooldowns = { SHADOW_DANCE = 30 } },
        { mode = "auto", cooldowns = "off" }),
    SubtletyScenario("Subtlety uses Fan even in Dance at five targets",
        "FAN_OF_KNIVES", { enemyCount = 5, shadowDance = true,
            shadowDanceRemaining = 7, cooldowns = { SHADOW_DANCE = 30 } },
        { mode = "auto", cooldowns = "off" }),
    SubtletyScenario("Subtlety maintains Crimson Tempest in mass AoE",
        "CRIMSON_TEMPEST", { enemyCount = 5, comboPoints = 5,
            crimsonTempestRemaining = 1 }, { mode = "auto", cooldowns = "off" }),
    SubtletyScenario("Subtlety spends after Crimson Tempest is safe", "EVISCERATE",
        { enemyCount = 5, comboPoints = 5, crimsonTempestRemaining = 10 },
        { mode = "auto", cooldowns = "off" }),
    SubtletyScenario("Subtlety uses Shuriken Toss while disconnected",
        "SHURIKEN_TOSS", { meleeRange = false, comboPoints = 2 }),
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
    if ns.state and ns.state.specID == ns.ASSASSINATION_SPEC_ID then
        state.specID = ns.ASSASSINATION_SPEC_ID
        state.isAssassinationSpec = true
        state.isCombatSpec = false
        state.energy = 72
        state.comboPoints = 5
        state.sndRemaining = 18.2
        state.ruptureRemaining = 14.8
        state.envenomRemaining = 0.6
        state.vendettaRemaining = 0
        state.cooldowns.VENDETTA = 8.1
        state.cooldowns.SHADOW_BLADES = 8.1
        state.cooldowns.VANISH = 27.3
        local assassinationSettings = { mode = "single", cooldowns = "boss" }
        return state, ns.Rotation_Evaluate(state, assassinationSettings)
    end
    if ns.state and ns.state.specID == ns.SUBTLETY_SPEC_ID then
        state.specID = ns.SUBTLETY_SPEC_ID
        state.isAssassinationSpec = false
        state.isCombatSpec = false
        state.isSubtletySpec = true
        state.targetIsBoss = true
        state.energy = 70
        state.comboPoints = 2
        state.sndRemaining = 18.2
        state.ruptureRemaining = 14.8
        state.hemorrhageRemaining = 12.4
        state.findWeaknessRemaining = 0
        state.cooldowns.SHADOW_DANCE = 0
        state.cooldowns.SHADOW_BLADES = 8.1
        state.cooldowns.VANISH = 27.3
        local subtletySettings = { mode = "single", cooldowns = "boss" }
        return state, ns.Rotation_Evaluate(state, subtletySettings)
    end
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
