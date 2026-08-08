# Security and trust notes

Rogue Rotation Helper is intentionally easy to inspect.

## What is in the archive

- One `.toc` manifest.
- Five readable `.lua` source files.
- Markdown documentation and a SHA-256 checksum list.

There are no `.exe`, `.dll`, `.bat`, `.cmd`, `.ps1`, installer, or compiled
binary files.

## What the addon does not do

The source does not call chat or addon-message sending APIs, does not contain a
network client, and does not load downloaded code. World of Warcraft addons run
inside the game's restricted Lua environment and cannot silently install
software on Windows.

The addon never reads or stores account names, character names, realm names,
target names, chat messages, Battle.net information, or combat-log names.
Transient unit GUIDs are used only in memory to estimate nearby enemy count and
target time-to-die; they are never saved.

## Saved data

`RogueRotationHelperDB` contains only:

- display position and scale;
- locked/enabled/glow/preview toggles;
- target mode;
- cooldown policy;
- offensive Vanish preference;
- optional Prey on the Weak advice preference;
- schema version.

## How to verify the package

1. Open `RogueRotationHelper.toc`. It lists every Lua file the game loads.
2. Open those Lua files in any text editor; all behavior is visible.
3. Confirm the archive contains no executable or script formats listed above.
4. Compare the files with `CHECKSUMS.sha256` after extraction.

Official source and releases are published at:

- https://github.com/Lillefot92/RogueRotationHelper
- https://github.com/Lillefot92/RogueRotationHelper/releases

Every public change has a visible commit history and reviewable diff. Report a
suspected security problem through the repository issue tracker without
including account credentials or other private information.
