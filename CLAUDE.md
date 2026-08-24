# ampremote contributor notes

This repo is an [mbm](https://github.com/andrewleech/micropython-branch-manager)-managed
integration of `mpremote` from `micropython/micropython` with extra PRs and
local-only patches applied. The set of branches in the integration lives in
`mbm.toml`; the integration branch in the submodule is `ampremote`.

## When to add a feature here vs upstream

Default to upstream. Any improvement that has general value should be raised
as a PR against `micropython/micropython` first. The ampremote integration
exists to consume those PRs early, not to replace upstream work.

Keep local-only when:

- The change is specific to this distribution (e.g. the `ampremote_rename`
  branch swaps the package and CLI names; that has no upstream home).
- The change is too speculative for upstream and needs hardware validation
  first; raise it as a draft PR on the fork (see "Draft PRs on the fork"
  below) and only promote to upstream once validated.

If a change starts local and is later validated, change its base in the PR
to `micropython:master` rather than opening a new PR -- the discussion and
review history stays attached.

## Adding an upstream PR to the integration

```bash
mbm add-pr <PR-number>
```

mbm fetches the PR from `upstream`, creates an `ampremote_update` working
branch from `ampremote`, merges the PR with a generated message containing
PR metadata trailers, and updates `mbm.toml`. On merge conflict it stops;
resolve and `git merge --continue`, then fast-forward `ampremote` to the
new tip:

```bash
git -C micropython branch -f ampremote ampremote_update
```

`git rerere` is enabled and the existing resolutions are in
`.git/modules/micropython/rr-cache/`. Future rebuilds replay them
automatically.

## Adding a local-only branch

1. Branch from upstream master in the submodule:
   ```bash
   git -C micropython checkout -b <branch> master
   ```
2. Make and commit the change.
3. Push to the andrewleech fork:
   ```bash
   git -C micropython push fork <branch>
   ```
4. Register manually in `mbm.toml`. mbm's PR lookup will fail without a
   PR number, so add the entry by hand with `pr_url` pointing at the fork
   branch:
   ```toml
   [[submodules.branches]]
   name = "<branch>"
   pr_url = "https://github.com/andrewleech/micropython/tree/<branch>"
   title = "<one-line description>"
   ```
   Insert it in the order it should merge. Functional changes go before
   `ampremote_rename`, which must always be last.
5. Merge into the integration branch:
   ```bash
   git -C micropython checkout ampremote_update
   git -C micropython merge <branch>
   git -C micropython branch -f ampremote ampremote_update
   ```
6. Commit the submodule pointer bump in the top-level repo.

## Draft PRs on the fork

For changes that aren't ready to surface to upstream maintainers but
benefit from a PR-shaped artifact (description, diff view, CI), open a
draft PR within the fork itself:

```bash
gh pr create --repo andrewleech/micropython \
    --base master --head <branch> --draft \
    --title "<title>" --body "..."
```

Both base and head are on the fork, so upstream maintainers are not
notified. Switch the base to `micropython:master` once the change is
validated and ready for upstream review.

## Rebuilding the integration on new upstream

```bash
mbm rebase --local
```

**Always `--local`.** Without it mbm's push routing targets `upstream`, not
the fork.

**Never finish a stopped rebase with `git rebase --continue`.** Resolve the
conflict, `git add` it, then hand back to `mbm rebase --resume --local`, which
continues the rebase itself. `--resume` only continues a rebase it can still
see: with no `rebase-merge` directory it restarts at the branch *after* the
index in `mbm-rebase-state.json`, so finishing by hand silently drops that
branch's merge from the integration. Measured 2026-08-25 - three of seven
branches went missing that way, and the rebuild still reported success.

Check the result by content, not by the merge list: assert a marker for every
registered branch (`verify_hash`, `DeflateIO`, the rename in `pyproject.toml`)
before force-moving `ampremote`.

Tag every branch tip before rebuilding, so restoring afterwards is a diff
rather than a reconstruction:

```bash
git -C micropython for-each-ref --format='%(refname:short)' refs/heads/ \
  | while read b; do git -C micropython tag -f "snap/$b" "$b"; done
```

A PR that has merged upstream must be deregistered: composing it replays
commits the base already has. A *partly* merged PR is worse, because
`git cherry` under-reports it - upstream reworks commits in review, so their
patch-ids no longer match. Compare subjects against upstream's log as well.

This rebuilds `ampremote` from upstream master plus the branches in
`mbm.toml`, in order. rerere replays prior conflict resolutions. After
the rebuild, push the new `ampremote` SHA to the fork and commit the
submodule pointer in the top-level repo.

## Testing

Hardware in the loop is required for anything touching serial transport
or device communication. Use `mpy-dev --help` to see the registered debug
probes and their serial numbers; never reference programmers or tty
devices by transient `/dev/tty*` paths in a script.

Unit tests for mpremote live in `micropython/tools/mpremote/tests/`.
They're shell scripts that exercise mpremote against a real device set
via `$MPREMOTE`. Run the relevant ones after any change to mpremote.

## Style for new mpremote code

Match the existing house style in `tools/mpremote/`:

- Inline byte literals for control characters with a trailing comment
  describing intent (e.g. `b"\x03"  # ctrl-C: interrupt`). The file does
  not define constants for control bytes.
- Prefer extending the existing `read_until` and `exec` primitives over
  adding new abstractions.
- New parameters on existing methods should default to the previous
  behaviour so unmodified callers see no change.
- Functions added for one specific caller should be marked with a leading
  underscore.

## Package / CLI naming

The `ampremote_rename` branch retargets the pip package to `ampremote`
and adds `ampr` as a second CLI entry point. The Python module is still
`mpremote` (so `import mpremote` and internal references remain
unchanged); only the distribution name and console scripts differ. Keep
upstream-bound changes referring to `mpremote`; the rename branch is the
single place where the substitution happens.
