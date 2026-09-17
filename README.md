# Kaiju

A Jira-style project management system, built **local-first** and **realtime**:
the client holds its own copy of the data, every interaction applies
immediately, and changes stream to other clients as they happen.

This file is the entry point. The full documentation lives in
[`docs/`](docs/README.md) and is written in Vietnamese; everything outside
`docs/` — including this file — is written in English.

---

## Status

Implementation **has not started**. What exists today is the design, plus the
infrastructure and pipeline needed to run it.

| Part | State |
|---|---|
| Brief, requirements, system design, features and roadmap | Complete |
| `infra/`, `.github/` | Scaffolded — four environment tiers, CI, and the delivery toolchain (OpenTofu, Ansible, Argo CD). Nothing applied: no cloud account, no cluster, no host |
| `backend/`, `frontend/` | Not created |
| UX/UI design, data model, detail design | Not started |

Next on the roadmap: the [data model](docs/06-erd/), then
[Phase 0](docs/03-features/roadmap.md#phase-0--nền-tảng).

Because neither application exists yet, the checks that would build them skip
themselves rather than fail. They switch back on by themselves the day
`backend/settings.gradle.kts` and `frontend/package.json` land.

---

## Layout

```
kaiju/
├── .github/     # CI workflows, shared check scripts, git hooks
├── docs/        # all documentation (Vietnamese)
├── backend/     # Spring Boot, Gradle multi-module          (not created yet)
├── frontend/    # Next.js                                    (not created yet)
└── infra/       # compose files per tier, Dockerfiles, proxy, Kubernetes
                 # manifests, OpenTofu stacks, Ansible playbooks, Makefile
```

Nothing else belongs at the top level.

---

## Running it locally

```bash
cd infra
make up        # tier 1: database, Redis, mail catcher, object storage
make db-up     # apply migrations - nothing migrates on startup, at any tier
make up-dev    # tier 2: adds the pooler, observability, proxy and the four roles
make check     # every static check, exactly as CI runs them
```

`make` on its own lists every target. What each tier is for, and which class of
failure **only that tier** catches, is in
[environments.md](docs/04-system-design/environments.md).

---

## Making a change

Every environment is a long-lived branch, and promoting is a pull request from
one to the next:

```
<type>/<slug> ──PR──> dev ──PR──> staging ──PR──> production
```

Merging the pull request **is** the deployment — there is no deploy button
anywhere. Rolling back is a git revert.

Before you push anything, read [CONTRIBUTING.md](CONTRIBUTING.md); it is short
and covers what will reject your pull request. The reasoning behind the model is
in [git-flow.md](docs/04-system-design/git-flow.md).

```bash
make -C infra hooks   # once per clone: local checks before a push
```

---

## Finding your way around the documentation

| Looking for | Read |
|---|---|
| What the project is and what it refuses to be | [Brief](docs/01-brief/) |
| Why something is built the way it is | [ADR](docs/adr/) — one file per decision, with the alternatives that were rejected |
| What is already decided and closed | [constraints.md](docs/02-requirement/constraints.md) |
| The exact meaning of a term | [glossary.md](docs/glossary.md) — especially `account` vs `member` |
| How the system is put together | [System design](docs/04-system-design/) |
| What is built and what comes next | [Feature catalog](docs/03-features/README.md) · [Roadmap](docs/03-features/roadmap.md) |

[`CLAUDE.md`](CLAUDE.md) is the short version for a working session: where to
read, what may never be violated, and how to record a decision that departs from
the documentation.

---

## Conventions

| | |
|---|---|
| Documentation under `docs/` | Vietnamese, technical terms kept in English |
| Everything else | English — including comments in scripts, configuration and manifests |
| Commit messages | English, Conventional Commits |
| Commit granularity | One commit per stage of work, never one large commit at the end |
| Feature status | Lives only in the feature catalog, never duplicated |

### Keeping this file true

**A change that makes any README wrong updates it in the same commit** — this
one, [`.github/CI.md`](.github/CI.md) and
[`infra/README.md`](infra/README.md). A README nobody maintains is worse than no
README: it is read by someone who has no way to know it is out of date.

The same rule the documentation follows applies here. Details and the mechanism
for recording a departure: [`CLAUDE.md`](CLAUDE.md).
