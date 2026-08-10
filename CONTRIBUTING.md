# Contributing and beta feedback

Thank you for helping test Rogue Rotation Helper. The public beta focuses on
level-90 Combat Rogue PvE; the current pre-release also contains an external
Assassination alpha and a local Subtlety alpha for Mists of Pandaria Classic
5.5.4.

## Before reporting a rotation problem

1. Install the versioned ZIP from the official GitHub Releases page.
2. Enter `/rrh status` and note the reported addon version.
3. Enter `/rrh sim` and note whether all rotation checks pass.
4. Reproduce the problem with Lua errors enabled using
   `/console scriptErrors 1` followed by `/reload`.

## What to include

- addon version, active specialization, and game client build;
- single, cleave, or AoE mode and cooldown policy;
- expected recommendation and actual recommendation;
- Energy, Combo Points, and relevant visible timers;
- complete Lua error text, if any;
- a short screenshot or clip when the issue is visual or timing-sensitive.

Never include account credentials or private chat. Raid-boss cooldown timing is
still a known pending validation item; reports from actual boss encounters are
especially useful.

Open feedback at:
https://github.com/Lillefot92/RogueRotationHelper/issues
