# Detached fork notes

This tree is a standalone fork. It is not intended to contribute changes back
or to send anything to the original upstream. Keep this file as the only place
that describes the relationship.

## Writable remotes

Only the `SrDicov/*` repositories are writable:

| Repo | Purpose |
|---|---|
| `SrDicov/singularity-desktop` | meta-repo (this tree) |
| `SrDicov/libsingularity` | Void fixes: timedate1 fallback, openntpd, GIR bindings |
| `SrDicov/singularity-shell` | hostname without hostnamed |
| `SrDicov/singularity-session` | doas and `/usr` prefix detection |
| `SrDicov/singularity-write` | GTK 4.14 accessible-text stubs |

`origin` in the meta-repo and in those four submodules points there. No
`upstream` remote with push access is configured.

The remaining submodules are unmodified and are cloned read-only from their
original URLs by `git submodule update`. That is a passive fetch, not a
contribution; do not add commits or push to them.

## Rules

- No pull requests, issues, comments, discussions, releases or pushes against
  any repository outside `SrDicov/*`.
- No `gh api` `POST`/`PATCH`/`PUT`/`DELETE` aimed at a foreign repository. The
  only exception is the read-only `gh run list`/`gh release view` used for
  status.
- Publishing workflows target `ghcr.io/srdicov/*` and the `SrDicov` release
  assets.

## Passive re-sync (optional, manual)

Upstream changes are not tracked. If a specific fix is ever wanted, fetch it
read-only into a scratch branch and cherry-pick locally; never push back:

```sh
git remote add upstream-ro https://github.com/singularityos-lab/singularity-desktop
git fetch upstream-ro
git cherry-pick <sha>
git remote remove upstream-ro
```

The same pattern applies to a submodule. Remove the temporary remote when
done so no accidental push is possible.

## Known remaining upstream references

- `cpak.json` keeps `github.com/singularityos-lab/singularity-runtime` as a
  layer dependency. There is no fork of that runtime under `SrDicov`; it is a
  read-only pull at install time.
- The xbps template downloads the unpatched app and gesture sources from their
  original URLs (read-only fetch). The main desktop tarball and the four
  patched submodules come from `SrDicov/*`.
