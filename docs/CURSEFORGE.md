# CurseForge release copy

## Project name

Rogue Rotation Helper

## Summary

Transparent, recommendation-only PvE rotation advisor for Combat,
Assassination, and Subtlety Rogues in Mists of Pandaria Classic.

## Description

Rogue Rotation Helper is a compact PvE rotation advisor for Rogues in **World
of Warcraft: Mists of Pandaria Classic 5.5.4**.

It displays the next recommended ability as a large icon, with major offensive
cooldowns arranged beside it. Detailed resources, timers, target mode, target
count, and poison status are available by hovering over the recommendation.

The addon is recommendation-only. It never casts a spell, presses a key,
targets an enemy, sends chat, downloads code, or automates gameplay.

### Specialization status

- **Combat — beta:** validated on level-90 single-target dummies and live
  dungeon pulls, including automatic AoE-to-cleave transitions.
- **Assassination — beta:** live level-90 single-target and cleave testing
  passed, along with execute, pooling, AoE, and specialization-switching checks.
- **Subtlety — beta:** live level-90 single-target and cleave testing passed,
  along with opener, maintenance, Shadow Dance/Vanish pooling, Find Weakness,
  Preparation, AoE, and switching checks.

### Main features

- Automatic Combat, Assassination, and Subtlety detection.
- Single-target, cleave, and AoE priorities.
- Automatic nearby-target estimation plus manual mode overrides.
- Energy-pooling indicators and action-bar glow.
- Major-cooldown policies: boss only, always, or disabled.
- High-priority missing-poison warnings.
- Native in-game settings under **Options > AddOns**, also opened with `/rrh`.
- Level-aware abilities and DPS-relevant talent support.
- A built-in deterministic rotation check with `/rrh sim`.

### Transparency and privacy

Every functional file is readable Lua source. The archive contains no
executables, installers, compiled libraries, advertisements, telemetry, or
networking. Only display and rotation preferences are saved.

Source code, commit history, releases, and issue reports are public:

- https://github.com/Lillefot92/RogueRotationHelper
- https://github.com/Lillefot92/RogueRotationHelper/issues

### Known beta limitations

- Raid-boss cooldown timing still needs broader live validation.
- Automatic enemy counting cannot see every unengaged or hidden enemy; manual
  modes are available for planned pulls.
- Killing Spree positioning and encounter-specific cooldown holds always
  require player judgment.
- Broader dungeon, raid, and real-pack/mass-AoE feedback remains welcome for
  all three beta specializations.

## First file

- Display name: `Rogue Rotation Helper 1.0.0-beta.1`
- File: `RogueRotationHelper-1.0.0-beta.1.zip`
- Release type: `Beta`
- Supported game version: `5.5.4`
- Flavor: `MoP Classic`
- License: `MIT License`

## File changelog

- Promotes Combat, Assassination, and Subtlety to one public beta after live
  level-90 single-target and cleave testing passed for all three.
- Retains the tested specialization switching, compact display, Energy
  pooling, poison warnings, cooldown policies, and talent-aware priorities.
- Keeps raid-boss timing and broader real-pack/mass-AoE behavior documented as
  open beta validation items.
- Passed all 112 deterministic rotation scenarios.
- See the public `CHANGELOG.md` for the complete version history.

## Gallery

- `docs/images/compact-combat-display.png` — compact recommendation display.
- `docs/images/in-game-settings.png` — native in-game settings panel.
- `docs/images/rogue-rotation-helper-logo-curseforge.png` — padded project
  logo for square and circular thumbnail crops.
