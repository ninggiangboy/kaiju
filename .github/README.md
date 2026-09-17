# .github/

The continuous integration pipeline, the pull request template, and the git
hooks. The design, and why each check exists, is documented in
[ci-cd.md](../docs/04-system-design/ci-cd.md) (Vietnamese, like everything under
`docs/`). What the rules mean for you when you push: [CONTRIBUTING.md](../CONTRIBUTING.md).

| File | Runs when |
|---|---|
| `workflows/ci.yml` | Every pull request, and every push to `dev`, `staging` or `production` |
| `workflows/release.yml` | Pushes to `dev` (build and pin) and `staging` (deploy tier 3), and every version tag |
| `workflows/security.yml` | Weekly, and whenever a dependency manifest changes |
| `workflows/pr-hygiene.yml` | Every pull request: title, branch name, promotion order |
| `scripts/check-docs.py` | Inside `ci.yml`, and by hand: `make -C infra check-docs` |
| `scripts/check-runtime-versions.py` | Inside `ci.yml`, and by hand: `make -C infra check-versions` |
| `hooks/pre-push` | Locally, once installed with `make -C infra hooks` |
| `PULL_REQUEST_TEMPLATE.md` | Filled into every new pull request by GitHub |

There is **no production deploy job**, and that is the point: merging the pull
request into `production` is the deployment, and Argo CD reconciles from that
branch. Nothing here issues a command against the cluster.

---

## Four things that are easy to get wrong

### The Gate is the required check, and on two branches it is not the only one

Branch protection declares **`Gate`**, so adding a new job to `ci.yml` never
means editing that configuration. `staging` and `production` carry a second one,
**`Promotion order`**, which lives in `pr-hygiene.yml` — GitHub can require that
a branch only take pull requests, but not say which branch they may come from.

`dev` carries **no** required check at all. The release pipeline pushes the
image-tag pin commit straight to it, and a required status check blocks direct
pushes as well as pull requests.

### A skipped job is a FAILURE

Unless its directory did not change (`CON-71`). Most CI configurations treat a
skipped job as passing; combined with a path filter that is wrong, that is how a
backend change merges without a single test having run.

The Gate also blocks in the other direction: a job that **ran** although its
directory was unchanged is a broken filter too, and it is reported.

### A rollback is exempt from the promotion order

A head branch named `rollback/*` may open a pull request straight into an
environment branch. It carries no new code — it puts the environment back in a
state it was just running. An urgent *fix* is new code and has no exemption.

### Dependabot cannot see half of a version bump

It bumps `FROM node:` in the Dockerfile and has no idea `NODE_VERSION` in
`ci.yml` exists. `scripts/check-runtime-versions.py` compares them, because the
failure mode is a runtime error in an environment rather than a red build.

---

## Running locally

Every check runs from a developer machine (`CON-72`):

```bash
make -C infra check    # all of them
actionlint             # the workflow files themselves
```

---

## Current state

Neither application has been written, so `ci.yml` and `release.yml` both ask
whether `backend/settings.gradle.kts` and `frontend/package.json` exist before
running anything that needs them. Without that, a bump to either Dockerfile
fails on a missing lockfile, and `Build images` fails on every push to `dev` —
and a permanently red workflow is one whose next failure nobody looks at.

Both guards are keyed on the build file rather than the directory, so an empty
scaffold directory does not switch the checks back on before there is anything
to check, and both remove themselves the day those files land.

`release.yml` also needs `STAGING_SSH_KEY` and `STAGING_KNOWN_HOSTS` before it
can deploy tier 3. They are not set yet.
