# Kaiju

A Jira-style project management system, built **local-first** and **realtime**.

Full documentation lives in [`docs/`](docs/README.md) and is written in
Vietnamese. **This file is written in English** and contains only what a working
session needs before touching anything: where to read, what may never be
violated, and how to record a decision that departs from the docs.

---

## Repository layout

```
kaiju/
├── .github/     # CI workflows and shared check scripts
├── docs/        # documentation
├── backend/     # Spring Boot, Gradle multi-module
├── frontend/    # Next.js
└── infra/       # Compose files per environment tier, Dockerfiles, reverse proxy,
                 # orchestration manifests, operational scripts
```

Do not add directories at the top level.

At the root, [`README.md`](README.md) is the entry point for a person arriving at
the repository and [`CONTRIBUTING.md`](CONTRIBUTING.md) is what to read before
pushing anything. `.github/hooks/pre-push`, installed by `make -C infra hooks`,
refuses a push those two rule out.

---

## Development principle

**Build one feature at a time, and build it completely.** Never ship a shallow
version with the intention of filling it in later. A feature is done only when
exception branches, permissions, tenant isolation and sync behaviour are all
handled — not when the happy path works.

Phase ordering is driven by **technical dependency**, not by difficulty or
appeal. See [roadmap](docs/03-features/roadmap.md) and the
[feature catalog](docs/03-features/README.md).

---

## What to read, by situation

Read the listed documents **before** writing code, not after. Everything is in
Vietnamese; this table is the index into it.

### Starting out

| Situation | Read |
|---|---|
| First time in this repo | [glossary](docs/glossary.md) → [brief](docs/01-brief/) → [ADR index](docs/adr/) → [system design README](docs/04-system-design/) → [roadmap](docs/03-features/roadmap.md) |
| Asked "why is it built this way?" | [ADR](docs/adr/) — one file per decision, each with context, reasoning, consequences and rejected alternatives |
| Need to know what is already decided and closed | [constraints.md](docs/02-requirement/constraints.md) — every entry links to its ADR |
| Need the exact meaning of a term | [glossary](docs/glossary.md) — especially `account` vs `member`, and `workspace` vs `project` |

### Implementing a feature

| Situation | Read |
|---|---|
| Any feature, always | [feature catalog](docs/03-features/README.md) (find the ID, check `Depends` are `DONE`) → the matching use case → the relevant system design doc → [constraints.md](docs/02-requirement/constraints.md) |
| Checking whether a feature is finished | [definition of done](docs/04-system-design/testing-strategy.md#thứ-được-coi-là-xong) |
| Unsure what the feature must cover | [functional.md](docs/02-requirement/functional.md) for the requirement, [roadmap](docs/03-features/roadmap.md) for that phase's scope and DoD |

### By area of work

| Working on | Read |
|---|---|
| Module layout, package structure, where code belongs | [backend-modules.md](docs/04-system-design/backend-modules.md) |
| Adding a new backend module | [backend-modules.md — checklist](docs/04-system-design/backend-modules.md#checklist-thêm-một-module-mới) |
| Aggregate design, transaction boundaries | [backend-modules.md](docs/04-system-design/backend-modules.md) + [ADR-0004](docs/adr/0004-spring-data-jdbc.md) |
| Repositories, queries, choosing between Spring Data JDBC / jOOQ / JdbcClient | [data-access-and-tenancy.md](docs/04-system-design/data-access-and-tenancy.md) |
| Migrations, new tables, tenant isolation | [data-access-and-tenancy.md](docs/04-system-design/data-access-and-tenancy.md) + [ERD constraints](docs/06-erd/) |
| Emitting or consuming domain events | [events-and-outbox.md](docs/04-system-design/events-and-outbox.md) |
| Background jobs, the relay worker, retries | [events-and-outbox.md](docs/04-system-design/events-and-outbox.md) |
| Anything that changes data the client holds | [realtime-and-sync.md](docs/04-system-design/realtime-and-sync.md) |
| The SSE protocol, cursors, catch-up, bootstrap | [realtime-and-sync.md](docs/04-system-design/realtime-and-sync.md) |
| Client-side store, optimistic updates, offline queue | [frontend.md](docs/04-system-design/frontend.md) + [realtime-and-sync.md](docs/04-system-design/realtime-and-sync.md) |
| Next.js routing, deciding where something renders | [frontend.md](docs/04-system-design/frontend.md) + [ADR-0008](docs/adr/0008-nextjs-as-spa-shell.md) |
| Auth, sessions, magic link | [identity-and-permission.md](docs/04-system-design/identity-and-permission.md) + [uc-auth.md](docs/03-features/usecases/uc-auth.md) |
| Permission checks, roles, bitmasks | [identity-and-permission.md](docs/04-system-design/identity-and-permission.md) + [ADR-0010](docs/adr/0010-bitmask-permission.md) |
| Anything that grants or removes access | [uc-member-invite.md](docs/03-features/usecases/uc-member-invite.md) + [realtime-and-sync.md — revocation](docs/04-system-design/realtime-and-sync.md#khi-quyền-bị-thu-hồi) |
| Writing tests | [testing-strategy.md](docs/04-system-design/testing-strategy.md) |
| Docker, proxy config, deployment, metrics, logging | [observability-and-ops.md](docs/04-system-design/observability-and-ops.md) |
| Standing up or changing an environment | [environments.md](docs/04-system-design/environments.md) — four tiers, and what only that tier catches |
| CI workflows, release, rollback | [ci-cd.md](docs/04-system-design/ci-cd.md) |
| Branching, merging, promoting a change, rolling one back | [git-flow.md](docs/04-system-design/git-flow.md) |
| Writing a database migration, or running one up or down | [data-access-and-tenancy.md — migration](docs/04-system-design/data-access-and-tenancy.md#migration) + [ADR-0013](docs/adr/0013-explicit-two-way-migration.md) |
| Adding a dependency, or standing up an infrastructure component | [infrastructure.md](docs/04-system-design/infrastructure.md) |
| Performance, availability or security targets | [non-functional.md](docs/02-requirement/non-functional.md) |

### Red flags — stop and read first

| If you are about to… | Read this first |
|---|---|
| Write a SQL `JOIN` across two modules' tables | [backend-modules.md — boundary rules](docs/04-system-design/backend-modules.md#ba-luật-biên-giới). You almost certainly must not |
| Add a foreign key to a global table | [ADR-0011](docs/adr/0011-account-vs-member.md). This is unfixable once data exists |
| Reference a person from business data | [ADR-0011](docs/adr/0011-account-vs-member.md). It must point at `member`, never `account` |
| Write a Server Action or fetch business data in a server component | [ADR-0008](docs/adr/0008-nextjs-as-spa-shell.md). Both are forbidden |
| Add a datastore, a broker, or a sync library | [ADR-0002](docs/adr/0002-postgres-only.md), [ADR-0005](docs/adr/0005-outbox-db-job.md), [ADR-0007](docs/adr/0007-build-own-sync-engine.md) |
| Add any event-store library of the base framework, or use its transactional event listener annotations | [events-and-outbox.md](docs/04-system-design/events-and-outbox.md#ba-điều-cấm). It silently creates a second, competing outbox |
| Create a package, move one, or add a module | [backend-modules.md](docs/04-system-design/backend-modules.md#quy-ước-package-bắt-buộc). Get this wrong and the boundary check silently verifies nothing |
| Branch on the environment name in code | [environments.md](docs/04-system-design/environments.md). Forbidden — that branch is never exercised where it actually runs |
| Deploy `api` before `worker` | [ci-cd.md](docs/04-system-design/ci-cd.md#thứ-tự-triển-khai) |
| Force-push, rebase or cherry-pick onto `dev`, `staging` or `production` | [git-flow.md](docs/04-system-design/git-flow.md#điều-cấm). These branches record what an environment ran |
| Roll back an environment | [git-flow.md](docs/04-system-design/git-flow.md#quay-lui). Step 4 — bringing the revert back to `dev` — is not optional |
| Let the application run migrations at startup, in **any** tier | [ADR-0013](docs/adr/0013-explicit-two-way-migration.md). Migrations are always invoked explicitly |
| Put a spinner in a main-flow interaction | [frontend.md](docs/04-system-design/frontend.md). It means the action is not optimistic yet |
| Reuse a permission bit position | [ADR-0010](docs/adr/0010-bitmask-permission.md). Never do this |

---

## Invariants

These may not be violated. Full reasoning lives in the linked ADRs and in
[constraints.md](docs/02-requirement/constraints.md).

### Architecture

1. A module never imports another module's internal packages — only its `api` package
2. A module never queries tables owned by another module
3. Asynchronous communication between modules happens **only** through domain events
4. No JPA/Hibernate. Writes use Spring Data JDBC, dynamic queries use jOOQ, simple
   reads use `JdbcClient`
5. No datastore other than PostgreSQL. Redis is cache, pub/sub, locks and rate
   limiting only — losing Redis makes the system slower, never wrong

### Code layout

6. Business module packages are **direct sub-packages of the application base
   package** and map one-to-one onto Gradle modules; a module's base package stays
   empty and its `api` sub-package is declared as the exposed one
7. Shared platform code lives **outside** the application base package, so it is
   not treated as a business module
8. Each module owns a table name prefix. **The boundary tool does not catch
   cross-module table access** — the dedicated test does

### Data

9. **Every business table carries a workspace identifier**, even when it already
   has a project identifier
10. **Every business table has row level security enabled** on that workspace identifier
11. **No foreign key** from a business table to a table in the global data region
12. **Every reference to a person points at `member`, never at `account`**
13. People who leave a workspace are deactivated, **never hard-deleted**

### Events

14. Domain events are written to the outbox table **in the same transaction** as
    the business change
15. Delivery is at-least-once, so **every consumer must be idempotent**
16. Events carry a version field from the very first event
17. The connection that listens for PostgreSQL notifications **must not come from
    the shared connection pool**

### Sync

18. Every data change produces a change log entry whose patch contains **only the
    fields that changed**
19. Mutations go over HTTP POST with an idempotency key, never over the sync stream
20. **Every change that narrows permissions must emit a revocation event**, and the
    client must purge that scope's local data

### Frontend

21. **No Server Actions for business mutations**
22. **No business data fetching in server components**
23. The app area renders entirely on the client; only marketing pages and the
    magic-link landing page render on the server
24. Multiple tabs share **one** sync connection and **one** local writer

### Identity and permissions

25. There are no passwords anywhere. Magic link is the only authentication method
26. Access tokens carry **basic claims only** — account, session, issue and expiry
    time, token type. Never roles, permissions or the workspace list
27. The permission mask is **always resolved server-side per request**, never read
    from the token and never from anything the client sends
28. **Every action declares exactly one required permission**, and an action with
    no declared permission is **denied**, not allowed
29. Permission checks live in command and query handlers, not in controllers —
    background jobs, automation rules and bulk operations enter another way
30. **A permission bit position is never redefined or reused**
31. All permission checks go through a single entry point that also receives the
    data context, so the permission condition layer can plug in

### Environments and delivery

32. **One container image runs in all four tiers.** Differences live in environment
    variables and the role profile — **never in a code branch on the environment name**
33. **Migrations never run at application startup, in any tier.** They are an
    explicit, two-way operation run through the `migrate` role of the same image,
    and they finish before the application comes up. The deployment order is
    migration → `worker` and `scheduler` → `api` and `realtime`
34. Deployments always pin an immutable image tag bound to a commit, never a moving tag
38. **Environment branches are never force-pushed, rebased, deleted or cherry-picked
    into.** Every change reaches them by merge commit — squash and rebase merges are
    disabled, because both break the ancestry that promotion depends on
39. **`rollback/*` is the only branch that may open a pull request straight into an
    environment branch**, and the revert it carries must then be brought back to `dev`
35. A CI job that was **skipped counts as failed** unless its directory did not change
36. `staging` uses no stand-in services — real mail, real object storage, real database
37. **Every migration changeset carries a hand-written rollback**, and the down
    direction is never used in production — roll forward with a backward-compatible
    migration instead

---

## Recording decisions that depart from the docs

The documentation describes decisions made before implementation. Implementation
will sometimes prove one of them wrong, incomplete, or impractical. **When that
happens, update the documentation in the same change — and never erase the
decision that was replaced.**

The history of a decision, including a wrong one, is information. Silently
rewriting a document so the old decision appears never to have existed destroys
the reason the documentation exists at all, and guarantees the same debate
happens again later.

### Which mechanism to use

| Scope of the change | What to do |
|---|---|
| **An ADR turns out to be wrong** | Write a **new ADR**. Set the old one's status to `Superseded by ADR-00xx` and add a short line saying what changed. **Do not edit the old ADR's body.** Update the index table and every `constraints.md` row that pointed at it |
| **A system design doc no longer matches reality** | Edit the document, but keep the previous statement visible in a `> **Changed (YYYY-MM-DD):**` note giving the old approach, the new one, and why. Link the ADR if one was written |
| **A use case gains or loses a branch** | Add or amend the branch, and note in the business-rules table that the rule changed and when |
| **A requirement turns out to be wrong** | Keep the ID. Update the text and add a note recording the previous wording. Never delete the row and never reuse the ID |
| **A feature is dropped or postponed** | Keep the row and the ID, set status to `DEFERRED`, and state in the notes which phase it moved to and why |
| **A change makes a README wrong** | Update that README **in the same commit** — `README.md`, `.github/README.md` or `infra/README.md`. A stale README is worse than none: it is read by someone with no way to know it is out of date |
| **A small, purely local choice** | No documentation change needed. If it does not cross a module boundary and does not contradict anything written down, it is not a departure |

### What counts as a departure worth recording

Record it when the change would surprise someone who had read the docs: a
different mechanism than the one described, a rule that no longer holds, a
constraint that had to be relaxed, an interface shaped differently than specified.

Do not record routine implementation detail that the docs never claimed anything
about.

### When to write a new ADR rather than a note

Write an ADR when the decision is hard to reverse, when it crosses module
boundaries or both backend and frontend, or when it rules out an option someone
may well propose again. A choice that is local to one module, or reversible in an
afternoon, is a note — not an ADR.

### Commit it together

The documentation update belongs in the **same commit** as the code that departs
from it. A separate follow-up commit is a follow-up that does not happen.

---

## Conventions

| | |
|---|---|
| Documentation language (`docs/`) | Vietnamese, with technical terms kept in English |
| **Everything outside `docs/`** | **English, including comments inside scripts and configuration** — shell, Makefile, compose, Dockerfiles, orchestration manifests, CI workflows, and source |
| This file | English only |
| Code, identifiers, file names | English |
| **Commit messages** | **English**, Conventional Commits |
| Commit granularity | One commit per stage of work; never one large commit at the end |
| Feature status | Lives only in the [feature catalog](docs/03-features/README.md); never duplicated elsewhere |
| Unsettled points | Write `> **Chưa chốt:** …` rather than guessing |
| Diagrams | Mermaid |
| READMEs | Updated in the same commit as the change that makes them wrong (`CON-85`) |
| Working rules a newcomer needs | Live **in the repository**, not only in a design document: `CONTRIBUTING.md`, the pull request template, the pre-push hook, and a CI check where one can actually enforce it |

---

## Current status

The project **has not started implementation**. Documentation only.

| Part | Status |
|---|---|
| Brief, Requirement, System Design, Features & Roadmap | ✅ Complete |
| UX/UI design, ERD, Detail design | ⬜ Not started |
| `infra/`, `.github/` | ✅ Scaffolded — environment tiers, CI pipeline, and the delivery toolchain (OpenTofu, Ansible, Argo CD). Nothing applied yet: no cloud account, no cluster, no host |
| `backend/`, `frontend/` | ⬜ Not created |

Next steps on the roadmap: analyse the data model ([ERD](docs/06-erd/) — its
README already lists the nine constraints that model must satisfy), then start
[Phase 0](docs/03-features/roadmap.md#phase-0--nền-tảng).
