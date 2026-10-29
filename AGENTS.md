# Repository instructions

## Generative AI disclosure

Read this section before changing files, creating a commit, or opening a pull
request.

When generative AI contributes more than a trivial completion, add both of
these trailers to every assisted commit:

```plain
Assisted-by: <tool>:<model-version>
AI-Scope: <what the tool generated and the prompt or a short prompt summary>
```

Single-line completions, renames, and formatting changes do not need trailers.
Work completed without generative AI does not need trailers.

Before opening a pull request, set `AI assistance` in the pull request template
to `none`, `trivial`, or `disclosed`. Use `disclosed` when at least one commit
has the trailers above. Review every assisted change before submission.

Do not create the commit or pull request until its disclosure matches the work.
`.github/workflows/ai-disclosure.yml` enforces this; its checker is
`.github/scripts/check-ai-disclosure.cjs`.

## This is a meta-repo

- Real source for the shell, the toolkit, and every app is in git submodules
  under `subprojects/`. The root only wires the build (`meson.build`,
  `Makefile`, `scripts/`, `data/`, `Containerfile`, `cpak/`).
- `git submodule status` shows `-` prefixes here: submodules are not checked
  out. Run `git submodule update --init --recursive` before touching code.
- Edit app/shell/toolkit code in its submodule repo and commit there. The
  meta-repo commit only bumps the submodule pointer. Do not copy a submodule's
  files into the root.
- Root `meson.build` is the source of truth for what gets built.
  `CONTRIBUTING.md`'s architecture tree (`src/core`, `src/apps`) is stale: that
  code now lives in `subprojects/singularity-shell` and the `singularity-*`
  submodules.

## Branch and commits

- Default branch is `master` (CONTRIBUTING.md says `main`; the repo and CI use
  `master`). Target PRs at `master`.
- Conventional Commits: `<type>: <subject>` with `feat`, `fix`, `chore`,
  `docs`, `build`, `ci`, `refactor`, `perf`, `style`, `test`, `revert`.

## Build and run

- `make prepare-deps` installs dependencies (Debian, Fedora, openSUSE, Arch,
  Void); add `--dry-run` via `bash scripts/prepare-deps.sh --dry-run` to only
  print.
- `make` is the full build: it first builds labwc, libinput, libfprint (cloned
  into `subprojects/` on demand) and `sit`, then the desktop. A bare
  `meson setup build && meson compile -C build` is not enough on a fresh
  checkout.
- Configuring needs Go to build `subprojects/vetro` (or a system `vetro`), and
  the gesture runtime (`make gesture-runtime`) unless `GESTURES=disabled`.
- App tiers come from `apps.txt`: `-Dapps=all|core|essential` or
  `APPS=all|core|essential` (`SKIP_EXTRA=1`, `SKIP_NONESSENTIAL=1`).
- `make install-app <app>` (for example `messages`) rebuilds and deploys one
  app plus libsingularity. It requires an already-configured `build/`, so run
  `make` once first.
- `make install` deploys to `/opt/local` and needs root (via `run0`).
  `bash scripts/deploy-to-host.sh --root DIR` deploys into a scratch dir as a
  normal user; `--dry-run` lists every installed file.

## Testing and verification

- There is no automated test suite for the shell or apps. `libsingularity` is
  built in CI (`.github/workflows/libsingularity-ci.yml`); `make
  libfprint-test` runs libfprint's tests.
- Builds must be warning-free (`ninja -C build`); CONTRIBUTING asks for zero
  errors and zero warnings.
- `node --test .github/scripts/check-ai-disclosure.test.cjs` tests the
  disclosure checker.

## Conventions worth knowing

- Vala, 4-space indent. No Adwaita in the core shell. No `Gtk.MessageDialog`
  (use `Gtk.InfoBar` or a `SettingsPage`). Store `Timeout`/`Idle` IDs and cancel
  them in `dispose()`. Spawn with `GLib.Subprocess.newv()`, not `sh -c`.
- Headless backends (D-Bus, sysfs, hardware; no GTK) belong in
  `libsingularity-system` (`subprojects/libsingularity/src/system/`), not the
  shell.
- Adding an app needs three edits: submodule in `.gitmodules`, a
  `<name> <tier>` line in `apps.txt`, and a matching `subproject()` in root
  `meson.build`.
- After editing `data/dev.sinty.desktop.gschema.xml`, run `make schemas`.
- `cpak.json`'s `image` digest is rewritten by `cpak-publish.yml`; do not
  hand-edit it.

## Detached fork policy

- This tree is a standalone fork. Only `SrDicov/*` repos are writable:
  `singularity-desktop` plus the four patched submodules (`libsingularity`,
  `singularity-shell`, `singularity-session`, `singularity-write`).
- Never open PRs, issues, comments, releases or pushes against any other repo.
  The unpatched submodules are fetched read-only from their original URLs;
  that is a passive download, not a contribution.
- Keep `origin` as the only writable remote. Do not add an `upstream` remote
  with push access. See `docs/FORK.md` for the re-sync procedure (fetch only).

## Packaging CI concurrency

- `z-packages/.github/workflows/trigger-repos.yml` must not dispatch a build
  while `z-repo` or `z-repo-musl` already has a run that is not `completed`;
  the dispatch is skipped in that case. It also runs with `cancel-in-progress:
  true` so rapid pushes collapse into one trigger.
- The autobuild workflows keep `concurrency.cancel-in-progress: false`; the
  guard in the trigger is what prevents a fresh dispatch from killing a
  running 40-minute build.
