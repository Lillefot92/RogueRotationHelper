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
- **Assassination — external alpha:** focused live dummy, execute, four-plus
  target, pooling, and specialization-switching checks passed.
- **Subtlety — external alpha:** focused live opener, maintenance, Shadow
  Dance/Vanish pooling, Find Weakness, Preparation, AoE, and switching checks
  passed.

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
- Assassination and Subtlety need more dungeon and raid feedback before their
  alpha labels are removed.

## First file

- Display name: `Rogue Rotation Helper 0.3.0-beta.1`
- File: `RogueRotationHelper-0.3.0-beta.1.zip`
- Release type: `Beta`
- Supported game version: `5.5.4`
- Flavor: `MoP Classic`
- License: `MIT License`

## File changelog

- Added the first publicly testable Subtlety rotation.
- Added Shadow Dance and Vanish pooling, Find Weakness tracking, Preparation
  ordering, and Subtlety AoE priorities.
- Included the previously tested Assassination alpha and validated Combat beta
  in one package.
- Passed all 112 deterministic rotation scenarios.
- See the public `CHANGELOG.md` for the complete version history.

## Gallery

- `docs/images/compact-combat-display.png` — compact recommendation display.
- `docs/images/in-game-settings.png` — native in-game settings panel.
- `docs/images/rogue-rotation-helper-logo.png` — project logo.
