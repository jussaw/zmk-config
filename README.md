# zmk-config

Personal [ZMK](https://zmk.dev) firmware configs for my keyboards. One repo, one GitHub Actions
build per keyboard — push, then download the `.uf2` artifacts and flash.

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
| `build.yaml` | **Shared** GitHub Actions build matrix — one `include` entry per board/shield target |
| `.github/workflows/build.yml` | Workflow that runs the ZMK user-config build |
| `boards/shields/` | Local shield overrides (currently empty) |

ZMK matches a config file to a shield by name (the `_left`/`_right` side suffix is stripped), so
`corne_left` and `corne_right` both read `config/corne.keymap` / `config/corne.conf`.

## Adding another keyboard

1. **Add the config files** — `config/<board>.keymap` and `config/<board>.conf`, named to match the
   shield (e.g. `config/lily58.keymap` for a `lily58` shield).
2. **Add build target(s)** — append the board/shield combo(s) to the `include:` list in
   [`build.yaml`](build.yaml), each with an `artifact-name`. Add `snippet` / `cmake-args` (e.g. for
   ZMK Studio) as needed.
3. **Add dependencies (if any)** — if the keyboard needs extra modules (custom board, shield, or
   display), add the remote and project to [`config/west.yml`](config/west.yml).
4. **Local shields (optional)** — drop a local shield definition under `boards/shields/` if the
   keyboard isn't upstream.
5. **Push** — GitHub Actions builds every target in `build.yaml`; grab that keyboard's `.uf2`
   artifact(s) from the run.

## Building & flashing

Firmware is built entirely in **GitHub Actions** — there is no local build step.

1. Push to `main` (or open a pull request) to trigger the build.
2. Open the run under the repo's **Actions** tab and download the `.uf2` artifacts (named per the
   `artifact-name` in `build.yaml` — e.g. `corne_left`, `corne_right`).
3. Put each half/board into bootloader mode (double-tap reset) and copy its `.uf2` onto the USB
   drive it exposes (e.g. `NICENANO`).

For the Corne, the left half is built with **ZMK Studio** support (`studio-rpc-usb-uart` snippet +
`CONFIG_ZMK_STUDIO=y`), so it can be edited live via [ZMK Studio](https://zmk.dev/docs/features/studio);
the right half is built without it.

## Dependencies

Pinned in [`config/west.yml`](config/west.yml), all tracking `main`:

- [`zmk`](https://github.com/zmkfirmware/zmk) — core firmware
- [`nice-view-gem`](https://github.com/M165437/nice-view-gem) — custom display module (Corne)
- [`zmk-behavior-socd`](https://github.com/nguyendown/zmk-behavior-socd) — SOCD cleaning behavior (Corne)
