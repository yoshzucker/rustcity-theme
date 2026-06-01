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

- Inside Emacs (e.g. for additional custom faces in your config):
  ```elisp
  (rustcity-palette)        ; current variant based on frame-background-mode
  (rustcity-palette 'neon)
  ```
  Returns the raw alist of 18 entries: `((background . "#...") (red . "#...") ...)`.

- For external tools (Alacritty, kitty, WezTerm, ghostty, dircolors, etc.):
  ```elisp
  (rustcity-export-palette 'json 'neon)
  (rustcity-export-palette 'alist 'downpour)
  (rustcity-export-palette 'hex-list)
  ```

The canonical definitions are the HSLuv constants (`rustcity-*-hsl`). Hex values and the alist accessors are derived from them.

Example JSON (truncated):
```json
{
  "black": "#2f2a3a",
  ...
  "background": "#2f2a3a",
  "foreground": "#a89fb0"
}
```

## Palette overview

| Role          | neon (dark)                  | downpour (light)             |
|---------------|------------------------------|------------------------------|
| background    | deep indigo night            | pale rain-washed concrete    |
| foreground    | cool desaturated lavender    | dark steel gray              |
| accent neon   | saturated reds, magentas, cyans | diffused, rain-muted versions |
| secondary     | muted industrial tones       | rusted, overcast hues        |

Exact values are generated from HSLuv at load time. They are exposed via the HSL constants, the derived hex constants (`rustcity-neon`, `rustcity-downpour`), and the accessors `rustcity-palette` / `rustcity-export-palette`.

## License

MIT License. See `LICENSE`.

## Credits

Original concept and implementation by yoshzucker. Extracted from personal dotfiles into a standalone package.
