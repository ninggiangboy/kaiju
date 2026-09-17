# infra/tofu/

Cloud resources that have their own lifecycle — the ones where losing the
resource means losing data. Everything that *runs inside the cluster* belongs to
Argo CD instead, and everything *inside an existing machine* belongs to Ansible
(ADR-0014).

> **Nothing here has been applied yet.** There is no cloud account wired up. The
> code is written and formatted, not proven.

---

## The rule that keeps this from fighting Argo CD

**This directory never creates a Kubernetes object** (CON-76). No `kubernetes`
provider, no `Deployment`, no `Service`, no `ConfigMap`. It builds the cluster
and the stateful services around it, then stops.

Break that rule and OpenTofu and Argo CD both believe they own the same object:
Argo syncs it back to git, the next `apply` overwrites it again, and the loop is
very hard to unpick once it is live.

---

## Why AWS first

RDS, S3 and SES were the services actually asked for, and they are AWS names.
Only one cloud is implemented because a second, unused module is twice the
maintenance for something nothing has exercised.

**A second cloud is a sibling of `modules/aws/` implementing the same outputs.**
That list is in [`modules/aws/outputs.tf`](modules/aws/outputs.tf) and it is the
whole portability story. Resources themselves do not abstract — `aws_db_instance`
and its Azure and GCP counterparts have nothing in common — but the values the
application consumes do:

```
db_url  db_direct_url  object_storage_endpoint  object_storage_bucket
mail_host  mail_port  mail_dns_records
```

The application never learns which cloud it is running on, the same way it never
learns which tier it is running in (CON-67).

---

## Layout

```
tofu/
├── bootstrap/        # the state bucket; run once, by hand, before anything else
├── modules/aws/      # the implementation
└── environments/     # one stack per tier, each pinning its own state key
```

---

## Running it

```bash
cd infra/tofu/environments/staging
cp terraform.tfvars.example terraform.tfvars   # fill in the REPLACE values
tofu init
tofu plan
```

`bootstrap/` must have been applied first, or `init` has nowhere to put state.

---

## Two things that will bite

### The state file contains secrets

The database password and the SMTP credentials are in it, readable. It lives in
an encrypted remote backend and is never committed — the same rule as every
other secret in this project. Treat `tofu output` as the boundary: values go
from there into the platform's secret store, never into a file in the repository.

### SES starts in the sandbox, and getting out takes days

A new account can only send to verified addresses, at 200 messages a day. Moving
to production access means opening a support request and waiting.

Because magic link is the only way to sign in, that limit does not mean "mail is
degraded" — it means **nobody can sign in who was not already on the list**. Ask
for production access as early as possible, well before it is needed, rather than
discovering it on the day staging goes up.
