# Combat beta test pass

This build targets official MoP Classic 5.5.4 / Interface 50504.

## Before testing

1. Install the `RogueRotationHelper` folder in `_classic_/Interface/AddOns`.
2. Enable Lua errors with `/console scriptErrors 1`, then `/reload`.
3. Enter `/rrh sim` and confirm every check passes.
4. Enter `/rrh test` and verify the preview is readable at your UI scale.
5. Use `/rrh unlock`, drag the display, then `/rrh lock`.
6. Enter `/rrh` and confirm the native AddOns panel opens.
7. Confirm the panel identifies the Rogue as level 90 and reports the selected
   final-row talent.
8. Enter `/rrh talents` and confirm it matches the learned talents.

## Settings panel

1. Open **Escape > Options > AddOns > Rogue Rotation Helper** and confirm it is
   the same panel opened by `/rrh`.
2. Change target mode and cooldown usage; confirm the selected buttons update
   immediately.
3. Toggle side cooldown icons, action-bar glow, and display locking.
4. Move the scale slider and confirm the main icon changes size immediately.
5. Use **Preview display**, **Reset position**, and **Run rotation check**.
6. Reload the UI and confirm the chosen settings were saved.

## Poison preparation

1. Remove or let poisons expire. The helper should remain visible without a
   target and recommend Deadly Poison first.
2. After applying Deadly Poison, confirm it recommends Leeching Poison when
   that talent is selected.
3. Apply both poisons and confirm the preparation warning disappears.
4. Mouse over the main icon and confirm the poison warning is gone.

## Training-dummy checks

### Single target

1. Set `/rrh mode single` and `/rrh cooldowns off`.
2. Start from Stealth and confirm Ambush is recommended.
3. Confirm Slice and Dice is established and refreshed before expiry.
4. Confirm Revealing Strike is maintained.
5. Confirm a 5-point Rupture is used on a long-lived target, followed by
   5-point Eviscerates.
6. Confirm Revealing Strike is normally the 40-Energy Phase 5 builder, while
   its target effect stays active.

### Level and talent checks

1. At level 90 with Anticipation selected, confirm the settings panel reports
   Anticipation and the hover details show stored charges after Combo Points.
2. Confirm Shadow Blades appears as the third side cooldown icon.
3. If Deadly Throw is selected, move out of melee with Combo Points and confirm
   it can be recommended as a ranged finisher.
4. If testing Shuriken Toss later, confirm it is used as the ranged builder.
5. If testing Marked for Death later, confirm it is used at zero Combo Points.
6. Optional: with Prey on the Weak selected, enable it in the panel on a stunnable
   non-boss target. Never follow this prompt on an immune target.

### Cooldowns

1. Set `/rrh cooldowns on`.
2. Confirm Killing Spree waits for safe Energy and is not recommended during
   Adrenaline Rush or Shadow Blades.
3. Confirm Adrenaline Rush appears at safe Energy.
4. After Adrenaline Rush activates, confirm Shadow Blades follows.
5. Under both Adrenaline Rush and Heroism/Bloodlust, confirm Sinister Strike
   replaces Revealing Strike as the main builder.
6. Optional: set `/rrh vanish on`; during Deep Insight at low Energy and no
   more than 3 Combo Points, confirm Vanish is followed by Ambush advice.

### Cleave and AoE

1. Set `/rrh mode cleave`; confirm Blade Flurry is recommended on.
2. Return to `/rrh mode single`; confirm Blade Flurry is recommended off.
3. In forced cleave or AoE mode, let the pull shrink to one enemy; confirm
   Blade Flurry is recommended off and is never recommended on for `1T`.
4. In cleave mode, confirm Eviscerate replaces Rupture as the finisher.
5. Set `/rrh mode aoe`; confirm Fan of Knives builds points.
6. At 5 points, confirm Crimson Tempest is recommended on long-lived enemies.
7. While Fan of Knives hits the training-dummy group, mouse over the main icon
   and confirm every visibly damaged dummy is included in the target count for
   at least five seconds between confirmed hits.
8. In forced AoE below eight detected targets, confirm the hover reason says
   `forced AoE mode` rather than claiming that eight enemies were detected.

### Compact display

1. Confirm the main window contains only the large recommendation icon during
   normal play.
2. Confirm all three learned major cooldowns—including Shadow Blades—appear as
   larger icons stacked on its right at level 90.
3. Mouse over the main icon and confirm the reason, mode/target count, Energy,
   Combo Points, key timers, and poison state are available in the tooltip.
4. Confirm a gold border/icon means pool, red means range or poison attention,
   and teal means the recommendation is ready.
5. Hover the recommendation icon, then hover bag items, equipped gear, spells,
   and action buttons. Confirm their normal tooltips remain visible and are not
   replaced or hidden by the addon.

## Dungeon or raid checks

- Live dungeon validation passed for the automatic transition from 18-target
  AoE to 5-target cleave, with live tooltip state and no visible Lua errors.
- Level-90 single-target dummy validation passed for Energy pooling, Revealing
  Strike upkeep, finishers, and paired Adrenaline Rush/Shadow Blades timers.
- Use `/rrh mode auto` and note pulls where target counting is late or wrong.
- Use `/rrh cooldowns boss` and confirm cooldowns appear on actual bosses but
  remain held on ordinary trash.
- Raid-boss cooldown timing is the remaining required check before stable.
- Treat every Killing Spree recommendation as conditional on safe positioning.
- Watch for display flicker, stale auras after target swaps, wrong range state,
  or an action-bar glow that remains after combat.

## Useful feedback

Please include:

- addon version from `/rrh status`;
- exact client build shown on the login screen;
- single/cleave/AoE mode and cooldown policy;
- expected recommendation and actual recommendation;
- Energy, Combo Points, and visible buff/debuff timers;
- complete Lua error text, if any;
- a screenshot or short clip if the issue is visual or timing-sensitive.

Do not include account credentials or private chat.
