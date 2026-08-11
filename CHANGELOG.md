# Changelog

## 0.3.0-beta.2

- Fixed a Lua error when Mists of Pandaria Classic fires
  `UNIT_SPELLCAST_SUCCEEDED` with only the player unit token and no spell ID.
- Incomplete spellcast events are now ignored safely while the modern and
  legacy spell-ID positions remain supported for confirmed area casts.
- Passed the full addon load test and all 112 deterministic rotation scenarios.

## 0.3.0-beta.1

- Published the first unified public beta containing Combat plus the
  Assassination and Subtlety external-alpha evaluators.
- Completed focused level-90 Subtlety live validation for the opener,
  maintenance cycle, 80-Energy Shadow Dance and Vanish pooling, paired Shadow
  Blades, Find Weakness windows, Preparation ordering, AoE recommendations,
  cooldown display, and specialization switching.
- Kept Combat priorities unchanged from the validated public beta and retained
  the Assassination behavior previously published as `0.2.0-alpha.2`.
- Documented remaining external checks: live raid-boss cooldown timing,
  Assassination mass-AoE/dungeon behavior, and Subtlety dungeon/raid packs.
- Passed all 112 deterministic rotation scenarios before packaging.

## 0.3.0-alpha.3

- Fixed live Find Weakness tracking from the second Subtlety video pass.
  `91023` is the passive spell, while Ambush and Garrote apply target debuff
  `91021`; using the passive ID caused Vanish to overlap an active Find
  Weakness window immediately after Shadow Dance.
- Moved Preparation behind the stealth Ambush priority. The first Vanish can
  now always apply Find Weakness before Preparation resets Vanish for a later
  window.
- Confirmed live 80-Energy Shadow Dance pooling, paired Shadow Blades,
  Premeditation/Ambush Dance actions, corrected 24-second Hemorrhage upkeep,
  and the normal cooldown-disabled maintenance cycle.
- Expanded the deterministic rotation suite from 110 to 112 scenarios.

## 0.3.0-alpha.2

- Fixed live Hemorrhage maintenance after the first Subtlety video pass. The
  ability is cast with spell ID `16511`, while its actual 24-second target DoT
  uses aura ID `89775`; tracking the cast ID caused Hemorrhage to be suggested
  repeatedly.
- This also unblocks Shadow Dance and Vanish setup, which correctly waited for
  safe maintenance but could never see Hemorrhage as active in Alpha 1.
- Confirmed clean Subtlety opener/display transitions and correct
  Shadow Dance, Shadow Blades, and Vanish side cooldown visibility with the
  major-cooldown policy both off and on.

## 0.3.0-alpha.1

- Added the first Subtlety evaluator with Premeditation/Slice and Dice setup,
  Ambush, Backstab, Hemorrhage, Rupture, Eviscerate, and ranged fallbacks.
- Added maintenance-aware 80-Energy pooling before Shadow Dance and offensive
  Vanish, Find Weakness tracking, paired Shadow Blades, and Preparation advice.
- Added Subtlety AoE behavior: Fan of Knives at three or more targets outside
  Dance, Ambush during Dance at three to four targets, Fan throughout at five
  or more, and five-point Crimson Tempest maintenance.
- Added automatic live switching to Subtlety, a Subtlety-specific tooltip,
  preview state, and Shadow Dance/Shadow Blades/Vanish side cooldown icons.
- Expanded deterministic coverage from 87 to 110 scenarios and replaced the
  unsupported-spec smoke test with full Combat/Assassination/Subtlety dispatch.
- This is a local test alpha; the published Assassination alpha remains
  unchanged until Subtlety passes its focused live checks.

## 0.2.0-alpha.2

- Added a small Energy target on the main icon while an ability is being
  pooled. For example, pooled Envenom now shows `80`; the number disappears
  immediately when the recommendation becomes ready.
- Kept the normal display icon-only outside pooling and retained the existing
  gold, teal, and red status colors.
- Completed the first level-90 Assassination live pass: single target,
  Blindside and execute Dispatch, pooled Envenom, four-plus-target Fan of
  Knives/Rupture behavior, automatic target-mode changes, and tooltip safety.
- Confirmed live Assassination-to-Combat switching without a UI reload. The
  recommendation and cooldown column change cleanly with no cross-spec icons.
- Nine-or-more-target and dungeon/raid behavior remain external-alpha checks.

## 0.2.0-alpha.1

- Added a spec-aware rotation dispatcher while preserving all 56 validated
  Combat decisions as regression checks.
- Added the first Assassination evaluator: Mutilate opener, Slice and Dice,
  Rupture, pooled Envenom, Blindside/execute Dispatch, Marked for Death,
  Vendetta, Shadow Blades, optional Vanish/Preparation, and ranged fallbacks.
- Added separate Assassination behavior for two-to-three, four-to-eight, and
  nine-or-more targets based on current Phase 5 guidance.
- Added automatic live switching between Combat and Assassination without a UI
  reload.
- Made the icon tooltip, settings status, preview, and side cooldown column
  specialization-aware.
- Expanded the deterministic rotation suite from 56 to 87 scenarios and added
  a mocked live Combat-to-Assassination switching test.
- Kept Subtlety safely disabled until its own evaluator is implemented.

## 0.1.0-beta.2

- Fixed normal item, equipment, spell, and action tooltips disappearing while
  Rogue Rotation Helper was enabled.
- The live recommendation tooltip now refreshes or hides only while the addon
  still owns WoW's shared `GameTooltip`; it can no longer reclaim or close a
  tooltip opened by another UI element.
- Added a regression test covering both tooltip takeover and addon hiding while
  an item tooltip is visible.

## 0.1.0-beta.1

- Promoted Combat to beta after level-90 single-target dummy and live dungeon
  validation.
- Confirmed that automatic target mode transitions live from 18-target AoE to
  5-target cleave while the recommendation tooltip remains open.
- Confirmed Phase 5 priorities against current 5.5.4 guidance: Revealing Strike
  as the normal builder, Sinister Strike during combined Adrenaline Rush and
  Heroism, and Fan of Knives/Crimson Tempest at eight or more targets.
- No rotation-logic changes from Alpha 9; boss-specific cooldown timing remains
  the final raid validation item before a stable release.

## 0.1.0-alpha.9

- Fixed the recommendation tooltip showing a frozen snapshot while the cursor
  remained over the icon. Target counts, resources, timers, and optional
  diagnostics now refresh live every 0.20 seconds.
- Alpha 8 diagnostics confirmed the tested pack contained three distinct nearby
  dummy GUIDs (`2` nameplates plus `1` remembered hit); Fan of Knives spell
  `51723` and outgoing-hit ownership were both detected correctly.

## 0.1.0-alpha.8

- Expanded outgoing-event ownership detection to accept either an exact player
  GUID or WoW's `AFFILIATION_MINE` combat-log flag. This addresses clients that
  report an alternate source GUID for Rogue AoE damage events.
- Added `/rrh debug on|off`. When enabled, the normal icon tooltip gains compact
  target-tracker diagnostics; it remains completely hidden by default.

## 0.1.0-alpha.7

- Added a short Fan of Knives/Crimson Tempest cast window so every confirmed
  target is counted even when MoP reports the damage under a separate internal
  spell ID from the ability shown in the spellbook.
- Kept the five-second enemy memory and confirmed-hit flag bypass from Alpha 6;
  the new fallback only applies immediately after the player casts a nearby AoE.

## 0.1.0-alpha.6

- Added a native in-game panel under **Options > AddOns > Rogue Rotation
  Helper**; `/rrh` and `/rrh options` open it directly.
- Added panel controls for target mode, cooldown policy, addon enablement,
  action-bar glow, side cooldown icons, display lock/scale, preview, position
  reset, rotation self-check, offensive Vanish, and Prey on the Weak.
- Added live panel status for level/spec, detected level-90 talent, all detected
  talents, current nearby-target count, and resolved rotation mode.
- Finished the level-90 display pass: Anticipation is reported in the panel and
  learned Shadow Blades appears automatically in the side cooldown column.
- Fixed confirmed Fan of Knives and other melee/AoE hits being discarded when
  training dummies report friendly or incomplete combat-log reaction flags.
- Forced AoE explanations now say `forced AoE mode` instead of incorrectly
  claiming that eight targets were detected.
- Expanded the deterministic rotation suite from 54 to 56 scenarios.

## 0.1.0-alpha.5

- Rebuilt the main window as a clean icon-first display with one large next
  action and larger, vertically stacked major-cooldown icons on its right.
- Moved recommendation reasons, target mode, target count, resources, aura
  timers, and poison state into the mouseover tooltip.
- Fixed neutral training dummies being excluded from recent-enemy memory.
- Nearby-enemy memory now uses confirmed melee, Fan of Knives, Crimson Tempest,
  and Blade Flurry hits instead of distant periodic-damage events.
- Increased the confirmed-target memory to five seconds to prevent target-count
  flicker between Energy-limited AoE abilities.

## 0.1.0-alpha.4

- Fixed Blade Flurry being recommended with only one real nearby enemy while
  using a forced cleave or AoE test mode.
- Blade Flurry now automatically recommends turning off whenever the pull
  shrinks to one target, regardless of the manually selected rotation branch.
- Manual mode headers now say `FORCED SINGLE`, `FORCED CLEAVE`, or `FORCED AOE`
  so test overrides cannot be confused with automatic target detection.
- Validated short-lived AoE behavior: the helper correctly prefers Eviscerate
  over Crimson Tempest when its bleed would not have time to pay off.

## 0.1.0-alpha.3

- Validated the Combat single-target and two-target cleave priorities against
  level-86 gameplay recordings.
- Fixed the cooldown row showing unlearned abilities as ready; Shadow Blades
  now stays hidden until it is learned at level 87.
- Kept the validated Revealing Strike, Slice and Dice, Rupture, Eviscerate,
  poison, and Blade Flurry priorities unchanged.

## 0.1.0-alpha.2

- Added full level-aware behavior so level-86 Rogues do not receive level-90
  talent recommendations.
- Added high-priority Deadly Poison and selected non-lethal poison preparation
  warnings, including Leeching Poison support.
- Added Shuriken Toss and Deadly Throw ranged fallbacks.
- Added correct Anticipation charge-aura tracking and Subterfuge window
  detection.
- Added optional, disabled-by-default Prey on the Weak advice for stunnable
  non-boss targets.
- Added `/rrh talents` plus level and poison details in `/rrh status`.
- Clarified why Revealing Strike is the normal Phase 5 builder.

## 0.1.0-alpha.1

- First Combat Rogue alpha for MoP Classic 5.5.4 / Interface 50504.
- Added single-target, cleave, and 8+ target AoE priorities.
- Added current Phase 5 Revealing Strike / Sinister Strike builder logic.
- Added Blade Flurry toggle advice and automatic/manual target modes.
- Added boss-only, always-on, and disabled cooldown policies.
- Added disabled-by-default offensive Vanish advice for Deep Insight.
- Added Energy pooling, range warnings, aura/Combo Point status, Bandit's Guile
  display, cooldown row, and Blizzard action-bar glow.
- Added deterministic rotation self-checks.
- Added security, installation, and in-game test documentation.
