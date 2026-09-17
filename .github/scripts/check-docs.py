#!/usr/bin/env python3
"""Integrity checks for docs/.

Runs from a developer machine with one command:
    python3 .github/scripts/check-docs.py

No third-party dependencies.
"""
from __future__ import annotations

import re
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs"
# The three root files are checked too. They are the ones a newcomer reads
# first, and a broken link there is the worst place to have one (CON-85).
MD = sorted(DOCS.rglob("*.md")) + [
    ROOT / "CLAUDE.md",
    ROOT / "README.md",
    ROOT / "CONTRIBUTING.md",
]

errors: list[str] = []


def slug(heading: str) -> str:
    """Build the anchor the way GitHub does: drop anything that is not
    alphanumeric, a hyphen, an underscore or a space; lowercase it; then turn
    every space into a single hyphen."""
    h = heading.strip()
    h = re.sub(r"`|\*|_", "", h)
    h = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", h)  # a link inside the heading
    h = "".join(
        c for c in h if c.isalnum() or c in " -_" or unicodedata.combining(c)
    )
    return h.strip().lower().replace(" ", "-")


def anchors_of(path: Path) -> set[str]:
    out: set[str] = set()
    fenced = False
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("```"):
            fenced = not fenced
            continue
        if fenced:
            continue
        m = re.match(r"^#{1,6}\s+(.*)$", line)
        if m:
            out.add(slug(m.group(1)))
    return out


anchor_cache = {p: anchors_of(p) for p in MD}

LINK = re.compile(r"\[[^\]]*\]\(([^)\s]+)\)")

for path in MD:
    text = path.read_text(encoding="utf-8")
    for target in LINK.findall(text):
        if target.startswith(("http://", "https://", "mailto:")):
            continue
        file_part, _, anchor = target.partition("#")
        if file_part:
            dest = (path.parent / file_part).resolve()
            if dest.is_dir():
                dest = dest / "README.md"
            if not dest.exists():
                errors.append(f"{path.relative_to(ROOT)}: broken link -> {target}")
                continue
        else:
            dest = path
        if anchor:
            known = anchor_cache.get(dest)
            if known is None and dest.suffix == ".md" and dest.exists():
                known = anchor_cache[dest] = anchors_of(dest)
            if known is not None and anchor not in known:
                errors.append(
                    f"{path.relative_to(ROOT)}: anchor does not exist -> {target}"
                )

# No DDL under docs/ - the data model analysis is deferred.
DDL = re.compile(r"create\s+table|alter\s+table|@Entity|@Table", re.I)
for path in DOCS.rglob("*.md"):
    for i, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if DDL.search(line):
            errors.append(f"{path.relative_to(ROOT)}:{i}: DDL in documentation")

# Feature table: no duplicate identifiers, every dependency points at a real one.
catalog = DOCS / "03-features" / "README.md"
rows = re.findall(
    r"^\|\s*(KJ-[A-Z]+-\d+)\s*\|[^|]*\|([^|]*)\|", catalog.read_text(encoding="utf-8"), re.M
)
ids = [r[0] for r in rows]
dupes = {i for i in ids if ids.count(i) > 1}
for d in sorted(dupes):
    errors.append(f"03-features/README.md: duplicate identifier -> {d}")
known_ids = set(ids)
for fid, deps in rows:
    for dep in re.findall(r"KJ-[A-Z]+-\d+", deps):
        if dep not in known_ids:
            errors.append(f"03-features/README.md: {fid} depends on {dep}, which does not exist")

# Constraints: no duplicate CON identifiers.
con_text = (DOCS / "02-requirement" / "constraints.md").read_text(encoding="utf-8")
cons = re.findall(r"^\|\s*(CON-\d+)\s*\|", con_text, re.M)
for c in sorted({c for c in cons if cons.count(c) > 1}):
    errors.append(f"02-requirement/constraints.md: duplicate identifier -> {c}")

if errors:
    print(f"FAIL: {len(errors)} problem(s):")
    for e in errors:
        print("  " + e)
    sys.exit(1)

print(f"PASS: {len(MD)} documents, {len(ids)} features, {len(cons)} constraints")
