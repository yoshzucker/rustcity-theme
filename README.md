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

The theme reads `frame-background-mode` at load time. To change between `neon` and `downpour` after the theme is already loaded, disable it and reload with the desired value:

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
  (rustcity-palette 'neon)
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

The canonical definitions are the HSLuv constants (`rustcity-*-hsl`). Hex values and the alist accessors are derived from them.

Example JSON (truncated, neon variant, via `rustcity-export-palette 'json 'neon`):
```json
{
  "background": "#192141",
  "foreground": "#8995d1",
  "black": "#253058",
  "red": "#fe608a",
  "green": "#73a700",
  "yellow": "#b19600",
  "blue": "#359bff",
  "magenta": "#fe3ef8",
  "cyan": "#00a9b1",
  "white": "#5c6fbe",
  ...
  "brightwhite": "#8995d1"
}
```

## Palette overview + terminal mapping

| Role / ANSI key | Internal key | neon (dark) | downpour (light)          |
|-----------------|--------------|-------------|---------------------------|
| background      | mono0        | deep indigo night | pale rain-washed concrete |
| foreground      | mono7        | cool desaturated lavender | dark steel gray       |
| black           | mono1        | ...         | ...                       |
| brightred       | orange       | ...         | ...                       |
| ... (see export) | ...       | ...         | ...                       |

Exact values are generated from HSLuv at load time. They are exposed via the HSL constants, the derived hex constants (`rustcity-neon`, `rustcity-downpour`), and the accessors `rustcity-palette` (internal semantic keys) / `rustcity-export-palette` (ANSI/terminal names for external use).

For terminal emulators that want a 16-color palette, use the values from `rustcity-export-palette` (or run it and copy). The 16 ANSI slots are assigned from the 16 internal colors; some "bright" slots receive gray-ramp entries because the design uses one unified 8-step mono ramp + 8 saturated accent hues. 'hex-list gives the direct ordered list for slot 0-15.

## License

MIT License. See `LICENSE`.

## Credits

Original concept and implementation by yoshzucker. Extracted from personal dotfiles into a standalone package.
