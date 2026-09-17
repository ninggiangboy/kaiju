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
├── docs/        # documentation
├── backend/     # Spring Boot, Gradle multi-module
├── frontend/    # Next.js
└── infra/       # Docker Compose, Dockerfiles, reverse proxy, operational scripts
```

Do not add directories at the top level.

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
| Performance, availability or security targets | [non-functional.md](docs/02-requirement/non-functional.md) |

### Red flags — stop and read first

| If you are about to… | Read this first |
|---|---|
| Write a SQL `JOIN` across two modules' tables | [backend-modules.md — boundary rules](docs/04-system-design/backend-modules.md#ba-luật-biên-giới). You almost certainly must not |
| Add a foreign key to a global table | [ADR-0011](docs/adr/0011-account-vs-member.md). This is unfixable once data exists |
| Reference a person from business data | [ADR-0011](docs/adr/0011-account-vs-member.md). It must point at `member`, never `account` |
| Write a Server Action or fetch business data in a server component | [ADR-0008](docs/adr/0008-nextjs-as-spa-shell.md). Both are forbidden |
| Add a datastore, a broker, or a sync library | [ADR-0002](docs/adr/0002-postgres-only.md), [ADR-0005](docs/adr/0005-outbox-db-job.md), [ADR-0007](docs/adr/0007-build-own-sync-engine.md) |
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

### Data

6. **Every business table carries a workspace identifier**, even when it already
   has a project identifier
7. **Every business table has row level security enabled** on that workspace identifier
8. **No foreign key** from a business table to a table in the global data region
9. **Every reference to a person points at `member`, never at `account`**
10. People who leave a workspace are deactivated, **never hard-deleted**

### Events

11. Domain events are written to the outbox table **in the same transaction** as
    the business change
12. Delivery is at-least-once, so **every consumer must be idempotent**
13. Events carry a version field from the very first event
14. The connection that listens for PostgreSQL notifications **must not come from
    the shared connection pool**

### Sync

15. Every data change produces a change log entry whose patch contains **only the
    fields that changed**
16. Mutations go over HTTP POST with an idempotency key, never over the sync stream
17. **Every change that narrows permissions must emit a revocation event**, and the
    client must purge that scope's local data

### Frontend

18. **No Server Actions for business mutations**
19. **No business data fetching in server components**
20. The app area renders entirely on the client; only marketing pages and the
    magic-link landing page render on the server
21. Multiple tabs share **one** sync connection and **one** local writer

### Identity and permissions

22. There are no passwords anywhere. Magic link is the only authentication method
23. Access tokens **never carry a permission list**
24. **A permission bit position is never redefined or reused**
25. All permission checks go through a single entry point that also receives the
    data context, so the permission condition layer can plug in

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
| Documentation language | Vietnamese, with technical terms kept in English |
| This file | English only |
| Code, identifiers, file names | English |
| **Commit messages** | **English**, Conventional Commits |
| Commit granularity | One commit per stage of work; never one large commit at the end |
| Feature status | Lives only in the [feature catalog](docs/03-features/README.md); never duplicated elsewhere |
| Unsettled points | Write `> **Chưa chốt:** …` rather than guessing |
| Diagrams | Mermaid |

---

## Current status

The project **has not started implementation**. Documentation only.

| Part | Status |
|---|---|
| Brief, Requirement, System Design, Features & Roadmap | ✅ Complete |
| UX/UI design, ERD, Detail design | ⬜ Not started |
| `backend/`, `frontend/`, `infra/` | ⬜ Not created |

Next steps on the roadmap: analyse the data model ([ERD](docs/06-erd/) — its
README already lists the nine constraints that model must satisfy), then start
[Phase 0](docs/03-features/roadmap.md#phase-0--nền-tảng).
