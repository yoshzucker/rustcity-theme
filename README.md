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
  Returns the raw alist using the theme's internal semantic keys:
  `mono0`..`mono7` (perceptual gray ramp; `mono1` is the background and `mono7`
  the foreground for the variant, with `mono0` lying outside `mono1`, away from
  the foreground) plus `dim0`, `dim1` (dedicated dim levels for
  non-selected/unreal support in auto-dim-other-buffers-mode and solaire-mode)
  plus the 8 accent hues `red orange yellow green cyan blue purple magenta`.
  Only the 8 mono levels and the 8 hues reach the terminal export; `dim0` and
  `dim1` are for Emacs faces.

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
  slot order chosen for this palette (the core 8 mono + 8 accent; dim* levels
  are UI-only and not exported).

## Display compensation

```elisp
(setq rustcity-hsl-correction '(0.0 0.0 -1.5))  ; e.g. darken L a bit
(rustcity-apply-hsl-correction)                 ; then reloads theme if active
```
See the defcustom docstring for details and caveats (linear approx. in HSLuv space; useful for neon/dark setups on different displays).

The canonical definitions are the HSLuv constants (`rustcity-neon-hsl` / `rustcity-downpour-hsl`). Hex values (`rustcity-neon`, `rustcity-downpour`) and the accessors are derived from them (respecting `rustcity-hsl-correction` if non-zero).

## Non-selected window support

The theme provides face definitions for two popular de-facto modes that dim non-selected or "unreal" buffers/windows:

- `auto-dim-other-buffers-mode`
- `solaire-mode`

Their dim faces use the dedicated `dim0` level, which shifts the background by less than a full step of the main ramp. This gives a subtle auxiliary tone for non-selected areas without spending a level of the ramp itself.

`dim1` is also available in the palette for further customization.

No colors outside the published structure are used.

Example JSON (via `rustcity-export-palette 'json 'neon`):
```json
{
  "background": "#192141",
  "foreground": "#8692d0",
  "black": "#0c1227",
  "brightblack": "#27325c",
  "brightgreen": "#354379",
  "brightyellow": "#455596",
  "brightblue": "#5468b6",
  "white": "#6c7dc6",
  "brightwhite": "#8692d0",
  "red": "#fe5a87",
  "brightred": "#ea7500",
  "yellow": "#ae9400",
  "green": "#71a400",
  "cyan": "#00a6ae",
  "brightcyan": "#00a6ae",
  "blue": "#2698ff",
  "brightmagenta": "#b478ff",
  "magenta": "#fe32f8"
}
```

(The `neon` variant is the dark one; use `'downpour` for the light variant.)

## Palette overview + terminal mapping

| Role / ANSI key     | Internal key | neon (dark) | downpour (light) |
|---------------------|--------------|-------------|------------------|
| black               | mono0        | #0c1227     | #ededf1          |
| background          | mono1        | #192141     | #d5d6df          |
| brightblack         | mono2        | #27325c     | #bec0cd          |
| brightgreen         | mono3        | #354379     | #a7aabc          |
| brightyellow        | mono4        | #455596     | #9094ac          |
| brightblue          | mono5        | #5468b6     | #7b7f9b          |
| white               | mono6        | #6c7dc6     | #666b88          |
| foreground, brightwhite | mono7    | #8692d0     | #535870          |
| red                 | red          | #fe5a87     | #fc006d          |
| brightred           | orange       | #ea7500     | #cb6400          |
| yellow              | yellow       | #ae9400     | #967f00          |
| green               | green        | #71a400     | #618e00          |
| cyan, brightcyan    | cyan         | #00a6ae     | #008f96          |
| blue                | blue         | #2698ff     | #0083e1          |
| brightmagenta       | purple       | #b478ff     | #a754ff          |
| magenta             | magenta      | #fe32f8     | #e500de          |

The grey rows are in ramp order: `mono0` lies outside the background, away from
the foreground, and each `bright` slot is lighter than the plain one of the same
name (in `neon`; in `downpour`, where the foreground is the darker end, the
relationship is the same distance in the other direction). `dim0` and `dim1` are
not in the table — see below.

Exact values are generated from HSLuv at load time (with `rustcity-hsl-correction` deltas applied if set). They are exposed via the HSL constants (`rustcity-neon-hsl`, `rustcity-downpour-hsl`), the derived hex variables (`rustcity-neon`, `rustcity-downpour`), and the accessors `rustcity-palette` (internal semantic keys) / `rustcity-export-palette` (ANSI/terminal names for external use).

For terminal emulators that want a 16-color palette, use the values from `rustcity-export-palette` (or run it and copy). The background and the foreground are `mono1` and `mono7`, so they take the terminal's own background and foreground rather than a numbered slot, and the whole eight-step ramp reaches the terminal between them. `brightblack` holds `mono2` — dim but readable, which is what TUI tools actually want from that slot — and `black` holds `mono0`, the level outside the background. Eight hues cannot fill twelve hue slots, so `brightcyan` repeats `cyan`; the other three bright hue slots carry ramp levels.

`dim0` and `dim1` are not exported. They mean "this Emacs window is not the selected one", which a terminal has no notion of, so a slot spent on one would be a slot no program could ask for. Leaving them out is what lets `brightcyan` go back to being cyan.

`'hex-list` gives the direct ordered list for slots 0-15. Magit and Marginalia faces are also provided and tuned to the mono ramp (with higher-pop accents) for harmony in the neon aesthetic.

## License

MIT License. See `LICENSE`.

## Credits

Original concept and implementation by yoshzucker. Structural modernizations (design notes, face refinements, documentation, hsl-correction, marginalia/magit faces) backported/adapted from gensho-theme (https://github.com/yoshzucker/gensho-theme), with complementary/higher-pop strategy for the neon city theme. Extracted from personal dotfiles into a standalone package.
