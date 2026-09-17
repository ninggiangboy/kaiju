# .github/

The continuous integration pipeline. The design, and why each check exists, is
documented in [ci-cd.md](../docs/04-system-design/ci-cd.md) (Vietnamese, like
everything under `docs/`).

| File | Runs when |
|---|---|
| `workflows/ci.yml` | Every pull request and every push to `main` or `dev` |
| `workflows/release.yml` | Pushes to `main` (build only) and every version tag (build and deploy) |
| `workflows/security.yml` | Weekly, and whenever a dependency manifest changes |
| `workflows/pr-hygiene.yml` | Every time a pull request title is edited |
| `scripts/check-docs.py` | Inside `ci.yml`, and by hand: `make -C infra check-docs` |

---

## Two things that are easy to get wrong

### The Gate is the only required check

Branch protection declares **`Gate`** and nothing else. That way, adding a new
check to the pipeline never means editing that configuration.

### A skipped job is a FAILURE

Unless its directory did not change (`CON-71`). Most CI configurations treat a
skipped job as passing; combined with a path filter that is wrong, that is how a
backend change merges without a single test having run.

The Gate also blocks in the other direction: a job that **ran** although its
directory was unchanged is a broken filter too, and it is reported.

---

## Running locally

Every static check runs from a developer machine (`CON-72`):

```bash
make -C infra check
```

The workflow files themselves:

```bash
actionlint
```

---

## Current state

The backend and frontend jobs **stay skipped until `backend/` and `frontend/`
exist** — the path filters match nothing, so they do not run and the Gate counts
that as legitimate. Today only `Documentation` and `Infrastructure` actually run.

The two deploy steps in `release.yml` deliberately **exit non-zero** and print
the exact commands instead: they need host and cluster credentials that do not
exist yet. Letting them "succeed" while doing nothing is the worst available
outcome — it reports a deployment that never happened.
