# Contributing and beta feedback

Thank you for helping test Rogue Rotation Helper. The public beta focuses on
level-90 Combat Rogue PvE and also contains external Assassination and
Subtlety alphas for Mists of Pandaria Classic 5.5.4.

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

## Development safeguards

Submit code changes through a pull request. Before requesting review, run:

```text
python3 tests/validate_repository.py
lua5.1 tests/run_simulator.lua
python3 tools/build_release.py
```

GitHub repeats these checks automatically. Release archives are generated only
from the explicit allowlist in `tools/build_release.py`; generated `dist/`
files must not be committed.
