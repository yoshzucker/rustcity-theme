;;; rustcity-theme.el --- Rustcity theme: neon nights and rainy days -*- lexical-binding: t; -*-

;; Author: yoshzucker
;; Maintainer: yoshzucker
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1") (hsluv "1.0"))
;; Keywords: faces, themes, rustcity, downpour, neon
;; Homepage: https://github.com/yoshzucker/rustcity-theme
;; License: MIT

;;; Commentary:

;; Dual light/dark theme using HSLuv colors.
;;
;; Usage (standalone):
;;   (setq frame-background-mode 'dark)   ; or 'light
;;   (load-theme 'rustcity t)
;;
;; Or with straight/use-package:
;;   (use-package rustcity-theme
;;     :straight (:host github :repo "yoshzucker/rustcity-theme")
;;     :config
;;     (setq frame-background-mode 'dark)
;;     (load-theme 'rustcity t))
;;
;; Programmatic palette access:
;;   (rustcity-palette)        ; internal semantic keys (mono0-7, dim0-1, 8 hues)
;;   (rustcity-export-palette 'json 'neon)  ; ANSI/terminal names for external tools
;;
;; Display compensation:
;;   (setq rustcity-hsl-correction '(0.0 0.0 -1.5))  ; e.g. darken L a bit
;;   (rustcity-apply-hsl-correction)                 ; then reloads theme if active
;; See the defcustom docstring for details and caveats (linear approx.).
;;
;; Magit and Marginalia faces are included and follow the theme's mono ramp
;; + limited (but higher-pop) accents (with heavy use of :inherit) so that
;; highlights/headers harmonize with the neon aesthetic.
;;
;; Weight is used where gensho-theme uses it and nowhere else -- the two are
;; one design read at two temperatures, and a face that is bold in one and not
;; the other is a difference nobody asked for.  The accents carry the pop; the
;; weight carries what the weight carried there.

;;; Code:

(require 'hsluv)
(require 'cl-lib)

(deftheme rustcity
  "A theme inspired by a rusted industrial cityscape—silent under neon rain, and hollow in a daylight downpour.")

(defconst rustcity-downpour-hsl
  '((mono0   . (260  20  94))
    (mono1   . (260  20  86))
    (dim0    . (260  20  84))   ; dedicated dim levels for non-selected/unreal areas
    (dim1    . (260  20  82))
    (mono2   . (260  20  78))
    (mono3   . (260  20  70))
    (mono4   . (260  20  62))
    (mono5   . (260  20  54))
    (mono6   . (260  20  46))
    (mono7   . (260  20  38))
    (red     . (  0 100  54))
    (orange  . ( 30 100  54))
    (yellow  . ( 70 100  54))
    (green   . (110 100  54))
    (cyan    . (200 100  54))
    (blue    . (250 100  54))
    (purple  . (280 100  54))
    (magenta . (310 100  54))))

(defconst rustcity-neon-hsl
  '((mono0   . (260  55   6))
    (mono1   . (260  55  14))
    (dim0    . (260  55  16))   ; dedicated dim levels for non-selected/unreal areas
    (dim1    . (260  55  18))
    (mono2   . (260  55  22))
    (mono3   . (260  55  30))
    (mono4   . (260  55  38))
    (mono5   . (260  55  46))
    (mono6   . (260  55  54))
    (mono7   . (260  55  62))
    (red     . (  0 100  62))
    (orange  . ( 30 100  62))
    (yellow  . ( 70 100  62))
    (green   . (110 100  62))
    (cyan    . (200 100  62))
    (blue    . (250 100  62))
    (purple  . (280 100  62))
    (magenta . (310 100  62))))

(defcustom rustcity-hsl-correction '(0.0 0.0 0.0)
  "HSLuv deltas (h s l) added to every base color before hex conversion.

Intended to compensate for display characteristic differences (e.g.
perceived darkness of the neon variant's mono1 background on some
setups vs. others).  The correction is applied uniformly and
linearly in HSLuv space to every palette entry (mono0-7, dim0-1 and
the 8 hues) for both neon and downpour variants.

Because the relationship between HSLuv values and actual display
response may not be perfectly linear, a single set of deltas is a
first-order approximation.  Small L adjustments are often most
effective for background lightness; large corrections can affect
ramp spacing or accent distinguishability.  Always verify visually
after changing, and prefer the smallest effective values.

The canonical design values remain in `rustcity-neon-hsl' and
`rustcity-downpour-hsl'; this option only affects derived hex palettes.

Set the value before loading the theme, or call
`rustcity-apply-hsl-correction' afterwards (and reload the theme if
necessary)."
  :type '(list float float float)
  :group 'rustcity-theme
  :set (lambda (sym val)
         (set-default sym val)
         (when (fboundp 'rustcity--recompute-derived-palettes)
           (rustcity--recompute-derived-palettes))))

;; HSL correction helpers (after defcustom so the variable is known).
(defun rustcity--correct-hsl (hsl)
  "Add `rustcity-hsl-correction' deltas to HSL (h s l) list.
Uses cl-destructuring-bind for clarity (cl-lib is already required
and cl-loop is used elsewhere with the cl- prefix)."
  (cl-destructuring-bind (h s l) hsl
    (cl-destructuring-bind (dh ds dl) rustcity-hsl-correction
      (list (mod (+ h dh) 360.0)
            (max 0.0 (min 100.0 (+ s ds)))
            (max 0.0 (min 100.0 (+ l dl)))))))

(defun rustcity--hex-palette (hsl-palette)
  "Convert HSL alist to hex alist using `hsluv-hsluv-to-hex'.
Respects the current value of `rustcity-hsl-correction'."
  (cl-loop for entry in hsl-palette
           for name = (car entry)
           for hsl = (rustcity--correct-hsl (cdr entry))
           collect `(,name . ,(hsluv-hsluv-to-hex hsl))))

(defvar rustcity-downpour nil
  "Derived hex palette for the downpour (light/washed) variant.
Computed from `rustcity-downpour-hsl' + `rustcity-hsl-correction'.")

(defvar rustcity-neon nil
  "Derived hex palette for the neon (dark) variant.
Computed from `rustcity-neon-hsl' + `rustcity-hsl-correction'.")

(defun rustcity--recompute-derived-palettes ()
  "Recompute `rustcity-downpour' and `rustcity-neon' from HSL bases + correction."
  (setq rustcity-downpour (rustcity--hex-palette rustcity-downpour-hsl)
        rustcity-neon (rustcity--hex-palette rustcity-neon-hsl)))

;; Initial computation (after defcustom and helpers are defined).
(rustcity--recompute-derived-palettes)

;;;###autoload
(defun rustcity-palette (&optional variant)
  "Return hex color alist for VARIANT or current `frame-background-mode'.
VARIANT is `neon' or `downpour' (defaults from `frame-background-mode').

The alist uses the theme's internal semantic palette keys:
  mono0..mono7  (perceptual gray ramp; mono1 is the background and mono7 the
                 foreground for the chosen variant.  mono0 lies outside mono1,
                 away from fg, and carries what is current inside the content;
                 mono2 carries what is not current; mono3 is the ground a bar
                 is drawn on.)
  dim0, dim1    (dedicated dim levels for the base background of
                 non-selected/unreal areas when using the supported modes
                 auto-dim-other-buffers-mode or solaire-mode.  They give a
                 weaker shift than a full step of the main ramp.)
  red orange yellow green cyan blue purple magenta  (accent hues)

The returned colors respect `rustcity-hsl-correction' (if non-zero).
For external tools / terminal emulators prefer `rustcity-export-palette',
which maps to conventional ANSI/terminal color names (background, black,
brightblack, ...).  dim0 and dim1 have no slot there: they mean \"not
the selected window\", which a terminal has no notion of."
  (let ((v (or variant
               (if (eq frame-background-mode 'light) 'downpour 'neon))))
    (if (eq v 'downpour) rustcity-downpour rustcity-neon)))

(let* ((class '((class color) (min-colors 89)))
       (colors (rustcity-palette))
       (mono0  (alist-get 'mono0 colors))
       (mono1  (alist-get 'mono1 colors))
       (mono2  (alist-get 'mono2 colors))
       (mono3  (alist-get 'mono3 colors))
       (mono4  (alist-get 'mono4 colors))
       (mono5  (alist-get 'mono5 colors))
       (mono6  (alist-get 'mono6 colors))
       (mono7  (alist-get 'mono7 colors))
       (dim0   (alist-get 'dim0 colors))
       (dim1   (alist-get 'dim1 colors))
       (red    (alist-get 'red colors))
       (orange (alist-get 'orange colors))
       (yellow (alist-get 'yellow colors))
       (green  (alist-get 'green colors))
       (cyan   (alist-get 'cyan colors))
       (blue   (alist-get 'blue colors))
       (purple (alist-get 'purple colors))
       (magenta (alist-get 'magenta colors)))

  ;; Mono ramp (perceptual lightness steps)
  ;;
  ;; Surveys of many themes reveal a clear, consistent pattern for gray ramps
  ;; used to establish visual hierarchy and a layered background texture.
  ;; Importantly, the assignment of meaning to the (typically ~8) steps of
  ;; such a ramp is itself part of the general, survey-derived knowledge:
  ;;
  ;; - A perceptual ramp (typically 6-9 steps, often computed via HSLuv or
  ;;   similar for uniform lightness) provides the foundation. The steps create
  ;;   a subtle stacked layering that remains visible even when syntax colors
  ;;   and UI elements are present.
  ;; - Related chrome elements are assigned *adjacent* steps on the ramp. This
  ;;   preserves the coherence of the layering (e.g. an active bar is one step
  ;;   "above" its inactive counterpart).
  ;; - A clear, recurring pattern is the assignment of semantic roles to an
  ;;   8-step (or similar) perceptual gray ramp. This assignment of "what each
  ;;   of the 8 levels means" is itself a general fact derived from surveys,
  ;;   not specific to any one theme:
  ;;     step ~0 (lowest): main background; also used as foreground for
  ;;                       high-attention pop elements that sit on colored
  ;;                       backgrounds.
  ;;     step ~1 (next):   subtle backgrounds for selection, current item,
  ;;                       highlights, matching regions, etc. (the standard
  ;;                       de-facto aux step on main content).
  ;;                       Dedicated dim levels (dim0/dim1) are provided for
  ;;                       the supported modes' non-selected/unreal faces, so
  ;;                       dim can be weaker than the main aux while
  ;;                       preserving the 8-step semantics for content.
  ;;     step ~2-3:        alt / medium subtle (active chrome bg, some
  ;;                       highlights).
  ;;     step ~4 (mid-low): faint / secondary (shadow, doc-face, low-
  ;;                       priority or weekend indicators).
  ;;     step ~5 (mid):    comments and other secondary / low-weight text
  ;;                       and UI elements.
  ;;     step ~6 (high-mid): prominent secondary (cursor bg, minibuffer
  ;;                         prompt, current completion item text, inactive
  ;;                         chrome fg, etc.).
  ;;     step ~7 (highest): primary / main foreground (default text,
  ;;                        active chrome text, etc.).
  ;;   (The exact numbering and lightness deltas are implementation
  ;;   details; the *role assignment to the 8 levels* is the survey-derived
  ;;   universal pattern.)
  ;;   Rustcity departs from the survey at the two lowest steps: it seats the
  ;;   background at mono1, one step in from the end, and spends mono0 on
  ;;   what is current inside the content, so a highlight recesses instead
  ;;   of rising.  The survey's ha-ha themes already recess chrome this way;
  ;;   rustcity leaves chrome sunken and recesses the content marks instead.
  ;; - The overall derived principle: the gray ramp layers supply the primary
  ;;   visual rhythm; color is used as accent on top of this foundation.

  ;; Layered chrome / panel texture (universal application of the above)
  ;;
  ;; To create depth with Emacs' sparse chrome primitives (no borders, shadows
  ;; or gradients), every surface in the frame is placed on the low end of the
  ;; ramp, and the depth is allowed to say one thing only: how current that
  ;; surface is.  Anything that carries a meaning takes a hue instead, so a
  ;; single step never has to say "you are here" and "this is idle" at once.
  ;;
  ;;   mono0  what is current inside the content -- the line point is on,
  ;;          the region, the hunk you are reading, the candidate you are on.
  ;;          It lies outside mono1, away from fg: a recess, not a rise.
  ;;   mono1  the content surface itself, with its fringe, line numbers, the
  ;;          frame's internal border and the dividers between windows, which
  ;;          stay flush so that no seam fights the planes.  The figure of an
  ;;          active bar sits here too -- the selected tab and the mode line
  ;;          of the window you are in -- so the working surface is continuous
  ;;          from the tab down into the text.
  ;;   mono2  what is not current -- the inactive mode line, unselected tabs,
  ;;          the other search matches, the secondary selection, diff lines
  ;;          outside the hunk point is in, a dimmed panel.  It is also the
  ;;          plane a buffer alternates onto when it has to band its own
  ;;          content, as an expanded dired subtree or a weekend column does.
  ;;   mono3  what frames or labels content rather than being content --
  ;;          tab-bar and tab-line fields, the header line, tooltips and
  ;;          child-frame rims, column titles, table and hunk headings.
  ;;
  ;; The first three are one axis, how current a surface is.  mono3 is not on
  ;; it: it is a place rather than a state.  Which is why a bar can show up on
  ;; both -- tab-bar is a mono3 field carrying mono1/mono2 tabs, the mode line
  ;; is a figure with no field of its own, and the header line a field with no
  ;; figure, since one window has exactly one and there is no active or
  ;; inactive about it.
  ;;
  ;; Reading the state axis as one order is what makes the bars symmetric:
  ;; tab-bar and tab-line both lie on mono3 with the current tab at mono1 and
  ;; the rest at mono2, and the mode line follows the same pair without a
  ;; ground of its own.
  ;;
  ;; For non-selected windows and unreal buffers, solaire-mode and
  ;; auto-dim-other-buffers-mode take dim0, a dedicated level that shifts
  ;; mono1 by less than a full step of the main ramp, so a dimmed window reads
  ;; as not current without taking mono2 outright.  dim1 is a second such
  ;; level, available for customization.
  ;;
  ;; See the "Gutter, dividers..." section below and README for the current
  ;; practical choices and usage notes (including how to enable the two modes).

  ;; Chrome direction -- walled / sunken / ha-ha
  ;; (garden architecture metaphor)
  ;;
  ;; Three patterns coexist for chrome elements (mode-line, tab-bar,
  ;; tab-line) that sit alongside the body.  The metaphor comes from
  ;; garden architecture: the "garden floor" is body bg (the active
  ;; editing surface) and the surroundings are chrome bg.
  ;;
  ;;   Walled: active chrome FAR from body in the fg direction (tall
  ;;     wall); inactive chrome closer to body.  The active focus
  ;;     area is surrounded by tall walls that make it stand out.
  ;;
  ;;   Sunken: active chrome at body level; inactive chrome moves
  ;;     slightly TOWARD fg from body.  The active focused window
  ;;     reads as the sunken floor; inactive surroundings rise as
  ;;     walls on the fg-facing side.
  ;;
  ;;   Ha-ha (sunken fence): active chrome at or near body level;
  ;;     inactive chrome moves AWAY FROM fg from body (into a ditch
  ;;     on the anti-fg side).  The focus area sits on garden level
  ;;     while the surrounding chrome lies in a recessed ditch.
  ;;
  ;; "Toward fg" and "anti-fg" are direction-agnostic on the brightness
  ;; ramp.  Neon has fg brighter than bg, so toward fg = brighter;
  ;; downpour has fg darker than bg, so toward fg = darker.  The
  ;; semantic (active position vs inactive position relative to body
  ;; and fg) is what matters, and it is the same in both variants even
  ;; though the absolute brightness moves the other way.
  ;;
  ;; Whether a theme can express all three patterns depends on its
  ;; palette geometry: if body bg sits at an extreme of the ramp
  ;; (e.g. pure white in Modus operandi, pure black in Modus vivendi),
  ;; the anti-fg direction has no palette room, so ha-ha is not
  ;; available -- only walled or sunken.  Rustcity seats its background
  ;; at mono1 and keeps mono0 outside it, which leaves that direction
  ;; open; it spends it on content marks rather than on chrome.
  ;;
  ;; Survey (source inspection, body-distance + fg-direction analysis):
  ;;
  ;;   Theme               | mode-line | tab-bar
  ;;   --------------------+-----------+--------
  ;;   Modus operandi/viv. | walled    | sunken
  ;;   Catppuccin mocha    | ha-ha     | walled
  ;;   Catppuccin latte    | sunken    | walled
  ;;   Doom one dark       | ha-ha     | ha-ha
  ;;   Doom one light      | sunken    | sunken
  ;;
  ;; All three patterns are in active use.  The same design intent
  ;; can classify differently between a theme's light and dark
  ;; variants (Doom one and Catppuccin's mode-line) because the bg/fg
  ;; direction flips while the chrome's palette direction stays
  ;; fixed.  Themes with body bg at a brightness extreme (Modus) can
  ;; only express walled or sunken (no ha-ha possible).
  ;;
  ;; The pattern interacts with the theme's "dim direction" -- where
  ;; body bg shifts when a non-active window is dimmed (by solaire /
  ;; auto-dim-other-buffers, or any equivalent mode), and whether
  ;; that direction is toward fg or anti-fg:
  ;;
  ;;   - dim toward fg: sunken keeps all "active" elements (body,
  ;;     mode-line, selected tab) at the same body-bg stratum, with
  ;;     dim'd bodies and inactive chrome rising slightly toward fg as
  ;;     a coherent unit.  Walled or ha-ha would split "active" across
  ;;     strata.
  ;;
  ;;   - dim anti-fg: active body sits on the fg side of dim'd body.
  ;;     Walled or ha-ha (active chrome aligned with active body)
  ;;     would keep "active" coherent; sunken would split it.
  ;;
  ;; This is orthogonal to whether any dimming mode is actually
  ;; enabled -- the principle applies to the static palette geometry.
  ;;
  ;; This theme commits to fully sunken for chrome: `mode-line',
  ;; `tab-bar-tab' and `tab-line-tab-current' bg = mono1, flush with
  ;; the content surface, while everything inactive rises to mono2 and
  ;; the bars' own ground sits at mono3.  `header-line' is on that
  ;; ground rather than in the pair, having no active or inactive to
  ;; tell apart.  Rustcity
  ;; dims toward fg in both variants -- neon bg -> dim0 is brighter
  ;; and neon has fg above bg, downpour bg -> dim0 is darker and
  ;; downpour has fg below bg -- so sunken keeps every active element
  ;; on one stratum and lets the dimmed windows and the inactive bars
  ;; rise together.  Among surveyed themes the closest match is Doom
  ;; one light.  Aesthetically, chrome at surface level leaves the lit
  ;; accents -- signage hues on a flush dark street -- as the only
  ;; things standing above the plane.
  ;;
  ;; What rustcity does differently is below that stratum rather than
  ;; around it.  The survey's ha-ha themes put chrome in the recess;
  ;; rustcity leaves chrome sunken and gives the recess to content --
  ;; mono0 carries the highlight, the region, the current hunk.  The
  ;; street stays the street, and what you are pointing at is cut into
  ;; it.  It is available for the same reason ha-ha would be: the
  ;; content surface sits at mono1, not at the end of the ramp.

  ;; Accent colors (hues)
  ;;
  ;; A. Observed convergence on semantic mappings
  ;;    Across the surveyed themes there is strong agreement on hue choices for
  ;;    common semantic roles (chosen for harmony, distinguishability, and
  ;;    modern "feel"):
  ;;    - Strings/literals: green (positive, harmonious; dominant modern
  ;;      choice).
  ;;    - Keywords and control flow: purple or mauve.
  ;;    - Builtins: red or orange-red (pairs with error).
  ;;    - Functions and calls: often magenta or a blue/magenta family member.
  ;;    - Types: cyan or blue (provides structure with low pop).
  ;;    - Constants: frequently a blue or near-background hue (avoids over-use
  ;;      of warm complements).
  ;;    - Warnings/alerts: yellow (kept distinct from error red).
  ;;    - Variables/identifiers: a hue, and warm in the plurality.  Counted
  ;;      over the themes shipped with Emacs plus solarized (16 definitions):
  ;;      8 warm (orange, saddle brown, yellow-green, khaki -- tango,
  ;;      dichromacy, tsdh, wheatgrass, wombat, misterioso), 4 green, 3
  ;;      blue/cyan (adwaita, solarized, modus), 1 magenta.  None grey.
  ;;      This role was the one missing from the list above, and a role with
  ;;      no entry fell through to the mono ramp: `font-lock-variable-name-
  ;;      face' sat at step 6 on the reading that identifiers are the most
  ;;      frequent text and should not shout.  That reading is a real
  ;;      minority school, but it belongs to themes that leave *every*
  ;;      identifier-ish face uncoloured; here it made one face of eight an
  ;;      outlier -- and `outline-2' inherits this face by Emacs' own default
  ;;      (outline.el), so every level-two heading in Org came out at step 6,
  ;;      dimmer than the body text under it.
  ;;    - Errors: red (near-universal); success/DONE states: green.
  ;;
  ;; B. Strategies for choosing specific hues against a tinted background
  ;;    When the background itself carries a hue (even a very low-saturation
  ;;    one), two broad strategies are observable:
  ;;    - Analogous / cool-bias: select accent hues close to the background's
  ;;      own hue. This favors calm, harmony, and lets low-saturation gray
  ;;      layers stay prominent (seen in solarized cool variants, nord, many
  ;;      "slate" or muted dark themes).
  ;;    - Complementary / higher-pop: make greater use of opposing or warmer
  ;;      hues for stronger vibrancy and immediate visual distinction.
  ;;
  ;; C. Principles shared by both strategies
  ;;    - Strictly limit the number of distinct hues present in any single
  ;;      buffer or major UI component.
  ;;    - Rely heavily on the mono gray ramp plus `:inherit` for the majority
  ;;      of faces (outlines, directory faces, titles, etc.) so that hue noise
  ;;      does not overwhelm the gray foundation.
  ;;    - Reserve the most saturated, attention-grabbing hues for short-lived,
  ;;      interactive or transient overlays only (isearch, tooltips, avy
  ;;      leads, orderless match highlights, etc.). Persistent syntax and
  ;;      structural elements stay within the gray ramp or the limited
  ;;      semantic hues.
  ;;
  ;; D. Other recurring tendencies
  ;;    - Links often use a cool hue (blue) to differentiate navigation from
  ;;      the green used for strings.
  ;;    - Org/Magit/Agenda and similar rich modes inherit the font-lock and
  ;;      mono decisions heavily; hues are introduced only for key status
  ;;      indicators (TODO, DONE). Secondary or historical information (past
  ;;      scheduled, weekend dates, etc.) stays in the gray ramp.
  ;;    - Tables, dates, and calendar elements commonly inherit from the type
  ;;      face (cyan/blue) or fall back to mono.

  ;; === General knowledge (applicable to any theme; derived from color
  ;; theory surveys including 色彩検定/PCCS, Itten/Judd, and de-facto UI
  ;; theme analysis) ===
  ;; - Hue circle and hue difference (PCCS 24-hue circle, ~15° per step;
  ;;   色彩検定 3級 level): hue diff 0 = identical hue (vary tone only);
  ;;   diff 1 = adjacent; 2-3 = similar (類似色相配色, harmonious, stable,
  ;;   analogous basic); 4-7 = medium; 8-10 = contrast (対照色相配色,
  ;;   warm/cool opposition, clear pop); 11-12 = complementary (補色, 180°,
  ;;   strong but use carefully).
  ;; - Geometric schemes (Itten/Judd "order principle"): diad 180°,
  ;;   triadic 120°, tetradic square 90° or rectangle. These are
  ;;   number-first (geometric positions for harmony) and can feel
  ;;   artificial/sensibility-light; treat as reference only, not primary
  ;;   for image-driven themes.
  ;; - Other harmony principles (Judd 4 principles, 色彩検定): similarity
  ;;   (common attributes harmonize), clarity/contrast (明瞭性), order
  ;;   (geometric as above), familiarity (なじみ, habitual/natural combos).
  ;;   Dominant-color scheme (one main hue family + tone variations);
  ;;   tone-on-tone etc.
  ;; - UI/theme practice (from nord, solarized, modus etc.): when bg is
  ;;   tinted (low-sat hue), analogous/cool-bias (cluster near bg hue)
  ;;   favors calm + mono-ramp prominence. Complementary/higher-pop for
  ;;   vibrancy. Strictly limit distinct hues (4-8 total). Base (bg/fg/
  ;;   most chrome) = mono ramp; accents limited to semantic roles.
  ;;   De-facto semantics (strong convergence): string/literal=green,
  ;;   keyword=purple/mauve, function=magenta or blue-magenta, type=cyan
  ;;   or blue (low pop structure), constant=near-bg blue, builtin=red,
  ;;   warning=yellow, error=red; success=green; link=blue. Transient/
  ;;   highlight can use more pop. Secondary/derived faces (many org,
  ;;   calendar, etc.) fall to mono + :inherit to avoid hue noise.
  ;;   Distribution tactics: even spacing (balance), clustered (warms for
  ;;   energy/alert/seasonal, cools for structure), sector emphasis.
  ;;   Reference choice: bg hue as anchor for analogous (common for
  ;;   tinted-bg calm themes); or key semantic / natural reference.
  ;;   Overall process (structural, any theme): 1. de-facto semantic survey,
  ;;   2. choose harmony type per desired image (calm vs pop vs seasonal),
  ;;   3. limit total hues, 4. use tone/s for variation instead of more
  ;;   hues, 5. visual tune. Hue-diff theory often for 2-4 colors; for 8+
  ;;   use composites (dominant analogous group + contrast accents).

  ;; Rustcity follows the complementary/higher-pop strategy (see B above) for
  ;; its accent hues to evoke the vibrant, energetic neon city aesthetic.
  ;; Greater use of opposing or warmer hues (spread across the circle with
  ;; high saturation in neon variant) for stronger vibrancy, immediate pop,
  ;; and visual distinction against the cool industrial/rain-washed bg,
  ;; while still strictly limiting total distinct hues, relying heavily on
  ;; the (high-sat in neon) mono gray ramp + :inherit for structure and
  ;; hierarchy, and reserving the most saturated accents for transient
  ;; overlays.  This matches the "neon街" image of glowing opposing lights
  ;; (warm signage vs cool night/rain) with perceptual mono foundation for
  ;; the empty streets and rusted details.  Concrete h/s/l assignments and
  ;; the extensive mono usage apply the general patterns (A-D) + this
  ;; higher-pop choice.

  ;; Face spec discipline (Emacs `face-spec-recalc' behavior)
  ;;
  ;; When `custom-theme-set-faces' overrides a face, the override does NOT
  ;; merge with the face's defface. `face-spec-recalc' first resets every
  ;; attribute to `unspecified', then applies the theme spec on top. The
  ;; defface spec is consulted only when no theme entry matches.
  ;;
  ;; The single exception is `:extend': if the theme spec leaves it
  ;; unspecified, `face-spec-recalc' copies the value from defface. So
  ;; `:extend' is the only attribute the theme can omit and still get the
  ;; defface value.
  ;;
  ;; (`set-face-attribute' is a different, lower-level primitive with true
  ;; merge semantics -- only the listed attributes change. The theme path
  ;; goes through `face-spec-recalc' and does NOT have those semantics.)
  ;;
  ;; Consequence for rustcity: for any attribute other than `:extend' that
  ;; the defface specifies and we want to preserve, we must restate it
  ;; explicitly. Omitting it means dropping it. So:
  ;;   - `:extend'        -> omit (Emacs preserves the defface value).
  ;;   - everything else  -> state explicitly if we want it; omit only when
  ;;                         we actively want it cleared.

  ;; Decoration attribute policy (survey-derived; same structure as the
  ;; mono ramp / accent design notes above: facts -> pattern -> rustcity
  ;; choice).
  ;;
  ;; Big-picture philosophy.  Modern minimalist themes (Nord, Modus,
  ;; Catppuccin) carry visual structure through a perceptual mono ramp
  ;; (~8 steps) and adjacent bg planes; borders are removed or flattened.
  ;; Information that the plane painting cannot carry (interactivity,
  ;; diagnostics, hierarchy, state) is delegated to color accents and --
  ;; only where the plane is insufficient -- to text-decoration
  ;; attributes.  Heavier themes (Zenburn, doom-themes) keep older
  ;; decoration conventions (released-button 3D box, broad straight-
  ;; underline usage, frequent inverse-video).  Rustcity follows the
  ;; minimalist line on every attribute below.  Its higher-pop strategy
  ;; (see B above) spends itself on hue, not on decoration.
  ;;
  ;; :underline t
  ;;   Survey: minimalist themes confine straight underline to (a)
  ;;   actionable navigation (`link', `link-visited').  Wave-style
  ;;   underline for diagnostics (flyspell/flycheck) is a separate
  ;;   built-in convention shared by all themes.  Heavier themes
  ;;   additionally underline dates, references, document-structure
  ;;   markers and "intra-mono distinction" cases such as dired
  ;;   permission chars; minimalist themes do NOT (Nord, Catppuccin,
  ;;   Modus do not override `dired-perm-write' / `marginalia-file-
  ;;   priv-*' to add underline).  Rustcity choice: minimalist.
  ;;   Allowed:
  ;;     (a) navigation: `link', `link-visited'.
  ;;     (b) defface-provided straight underline that other minimalist
  ;;         themes also let stand (they don't override): `calendar-
  ;;         today' (defface has `:underline t', conventional today
  ;;         marker -- we restate it to survive the theme replace).
  ;;     (c) wave-style diagnostics (override flyspell/flycheck etc.
  ;;         when needed -- keeps the built-in convention).
  ;;   NOT allowed (do not restate defface underline, do not invent
  ;;   intra-mono underline): document text and heading decoration --
  ;;   `org-date', `org-footnote', `org-ellipsis', `org-column-title',
  ;;   `org-latex-and-related', `eww-valid-certificate', font-lock
  ;;   tty-fallback underlines; and intra-mono distinction faces --
  ;;   `dired-perm-write', `marginalia-file-priv-write', where weight
  ;;   and slant carry the distinction instead.
  ;;
  ;; :weight bold
  ;;   Survey: all themes use bold for hierarchy/structural prominence
  ;;   (headings, outline levels) and state indicators (error/warning/
  ;;   success).  Minimalist themes (Modus) gate it behind a user
  ;;   toggle and default to "only where necessary"; heavier themes
  ;;   additionally bold every font-lock keyword/function-name/type.
  ;;   Rustcity choice: minimalist.  Bold for exactly two roles:
  ;;     (1) Hierarchy / structural prominence -- headings where the
  ;;         bg plane alone cannot carry the body/heading split
  ;;         (`org-document-title', the magit-section-heading and
  ;;         magit-diff-file-heading families, `deft-*',
  ;;         `line-number-current-line', the current tab group and
  ;;         modified tab).
  ;;     (2) State indicators on low-cardinality markers (`error',
  ;;         `warning', `success', `mode-line-buffer-id', `org-tag',
  ;;         the org-agenda date/time markers, the magit process,
  ;;         tag and branch markers, `show-paren-match').
  ;;   No bold on syntax (font-lock-keyword-face etc.) -- color alone
  ;;   carries the semantic, and in neon the color is loud enough that
  ;;   bold on top would be noise.  When defface has bold but rustcity
  ;;   wants to drop it (high-frequency dense markers like `orderless-
  ;;   match-face-*'; chrome neutrals like `header-line'), simply omit
  ;;   `:weight' from the override -- theme replace makes it
  ;;   unspecified automatically.
  ;;
  ;; :box
  ;;   Survey: sparse in all themes (8-45 entries).  Heavier themes
  ;;   (Zenburn) use `:style released-button' on mode-line / headers
  ;;   (legacy 3D look); minimalist themes (Nord, Catppuccin) confine
  ;;   `:box' to clickable affordances with flat `:line-width N :color X'.
  ;;   Rustcity choice: minimalist.  `:box' only where the bg plane
  ;;   alone cannot carry the affordance:
  ;;     - `magit-branch-current' (`:box t' delimits the current
  ;;       branch among a list of branches).
  ;;     - `magit-blame-heading' (sized box frames the blame line).
  ;;     - `transient-nonstandard-key' / `transient-mismatched-key'
  ;;       (a negative-width hue box marks the odd key without moving
  ;;       any text).
  ;;   Otherwise the affordance rides the bg plane (e.g.
  ;;   `help-key-binding' renders the key chip as a `mono3' fill on the
  ;;   `mono1' plane -- the step is enough, no box is added).
  ;;   No `:style released-button' anywhere.
  ;;
  ;; :slant italic
  ;;   Survey: all themes use italic for secondary/de-emphasized
  ;;   content (comments, docstrings, blockquotes, citations).
  ;;   Italic is gentler than bold and does not impede plane reading;
  ;;   even minimalist themes use it readily.  Rustcity follows the
  ;;   common pattern.  Used on: `font-lock-comment-face',
  ;;   `marginalia-file-priv-link', `magit-branch-upstream',
  ;;   `org-agenda-clocking', `org-agenda-date-today' (with bold),
  ;;   `org-foresight-agenda-derived' and
  ;;   `org-foresight-agenda-free' (both of which mark an entry the
  ;;   user did not write themselves).
  ;;
  ;; :inverse-video
  ;;   Survey: minimalist themes (Nord 0, Catppuccin tty fallback only,
  ;;   Modus sparse) avoid it; heavier themes (Doom, Zenburn) use it
  ;;   sparsely.  Reason for avoiding: explicit bg/fg pairs are more
  ;;   predictable and interact more cleanly with the mono-ramp planes.
  ;;   Rustcity choice: never use `:inverse-video'.  Where defface has
  ;;   it (`org-todo', `org-done', `org-date-selected'), rustcity writes
  ;;   the equivalent display as an explicit `:foreground' / `:background'
  ;;   pair (theme replace drops the defface inverse-video for free).
  ;;
  ;; :inherit (not a decoration but related)
  ;;   When defface `:inherit' aligns with rustcity intent, RESTATE it
  ;;   explicitly (theme override replaces defface, so omitted inherit
  ;;   is dropped).  When defface `:inherit' conflicts, re-target it
  ;;   (e.g. `dired-directory' -> `font-lock-type-face', `font-lock-
  ;;   doc-face' -> `mono4').
  ;;
  ;; Typeface
  ;;   Families are the user's to choose, so the theme states color and
  ;;   never `:family'.  `fixed-pitch' and `variable-pitch' are left to
  ;;   their defface entirely; faces that must be monospaced regardless
  ;;   of what the surrounding text uses say so by inheriting
  ;;   `fixed-pitch' (`tooltip', `help-key-binding').
  ;;
  ;; Face-stack defence reset (`:weight normal :slant normal')
  ;;   Defface sometimes places an explicit normal-reset to prevent
  ;;   weight/slant inheriting from the face stack below (overlay
  ;;   before-string, text under another face's region).  Rustcity
  ;;   preserves the reset only where the inheritance path exists:
  ;;   `magit-blame-heading' (before-string overlay; magit source
  ;;   comments on the inheritance risk), `org-column' (drawn atop
  ;;   underlying buffer text).  Margin overlays and independent
  ;;   regions do NOT need it -- `magit-log-author' / `magit-log-date'
  ;;   live in the margin overlay so the reset is omitted.
  ;;
  ;; No explicit `:foo unspecified'
  ;;   Theme override replaces defface entirely, so omitting an
  ;;   attribute IS unspecified.  Writing `:foo unspecified' carries
  ;;   no functional effect; the documentation value is covered by
  ;;   this block.  We therefore do not write any `:foo unspecified'
  ;;   in the spec list below.

  (custom-theme-set-faces
   'rustcity

   ;; Face support for two de-facto dimming / non-selected-window modes
   ;; (solaire-mode for "unreal" buffers and auto-dim-other-buffers-mode for
   ;; non-selected windows). These are the modes that can consume exact
   ;; palette colors without inventing new ones.
   ;;
   ;; We use dedicated dim levels (dim0/dim1) for their base dim faces. They
   ;; shift the surface by less than a full step of the main ramp, which keeps
   ;; the 8-step ramp and its roles unchanged while allowing a weaker
   ;; "ほんの少し" dim for non-selected areas. Inside a dimmed area the marks
   ;; still take mono0, the same as anywhere else.
   `(solaire-default-face ((,class (:background ,dim0))))
   `(solaire-hl-line-face ((,class (:background ,mono0))))
   `(solaire-region-face ((,class (:background ,mono0 :extend t))))
   `(auto-dim-other-buffers ((,class (:background ,dim0))))
   `(auto-dim-other-buffers-hide ((,class (:foreground ,dim0 :background ,dim0))))

   ;; --- Core primitives ---
   `(default ((,class (:foreground ,mono7 :background ,mono1))))
   `(cursor ((,class (:background ,mono6))))
   `(fringe ((,class (:background ,mono1))))
   `(border ((,class (:background ,mono1))))
   `(internal-border ((,class (:background ,mono1))))
   ;; Divider between windows, set to mono1 so that no seam line appears
   ;; between a differentiated side panel (e.g. treemacs at mono2) and the main
   ;; editor. Areas are then told apart by their bg tone and their content --
   ;; tree structure vs code, icons -- and by window geometry, which is the
   ;; common approach for quiet layered looks: a contrasting border line fights
   ;; the plane expression. Regular content-to-content splits can still get
   ;; subtle separation from window-divider-mode (see the Gutter section
   ;; below).
   `(vertical-border ((,class (:foreground ,mono1))))
   `(region ((,class (:background ,mono0))))
   `(secondary-selection ((,class (:background ,mono2))))
   `(highlight ((,class (:background ,mono0))))
   `(shadow ((,class (:foreground ,mono4))))
   `(match ((,class (:foreground ,mono1 :background ,green))))
   ;; The partner delimiter is marked by weight and the far end of the ramp
   ;; alone.  A plane would be too much for two characters, and a hue is not
   ;; available: every one of the eight is already a font-lock category, so a
   ;; colored paren would read as a variable or a type in the one buffer where
   ;; paren matching matters.
   `(show-paren-match ((,class (:foreground ,mono7 :weight bold))))
   `(link ((,class (:foreground ,blue :underline t))))
   `(link-visited ((,class (:foreground ,purple :underline t))))
   `(error ((,class (:foreground ,red :weight bold))))
   `(warning ((,class (:foreground ,yellow :weight bold))))
   `(success ((,class (:foreground ,green :weight bold))))
   `(minibuffer-prompt ((,class (:foreground ,mono6))))
   `(minibuffer-nonselected ((,class (:foreground ,mono1 :background ,yellow))))
   ;; A tooltip is chrome, not a signal: it appears because the pointer
   ;; happened to rest somewhere, and an accent plane makes that read as an
   ;; alert.  The neutral chrome step is what the minimalist tooltip pattern
   ;; uses (Doom, Catppuccin), and gensho settled there for the same reason.
   ;; The fixed face is explicit because Emacs's own definition of `tooltip'
   ;; inherits `variable-pitch', which puts a proportional face in front of
   ;; somebody whose every other window is monospaced -- and key bindings,
   ;; signatures and paths are read by their columns.
   `(tooltip ((,class (:foreground ,mono7 :background ,mono3 :inherit fixed-pitch))))
   `(help-key-binding ((,class (:foreground ,mono7 :background ,mono3 :inherit fixed-pitch))))

   ;; --- Modeline, header-line, tab-bar, tab-line (UI chrome) ---
   ;; Layered chrome strategy: We differentiate "chrome layers" (bars, side
   ;; panels) from the main "content plane" using adjacent steps on the mono
   ;; ramp. This is the primary way to create visual depth and a layered
   ;; "slab" feel in Emacs, which lacks heavy decorative primitives (borders,
   ;; shadows, titlebar gradients) available in other editors.
   ;; - tab-bar and tab-line are drawn on the outer ground, mono3.
   ;; - The current tab is mono1, flush with the content surface, so the view
   ;;   you are in is continuous from the tab "lid" down into the content.
   ;;   This creates the recessed/chiseled selection + unified chrome slab.
   ;; - The other tabs rise to mono2 with dimmer fg, the same level every other
   ;;   idle surface takes.
   ;; - mode-line follows the same pair, mono1 active and mono2 inactive,
   ;;   without a ground of its own: one bar, so there is no field for it to
   ;;   sit on.
   ;; - header-line is the other way round -- a field with no figure.  One
   ;;   window has exactly one, with no active or inactive to tell apart, so
   ;;   it sits on mono3 with the other things that label content.
   `(mode-line ((,class (:foreground ,mono7 :background ,mono1))))
   ;; mode-line-inactive at mono2 -- the idle reference plane shared with
   ;; `tab-bar-tab-inactive' and `tab-line-tab-inactive', one step toward fg
   ;; from the content surface.  This level is invariant under
   ;; the walled / sunken / ha-ha choice for the active mode-line (see
   ;; "Chrome direction" notes in the mono ramp design above).  When a
   ;; window is dimmed by the supported modes the layer distinction still
   ;; holds: inactive chrome is distinct from both the content plane and
   ;; the dim content bg.
   `(mode-line-inactive ((,class (:foreground ,mono6 :background ,mono2))))
   `(mode-line-buffer-id ((,class (:weight bold))))
   ;; mode-line-highlight: minimalist convention (Nord, Doom) -- replace the
   ;; defface flat box on mouse-over with a plane shift (inherit `highlight'),
   ;; matching the "no boxes; bg-plane carries affordance" attribute policy.
   `(mode-line-highlight ((,class (:inherit highlight))))
   `(header-line ((,class (:foreground ,mono7 :background ,mono3))))
   `(tab-bar ((,class (:foreground ,mono7 :background ,mono3))))
   `(tab-bar-tab ((,class (:foreground ,mono7 :background ,mono1))))
   ;; Inactive tabs sit below the bar's own ground (mono3) at mono2, the idle
   ;; plane.  This is a chrome step, not a content selection.
   `(tab-bar-tab-inactive ((,class (:foreground ,mono6 :background ,mono2))))
   `(tab-bar-tab-group-current ((,class (:inherit tab-bar-tab :weight bold))))
   `(tab-bar-tab-group-inactive ((,class (:inherit tab-bar-tab-inactive))))
   ;; tab-line is per-window rather than per-frame, but it is still a bar, so
   ;; it takes the same three levels as tab-bar.
   `(tab-line ((,class (:foreground ,mono7 :background ,mono3))))
   `(tab-line-tab ((,class (:foreground ,mono6 :background ,mono2))))
   `(tab-line-tab-current ((,class (:foreground ,mono7 :background ,mono1))))
   `(tab-line-tab-inactive ((,class (:foreground ,mono5 :background ,mono2))))
   `(tab-line-tab-modified ((,class (:inherit tab-line-tab-current :weight bold))))

   ;; --- Gutter, dividers, borders (additional vertical/horizontal layering) ---
   ;; These provide extra "slab" and "grout" elements with almost zero added
   ;; decoration primitives, purely via mono ramp assignment.
   ;; Gutter (line numbers) acts as a vertical pillar on the left.
   ;;
   ;; The divider takes mono1, which is what keeps the layered look free of a
   ;; seam line: next to a differentiated side panel (e.g. treemacs at mono2)
   ;; the transition is silent, and the panel stands out through its tone and
   ;; content instead of an extra border.  For regular content-to-content
   ;; splits, `window-divider-mode' still gives a very gentle separation from
   ;; close tones in the ramp; enable it with `(window-divider-mode 1)' plus
   ;; the width variables.
   ;;
   ;; child-frame-border keeps popups framed consistently with other chrome.
   `(line-number ((,class (:foreground ,mono4 :background ,mono1))))
   `(line-number-current-line ((,class (:foreground ,mono6 :background ,mono0 :weight bold))))
   ;; The major tick has to read as more than the minor one it outranks.
   `(line-number-major-tick ((,class (:foreground ,mono5 :background ,mono1 :weight bold))))
   `(line-number-minor-tick ((,class (:foreground ,mono4 :background ,mono1))))
   `(window-divider ((,class (:foreground ,mono1))))
   `(window-divider-first-pixel ((,class (:foreground ,mono2))))
   `(window-divider-last-pixel ((,class (:foreground ,mono1))))
   ;; A rim takes the colour of what is outside it.  The inside of a popup is
   ;; more than one level, so a rim drawn from the inside agrees with one of
   ;; them and parts from the rest; drawn from the page it is a gap instead,
   ;; which is how areas are separated everywhere else here.
   `(child-frame-border ((,class (:background ,mono1))))

   ;; --- Font-lock (syntax primitives; bases for inherits) ---
   `(font-lock-comment-face ((,class (:foreground ,mono5 :slant italic))))
   `(font-lock-string-face ((,class (:foreground ,green))))
   `(font-lock-doc-face ((,class (:foreground ,mono4))))
   `(font-lock-keyword-face ((,class (:foreground ,purple))))
   `(font-lock-builtin-face ((,class (:foreground ,red))))
   `(font-lock-variable-name-face ((,class (:foreground ,orange))))
   `(font-lock-function-name-face ((,class (:foreground ,magenta))))
   `(font-lock-type-face ((,class (:foreground ,cyan))))
   `(font-lock-constant-face ((,class (:foreground ,blue))))
   `(font-lock-warning-face ((,class (:foreground ,yellow))))

   ;; --- Search, jump, isearch (interactive highlights) ---
   `(isearch ((,class (:foreground ,mono1 :background ,orange))))
   ;; The other matches take the idle plane: only the one point is on is
   ;; current.
   `(lazy-highlight ((,class (:foreground ,mono7 :background ,mono2))))
   `(avy-lead-face ((,class (:foreground ,mono1 :background ,blue))))
   `(avy-lead-face-0 ((,class (:foreground ,mono1 :background ,orange))))
   `(avy-lead-face-1 ((,class (:foreground ,mono1 :background ,red))))
   `(avy-lead-face-2 ((,class (:foreground ,mono1 :background ,magenta))))

   ;; --- Completion & narrowing (modern UIs) ---
   `(vertico-current ((,class (:background ,mono0))))
   `(orderless-match-face-0 ((,class (:foreground ,orange))))
   `(orderless-match-face-1 ((,class (:foreground ,magenta))))
   `(orderless-match-face-2 ((,class (:foreground ,green))))
   `(orderless-match-face-3 ((,class (:foreground ,red))))
   `(consult-buffer ((,class (:foreground ,mono6))))
   `(consult-file ((,class (:foreground ,mono5))))
   `(corfu-default ((,class (:background ,mono2))))
   `(corfu-current ((,class (:foreground ,mono6 :background ,mono0))))
   `(corfu-bar ((,class (:background ,mono5))))
   `(corfu-border ((,class (:background ,mono1))))

   ;; --- Navigation & project (dired, bookmark, etc.) ---
   `(dired-directory ((,class (:inherit font-lock-type-face))))
   `(dired-perm-write ((,class (:foreground ,mono4))))
   ;; dired-subtree hard-codes six backgrounds of its own, a teal-tinted dark
   ;; ramp that belongs to no theme -- and to a light variant, nothing at all.
   ;; It asks for six background planes; the ramp has two to spare (mono1 for
   ;; content, mono2 for the idle step on top of it), and spending mono3 here
   ;; would put a file listing at tab-bar brightness while mono0 would claim
   ;; the level that means "current".  So the
   ;; background carries the one thing it is needed for -- where an expanded
   ;; block begins and ends -- and the two planes alternate: each nesting sits
   ;; on the other plane from the block holding it.  How deep a row is, is
   ;; already said by the indentation.
   `(dired-subtree-depth-1-face ((,class (:background ,mono2))))
   `(dired-subtree-depth-2-face ((,class (:background ,mono1))))
   `(dired-subtree-depth-3-face ((,class (:background ,mono2))))
   `(dired-subtree-depth-4-face ((,class (:background ,mono1))))
   `(dired-subtree-depth-5-face ((,class (:background ,mono2))))
   `(dired-subtree-depth-6-face ((,class (:background ,mono1))))
   `(bookmark-face ((,class (:foreground ,mono5 :distant-foreground ,mono5))))
   `(deadgrep-filename-face ((,class (:inherit font-lock-builtin-face))))
   `(treemacs-root-face ((,class (:inherit font-lock-constant-face))))
   ;; Sidebar slab: give the whole treemacs window the idle layer (mono2) so
   ;; it reads as a side panel next to the mono1 content.  With
   ;; `vertical-border' at mono1 the transition carries no extra seam line, and
   ;; the panel stands out through its tone and its content.  If the step feels
   ;; strong, override this face to mono1 in your config.
   ;; hl-line inside the panel takes mono0, like every other current row.
   `(treemacs-window-background-face ((,class (:background ,mono2))))
   `(treemacs-hl-line-face ((,class (:background ,mono0))))
   `(treemacs-directory-face ((,class (:inherit font-lock-type-face))))
   `(treemacs-directory-collapsed-face ((,class (:inherit treemacs-directory-face))))
   `(treemacs-file-face ((,class (:foreground ,mono6))))
   `(treemacs-git-added-face ((,class (:foreground ,green))))
   `(treemacs-git-modified-face ((,class (:foreground ,yellow))))
   `(treemacs-git-untracked-face ((,class (:foreground ,cyan))))
   `(treemacs-git-ignored-face ((,class (:inherit shadow))))
   `(treemacs-git-conflict-face ((,class (:foreground ,red))))

   ;; dirvish (dired-based modern file manager). We style its custom hl/inactive
   ;; faces to follow the mono ramp. For dirvish-side (sidebar usage) the main
   ;; directory listing background remains mono1 (`default') because dirvish
   ;; re-uses dired buffers and does not expose a dedicated
   ;; window-background-face like treemacs. Distinction for the pane comes from
   ;; header-line, our hl-line faces, window dividers (which blend to panel
   ;; tone when next to a mono2 area), and optional multi-pane layout. This
   ;; matches the design constraints of the package. See README for a user hook
   ;; example if you want mono2 for the whole side pane.
   ;; Recommended dired-native alternative to treemacs (for users who prefer
   ;; dired-native navigation with built-in preview).
   `(dirvish-hl-line ((,class (:background ,mono0 :extend t))))
   `(dirvish-hl-line-inactive ((,class (:background ,mono2 :extend t))))
   `(dirvish-inactive ((,class (:inherit shadow))))

   ;; --- Marginalia (completion annotations; tone down lively file attrs) ---
   ;; Follows the mono usage (supplementary file info -> shadow/mono4 or
   ;; font-lock-comment-face/mono5) and colored semantic de-facto documented
   ;; in the design notes above.  Explicitly overrides marginalia's default
   ;; inherits from font-lock-* (which would produce purple/red/magenta/cyan
   ;; noise on "lrwxr-xr-x ..." permission strings and similar).
   ;; All marginalia-file-priv-* now use the shadow family for visual
   ;; uniformity within the compact permission annotation string.
   ;; Weight/underline/italic provide intra-mono distinction (e.g. bold 'd'
   ;; for dir, italic for link).  Underline is intentionally NOT used
   ;; here -- see the `:underline' decoration policy above (minimalist
   ;; themes such as Nord, Catppuccin and Modus do not underline
   ;; intra-mono distinction cases like `dired-perm-write' /
   ;; `marginalia-file-priv-*'; rustcity follows that line, and the
   ;; compact permission string stays uniform).  Leverages :inherit heavily
   ;; to respect marginalia's own face hierarchy (e.g. marginalia-size
   ;; inherits number, marginalia-file-name inherits documentation)
   ;; without touching the base font-lock-*/shadow definitions.
   ;; (For rustcity's higher-pop aesthetic the orderless matches use warm
   ;; pop colors, but file attrs in marginalia stay low-key mono.)
   `(marginalia-documentation ((,class (:inherit font-lock-comment-face))))
   `(marginalia-file-name ((,class (:inherit marginalia-documentation))))
   `(marginalia-file-owner ((,class (:inherit shadow))))
   `(marginalia-size ((,class (:inherit shadow))))
   `(marginalia-date ((,class (:inherit shadow))))
   `(marginalia-file-priv-no ((,class (:inherit shadow))))
   `(marginalia-file-priv-dir ((,class (:inherit shadow :weight bold))))
   `(marginalia-file-priv-link ((,class (:inherit shadow :slant italic))))
   `(marginalia-file-priv-read ((,class (:inherit shadow))))
   `(marginalia-file-priv-write ((,class (:inherit shadow))))
   `(marginalia-file-priv-exec ((,class (:inherit shadow))))
   `(marginalia-file-priv-other ((,class (:inherit shadow))))
   `(marginalia-file-priv-rare ((,class (:inherit shadow))))
   ;; Other marginalia faces (key, number, on/off, archive, installed,
   ;; value, etc.) intentionally left to their defface defaults or the
   ;; existing font-lock-/success-/error- inherits; they align with
   ;; semantic de-facto (e.g. on=success/green, archive=warning) or the
   ;; higher-pop cluster used for orderless matches and do not contribute
   ;; to the file-perm liveliness problem.

   ;; --- Dev tools (eglot, compilation, ein) ---
   `(eglot-mode-line ((,class (:inherit mode-line))))
   `(compilation-info ((,class (:inherit success))))
   `(compilation-mode-line-fail ((,class (:inherit compilation-error))))
   `(compilation-mode-line-exit ((,class (:inherit compilation-info))))

   ;; --- Evil / vim-emulation ---
   `(evil-snipe-first-match-face ((,class (:background ,mono0))))

   ;; --- Outlines (inherit font-lock-*) ---
   `(outline-1 ((,class (:inherit font-lock-type-face))))
   `(outline-2 ((,class (:inherit font-lock-variable-name-face))))
   `(outline-3 ((,class (:inherit font-lock-constant-face))))
   `(outline-4 ((,class (:inherit font-lock-builtin-face))))
   `(outline-5 ((,class (:inherit font-lock-function-name-face))))
   `(outline-6 ((,class (:inherit font-lock-string-face))))
   `(outline-7 ((,class (:inherit font-lock-warning-face))))
   `(outline-8 ((,class (:inherit font-lock-keyword-face))))

   ;; --- Org mode + extensions (rich derived faces) ---
   ;; Document
   `(org-document-title ((,class (:foreground ,mono7 :weight bold))))
   `(org-document-info ((,class (:foreground ,mono6))))

   ;; TODO / DONE
   ;; The colours are the way round they are drawn *from*, not the way round
   ;; they appear: `:inverse-video' swaps them at draw time, so the badge is
   ;; a red field with page-coloured text as before.
   ;;
   ;; Written this way so a highlighted line cannot take the badge off.  An
   ;; overlay's face outranks the text's -- always, whatever its priority --
   ;; but it outranks it attribute by attribute, and `hl-line' sets only a
   ;; background.  With the red in `:background' the band replaced it and the
   ;; keyword went page-colour on panel-colour, which is not a duller badge
   ;; but an invisible word.  In `:foreground' the band cannot reach it: all
   ;; that moves is the glyph, one step along the mono ramp.
   `(org-todo ((,class (:foreground ,red :background ,mono1 :inverse-video t))))
   `(org-done ((,class (:foreground ,green :background ,mono1 :inverse-video t))))
   `(org-headline-todo ((,class (:foreground ,mono7))))
   `(org-headline-done ((,class (:inherit font-lock-comment-face))))
   `(org-archived ((,class (:inherit org-headline-done))))
   `(org-agenda-done ((,class (:inherit org-headline-done))))
   `(org-agenda-dimmed-todo-face ((,class (:inherit font-lock-comment-face))))

   ;; Markup / structure
   `(org-drawer ((,class (:inherit font-lock-comment-face))))
   `(org-special-keyword ((,class (:inherit font-lock-comment-face))))
   `(org-ellipsis ((,class (:foreground ,mono4))))

   ;; Tables / columns
   `(org-table ((,class (:foreground ,mono6))))
   `(org-table-header ((,class (:foreground ,mono7 :background ,mono3))))
   `(org-column ((,class (:foreground ,mono7 :background ,mono3 :weight normal :slant normal :strike-through nil :underline nil))))
   `(org-column-title ((,class (:foreground ,mono7 :background ,mono3))))
   `(org-tag ((,class (:weight bold))))

   ;; Timestamps / dates
   `(org-time-stamp ((,class (:foreground ,mono5))))
   `(org-date ((,class (:foreground ,mono5))))
   `(org-sexp-date ((,class (:foreground ,mono5))))
   `(org-date-selected ((,class (:foreground ,mono1 :background ,orange))))

   ;; Formula / footnote
   `(org-formula ((,class (:foreground ,yellow))))
   `(org-footnote ((,class (:foreground ,mono5))))

   ;; Agenda - structure & dates
   `(org-agenda-structure ((,class (:foreground ,mono6))))
   ;; The same green org-foresight rules its bars at, and no weight.  The
   ;; package draws this very line itself whenever the hour is pinned, in
   ;; `org-foresight-report-now' -- which falls back to `font-lock-string-face'
   ;; here, the green above.  A different colour would make the same moment
   ;; look like two things depending on which of them drew it.
   `(org-agenda-current-time ((,class (:foreground ,green))))
   `(org-agenda-date-today ((,class (:foreground ,mono6 :weight bold :slant italic))))
   `(org-agenda-date-weekend ((,class (:foreground ,mono4 :weight bold))))
   `(org-agenda-clocking ((,class (:slant italic :inherit secondary-selection))))
   `(org-time-grid ((,class (:inherit font-lock-comment-face))))

   ;; Scheduling
   `(org-scheduled ((,class (:foreground ,mono6))))
   `(org-scheduled-today ((,class (:foreground ,mono6))))
   `(org-scheduled-previously ((,class (:foreground ,mono5))))
   `(org-upcoming-deadline ((,class (:inherit org-scheduled-previously))))

   ;; Habits
   `(org-habit-clear-face ((,class (:foreground ,mono1 :background ,blue))))
   `(org-habit-clear-future-face ((,class (:inherit org-habit-clear-face))))
   `(org-habit-ready-face ((,class (:foreground ,mono1 :background ,green))))
   `(org-habit-ready-future-face ((,class (:inherit org-habit-ready-face))))
   `(org-habit-alert-face ((,class (:foreground ,mono1 :background ,yellow))))
   `(org-habit-alert-future-face ((,class (:inherit org-habit-alert-face))))
   `(org-habit-overdue-face ((,class (:foreground ,mono1 :background ,red))))
   `(org-habit-overdue-future-face ((,class (:inherit org-habit-overdue-face))))

   ;; Other org (low-frequency)
   `(org-clock-overlay ((,class (:foreground ,mono7 :background ,mono3))))
   `(org-mode-line-clock-overrun ((,class (:foreground ,mono1 :background ,red))))
   `(org-dispatcher-highlight ((,class (:foreground ,mono7 :background ,mono0 :weight bold))))
   `(org-latex-and-related ((,class (:foreground ,mono5))))
   `(org-agenda-restriction-lock ((,class (:foreground ,mono7 :background ,mono3))))

   ;; Extensions (org-around packages)
   `(org-roam-header-line ((,class (:inherit header-line))))
   `(org-noter-notes-exist-face ((,class (:foreground ,mono6 :weight bold))))
   `(org-noter-no-notes-exist-face ((,class (:foreground ,mono5 :weight bold))))
   `(deft-header-face ((,class (:inherit font-lock-builtin-face :weight bold))))
   `(deft-title-face ((,class (:inherit font-lock-constant-face :weight bold))))

   ;; org-dayflow -- timeline column chrome on the mono ramp (not raw gray20).
   ;; Three bands can land on the same column: the weekend shade, the current
   ;; time and the cursor.  The weekend one is always there, so it takes the
   ;; idle step (mono2) and the two moving ones take the levels the ramp gives
   ;; to what is happening now: mono3 for the current time and mono0, the
   ;; current level, for the cursor.  Without the gap, a Saturday would swallow
   ;; the current-time column on two days in seven.  dim0/dim1 are not
   ;; candidates: those levels mean "this window is not the selected one"
   ;; wherever solaire-mode or auto-dim-other-buffers is on, and a weekend is
   ;; not that.
   `(org-dayflow-weekend-column-face ((,class (:background ,mono2 :extend t))))
   `(org-dayflow-weekend-face ((,class (:foreground ,mono4 :weight bold))))
   `(org-dayflow-weekday-face ((,class (:foreground ,mono5))))
   `(org-dayflow-units-face ((,class (:foreground ,mono5))))
   `(org-dayflow-label-face ((,class (:foreground ,mono5))))
   `(org-dayflow-query-face ((,class (:inherit org-agenda-structure))))
   `(org-dayflow-now-column-face ((,class (:background ,mono3 :extend t))))
   `(org-dayflow-cursor-column-face ((,class (:background ,mono0 :extend t))))
   `(org-dayflow-now-unit-face ((,class (:inherit calendar-today))))
   `(org-dayflow-cursor-unit-face ((,class (:inherit org-date-selected))))
   `(org-dayflow-title-done-face ((,class (:inherit org-headline-done :strike-through t))))

   ;; org-foresight -- the capacity bar and the rows it adds to the agenda.
   ;; Two rules.  Grey says "work already claimed", and only three steps of it,
   ;; two apart, because a ramp fine enough to encode six things is a ramp
   ;; nobody reads; booked tops out at mono6, the badge's own grey, so nothing
   ;; inside a section is louder than the badge announcing it.  Colour is kept
   ;; for what is not claimed work, which is where the decisions are: blue is
   ;; room -- spare, and the free gaps it is made of -- and green is life,
   ;; neither work nor room, and not to be mistaken for either.  The bar draws
   ;; private between travel and promised, so every pair that touches is either
   ;; two steps of grey apart or a change of hue.
   `(org-foresight-report-booked ((,class (:foreground ,mono6))))
   `(org-foresight-report-travel ((,class (:foreground ,mono4))))
   ;; The quietest the ramp goes and still be text, shared with the other
   ;; faint markers.
   `(org-foresight-report-promised ((,class (:foreground ,mono4))))
   `(org-foresight-report-spare ((,class (:foreground ,blue))))
   ;; Emptiness, wherever it is drawn: the same dot in the bar and in the
   ;; sparkline, so two identical characters stop looking like two sizes.
   `(org-foresight-report-empty ((,class (:foreground ,mono4 :weight bold))))
   `(org-foresight-report-private ((,class (:foreground ,green))))
   ;; The reserve keeps the package's outline in the overrun's own yellow: it
   ;; is the last thing between the day and an overrun, so spending it is
   ;; being over without having said so.  `unclocked' is that same reserve
   ;; found spent, so it is the same yellow -- the outline held open ahead of
   ;; now, met empty behind it.  The bar boxes every segment itself, so
   ;; nothing here needs to set one.
   `(org-foresight-report-overcommitted ((,class (:foreground ,yellow))))
   `(org-foresight-report-surge ((,class (:foreground ,yellow))))
   `(org-foresight-report-unclocked ((,class (:foreground ,yellow))))
   ;; Hours the watcher accounted for and nobody claimed: the grey the
   ;; sparkline already gives time away from the machine.
   `(org-foresight-report-away ((,class (:foreground ,mono4))))
   ;; Where now falls, in the colour of the hours it protects: everything
   ;; right of the mark is the part of the day still to be decided.  The same
   ;; green `org-agenda-current-time' is set to above, since the package draws
   ;; that line itself whenever the hour is pinned.
   `(org-foresight-report-now ((,class (:foreground ,green))))
   `(org-foresight-agenda-derived ((,class (:slant italic))))
   `(org-foresight-agenda-free ((,class (:foreground ,blue :slant italic))))
   ;; The one mark that reports no decision, so the one mark with no hue: the
   ;; other two borrow the overrun's yellow and the colour of room precisely
   ;; because something has to be done about them.  mono6, the badges' grey --
   ;; a step brighter than the rows it sits among, which is all a mark that
   ;; means "nothing to resolve here" needs to be.
   `(org-foresight-agenda-shared ((,class (:foreground ,mono6))))
   ;; Where a row came from, not what to do about it: the same quiet grey as
   ;; the shared mark, and the shape tells them apart.
   `(org-foresight-agenda-arrival ((,class (:foreground ,mono6))))
   ;; The bracket down the left edge marking the working hours.  A step below
   ;; the marks: a mark asks for a decision and the frame asks for nothing, so
   ;; it should be findable when looked for and invisible when not.
   `(org-foresight-agenda-spine ((,class (:foreground ,mono5))))

   ;; --- Magit (Git porcelain; rich derived mode) ---
   ;; Follows design notes: "Org/Magit/Agenda and similar rich modes inherit the
   ;; font-lock and mono decisions heavily; hues only for key status indicators".
   ;; All specs use the variant-specific mono*/accent vars bound in the enclosing
   ;; let*, so no explicit dark/light branching is needed here (unlike many
   ;; magit deffaces).  This also works well with rustcity's higher-pop
   ;; (accents will pop more due to high sat in neon variant).
   ;; Prefer :inherit + mono* over direct colors for harmony and DRY.
   ;; `:extend t' on diff/heading/blame bgs is supplied by defface and
   ;; preserved by `face-spec-recalc' (see face-spec discipline notes
   ;; above), so it is not restated here.
   `(magit-section-highlight ((,class (:background ,mono0))))
   `(magit-section-heading ((,class (:inherit font-lock-keyword-face :weight bold))))
   `(magit-section-secondary-heading ((,class (:weight bold))))
   `(magit-section-heading-selection ((,class (:inherit magit-section-highlight :foreground ,orange :weight bold))))
   `(magit-diff-file-heading ((,class (:weight bold))))
   `(magit-diff-file-heading-highlight ((,class (:inherit magit-section-highlight :weight bold))))
   `(magit-diff-file-heading-selection ((,class (:inherit magit-diff-file-heading-highlight :foreground ,orange))))
   `(magit-diff-hunk-heading ((,class (:background ,mono3 :foreground ,mono6))))
   `(magit-diff-hunk-heading-highlight ((,class (:background ,mono0 :foreground ,mono7))))
   `(magit-diff-hunk-heading-selection ((,class (:inherit magit-diff-hunk-heading-highlight :foreground ,orange))))
   `(magit-diff-conflict-heading ((,class (:inherit magit-diff-hunk-heading))))
   `(magit-diff-revision-summary ((,class (:inherit magit-diff-hunk-heading))))
   `(magit-diff-lines-heading ((,class (:background ,orange :foreground ,mono1))))
   `(magit-diff-context ((,class (:foreground ,mono5))))
   `(magit-diff-context-highlight ((,class (:background ,mono0 :foreground ,mono6))))
   `(magit-diff-added ((,class (:background ,mono2 :foreground ,green))))
   `(magit-diff-added-highlight ((,class (:background ,mono0 :foreground ,green))))
   `(magit-diff-removed ((,class (:background ,mono2 :foreground ,red))))
   `(magit-diff-removed-highlight ((,class (:background ,mono0 :foreground ,red))))
   `(magit-diff-base ((,class (:background ,mono2 :foreground ,yellow))))
   `(magit-diff-base-highlight ((,class (:background ,mono0 :foreground ,yellow))))
   `(magit-diff-our ((,class (:inherit magit-diff-removed))))
   `(magit-diff-their ((,class (:inherit magit-diff-added))))
   `(magit-diff-our-highlight ((,class (:inherit magit-diff-removed-highlight))))
   `(magit-diff-their-highlight ((,class (:inherit magit-diff-added-highlight))))
   `(magit-diffstat-added ((,class (:foreground ,green))))
   `(magit-diffstat-removed ((,class (:foreground ,red))))
   `(magit-process-ok ((,class (:foreground ,green :weight bold))))
   `(magit-process-ng ((,class (:foreground ,red :weight bold))))
   `(magit-log-author ((,class (:foreground ,mono6))))
   `(magit-log-date ((,class (:foreground ,mono5))))
   `(magit-log-graph ((,class (:foreground ,mono4))))
   `(magit-dimmed ((,class (:foreground ,mono4))))
   `(magit-hash ((,class (:foreground ,mono4))))
   `(magit-tag ((,class (:foreground ,yellow :weight bold))))
   `(magit-branch-remote ((,class (:foreground ,green :weight bold))))
   `(magit-branch-local ((,class (:foreground ,cyan :weight bold))))
   `(magit-branch-current ((,class (:foreground ,blue :weight bold :box t))))
   `(magit-branch-upstream ((,class (:slant italic))))
   `(magit-head ((,class (:inherit magit-branch-local))))
   `(magit-refname ((,class (:foreground ,mono5))))
   `(magit-keyword ((,class (:inherit font-lock-string-face))))
   `(magit-keyword-squash ((,class (:inherit font-lock-warning-face))))
   `(magit-blame-highlight ((,class (:background ,mono0))))
   `(magit-blame-heading ((,class (:background ,mono3 :foreground ,mono6
                                               :weight normal :slant normal
                                               :box (:color ,mono2 :line-width 2)))))
   `(magit-blame-summary ((,class (:foreground ,mono7))))
   `(magit-blame-hash ((,class (:foreground ,mono4))))
   `(magit-blame-name ((,class (:foreground ,mono6))))
   `(magit-blame-date ((,class (:foreground ,mono5))))

   ;; --- transient ---
   ;; Override only the faces that hard-code hex/ANSI names in their defface.
   ;; The rest of transient's faces inherit cleanly (font-lock, shadow,
   ;; highlight, font-lock-builtin-face) and need no entry here.
   ;; Key colors follow rustcity semantics: stay=green (continuity),
   ;; return=yellow (warn/route), recurse=blue (descend/link),
   ;; stack=magenta (escalate), exit=orange (decisive leave), noop=mono4
   ;; (shadow ramp). Box colors of the (non)standard-key faces are pinned
   ;; to rustcity's cyan / magenta instead of vanilla ANSI cyan / magenta.
   `(transient-enabled-suffix  ((,class (:background ,green :foreground ,mono1 :weight bold))))
   `(transient-disabled-suffix ((,class (:background ,red   :foreground ,mono1 :weight bold))))
   `(transient-key-stay        ((,class (:foreground ,green))))
   `(transient-key-noop        ((,class (:foreground ,mono4))))
   `(transient-key-return      ((,class (:foreground ,yellow))))
   `(transient-key-recurse     ((,class (:foreground ,blue))))
   `(transient-key-stack       ((,class (:foreground ,magenta))))
   `(transient-key-exit        ((,class (:foreground ,orange))))
   `(transient-nonstandard-key ((,class (:box (:line-width (-1 . -1) :color ,cyan)))))
   `(transient-mismatched-key  ((,class (:box (:line-width (-1 . -1) :color ,magenta)))))

   ;; --- diff-hl / ediff ---
   ;; Mirrors the `magit-diff-*' semantic mapping (red=removed, green=added,
   ;; yellow=base/combined, blue=ancestor). Follows the face-spec discipline
   ;; documented above: `:extend t' is omitted when the defface already
   ;; supplies it (vanilla ediff-current-*/ediff-even-*/ediff-odd-* defaces
   ;; all carry it). diff-hl renders one column in the fringe, so only
   ;; foreground hue matters; bg/extend from the inherit chain are dropped.

   ;; diff-hl
   `(diff-hl-insert ((,class (:foreground ,green))))
   `(diff-hl-delete ((,class (:foreground ,red))))
   `(diff-hl-change ((,class (:foreground ,yellow))))

   ;; ediff: current diff (focused chunk)
   `(ediff-current-diff-A        ((,class (:background ,mono0 :foreground ,red))))
   `(ediff-current-diff-B        ((,class (:background ,mono0 :foreground ,green))))
   `(ediff-current-diff-C        ((,class (:background ,mono0 :foreground ,yellow))))
   `(ediff-current-diff-Ancestor ((,class (:background ,mono0 :foreground ,blue))))

   ;; ediff: fine diff (sub-region emphasis within current; the hue fills, since
   ;; the current diff already holds the near depth)
   `(ediff-fine-diff-A           ((,class (:background ,red    :foreground ,mono1 :weight bold))))
   `(ediff-fine-diff-B           ((,class (:background ,green  :foreground ,mono1 :weight bold))))
   `(ediff-fine-diff-C           ((,class (:background ,yellow :foreground ,mono1 :weight bold))))
   `(ediff-fine-diff-Ancestor    ((,class (:background ,blue   :foreground ,mono1 :weight bold))))

   ;; ediff: non-current diffs (alternating markers; quiet so current wins)
   `(ediff-even-diff-A           ((,class (:background ,mono2 :foreground ,mono5))))
   `(ediff-even-diff-B           ((,class (:background ,mono2 :foreground ,mono5))))
   `(ediff-even-diff-C           ((,class (:background ,mono2 :foreground ,mono5))))
   `(ediff-even-diff-Ancestor    ((,class (:background ,mono2 :foreground ,mono5))))
   `(ediff-odd-diff-A            ((,class (:background ,mono2 :foreground ,mono5))))
   `(ediff-odd-diff-B            ((,class (:background ,mono2 :foreground ,mono5))))
   `(ediff-odd-diff-C            ((,class (:background ,mono2 :foreground ,mono5))))
   `(ediff-odd-diff-Ancestor     ((,class (:background ,mono2 :foreground ,mono5))))

   ;; --- Calendar / eww (other apps) ---
   `(calendar-today ((,class (:inherit font-lock-warning-face :underline t))))
   `(calendar-weekend-header ((,class (:inherit font-lock-type-face))))
   `(holiday ((,class (:background ,mono3))))
   `(diary ((,class (:inherit font-lock-string-face))))
   `(eww-valid-certificate ((,class (:weight bold :foreground ,mono6))))

   ;; --- org-timeblock (calendar day/week time blocks) ---
   ;; Block palette maps to the theme's hues with knockout text; the hour
   ;; line and selection/mark use the mono ramp so they never collide with a
   ;; block hue.  now = green (present position); red is reserved for
   ;; caution/warning and is therefore not used for the now line.
   `(org-timeblock-red     ((,class (:background ,red     :foreground ,mono1 :extend t))))
   `(org-timeblock-green   ((,class (:background ,green   :foreground ,mono1 :extend t))))
   `(org-timeblock-yellow  ((,class (:background ,yellow  :foreground ,mono1 :extend t))))
   `(org-timeblock-blue    ((,class (:background ,blue    :foreground ,mono1 :extend t))))
   `(org-timeblock-magenta ((,class (:background ,magenta :foreground ,mono1 :extend t))))
   `(org-timeblock-cyan    ((,class (:background ,cyan    :foreground ,mono1 :extend t))))
   `(org-timeblock-hours-line ((,class (:background ,mono3 :extend t))))
   `(org-timeblock-current-time-indicator ((,class (:background ,green))))
   `(org-timeblock-select ((,class (:background ,mono0 :foreground ,mono7 :extend t))))
   `(org-timeblock-mark ((,class (:background ,mono2 :foreground ,mono7 :extend t))))))

;; ANSI 16-color slot strategy.
;;
;; The eight hues fill red/green/yellow/blue/magenta/cyan (slots 1-6) plus
;; orange at brightred (9) and purple at brightmagenta (13); brightcyan (14)
;; repeats cyan, the usual fallback for a palette that carries eight hues
;; rather than twelve.  The remaining seven slots carry the mono ramp:
;;
;;   slot 0  black        mono0   (the level outside the background)
;;   slot 8  brightblack  mono2   (dim but readable -- the grey TUI tools
;;                                   reach for when they mean de-emphasised)
;;   slot 10 brightgreen  mono3
;;   slot 11 brightyellow mono4
;;   slot 12 brightblue   mono5
;;   slot 7  white        mono6
;;   slot 15 brightwhite  mono7   (brightest; repeats the foreground)
;;
;; The background is mono1 and the text mono7, so those two take the
;; terminal's own background and foreground rather than a numbered slot.
;; Between them the whole eight-step ramp reaches a terminal, and both grey
;; pairs run the way their names promise: black darker than brightblack,
;; white than brightwhite.
;;
;; dim0 and dim1 are not exported.  They mean \"this Emacs window is not the
;; selected one\", which a terminal has no notion of, so a slot spent on one
;; would be a slot no program could ask for.  Leaving them out is what lets
;; brightcyan go back to being cyan.
(defconst rustcity--export-name-map
  '((mono1   . background)
    (mono7   . foreground)
    (mono0   . black)
    (mono2   . brightblack)
    (mono3   . brightgreen)
    (mono4   . brightyellow)
    (mono5   . brightblue)
    (mono6   . white)
    (mono7   . brightwhite)
    (red     . red)
    (orange  . brightred)
    (yellow  . yellow)
    (green   . green)
    (cyan    . cyan)
    (cyan    . brightcyan)
    (blue    . blue)
    (purple  . brightmagenta)
    (magenta . magenta)))

;;;###autoload
(defun rustcity-export-palette (format &optional variant)
  "Export the palette for external tools.
FORMAT is `json', `alist', or `hex-list'.
VARIANT is `neon' or `downpour' (defaults from `frame-background-mode')."
  (let* ((palette (rustcity-palette variant))
         ;; ANSI names in the 0-15 slot order for hex-list.
         ;; Canonical ANSI 0-15 slot order.  It has to match the real slot
         ;; numbering, since an external consumer may index this list by
         ;; position rather than read the names.
         (ordered-keys '(black red green yellow blue magenta cyan white
                               brightblack brightred brightgreen brightyellow
                               brightblue brightmagenta brightcyan brightwhite)))
    (pcase format
      ('alist
       (mapcar (lambda (pair)
                 (let* ((internal (car pair))
                        (ansi (cdr pair)))
                   (cons ansi (alist-get internal palette))))
               rustcity--export-name-map))
      ('hex-list
       (mapcar (lambda (ansi)
                 (let ((internal (car (rassoc ansi rustcity--export-name-map))))
                   (alist-get internal palette)))
               ordered-keys))
      ('json
       (let ((json-pairs
              (mapconcat
               (lambda (pair)
                 (let* ((internal (car pair))
                        (ansi (cdr pair))
                        (v (alist-get internal palette)))
                   (format "  %S: %S" (symbol-name ansi) v)))
               rustcity--export-name-map
               ",\n")))
         (concat "{\n" json-pairs "\n}")))
      (_
       (error "Unsupported FORMAT: %s. Use 'json, 'alist or 'hex-list" format)))))

;;;###autoload
(defun rustcity-apply-hsl-correction (&optional correction)
  "Recompute derived palettes using CORRECTION (or current value) and refresh.

If the rustcity theme is active this disables and reloads it so the new
palette takes effect immediately (preserving the prior
`frame-background-mode').  This is the supported way to change the
correction at runtime after the package has been loaded.

Example:
  (setq rustcity-hsl-correction \\='(0.0 0.0 -2.0))
  (rustcity-apply-hsl-correction)"
  (when correction
    (setq rustcity-hsl-correction correction))
  (rustcity--recompute-derived-palettes)
  (when (custom-theme-enabled-p 'rustcity)
    (let ((was-light (eq frame-background-mode 'light)))
      (disable-theme 'rustcity)
      (setq frame-background-mode (if was-light 'light 'dark))
      (load-theme 'rustcity t))))

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-directory load-file-name)))

(provide-theme 'rustcity)
(provide 'rustcity-theme)
;;; rustcity-theme.el ends here
