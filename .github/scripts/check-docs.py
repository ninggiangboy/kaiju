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


def check_usecases() -> tuple[int, int]:
    """Business-rule (QT-) and branch (NT-/NL-) IDs in docs/03-features/usecases/.

    Each use case file lists its exception/alternate flows in tables under a
    "### Luồng thay thế" (valid alternate) or "### Ngoại lệ" (rejection/error)
    heading, and its rules under "## Quy tắc nghiệp vụ". Every row must carry a
    unique, well-formed ID so a test can cite exactly which branch it covers —
    see docs/03-features/usecases/README.md for the ID scheme.
    """
    usecase_files = sorted((DOCS / "03-features" / "usecases").glob("uc-*.md"))

    functional_text = (DOCS / "02-requirement" / "functional.md").read_text(encoding="utf-8")
    fr_defined = set(re.findall(r"^\|\s*(FR-[A-Z]+-\d+)\s*\|", functional_text, re.M))
    fr_must = set(
        re.findall(r"^\|\s*(FR-[A-Z]+-\d+)\s*\|[^|]*\|\s*MUST\s*\|", functional_text, re.M)
    )
    nonfunctional_text = (DOCS / "02-requirement" / "non-functional.md").read_text(encoding="utf-8")
    nfr_defined = set(re.findall(r"^\|\s*(NFR-\d+)\s*\|", nonfunctional_text, re.M))

    requirement_line = re.compile(r"^\*\*Requirement:\*\*\s*(.*)$")
    fr_ref = re.compile(r"FR-[A-Z]+-\d+")
    nfr_ref = re.compile(r"NFR-\d+")
    fr_cited: set[str] = set()

    uc_heading = re.compile(r"^##\s+(UC-[A-Z]+-\d+)\b")
    branch_section = re.compile(r"^###\s+(Luồng thay thế|Ngoại lệ)\s*$")
    qt_row = re.compile(r"^\|\s*(QT-[A-Z]+-\d+)\s*\|")
    # A branch is defined either as a table row, or - when a sub-flow has enough
    # steps of its own to need a sub-heading - as a bold lead-in line such as
    # "**UC-PRJ-06/NT-01 — Lưu trữ**".
    branch_row = re.compile(
        r"^(?:\|\s*|\*\*)(UC-[A-Z]+-\d+)/(NT|NL)-(\d+)(?:\s*[—-].*)?(?:\*\*)?\s*(?:\|.*)?$"
    )
    qt_ref = re.compile(r"QT-[A-Z]+-\d+")
    branch_ref = re.compile(r"UC-[A-Z]+-\d+/(?:NT|NL)-\d+")
    bare_qt = re.compile(r"(?<![A-Z0-9-])QT-\d{2}\b")

    qt_defined: dict[str, str] = {}
    branch_defined: dict[str, str] = {}
    qt_cited: list[tuple[str, str, int]] = []
    branch_cited: list[tuple[str, str, int]] = []

    # Every "## UC-..." section must carry all of these, per the structure
    # table in usecases/README.md - a one-line "not applicable" reason counts
    # as present, this only checks the heading/label exists at all.
    REQUIRED_PARTS = ("Actor", "Tiền điều kiện", "Hậu điều kiện", "Ảnh hưởng tới đồng bộ")
    has_actor = re.compile(r"^\*\*Actor:\*\*")
    has_precond = re.compile(r"^\*\*Tiền điều kiện:\*\*")
    has_postcond = re.compile(r"^###\s+Hậu điều kiện\s*$")
    has_sync = re.compile(r"^###\s+Ảnh hưởng tới đồng bộ\s*$")

    for path in usecase_files:
        rel = path.relative_to(ROOT)
        current_uc: str | None = None
        current_section: str | None = None
        section_nums: dict[tuple[str, str], list[int]] = {}
        present: dict[str, bool] = {}

        def finalize_uc() -> None:
            if current_uc is None:
                return
            missing = [p for p in REQUIRED_PARTS if not present.get(p)]
            if missing:
                errors.append(
                    f"{rel}: {current_uc} is missing " + ", ".join(missing)
                )

        for i, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            m_uc = uc_heading.match(line)
            if m_uc:
                finalize_uc()
                current_uc = m_uc.group(1)
                current_section = None
                present = {}
                continue
            m_sec = branch_section.match(line)
            if m_sec:
                current_section = "NT" if m_sec.group(1) == "Luồng thay thế" else "NL"
                continue
            if line.startswith("## "):
                finalize_uc()
                current_uc = None
                current_section = None
                present = {}
                continue
            if line.startswith("### "):
                current_section = None

            if has_actor.match(line):
                present["Actor"] = True
            if has_precond.match(line):
                present["Tiền điều kiện"] = True
            if has_postcond.match(line):
                present["Hậu điều kiện"] = True
            if has_sync.match(line):
                present["Ảnh hưởng tới đồng bộ"] = True

            m_req = requirement_line.match(line)
            if m_req:
                for ref in fr_ref.findall(m_req.group(1)):
                    fr_cited.add(ref)
                    if ref not in fr_defined:
                        errors.append(
                            f"{rel}:{i}: cites {ref}, which does not exist in functional.md"
                        )
                for ref in nfr_ref.findall(m_req.group(1)):
                    if ref not in nfr_defined:
                        errors.append(
                            f"{rel}:{i}: cites {ref}, which does not exist in non-functional.md"
                        )

            m_qt = qt_row.match(line)
            if m_qt:
                qid = m_qt.group(1)
                if qid in qt_defined:
                    errors.append(
                        f"{rel}:{i}: duplicate business rule id -> {qid} "
                        f"(already defined in {qt_defined[qid]})"
                    )
                else:
                    qt_defined[qid] = str(rel)

            m_branch = branch_row.match(line)
            if m_branch:
                uc, kind, num = m_branch.group(1), m_branch.group(2), m_branch.group(3)
                bid = f"{uc}/{kind}-{num}"
                if current_uc is None:
                    errors.append(f"{rel}:{i}: branch id {bid} is outside any UC section")
                elif uc != current_uc:
                    errors.append(
                        f"{rel}:{i}: branch id {bid} prefix does not match enclosing section {current_uc}"
                    )
                if current_section is not None and kind != current_section:
                    errors.append(
                        f"{rel}:{i}: branch id {bid} sits in the {current_section} table, "
                        f"its own kind is {kind}"
                    )
                if bid in branch_defined:
                    errors.append(f"{rel}:{i}: duplicate branch id -> {bid}")
                else:
                    branch_defined[bid] = str(rel)
                section_nums.setdefault((uc, kind), []).append(int(num))

            for ref in qt_ref.findall(line):
                if not m_qt:
                    qt_cited.append((ref, str(rel), i))
            for ref in branch_ref.findall(line):
                if not m_branch:
                    branch_cited.append((ref, str(rel), i))
            for bare in bare_qt.findall(line):
                errors.append(f"{rel}:{i}: old-style business rule id -> {bare} (needs QT-<GROUP>-nn)")

        finalize_uc()

        for (uc, kind), nums in section_nums.items():
            if sorted(nums) != list(range(1, len(nums) + 1)):
                errors.append(
                    f"{rel}: {uc}/{kind}-nn ids are not contiguous from 01 -> got {sorted(nums)}"
                )

    for qid, rel, i in qt_cited:
        if qid not in qt_defined:
            errors.append(f"{rel}:{i}: cites {qid}, which no Quy tắc nghiệp vụ table defines")

    for bid, rel, i in branch_cited:
        if bid not in branch_defined:
            errors.append(f"{rel}:{i}: cites {bid}, which no branch table defines")

    for fid in sorted(fr_must - fr_cited):
        errors.append(
            f"02-requirement/functional.md: {fid} is MUST but no use case's Requirement line cites it"
        )

    return len(qt_defined), len(branch_defined)


qt_count, branch_count = check_usecases()

if errors:
    print(f"FAIL: {len(errors)} problem(s):")
    for e in errors:
        print("  " + e)
    sys.exit(1)

print(
    f"PASS: {len(MD)} documents, {len(ids)} features, {len(cons)} constraints, "
    f"{qt_count} business rules, {branch_count} use case branches"
)
