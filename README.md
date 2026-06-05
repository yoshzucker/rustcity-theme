# rustcity-theme

A dual light/dark Emacs theme inspired by the forgotten neon fringes of an industrial port city.

- **neon** (dark): Deep industrial night, heavy with the glow of signage that no one is left to read. Empty streets, the quiet tension between remaining neon shops and the workers who once filled them, and the economic codependence that lingers after dark.
- **downpour** (light): The washed-out morning after a torrential rain. Neon reflections pool in gutters and potholes. No one is on the street yet; only the memory of the previous night remains in the water and the rusted colors.

The theme is built on perceptual HSLuv colors for hue and lightness consistency. It aims for readability while keeping a strong atmospheric tone.

## Installation

### straight.el + use-package (recommended)

```elisp
(use-package rustcity-theme
  :straight (:host github :repo "yoshzucker/rustcity-theme")
  :config
  (setq frame-background-mode 'dark)   ; or 'light
  (load-theme 'rustcity t))
```

### Manual

Clone the repository and add its directory to your `load-path`, then:

```elisp
(setq frame-background-mode 'dark)   ; or 'light
(load-theme 'rustcity t)
```

### Switching variants

The theme reads `frame-background-mode` at load time. To change between `neon` (dark) and `downpour` (light) after the theme is already loaded, disable it and reload with the desired value:

```elisp
(disable-theme 'rustcity)
(setq frame-background-mode 'light)   ; or 'dark
(load-theme 'rustcity t)
```

## Using the palette

After loading the package (or the theme), the palette is available in two ways:

- Inside Emacs (e.g. for additional custom faces in your config or special setups):
  ```elisp
  (rustcity-palette)        ; current variant based on frame-background-mode
  (rustcity-palette 'neon)  ; or 'downpour
  ```
  Returns the raw alist of 16 entries using the theme's internal semantic keys:
  `mono0`..`mono7` (perceptual gray ramp; `mono0` is the background, `mono7` the
  foreground for the variant) plus the 8 accent hues `red orange yellow green cyan
  blue purple magenta`.

- For external tools (Alacritty, kitty, WezTerm, ghostty, dircolors, terminal OSC
  sequences, etc.):
  ```elisp
  (rustcity-export-palette 'json 'neon)
  (rustcity-export-palette 'alist 'downpour)
  (rustcity-export-palette 'hex-list)
  ```
  'json and 'alist use conventional ANSI/terminal color names (`background`,
  `foreground`, `black`, `red`, ..., `brightwhite`) so the data is directly usable
  in terminal configs. 'hex-list returns exactly 16 hex values in the ANSI 0-15
  slot order chosen for this palette.

## Display compensation

```elisp
(setq rustcity-hsl-correction '(0.0 0.0 -1.5))  ; e.g. darken L a bit
(rustcity-apply-hsl-correction)                 ; then reloads theme if active
```
See the defcustom docstring for details and caveats (linear approx. in HSLuv space; useful for neon/dark setups on different displays).

The canonical definitions are the HSLuv constants (`rustcity-neon-hsl` / `rustcity-downpour-hsl`). Hex values (`rustcity-neon`, `rustcity-downpour`) and the accessors are derived from them (respecting `rustcity-hsl-correction` if non-zero).

Example JSON (via `rustcity-export-palette 'json 'neon`):
```json
{
  "background": "#1a2241",
  "brightcyan": "#1a2241",
  "black": "#263059",
  "brightblack": "#323f72",
  "brightblue": "#3f4f8c",
  "brightgreen": "#4d5fa6",
  "white": "#5c70bf",
  "brightyellow": "#7382c9",
  "foreground": "#8995d2",
  "brightwhite": "#8995d2",
  "red": "#ff618b",
  "brightred": "#ef7700",
  "yellow": "#b29700",
  "green": "#73a800",
  "cyan": "#00a9b1",
  "blue": "#369bff",
  "brightmagenta": "#b67cff",
  "magenta": "#ff3ff8"
}
```

(The `neon` variant is the dark one; use `'downpour` for the light variant.)

## Palette overview + terminal mapping

| Role / ANSI key     | Internal key | neon (dark) | downpour (light) |
|---------------------|--------------|-------------|------------------|
| background, brightcyan | mono0     | #1a2241         | #d5d7df            |
| black               | mono1        | #263059         | #c1c3d0            |
| brightblack         | mono2        | #323f72         | #adb0c1            |
| brightblue          | mono3        | #3f4f8c         | #999db2            |
| brightgreen         | mono4        | #4d5fa6         | #868aa4            |
| white               | mono5        | #5c70bf         | #737895            |
| brightyellow        | mono6        | #7382c9         | #626783            |
| foreground, brightwhite | mono7   | #8995d2         | #52566e            |
| red                 | red          | #ff618b         | #ff3377            |
| brightred           | orange       | #ef7700         | #d76b00            |
| yellow              | yellow       | #b29700         | #a08700            |
| green               | green        | #73a800         | #679700            |
| cyan                | cyan         | #00a9b1         | #00989f            |
| blue                | blue         | #369bff         | #008cef            |
| brightmagenta       | purple       | #b67cff         | #ac63ff            |
| magenta             | magenta      | #ff3ff8         | #f200eb            |

Exact values are generated from HSLuv at load time (with `rustcity-hsl-correction` deltas applied if set). They are exposed via the HSL constants (`rustcity-neon-hsl`, `rustcity-downpour-hsl`), the derived hex variables (`rustcity-neon`, `rustcity-downpour`), and the accessors `rustcity-palette` (internal semantic keys) / `rustcity-export-palette` (ANSI/terminal names for external use).

For terminal emulators that want a 16-color palette, use the values from `rustcity-export-palette` (or run it and copy). The 16 ANSI slots are assigned from the 16 internal colors; some "bright" slots receive gray-ramp entries because the design uses one unified 8-step mono ramp + 8 saturated accent hues (see `rustcity-export-palette` for the full mapping including aliases like brightcyan=background). 'hex-list gives the direct ordered list for slot 0-15. Magit and Marginalia faces are also provided and tuned to the mono ramp (with higher-pop accents) for harmony in the neon aesthetic.

## License

MIT License. See `LICENSE`.

## Credits

Original concept and implementation by yoshzucker. Structural modernizations (design notes, face refinements, documentation, hsl-correction, marginalia/magit faces) backported/adapted from gensho-theme (https://github.com/yoshzucker/gensho-theme), with complementary/higher-pop strategy for the neon city theme. Extracted from personal dotfiles into a standalone package.
