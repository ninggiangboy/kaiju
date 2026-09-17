<!--
  Title: Conventional Commits, in English - it becomes the merge commit message.
  Example: feat(sync): send a heartbeat on an idle stream

  `Pull request title` in CI checks exactly this, and the type must be one of
  feat fix docs refactor test chore perf build ci infra.

  Promoting an environment? Title it `promote: dev -> staging` and delete the
  rest of this template; the diff is the description. Promotion order is
  enforced: `staging` only takes `dev`, `production` only takes `staging`.

  Rolling back? Branch `rollback/<slug>` off the environment branch, and read
  the Rollback section at the bottom - step 4 is not optional.

  The rules are in CONTRIBUTING.md, the reasoning in docs/04-system-design/git-flow.md.

  Delete every section below that does not apply to this change.
-->

## What this changes

<!--
  One paragraph. The diff already says what changed; say why it changed, and
  what a reviewer should be looking at first.
-->

## Scope

<!--
  Feature identifier from docs/03-features/README.md when there is one, plus the
  ADRs or constraints this touches. Write `none` rather than deleting the line.
-->

- Feature:
- Documents affected (ADR / system design / use case / constraint):

## How this was verified

<!--
  What you actually ran or clicked, not what CI will run for you. If this is a
  documentation-only change, say so.
-->

## Departures from the documentation

<!--
  A change that contradicts something written down updates the documentation in
  the SAME commit, and never erases the decision it replaced. State which
  mechanism was used, or write `none`.

  - An ADR turned out wrong        -> a new ADR, the old one marked Superseded
  - A system design doc is stale   -> a `> **Đã thay đổi (YYYY-MM-DD):**` note
  - A use case gained/lost a branch-> amended, noted in the business-rules table
  - A requirement was wrong        -> same identifier, text updated, note added
  - A feature was dropped          -> row kept, status `DEFERRED`, phase stated
-->

none

## Risk and rollback

<!--
  Only for a change that reaches a running environment. What breaks if this is
  wrong, and how it is undone. Delete this section for a documentation-only or
  backend-not-yet-running change.
-->

- Blast radius:
- How to undo:

---

## Checks

Always:

- [ ] `make -C infra check` passes locally - the same static checks CI runs
- [ ] Commits are in English, Conventional Commits, one per stage of work
- [ ] Documentation updated in the same commit, with the replaced decision kept visible
- [ ] Any README this makes wrong is updated in the same commit
- [ ] No CI job was skipped that should have run - a skipped job counts as failed

Touching the backend:

- [ ] No module imports another module's internals - only its `api` package
- [ ] No query or `JOIN` reaches a table another module owns
- [ ] Cross-module communication is a domain event, written to the outbox in the same transaction
- [ ] Every new business table carries the workspace identifier, has row level security, and no foreign key into the global region
- [ ] Every reference to a person points at `member`, never at `account`
- [ ] Every new action declares exactly one required permission, checked in the handler
- [ ] No permission bit position was reused or redefined

Touching data the client holds:

- [ ] The change emits a change log entry whose patch carries only the fields that changed
- [ ] Anything that narrows permissions emits a revocation event, and the client purges that scope

Touching migrations:

- [ ] Every changeset has a hand-written rollback, and `make -C infra db-down` was run against it
- [ ] Nothing runs migrations at application startup, in any tier
- [ ] The change is backward-compatible with the currently deployed application

Touching the frontend:

- [ ] No Server Action for a business mutation, and no business data fetched in a server component
- [ ] Main-flow interactions are optimistic - no spinner standing in for one

Touching `infra/` or `.github/`:

- [ ] One image still runs in all four tiers - no branch on the environment name
- [ ] Deployments pin an immutable image tag bound to a commit
- [ ] The deployment order still holds: migration -> `worker` and `scheduler` -> `api` and `realtime`

<!--
  Rollback (`rollback/*` into an environment branch) - the four steps are in
  docs/04-system-design/git-flow.md#quay-lui. Step 4, bringing the revert back
  to `dev`, is not optional: the reverted commits are still ancestors of the
  environment branch, so the next promotion will not restore them on its own.

  - [ ] The revert carries no new code
  - [ ] A follow-up pull request brings the revert back to `dev`
-->
