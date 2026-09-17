# infra/

The four environment tiers and what it takes to stand them up. Why each tier
exists, and which class of failure **only that tier** catches, is documented in
[environments.md](../docs/04-system-design/environments.md) (Vietnamese, like
everything under `docs/`).

---

## Getting started

```bash
cd infra
make up        # tier 1 - enough to run the backend and the test suite
make db-up     # apply migrations; nothing migrates on startup (CON-68)
make up-dev    # tier 2 - adds the operational layer
make check     # every static check, exactly as CI runs them
```

`make` with no target lists every command.

---

## The four tiers

| Tier | Stood up by | What only it catches |
|---|---|---|
| `local-mini` | `compose/docker-compose.yml` | Everything **unrelated** to the environment: logic, migrations, module boundaries |
| `dev` | plus `compose/docker-compose.dev.yml` | Session-state violations, a buffered sync stream, a broken trace, a role missing config once split out |
| `staging` | `staging/docker-compose.yml` on a VPS | The behaviour of **real services**: mail landing in spam, signed links, real TLS and a real domain |
| `production` | `k8s/overlays/production` | Multiple replicas of one role: sequence contention, the anti-overlap lock, cross-replica broadcast, rolling deployment |

**The same image runs in all four** (`CON-66`). The role is selected through
`KAIJU_ROLE`; everything else that differs is an environment variable. Nothing
branches on the environment name (`CON-67`).

---

## Ports on a developer machine

| | Tier 1 | Tier 2 |
|---|---|---|
| Database | 5432 | 5432 (direct) and **6432** (pooled) |
| Redis-protocol server | 6379 | 6379 |
| Mail — web interface | **8025** | 8025 |
| Object storage — console | 9001 | 9001 |
| App through the reverse proxy | — | **8080** |
| Observability — interface | — | **3001** |

Observability sits on 3001 rather than 3000 because 3000 is reserved for Next.

---

## Three details that are easy to get wrong

### `KAIJU_DB_URL` and `KAIJU_DB_DIRECT_URL` are two different variables

At tier 1 they point at the same place, and they **still stay separate**. From
tier 2 onward, ordinary reads and writes go through the connection pooler while
the notification listener connects **directly** — under transaction pooling,
listening never works through a pooler (`CON-25`).

Write them apart from the first line of code, rather than retrofitting the
split when the pooler arrives.

### Migrations are never a side effect of starting the application

No tier migrates at startup (`CON-68`). The schema moves because somebody ran
`make db-up`, or because the deploy step ran the `migrate` service before
bringing any role up. `make db-down` reverts, `make db-status` shows where
things stand.

Two consequences worth remembering:

- The application starts fine against an out-of-date schema. The `api` health
  check is what reports not-ready, so trust it rather than "the container is up".
- `make db-down` does **not** bring back data the up direction dropped. Tier 4
  forbids the down direction outright and rolls forward instead (`CON-75`).
  Tier 3 **does** allow it, through `ansible/migrate-staging.yml`, which records
  every run — a hand-written rollback nobody has executed is not a rollback, and
  staging is the only place it can be proven (`CON-80`).

The migration runner connects through `KAIJU_DB_DIRECT_URL`, not the pooled
URL — its changelog lock is session-scoped and would not survive transaction
pooling (`CON-62`).

### Buffering must be off for the sync stream

That is the entire reason `proxy/Caddyfile.*` exists, and the reason for the
`proxy-buffering: off` annotation in `k8s/base/ingress.yaml`. Getting it wrong
produces **no error at all** — the only symptom is "realtime does not work".

`scripts/smoke.sh` carries a check dedicated to it.

---

## Who changes what

Four tools, each owning one layer, and none reaching into another's
([ADR-0014](../docs/adr/0014-declarative-infra-gitops.md)). When something needs
changing, this table says where.

| Tool | Owns | Recognise it by |
|---|---|---|
| **OpenTofu** (`tofu/`) | Database, object storage, mail, cluster, node pools | Losing it loses data |
| **Ansible** (`ansible/`) | Configuration inside a machine that already exists; tier 3 deployment | It can be rebuilt |
| **Argo CD** (`argocd/`) | Everything running inside the tier 4 cluster | Desired state is in git |
| **This Makefile** | Tiers 1-2, and the static checks | A person runs it |

Two rules keep them from fighting:

**OpenTofu never creates a Kubernetes object.** If it did, it and Argo CD would
both believe they own that object, and the loop that follows is hard to unpick
once it is live.

**The Makefile never writes to the desired state of tiers 3-4** (`CON-78`).
There is no `make deploy-production`, and that is not an omission — two things
able to change production is two things that will disagree about it.

### How a change reaches production

```
merge to main        → build an image, tag it with the commit. Nothing deploys.
push a version tag   → Ansible deploys tier 3, then a pull request is opened
                       that bumps the image tag in the production overlay
merge that PR        → Argo CD reconciles. THIS is the deployment.
git revert that PR   → rollback
```

The merged pull request is the approval gate, and it shows exactly which tag is
replacing which. Argo CD enforces the mandatory order (`CON-69`) with sync
waves: migration as a `PreSync` hook, then `worker` and `scheduler`, then `api`
and `realtime`.

> **Not wired up yet.** No cloud account, no cluster, no host. The manifests,
> stacks and playbooks are written and checked; none has been applied.

---

## Secrets

No real secret lives in the repository, **not even for tier 1**.

| Tier | Secrets come from |
|---|---|
| 1, 2 | Fake values in `env/*.env.example`; the database cluster is thrown away on every rebuild |
| 3 | `/etc/kaiju/staging.env` on the host, mode `600` |
| 4 | The orchestrator Secret `kaiju-secrets` |

A missing required variable makes the application **stop at startup**. Failing
early beats running wrong in silence.

---

## Layout

```
infra/
├── Makefile                      # tiers 1-2, and every static check
├── compose/
│   ├── docker-compose.yml        # tier 1
│   └── docker-compose.dev.yml    # tier 2, layered on tier 1
├── staging/
│   └── docker-compose.yml        # tier 3, a single VPS
├── k8s/
│   ├── base/                     # tier 4, four roles + the migration job
│   └── overlays/{staging,production}/   # each pins its own image tag
├── argocd/                       # tier 4 Applications - what reconciles the above
├── ansible/                      # tier 3 deployment, and self-managed cluster nodes
├── tofu/                         # cloud resources: database, object storage, mail
├── docker/                       # backend and frontend Dockerfiles
├── proxy/                        # Caddyfile.dev and Caddyfile.staging
├── pgbouncer/                    # pooler configuration, shared with CI
├── postgres/init/                # extensions only, no table structure
├── scripts/                      # deploy-staging.sh, smoke.sh
└── env/                          # samples for all four tiers, fake values only
```

The CI pipeline and the path from a commit to each tier:
[ci-cd.md](../docs/04-system-design/ci-cd.md).
