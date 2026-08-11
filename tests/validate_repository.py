"""Repository, trust-claim, and addon-manifest validation."""

from __future__ import annotations

import hashlib
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TOC = ROOT / "RogueRotationHelper.toc"
CHECKSUMS = ROOT / "CHECKSUMS.sha256"

EXPECTED_INTERFACE = "50504"
EXPECTED_LUA_FILES = [
    "Core.lua",
    "Rotation.lua",
    "RotationCombat.lua",
    "RotationAssassination.lua",
    "RotationSubtlety.lua",
    "Simulator.lua",
    "Display.lua",
    "Settings.lua",
]

FORBIDDEN_REPOSITORY_SUFFIXES = {
    ".bat",
    ".cmd",
    ".com",
    ".dll",
    ".exe",
    ".jar",
    ".msi",
    ".scr",
}

# These APIs contradict the project's recommendation-only and no-network
# trust promises. Additions must be deliberately reviewed instead of silently
# entering a release.
FORBIDDEN_LUA_APIS = {
    "BNSendWhisper",
    "C_ChatInfo.SendAddonMessage",
    "CastSpellByID",
    "CastSpellByName",
    "FocusUnit",
    "RunMacroText",
    "SendAddonMessage",
    "SendChatMessage",
    "TargetUnit",
    "UseAction",
    "loadstring",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    data = path.read_bytes()
    if path.suffix.lower() in {".lua", ".md", ".toc"} or path.name == "LICENSE":
        # Git may materialize text as CRLF on Windows. Checksums use canonical
        # LF bytes so validation and release builds are platform-independent.
        data = data.replace(b"\r\n", b"\n")
    digest.update(data)
    return digest.hexdigest()


def parse_toc() -> tuple[dict[str, str], list[str]]:
    metadata: dict[str, str] = {}
    loaded_files: list[str] = []
    for raw_line in TOC.read_text(encoding="utf-8-sig").splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if line.startswith("##"):
            key, separator, value = line[2:].partition(":")
            if separator:
                metadata[key.strip()] = value.strip()
        elif not line.startswith("#"):
            loaded_files.append(line.replace("\\", "/"))
    return metadata, loaded_files


def expected_checksum_paths() -> set[str]:
    paths: set[str] = set()
    for path in ROOT.iterdir():
        if not path.is_file() or path.name == CHECKSUMS.name:
            continue
        if path.suffix.lower() in {".lua", ".md", ".toc"} or path.name == "LICENSE":
            paths.add(path.relative_to(ROOT).as_posix())
    docs = ROOT / "docs"
    if docs.exists():
        paths.update(
            path.relative_to(ROOT).as_posix()
            for path in docs.rglob("*")
            if path.is_file()
        )
    return paths


def validate_checksums(errors: list[str]) -> None:
    recorded: dict[str, str] = {}
    for line_number, line in enumerate(
        CHECKSUMS.read_text(encoding="utf-8").splitlines(), start=1
    ):
        match = re.fullmatch(r"([0-9a-f]{64})  (.+)", line)
        if not match:
            errors.append(f"invalid CHECKSUMS.sha256 line {line_number}")
            continue
        digest, relative = match.groups()
        relative = relative.replace("\\", "/")
        if relative in recorded:
            errors.append(f"duplicate checksum entry: {relative}")
        recorded[relative] = digest

    expected = expected_checksum_paths()
    missing_entries = sorted(expected - recorded.keys())
    unexpected_entries = sorted(recorded.keys() - expected)
    if missing_entries:
        errors.append("missing checksum entries: " + ", ".join(missing_entries))
    if unexpected_entries:
        errors.append("unexpected checksum entries: " + ", ".join(unexpected_entries))

    for relative, expected_digest in recorded.items():
        path = ROOT / relative
        if not path.is_file():
            errors.append(f"checksummed file does not exist: {relative}")
        elif sha256(path) != expected_digest:
            errors.append(f"checksum mismatch: {relative}")


def main() -> int:
    errors: list[str] = []
    metadata, loaded_files = parse_toc()

    if metadata.get("Interface") != EXPECTED_INTERFACE:
        errors.append(
            f"Interface must be {EXPECTED_INTERFACE}, got {metadata.get('Interface')!r}"
        )
    version = metadata.get("Version")
    if not version:
        errors.append("TOC Version is missing")
    if loaded_files != EXPECTED_LUA_FILES:
        errors.append(
            "TOC Lua file order changed: expected "
            + ", ".join(EXPECTED_LUA_FILES)
            + "; got "
            + ", ".join(loaded_files)
        )

    for relative in loaded_files:
        path = ROOT / relative
        if path.suffix.lower() != ".lua" or not path.is_file():
            errors.append(f"TOC entry is not a readable Lua file: {relative}")

    core_text = (ROOT / "Core.lua").read_text(encoding="utf-8-sig")
    core_version = re.search(r'ns\.VERSION\s*=\s*"([^"]+)"', core_text)
    if not core_version:
        errors.append("Core.lua ns.VERSION is missing")
    elif version and core_version.group(1) != version:
        errors.append(
            f"version mismatch: TOC={version}, Core.lua={core_version.group(1)}"
        )

    all_lua = "\n".join(
        (ROOT / relative).read_text(encoding="utf-8-sig")
        for relative in loaded_files
        if (ROOT / relative).is_file()
    )
    for api in sorted(FORBIDDEN_LUA_APIS):
        if api in all_lua:
            errors.append(f"forbidden recommendation-only API found: {api}")

    for path in ROOT.rglob("*"):
        if not path.is_file() or ".git" in path.parts or "dist" in path.parts:
            continue
        if path.suffix.lower() in FORBIDDEN_REPOSITORY_SUFFIXES:
            errors.append(f"forbidden executable file type: {path.relative_to(ROOT)}")

    security_text = (ROOT / "SECURITY.md").read_text(encoding="utf-8")
    private_report_url = (
        "https://github.com/Lillefot92/RogueRotationHelper/security/advisories/new"
    )
    if private_report_url not in security_text:
        errors.append("SECURITY.md does not direct private reports to GitHub Advisories")

    validate_checksums(errors)

    if errors:
        print("repository validation failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    print(
        f"repository validation passed: {len(loaded_files)} Lua files, "
        f"version {version}, checksums verified"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
