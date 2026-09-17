# Contributing

What you need before you push. It is short on purpose — the reasoning lives in
[git-flow.md](docs/04-system-design/git-flow.md), and this file only tells you
what to do and what will stop you.

```bash
make -C infra hooks   # once per clone
```

That points git at [`.github/hooks/pre-push`](.github/hooks/pre-push), which
refuses a push the server would refuse anyway — but tells you here, before the
upload, instead of after it.

---

## The flow

```
<type>/<slug> ──PR──> dev ──PR──> staging ──PR──> production
```

1. **Branch off `dev`.** Name it `<type>/<slug>`, where `type` is one of
   `feat` `fix` `docs` `refactor` `test` `chore` `perf` `build` `ci` `infra`.
   Use the feature identifier when there is one: `feat/kj-sync-07-catch-up`
2. **Commit per stage of work**, in English, Conventional Commits. Never one
   large commit at the end
3. **Run `make -C infra check`** — the same static checks CI runs
4. **Push, and open the pull request in the same breath.** A pushed branch with
   no pull request is invisible: nothing reviews it, no check is required of it,
   and it drifts behind `dev` while everyone assumes it is in flight. Open it
   into `dev`, and give it a title in the same form as a commit message, because
   it becomes the merge commit's message
5. **Promote** by opening a pull request from `dev` to `staging`, and later from
   `staging` to `production`

Merging a promotion pull request **is** the deployment. There is no deploy
button, and nothing outside git decides what an environment runs.

---

## What will reject your pull request

| Check | Rule |
|---|---|
| `Gate` | Every job that should have run for the directories you touched ended in success. A **skipped** job counts as a failure unless its directory did not change |
| `Promotion order` | `production` only takes pull requests from `staging`, and `staging` only from `dev`. The one exemption is a `rollback/*` branch |
| `Pull request title` | Conventional Commits, in English |
| `Branch name` | `<type>/<slug>`. Advisory on `dev` — it shows red but cannot block, because `dev` cannot carry required checks |

`Gate` and `Promotion order` are the required checks on `staging` and
`production`. `dev` has none: the release pipeline pushes the image-tag pin
commit straight to it, and a required check would block that push too.

---

## Things that are never done

| | Why |
|---|---|
| Force-push, rebase or delete `dev`, `staging`, `production` | They record what each environment ran |
| Cherry-pick between environment branches | New hashes, so the change reappears at the next promotion |
| Squash or rebase merges | Both are disabled on the repository, for the same reason |
| A shortcut into `production` for an urgent fix | New code has no exemption. Roll back first, fix afterwards |
| Migrations at application startup, at any tier | They are an explicit, two-way operation |

---

## Rolling back

A `rollback/*` branch is the only one allowed to open a pull request straight
into an environment branch, because a revert carries no new code.

It comes with an obligation that is **not** optional: bring the revert back to
`dev` afterwards. The reverted commits are still ancestors of the environment
branch, so the next promotion will not restore them on its own. The four steps
are in [git-flow.md](docs/04-system-design/git-flow.md#quay-lui).

---

## Documentation is part of the change

- Documentation under `docs/` is Vietnamese; everything else, including this
  file and every comment in a script or manifest, is English
- A change that departs from what the documentation says **updates the
  documentation in the same commit**, and never erases the decision it replaced
- A change that makes a README wrong updates that README in the same commit

The mechanism for each kind of departure — new ADR, `Đã thay đổi` note, keeping
an identifier while changing its text — is in [`CLAUDE.md`](CLAUDE.md).
