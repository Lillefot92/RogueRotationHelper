"""Build a deterministic, allowlisted Rogue Rotation Helper release archive."""

from __future__ import annotations

import argparse
import hashlib
import re
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FIXED_ZIP_TIME = (2026, 1, 1, 0, 0, 0)
DOCUMENTS = [
    "CHANGELOG.md",
    "CONTRIBUTING.md",
    "LICENSE",
    "README.md",
    "SECURITY.md",
    "TESTING.md",
    "CHECKSUMS.sha256",
]


def toc_data() -> tuple[str, list[str]]:
    text = (ROOT / "RogueRotationHelper.toc").read_text(encoding="utf-8-sig")
    version_match = re.search(r"^## Version:\s*(\S+)\s*$", text, re.MULTILINE)
    if not version_match:
        raise ValueError("RogueRotationHelper.toc has no Version metadata")
    loaded = [
        line.strip().replace("\\", "/")
        for line in text.splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]
    return version_match.group(1), loaded


def build(output: Path) -> tuple[Path, Path, str]:
    version, loaded = toc_data()
    relative_files = ["RogueRotationHelper.toc", *loaded, *DOCUMENTS]
    if len(relative_files) != len(set(relative_files)):
        raise ValueError("release allowlist contains duplicate files")

    for relative in relative_files:
        path = ROOT / relative
        if not path.is_file():
            raise FileNotFoundError(f"release file is missing: {relative}")
        if path.suffix.lower() in {".exe", ".dll", ".bat", ".cmd", ".ps1"}:
            raise ValueError(f"executable file cannot enter a release: {relative}")

    output.mkdir(parents=True, exist_ok=True)
    archive = output / f"RogueRotationHelper-{version}.zip"
    with zipfile.ZipFile(
        archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9
    ) as handle:
        for relative in relative_files:
            source = ROOT / relative
            data = source.read_bytes()
            if source.suffix.lower() in {".lua", ".md", ".toc"} or source.name == "LICENSE":
                data = data.replace(b"\r\n", b"\n")
            member = zipfile.ZipInfo(
                f"RogueRotationHelper/{relative}", date_time=FIXED_ZIP_TIME
            )
            member.compress_type = zipfile.ZIP_DEFLATED
            member.external_attr = 0o100644 << 16
            handle.writestr(member, data, compress_type=zipfile.ZIP_DEFLATED)

    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    sidecar = archive.with_suffix(archive.suffix + ".sha256")
    sidecar.write_text(f"{digest}  {archive.name}\n", encoding="ascii")
    return archive, sidecar, digest


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=ROOT / "dist")
    args = parser.parse_args()
    archive, sidecar, digest = build(args.output)
    print(f"built {archive}")
    print(f"built {sidecar}")
    print(f"sha256 {digest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
