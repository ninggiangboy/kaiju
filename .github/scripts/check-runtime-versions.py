#!/usr/bin/env python3
"""The CI toolchain and the container base images must agree on a version.

Dependabot bumps `FROM node:22-alpine` in the Dockerfile. It does not know that
`NODE_VERSION` in ci.yml exists, so accepting that bump silently leaves the
pipeline compiling and testing on one major version while the image that ships
runs another.

That is the same class of bug CON-66 rules out for configuration - one artifact,
one behaviour - except here it hides in two files nobody reads together. It
surfaces as a runtime failure in an environment, not as a red build.

Run: python3 .github/scripts/check-runtime-versions.py
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

# <CI env var> -> (Dockerfile, regex capturing the major version in every FROM)
PAIRS = {
    "JAVA_VERSION": ("infra/docker/backend.Dockerfile", r"^FROM eclipse-temurin:(\d+)-"),
    "NODE_VERSION": ("infra/docker/frontend.Dockerfile", r"^FROM node:(\d+)-"),
}


def ci_versions() -> dict[str, str]:
    """Read the `env:` block of ci.yml without a YAML parser dependency."""
    text = (ROOT / ".github/workflows/ci.yml").read_text()
    found = {}
    for name in PAIRS:
        m = re.search(rf'^\s*{name}:\s*"?(\d+)"?\s*$', text, re.M)
        if m:
            found[name] = m.group(1)
    return found


def main() -> int:
    failed = False
    ci = ci_versions()

    for name, (dockerfile, pattern) in PAIRS.items():
        path = ROOT / dockerfile
        if name not in ci:
            print(f"FAIL: {name} is not declared in ci.yml")
            failed = True
            continue
        if not path.exists():
            print(f"FAIL: {dockerfile} is missing")
            failed = True
            continue

        stages = re.findall(pattern, path.read_text(), re.M)
        if not stages:
            print(f"FAIL: no base image in {dockerfile} matched {pattern!r}")
            failed = True
            continue

        # Every stage too: a build stage left behind on an older major produces
        # artifacts the runtime stage may not accept.
        mismatched = sorted({v for v in stages if v != ci[name]})
        if mismatched:
            print(
                f"FAIL: ci.yml has {name}={ci[name]} but {dockerfile} "
                f"builds on {', '.join(mismatched)}"
            )
            failed = True
        else:
            print(f"PASS: {name}={ci[name]} matches all {len(stages)} stages of {dockerfile}")

    if failed:
        print("\nBump both, in the same commit.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
