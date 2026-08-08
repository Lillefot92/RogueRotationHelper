# Changelog

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
