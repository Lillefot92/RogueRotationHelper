# Protected release process

Use this process for every public version after repository release immutability
is enabled.

1. Merge the tested release pull request into `main`.
2. Confirm the version in `RogueRotationHelper.toc`, `Core.lua`, and the
   changelog matches the planned tag.
3. Wait for the required `Repository and rotation checks` result to pass.
4. Run `python3 tools/build_release.py`. This creates an allowlisted ZIP and a
   matching `.sha256` sidecar in `dist/`.
5. Create a draft GitHub release with a new `v<version>` tag targeting the
   tested commit on `main`.
6. Attach both files from `dist/` and finish the release notes while the
   release is still a draft.
7. Publish the release only after every asset is attached. Immutable releases
   lock the tag and assets after publication.
8. Upload that exact ZIP to CurseForge. Never rebuild or replace an artifact
   under an existing version number.

If a published build needs a correction, create a new patch or beta version.
Do not move an existing tag.
