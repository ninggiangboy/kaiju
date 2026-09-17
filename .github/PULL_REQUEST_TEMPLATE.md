<!--
  Title: Conventional Commits, in English - it becomes the merge commit message.
  Example: feat(sync): send a heartbeat on an idle stream

  Promoting an environment? Title it `promote: dev -> staging` and delete the
  rest of this template; the diff is the description.

  The rules are in CONTRIBUTING.md, the reasoning in docs/04-system-design/git-flow.md.
-->

## What this changes

<!-- One paragraph. The diff says what; say why. -->

## Checks

- [ ] `make -C infra check` passes locally
- [ ] Commits are in English, one per stage of work
- [ ] Documentation updated in the same commit, with the replaced decision kept visible
- [ ] Any README this makes wrong is updated in the same commit
