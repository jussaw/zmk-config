# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal [ZMK](https://zmk.dev) config repo that hosts **one or more keyboards**. It follows the
standard `zmk-config` layout, so adding a keyboard is a drop-in — no restructuring. Currently the
only keyboard is a Corne split.

Each keyboard is:
- a `config/<board>.keymap` + `config/<board>.conf` pair (ZMK matches these to a shield by name; the
  `_left`/`_right` side suffix is stripped, so `corne_left`/`corne_right` both read `config/corne.*`), plus
- one or more `include:` entries in `build.yaml` (the build matrix).

`config/west.yml` (the west manifest) and `build.yaml` are **shared** across all keyboards. To add a
keyboard: add its `config/<board>.*` files, append its board/shield combo(s) to `build.yaml` with an
`artifact-name`, and — only if it needs extra modules — add a remote/project to `config/west.yml`.

## Read the README first

[`README.md`](README.md) is the source of truth for everything about the hardware and the build — it
is deliberately **not** duplicated here, because the copy in this file drifted out of date. Consult
it for:

| Topic | Section |
|---|---|
| Layers, keymap layout, bluetooth profile assignments | *Corne → Layers* |
| Hardware, board IDs, shields, displays | *Corne → Hardware* |
| Custom behaviors (`hm`, `HYPER`, `socd`) | *Corne → Custom behaviors* |
| Pointing/mouse tuning and power settings | *Corne → Pointing / mouse*, *Power* |
| Building in CI or locally via `build.sh`, and flashing | *Building & flashing* |
| Repository layout | *Repository layout* |
| Dependency pins and how to bump them | *Dependencies* |

Two constraints worth knowing before touching `config/west.yml`: every project is pinned to a commit
SHA, and `zmk` and `nice-view-gem` must be bumped **together** — the module tracks ZMK's internal
API. The README's *Dependencies* section has the procedure.

## Git Commits

Follow [Conventional Commits](https://www.conventionalcommits.org/): `type(scope): summary`. Keep the summary in lowercase, imperative mood ("add", not "added"/"adds"), with no trailing period and ≤ 72 characters. Add a body (blank line, then prose) only when the *why* isn't obvious from the summary.

| Type | Use for |
|---|---|
| `feat` | New keys, layers, or behaviors |
| `fix` | Correcting broken keymap or config behavior |
| `refactor` | Restructuring without changing behavior (e.g. renaming a layer) |
| `docs` | README, CLAUDE.md, or in-file comments |
| `build` | `build.yaml`, `config/west.yml`, or firmware-target changes |
| `chore` | Tooling, metadata, or housekeeping |

Common scopes: `keymap`, `conf`, `build`, `west`. Scope is optional but preferred when a change is confined to one area.

Examples:
- `feat(keymap): add BT_CLR_ALL key to SETTINGS layer`
- `refactor(keymap): rename WINDOWS layer to BASE`
- `docs: document layers and build flow in README`
- `build: add settings_reset firmware target`

Keep each commit focused on a single logical change; don't mix keymap edits with unrelated doc or build changes.
