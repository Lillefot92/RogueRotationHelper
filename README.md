# Rogue Rotation Helper

Rogue Rotation Helper is a transparent, recommendation-only PvE addon for
Rogues in **World of Warcraft: Mists of Pandaria Classic**. This beta targets
the official **5.5.4 client (Interface 50504)** and currently supports the
**Combat** specialization.

The addon shows what to press next. It never casts a spell, presses a key,
targets a unit, sends chat, or automates gameplay.

## Download the public beta

Download `RogueRotationHelper-0.1.0-beta.1.zip` from the official
[GitHub Releases page](https://github.com/Lillefot92/RogueRotationHelper/releases).
The release ZIP contains only readable Lua source and documentation. Do not
install similarly named executables or third-party installers.

Combat has passed level-90 single-target dummy and live dungeon testing. The
remaining beta item is boss-specific cooldown validation on a live raid boss;
it is not required for general dungeon and dummy feedback.

Found a problem? Use the public
[issue tracker](https://github.com/Lillefot92/RogueRotationHelper/issues) so the
report and its eventual fix remain visible to everyone.

## What the Combat beta includes

- A clean, large next-action icon; mouse over it for the recommendation reason
  and detailed state.
- Energy pooling and out-of-range warnings.
- Energy, Combo Points, Slice and Dice, Revealing Strike, Rupture, target mode,
  target count, and poison status in the mouseover tooltip.
- Larger, vertically stacked Killing Spree, Adrenaline Rush, and Shadow Blades
  cooldown icons that hide abilities until they are learned.
- A native in-game settings panel under **Options > AddOns**, also opened by
  entering `/rrh`.
- Single-target, cleave, and 8+ target AoE priorities.
- Automatic target mode using melee-range nameplates and recent confirmed
  melee/AoE hits, including neutral training dummies.
- Manual target-mode overrides for encounters where automatic counting cannot
  see enemies early enough.
- Blade Flurry on **and** off recommendations.
- Optional action-bar glow for the recommended spell.
- Boss-only, always-on, and disabled offensive-cooldown policies.
- Optional, disabled-by-default offensive Vanish advice during Deep Insight.
- A deterministic in-game rotation self-check.
- Level-aware talent detection, including safe use below level 90.
- A high-priority warning when Deadly Poison or the selected non-lethal poison
  is missing or close to expiring.
- DPS-relevant talent support: all three level-90 choices, stealth-row damage
  choices, Deadly Throw while disconnected, talented poisons, and optional
  Prey on the Weak advice for stunnable enemies.

## Level-aware and level-90 talent support

The helper does not assume that the Rogue is level 90. Unlearned abilities are
removed from the priority automatically. At level 86 it runs the complete
available Combat rotation without asking for a level-90 talent.

- Nightstalker and Shadow Focus use the normal Ambush opener and the live
  in-game Energy cost. Subterfuge's extended Stealth window is recognized.
- Deadly Throw can preserve damage when a talented Rogue is forced out of
  melee range.
- Leeching Poison and Paralytic Poison are recognized as selected non-lethal
  poison talents and are included in preparation warnings.
- Prey on the Weak advice is available with `/rrh prey on`. It is off by
  default because bosses are immune and the addon cannot guarantee that a
  particular raid add is stunnable.
- Shuriken Toss is used as a ranged builder, Marked for Death is used at zero
  Combo Points, and Anticipation charges are tracked when those level-90
  talents are learned.
- At level 90, the panel reports the selected final-row talent. Shadow Blades
  is learned and automatically joins the side cooldown column.

## Current Phase 5 rotation model

The priority is specifically built for the current 5.5.4 rules, rather than an
older launch-version MoP rotation.

1. Before combat, apply Deadly Poison and a non-lethal poison. A selected
   Leeching or Paralytic Poison talent becomes the preferred non-lethal poison.
2. Toggle Blade Flurry appropriately for the selected target mode.
3. Open with Ambush from Stealth.
4. Use Marked for Death at zero Combo Points when talented.
5. Keep Slice and Dice active.
6. Keep Revealing Strike's target debuff active.
7. Use Killing Spree at safe Energy without overlapping Adrenaline Rush or
   Shadow Blades. Positioning still requires player judgment.
8. Pair Adrenaline Rush and Shadow Blades where possible.
9. On one target, maintain a 5-point Rupture when the target should live long
   enough, then spend excess points on Eviscerate.
10. In cleave, keep Blade Flurry active and use Eviscerate instead of Rupture.
11. At 8+ targets, use Fan of Knives and a 5-point Crimson Tempest when enemies
    should live for its duration.
12. Revealing Strike is the normal Phase 5 builder. Sinister Strike becomes the
    preferred builder while both Adrenaline Rush and a Heroism/Bloodlust-family
    effect are active.

The model is cross-checked against the current Wowhead Phase 5 guide and the
open-source WoWSims MoP Combat Rogue implementation/APL:

- https://www.wowhead.com/mop-classic/guide/classes/rogue/combat/dps-rotation-cooldowns-abilities-pve
- https://github.com/wowsims/mop/tree/master/sim/rogue/combat
- https://github.com/wowsims/mop/blob/master/ui/rogue/combat/apls/combat.apl.json

## Installation

1. Exit World of Warcraft.
2. Download the versioned ZIP from the official GitHub Releases page. Avoid
   GitHub's automatically generated `Source code` archives because their
   versioned folder name is not the intended addon folder name.
3. Extract the archive into:
   `World of Warcraft/_classic_/Interface/AddOns`
4. Confirm the final path is:
   `Interface/AddOns/RogueRotationHelper/RogueRotationHelper.toc`
5. Start MoP Classic and enable **Rogue Rotation Helper** on the AddOns screen.
6. On a Combat Rogue, enter `/rrh test` to preview the display.
7. Enter `/rrh sim`; all rotation checks should pass.

## Commands

- `/rrh` or `/rrh options` - open the in-game settings panel.
- `/rrh help` - list controls.
- `/rrh mode auto|single|cleave|aoe` - choose target behavior.
- `/rrh cooldowns boss|on|off` - choose offensive-cooldown behavior.
- `/rrh glow on|off` - toggle action-bar glow.
- `/rrh vanish on|off` - toggle optional offensive Vanish advice.
- `/rrh prey on|off` - toggle conditional Prey on the Weak/Kidney Shot advice.
- `/rrh unlock` and `/rrh lock` - move or lock the display.
- `/rrh scale 1.2` - scale the display from 0.5 to 2.0.
- `/rrh test` - toggle a display preview.
- `/rrh sim` - run deterministic rotation checks.
- `/rrh status` - print the active version and important settings.
- `/rrh talents` - print the talents detected for the current Rogue.
- `/rrh reset` - reset display position and scale.
- `/rrh on` and `/rrh off` - enable or disable recommendations.

Right-clicking the display cycles the target mode.

## In-game settings

Open **Escape > Options > AddOns > Rogue Rotation Helper**, or simply enter
`/rrh`. The panel changes settings immediately and includes:

- Automatic, single-target, cleave, and AoE modes.
- Boss-only, always, or disabled offensive cooldown usage.
- Addon enablement, action-bar glow, and side cooldown-icon toggles.
- Display locking, scaling, preview, and position reset.
- Optional offensive Vanish and Prey on the Weak advice.
- Level/spec, level-90 talent, detected talents, nearby-target count, and active
  rotation-mode status.
- A button that runs the same deterministic rotation check as `/rrh sim`.

## Trust and privacy

Every functional file is readable Lua source. There are no executables,
installers, DLLs, hidden downloads, advertisements, telemetry, or networking.
Only display preferences are saved. The public commit history makes every
change reviewable. See `SECURITY.md`, `CHECKSUMS.sha256`, and `LICENSE` for the
complete verification and reuse terms.

## Beta status and limitations

- Combat has passed level-90 single-target dummy and live dungeon validation,
  including an automatic transition from 18-target AoE to 5-target cleave.
- Boss-specific cooldown timing still needs a live raid-boss validation pass
  before the first stable release.
- Automatic enemy counting cannot see every unengaged or hidden enemy. Use a
  manual mode when planning a cleave or AoE pull.
- Killing Spree can move the Rogue into dangerous mechanics. The addon can
  recommend a damage timing, but only the player can confirm the cast is safe.
- Bandit's Guile progress between Insight stages is inferred from successful
  builder hits and can briefly desynchronize after reloads or unusual events.
- Encounter-specific cooldown holds and defensive/utility prompts are not yet
  included.
- Assassination and Subtlety modules come after Combat is validated.

See `TESTING.md` for the remaining Combat validation checks.
