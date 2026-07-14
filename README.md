# zmk-config

Personal [ZMK](https://zmk.dev) firmware configs for my keyboards. Build in **GitHub Actions**
(push, then download the `.uf2` artifacts) or **locally** with the bundled container script
([`build.sh`](build.sh)) — then flash.

The repo is keyboard-agnostic: each keyboard is a `config/<board>.keymap` + `config/<board>.conf`
pair plus one entry in [`build.yaml`](build.yaml). See [Adding another keyboard](#adding-another-keyboard).

## Keyboards

| Keyboard | Controllers | Displays | Config | Details |
|---|---|---|---|---|
| [Corne](#corne) (42-key, 3×6+3 split) | nice!nano | nice-view-gem | `config/corne.*` | Colemak-DH, home-row mods, gaming layer |

---

## Corne

Wireless [Corne](https://github.com/foostan/crkbd) split running on nice!nano controllers with
nice-view-gem displays. The base layer is **Colemak-DH** with home-row mods, plus symbol,
number/navigation, media/mouse, settings, and gaming layers.

### Hardware

| Part | Detail |
|---|---|
| Controllers | [nice!nano](https://nicekeyboards.com/nice-nano/) (board ID `nice_nano//zmk`) |
| Shields | `corne_left` / `corne_right` |
| Displays | [nice-view-gem](https://github.com/M165437/nice-view-gem) on `nice_view_adapter` |
| Keyboard name | `jussaw-corne` |

### Layers

```
0  BASE      — Colemak-DH, home row mods (LGUI/LALT/LCTL/LSFT on A R S T)
1  LOWER     — Symbols (!, @, #…) and brackets
2  UPPER     — Numbers, F-keys, navigation
3  ADJUST    — Media keys, mouse movement, and scroll (conditional: LOWER + UPPER)
4  SETTINGS  — Bluetooth profile selection (BT0–BT4), game toggle
5  GAME      — QWERTY, no home row mods, modifiers on bottom row
```

`ADJUST` is a conditional layer that activates automatically when `LOWER` and `UPPER` are held
together. `GAME` is toggled on/off from the `SETTINGS` layer (and from its own bottom-right thumb
key).

The full ASCII layout for every layer lives in the comments above each layer block in
[`config/corne.keymap`](config/corne.keymap).

#### Bluetooth profiles

| Profile | Device |
|---|---|
| BT0 | Windows desktop |
| BT1 | Personal MacBook Air |
| BT2 | Work MacBook Pro |
| BT3 / BT4 | unassigned |

Select a profile from the `SETTINGS` layer; `BT CLR` clears the current profile's pairing.

### Custom behaviors

- **`hm` (home_row_mod)** — `tap-preferred` hold-tap, 200 ms tapping term, `require-prior-idle-ms = 125`. Provides modifier access (GUI/Alt/Ctrl/Shift) on the home row of the `BASE` and `UPPER` layers.
- **`HYPER`** — `#define` expanding to `LC(LS(LA(LGUI)))` (Ctrl+Shift+Alt+GUI). Bound as `&kp HYPER` on the left thumb of every non-gaming layer.
- **`socd` (SOCD cleaning)** — from the [zmk-behavior-socd](https://github.com/nguyendown/zmk-behavior-socd) module, applied to `A`/`D` on the `GAME` layer so opposing simultaneous presses resolve to the last input.

### Pointing / mouse

`CONFIG_ZMK_POINTING=y` enables mouse emulation, used on the `ADJUST` layer. Movement and scroll
speeds are tuned above ZMK defaults:

- `ZMK_POINTING_DEFAULT_MOVE_VAL = 1500` (default 600)
- `ZMK_POINTING_DEFAULT_SCRL_VAL = 20` (default 10)

### Power

Deep sleep enabled (`CONFIG_ZMK_SLEEP=y`) with a 15-minute idle timeout
(`CONFIG_ZMK_IDLE_SLEEP_TIMEOUT=900000`). BLE TX power is boosted (`CONFIG_BT_CTLR_TX_PWR_PLUS_8=y`).

---

## Repository layout

| Path | Purpose |
|---|---|
| `config/<board>.keymap` | Per-keyboard layers and custom behaviors (DeviceTree syntax) — e.g. `config/corne.keymap` |
| `config/<board>.conf` | Per-keyboard Kconfig options — display, BLE, sleep, pointing — e.g. `config/corne.conf` |
| `config/west.yml` | **Shared** west manifest — pins ZMK and module dependencies for every keyboard |
| `build.yaml` | **Shared** build matrix (GitHub Actions **and** `build.sh`) — one `include` entry per board/shield target |
| `build.sh` | **Shared** local build script — `./build.sh <keyboard>` builds its `build.yaml` targets in a container |
| `.github/workflows/build.yml` | Workflow that runs the ZMK user-config build |
| `boards/shields/` | Local shield overrides (currently empty) |
| `firmware/` | Local build output — `.uf2`s written by `build.sh` (gitignored) |
| `.zmk/` | ZMK CLI's local copy of ZMK + modules (gitignored) |

ZMK matches a config file to a shield by name (the `_left`/`_right` side suffix is stripped), so
`corne_left` and `corne_right` both read `config/corne.keymap` / `config/corne.conf`.

## ZMK CLI

This repo uses the standard `zmk-config` layout, so the [ZMK CLI](https://zmk.dev/docs/zmk-cli)
(`zmk`) can manage it. Install it with [uv](https://docs.astral.sh/uv/) — `uv tool install zmk` — and
run `zmk init` to clone this repo onto a new machine.

| Command | Does |
|---|---|
| `zmk code corne` | Open `config/corne.keymap` in your editor (`--conf corne` for the `.conf`, `--build` for `build.yaml`) |
| `zmk keyboard add` | Add a supported keyboard to the build — writes its `build.yaml` entry + starter `config/*` files |
| `zmk keyboard new` | Scaffold a brand-new keyboard from a template |
| `zmk keyboard list` | List supported keyboard hardware |
| `zmk module add <url>` | Add a Zephyr module dependency to `config/west.yml` |
| `zmk module list` | List installed modules |
| `zmk update` | Update the CLI's local ZMK + module copies (in `.zmk/`) |
| `zmk dl` | Open the GitHub Actions page to download built firmware |

The CLI does **not** compile firmware — use [GitHub Actions or `build.sh`](#building--flashing) for
that. Its `.zmk/` workspace is separate from `build.sh`'s container workspace.

## Adding another keyboard

The [ZMK CLI](#zmk-cli) automates the mechanical parts:

```bash
zmk keyboard add        # pick a supported keyboard; writes its build.yaml entry + config/*.keymap|.conf
zmk module add <url>    # only if it needs an extra module (custom board / shield / display)
zmk code <keyboard>     # open the generated keymap to customize it
```

Under the hood that touches the same files you can also edit by hand:

1. **Config files** — `config/<board>.keymap` and `config/<board>.conf`, named to match the shield
   (e.g. `config/lily58.keymap` for a `lily58` shield).
2. **Build target(s)** — an `include:` entry per board/shield in [`build.yaml`](build.yaml), each with
   an `artifact-name` (plus `snippet` / `cmake-args`, e.g. for ZMK Studio).
3. **Dependencies** — extra modules (custom board, shield, or display) as a remote + project in
   [`config/west.yml`](config/west.yml).
4. **Local shields (optional)** — a local shield definition under `boards/shields/` if it isn't upstream.

Then **build**: push for GitHub Actions, or run `./build.sh <keyboard>` locally — no script changes
needed, since `build.sh` reads the new targets straight from `build.yaml`.

## Building & flashing

Build in **GitHub Actions** (zero setup) or **locally** with [`build.sh`](build.sh) (fast iteration).
Both read `build.yaml`, so they produce identical firmware.

### In GitHub Actions

1. Push to `main` (or open a pull request) to trigger the build.
2. Download the `.uf2` artifacts — open the run under the repo's **Actions** tab, or run `zmk dl` to
   jump straight there. Artifacts are named per the `artifact-name` in `build.yaml` (e.g. `corne_left`,
   `corne_right`).

### Locally with `build.sh`

[`build.sh`](build.sh) builds every `build.yaml` target for a keyboard inside the official
`zmkfirmware/zmk-build-arm` container, so **no host toolchain** (Zephyr SDK, west, CMake) is needed —
only **Docker or Podman**.

```bash
./build.sh corne        # builds all `corne*` targets -> firmware/corne_left.uf2, corne_right.uf2
```

`./build.sh <keyboard>` builds every `build.yaml` entry whose `artifact-name` matches (equals
`<keyboard>` or starts with `<keyboard>_`), mirroring the CI recipe exactly (same board, shield,
snippet, and `cmake-args`). Outputs land in `firmware/` (gitignored).

The first run pulls the image (~3 GB) and clones Zephyr into a cached `zmk-config-west` volume;
later runs skip that and rebuild incrementally. On SELinux systems (e.g. Fedora) the script handles
bind-mount labeling itself.

| Env var | Default | Purpose |
|---|---|---|
| `ZMK_RUNTIME` | auto (docker, else podman) | Force `docker` or `podman` |
| `ZMK_IMAGE` | `zmkfirmware/zmk-build-arm:stable` | Override the build image |
| `PRISTINE` | `0` | Set `1` to force a clean rebuild |

### Flashing

Put each half/board into bootloader mode (double-tap reset) and copy its `.uf2` onto the USB drive it
exposes (e.g. `NICENANO`).

For the Corne, the left half is built with **ZMK Studio** support (`studio-rpc-usb-uart` snippet +
`CONFIG_ZMK_STUDIO=y`), so it can be edited live via [ZMK Studio](https://zmk.dev/docs/features/studio);
the right half is built without it.

## Dependencies

Pinned in [`config/west.yml`](config/west.yml), all tracking `main` (add more with
`zmk module add <url>`; refresh the CLI's local copies with `zmk update`):

- [`zmk`](https://github.com/zmkfirmware/zmk) — core firmware
- [`nice-view-gem`](https://github.com/M165437/nice-view-gem) — custom display module (Corne)
- [`zmk-behavior-socd`](https://github.com/nguyendown/zmk-behavior-socd) — SOCD cleaning behavior (Corne)
