# Combat beta, Assassination alpha, and Subtlety alpha test pass

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
5. While pooling, confirm the required Energy number appears at the lower-right
   of the main icon and disappears immediately when the icon becomes ready.
6. Hover the recommendation icon, then hover bag items, equipped gear, spells,
   and action buttons. Confirm their normal tooltips remain visible and are not
   replaced or hidden by the addon.

## Assassination alpha checks

Live validation completed for level-90 single target, Blindside and execute
Dispatch, pooled Envenom, four-plus-target Fan of Knives/Rupture behavior,
automatic mode changes, tooltip safety, and switching back to Combat without a
UI reload. Nine-or-more targets and dungeon/raid behavior remain open checks.

### Specialization switching and display

1. Switch from Combat to Assassination without reloading the UI.
2. Confirm `/rrh status` reports `spec=Assassination` and the settings panel
   says **Assassination Rogue**.
3. Confirm the side icons change to Vendetta, Shadow Blades, and Vanish; Killing
   Spree and Adrenaline Rush must disappear.
4. Mouse over the main icon and confirm it shows Slice and Dice, Rupture,
   Envenom, Vendetta, and Blindside state instead of Combat's Revealing Strike
   and Insight details.
5. Enter `/rrh sim` and confirm all 110 rotation checks pass.

### Assassination single target and execute

1. Set `/rrh mode single` and `/rrh cooldowns off`.
2. Enter Stealth and confirm Mutilate—not Ambush—is recommended.
3. Confirm Slice and Dice is established manually, then refreshed by Envenom.
4. Confirm Rupture is established quickly and refreshed before it expires.
5. At 5 Combo Points with safe maintenance timers, confirm the Envenom icon
   turns gold and shows `80`, then removes the number and becomes teal at
   80 Energy.
6. Confirm a Blindside proc changes the builder to Dispatch above 35% health.
7. On a target below 35%, confirm Dispatch replaces Mutilate.
8. Set `/rrh cooldowns on`; confirm Vendetta waits for Slice and Dice and
   Rupture, then Shadow Blades follows during Vendetta.
9. Enable `/rrh vanish on`; confirm Vanish is followed by Mutilate and that
   Preparation can be suggested after Vanish is on cooldown. Turn the option
   back off after this check if you do not want situational Vanish advice.

### Assassination multi-target

1. At two to three targets, confirm the helper uses the normal builder and asks
   for Rupture on a current target that does not already have it.
2. At four to eight targets, confirm Fan of Knives builds Combo Points and a
   3+ point Rupture is recommended on an uncovered current target.
3. The addon cannot select the next unruptured target. Switch targets manually
   when spreading Rupture and report any misleading recommendation.
4. At nine or more targets, confirm Fan of Knives builds and Envenom spends;
   missing Rupture should no longer block this mass-AoE branch.
5. Let the pull shrink through nine, four, two, and one target and confirm the
   automatic mode and builder change without stale recommendations.

### Regression back to Combat

1. Switch back to Combat without reloading.
2. Confirm Killing Spree, Adrenaline Rush, and Shadow Blades return to the side
   column and `/rrh status` reports `spec=Combat`.
3. Repeat a short single-target sequence and confirm Revealing Strike remains
   the normal builder and no Assassination-only spell is recommended.

## Subtlety alpha checks

### Specialization switching and display

1. Switch to Subtlety without reloading the UI.
2. Confirm `/rrh status` and the settings panel identify **Subtlety Rogue**.
3. Confirm the side icons are Shadow Dance, Shadow Blades, and Vanish; Combat
   and Assassination-only cooldown icons must be gone.
4. Mouse over the main icon and confirm it shows Slice and Dice, Rupture,
   Hemorrhage, Find Weakness, and Shadow Dance timers.
5. Enter `/rrh sim` and confirm all 110 checks pass.

### Opener, maintenance, and positioning

1. Set `/rrh mode single` and `/rrh cooldowns off`, then enter Stealth at zero
   Combo Points. Confirm Premeditation is recommended first.
2. Use Premeditation and confirm Slice and Dice follows before Ambush.
3. Confirm Ambush opens the target, Hemorrhage is established, a five-point
   Rupture follows, and later five-point finishers use Eviscerate.
4. Stand behind the target and confirm Backstab is the normal maintained-state
   builder. Move in front and confirm the recommendation falls back to
   Hemorrhage instead of repeatedly asking for an unusable Backstab.
5. Let Slice and Dice, Rupture, and Hemorrhage approach expiry separately and
   confirm each is refreshed before a new burst window is suggested.

### Shadow Dance, Vanish, and Energy pooling

1. Set `/rrh cooldowns on` on a long-lived dummy.
2. With maintenance safely covered and Shadow Dance ready, confirm its icon is
   gold and shows `80` below 80 Energy, then becomes ready at 80 Energy.
3. During Shadow Dance, confirm Shadow Blades is paired, Eviscerate spends at
   five points, and Ambush is the builder between finishers.
4. After Find Weakness is nearly expired and Shadow Dance is at least five
   seconds away, confirm Vanish also pools to 80 before opening another Ambush
   window. Subtlety does this automatically regardless of `/rrh vanish`.
5. After Vanish is on a long cooldown, confirm Preparation can be recommended
   when maintenance is safe and Shadow Dance is not close.

### Subtlety AoE

1. In automatic mode, confirm two targets remain cleave and three targets
   switch to AoE.
2. At three to four targets outside Shadow Dance, confirm Fan of Knives is the
   builder. During Shadow Dance, confirm Ambush returns.
3. At five or more targets, confirm Fan of Knives remains the builder even
   during Shadow Dance.
4. At five Combo Points, confirm Crimson Tempest is maintained before excess
   points are spent on Eviscerate.
5. Let the pack shrink through five, three, two, and one target and confirm the
   mode and builder update without stale Subtlety recommendations.

## Combat dungeon or raid checks

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
- Assassination has passed its first live dummy and specialization-switching
  pass. Use external-alpha feedback to validate nine-or-more targets and live
  dungeon/raid behavior.

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
