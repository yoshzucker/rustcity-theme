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
;;   (rustcity-palette)        ; internal semantic keys (mono0-7 + 8 hues)
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

;;; Code:

(require 'hsluv)
(require 'cl-lib)

(deftheme rustcity
  "A theme inspired by a rusted industrial cityscape—silent under neon rain, and hollow in a daylight downpour.")

(defconst rustcity-downpour-hsl
  '((mono0   . (260  20  86))
    (dim0    . (260  20  84))   ; dedicated dim levels for non-selected (weaker than mono1 aux)
    (dim1    . (260  20  82))
    (mono1   . (260  20  79))
    (mono2   . (260  20  72))
    (mono3   . (260  20  65))
    (mono4   . (260  20  58))
    (mono5   . (260  20  51))
    (mono6   . (260  20  44))
    (mono7   . (260  20  37))
    (red     . (  0 100  57))
    (orange  . ( 30 100  57))
    (yellow  . ( 70 100  57))
    (green   . (110 100  57))
    (cyan    . (200 100  57))
    (blue    . (250 100  57))
    (purple  . (280 100  57))
    (magenta . (310 100  57))))

(defconst rustcity-neon-hsl
  '((mono0   . (260  55  14))
    (dim0    . (260  55  16))   ; dedicated dim levels for non-selected (weaker than mono1 aux)
    (dim1    . (260  55  18.5))
    (mono1   . (260  55  21))
    (mono2   . (260  55  28))
    (mono3   . (260  55  35))
    (mono4   . (260  55  42))
    (mono5   . (260  55  49))
    (mono6   . (260  55  56))
    (mono7   . (260  55  63))
    (red     . (  0 100  63))
    (orange  . ( 30 100  63))
    (yellow  . ( 70 100  63))
    (green   . (110 100  63))
    (cyan    . (200 100  63))
    (blue    . (250 100  63))
    (purple  . (280 100  63))
    (magenta . (310 100  63))))

(defcustom rustcity-hsl-correction '(0.0 0.0 0.0)
  "HSLuv deltas (h s l) added to every base color before hex conversion.

Intended to compensate for display characteristic differences (e.g.
perceived darkness of the neon variant mono0 background on some
setups vs. others).  The correction is applied uniformly and
linearly in HSLuv space to all 16 palette entries (mono0-7 and the
8 hues) for both neon and downpour variants.

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
  mono0..mono7  (perceptual gray ramp for main content; mono0 is background,
                 mono7 foreground for the chosen variant; de-facto roles:
                 mono1 for subtle selection/highlight on main, etc.)
  dim0, dim1    (dedicated dim levels between mono0 and mono1, for the base
                 background of non-selected/unreal areas when using the
                 supported modes auto-dim-other-buffers-mode or solaire-mode.
                 Allows weaker dim than the standard aux step at mono1 while
                 preserving the 8-step mono semantics for content.)
  red orange yellow green cyan blue purple magenta  (accent hues)

The returned colors respect `rustcity-hsl-correction' (if non-zero).
For external tools / terminal emulators prefer `rustcity-export-palette',
which maps to conventional ANSI/terminal color names (background, black,
brightblack, ...). The dim* levels are internal to Emacs UI and not
included in the 16-color export."
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
  ;;                       Dedicated dim levels (dim0/dim1, between mono0 and
  ;;                       this step) are provided for the supported modes'
  ;;                       non-selected/unreal faces, so dim can be weaker than
  ;;                       the main aux while preserving the 8-step semantics
  ;;                       for content.
  ;;     step ~2-3:        alt / medium subtle (active chrome bg, some
  ;;                       highlights).
  ;;     step ~4 (mid-low): faint / secondary (shadow, doc-face, low-
  ;;                       priority or weekend indicators).
  ;;     step ~5 (mid):    comments and other secondary / low-weight text
  ;;                       and UI elements.
  ;;     step ~6 (high-mid): prominent secondary (cursor bg, minibuffer
  ;;                         prompt, current completion item text, inactive
  ;;                         chrome fg, variables/identifiers as the most
  ;;                         frequent text, etc.).
  ;;     step ~7 (highest): primary / main foreground (default text,
  ;;                        active chrome text, etc.).
  ;;   (The exact numbering and lightness deltas are implementation
  ;;   details; the *role assignment to the 8 levels* is the survey-derived
  ;;   universal pattern.)
  ;; - The overall derived principle: the gray ramp layers supply the primary
  ;;   visual rhythm; color is used as accent on top of this foundation.

  ;; Layered chrome / panel texture (universal application of the above)
  ;;
  ;; To create visual depth and a layered "slab" feel even with Emacs' sparse
  ;; chrome primitives (no borders/shadows/gradients), we deliberately map UI
  ;; structural elements to adjacent ramp steps. The main content plane is at
  ;; mono0. Explicit auxiliary panels (such as the treemacs sidebar) use the
  ;; next step (mono1) via their dedicated faces for a subtle layered effect.
  ;;
  ;; For the divider between such a panel and the main content, we set it to
  ;; the main content color (mono0). This produces a clean transition without
  ;; a visible seam line that would fight the plane expression — the
  ;; distinction comes from the tone difference (where present) and the
  ;; content itself.
  ;;
  ;; We keep normal editing buffers on the main mono0 plane. The main de-facto
  ;; signal for non-active windows is `mode-line-inactive` (set to mono1 here,
  ;; providing a gentle auxiliary-layer treatment at the chrome level).
  ;; For users who want a global subtle shift for non-selected windows
  ;; or unreal buffers, we provide explicit face support for the two de-facto
  ;; modes that can use exact palette colors without inventing new ones:
  ;; solaire-mode (for "unreal" buffers) and auto-dim-other-buffers-mode (for
  ;; non-selected windows). Their dim faces are set to dim0 (a dedicated level
  ;; between mono0 and the standard aux mono1), so enabling the mode gives a
  ;; weaker aux tone while preserving the full de-facto role assignment for
  ;; the main 8 levels (subtle at mono1 etc.) on content. dim1 is also
  ;; available for customization.
  ;;
  ;; Selected tab and current content deliberately share mono0 so the working
  ;; surface feels continuous, while chrome elements (bars, header) use higher
  ;; steps for layered separation. This is ramp layering as the primary
  ;; decoration.
  ;;
  ;; See the "Gutter, dividers..." section below and README for the current
  ;; practical choices and usage notes (including how to enable the two modes).

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

  (custom-theme-set-faces
   'rustcity

   ;; Face support for two de-facto dimming / non-selected-window modes
   ;; (solaire-mode for "unreal" buffers and auto-dim-other-buffers-mode for
   ;; non-selected windows). These are the modes that can consume exact
   ;; palette colors without inventing new ones.
   ;;
   ;; We use dedicated dim levels (dim0/dim1, positioned between mono0 and
   ;; the standard aux mono1) for their base dim faces. This keeps the main
   ;; 8-step mono ramp (and its de-facto roles at mono1 for subtle selection
   ;; etc. on main content) unchanged, while allowing a weaker "ほんの少し"
   ;; dim for non-selected areas. Inside dimmed areas, highlights use the
   ;; main subtle step (mono1) or mono2 for contrast.
   `(solaire-default-face ((,class (:background ,dim0))))
   `(solaire-hl-line-face ((,class (:background ,mono1))))
   `(solaire-region-face ((,class (:background ,mono1 :extend t))))
   `(auto-dim-other-buffers ((,class (:background ,dim0))))
   `(auto-dim-other-buffers-hide ((,class (:foreground ,dim0 :background ,dim0))))

   ;; --- Core primitives ---
   `(default ((,class (:foreground ,mono7 :background ,mono0))))
   `(fixed-pitch ((,class (:family unspecified))))
   `(variable-pitch ((,class (:family unspecified))))
   `(cursor ((,class (:background ,mono6))))
   `(fringe ((,class (:background ,mono0))))
   `(border ((,class (:background ,mono0))))
   `(internal-border ((,class (:background ,mono0))))
   ;; Divider between windows. To achieve a clean layered feel, we set the
   ;; divider to the main content color (mono0). This removes any visible seam
   ;; line artifact between a differentiated side panel (e.g. treemacs at mono1)
   ;; and the main editor (mono0). The distinction between areas is then
   ;; expressed purely by the bg tone difference (where used) + the content
   ;; itself (tree structure vs code, icons, etc.) and window geometry.
   ;;
   ;; This is a common de-facto approach for quiet, layered looks: avoid a
   ;; contrasting border line that fights the plane expression. Regular
   ;; content-to-content splits can still get subtle separation when
   ;; window-divider-mode is enabled (see the Gutter section below).
   ;;
   ;; Note on treemacs mono1: The step from main mono0 to mono1 is the standard
   ;; first auxiliary step (panels use this; the even weaker dim0/dim1 are for
   ;; the modes' non-selected content). If it feels too strong compared to the
   ;; main bg, you can override `treemacs-window-background-face` to mono0 in
   ;; your personal config; the panel character will come from its distinct
   ;; content, hl-line, and the clean divider treatment.
   `(vertical-border ((,class (:foreground ,mono0))))
   `(region ((,class (:background ,mono1 :extend t))))
   `(secondary-selection ((,class (:background ,mono2))))
   `(highlight ((,class (:background ,mono1))))
   `(shadow ((,class (:foreground ,mono4))))
   `(match ((,class (:foreground ,mono0 :background ,green))))
   `(show-paren-match ((,class (:background ,mono1 :weight bold))))
   `(link ((,class (:foreground ,blue :underline t))))
   `(link-visited ((,class (:foreground ,purple :underline t))))
   `(error ((,class (:foreground ,red))))
   `(warning ((,class (:foreground ,yellow))))
   `(success ((,class (:foreground ,green))))
   `(minibuffer-prompt ((,class (:foreground ,mono6))))
   `(tooltip ((,class (:foreground ,mono7 :background ,orange))))
   `(help-key-binding ((,class (:foreground ,mono7 :background ,mono2 :box unspecified))))

   ;; --- Modeline, header-line, tab-bar, tab-line (UI chrome) ---
   ;; Layered chrome strategy: We differentiate "chrome layers" (bars, side
   ;; panels) from the main "content plane" using adjacent steps on the mono
   ;; ramp. This is the primary way to create visual depth and a layered
   ;; "slab" feel in Emacs, which lacks heavy decorative primitives (borders,
   ;; shadows, titlebar gradients) available in other editors.
   ;; - tab-bar bg at mono2 (toolbar/frame chrome layer).
   ;; - Selected tab bg = mono0 (flushes with buffer default bg), so the active
   ;;   view surface is continuous from the tab "lid" down into the content.
   ;;   This creates the recessed/chiseled selection + unified chrome slab.
   ;; - Inactive tabs sit on the bar (mono1) with dimmer fg for clear but quiet
   ;;   distinction.
   ;; - tab-line (per-window) follows a similar but slightly more content-adjacent
   ;;   layering (bar at mono1) since it lives closer to buffer content.
   ;; - mode-line already uses mono2 (active chrome) and mono1 (inactive),
   ;;   harmonizing with the new tab-bar top bar.
   `(mode-line ((,class (:foreground ,mono7 :background ,mono2))))
   ;; mode-line-inactive stays at mono1: this is chrome-layer "inactive" treatment
   ;; (one step below active chrome at mono2). It is not a content subtle bg.
   ;; When a window is dimmed by the supported modes the mode-line itself may
   ;; still be remapped or left, but the layer distinction is preserved per
   ;; de-facto (inactive chrome is distinct from both main content and the
   ;; dim content bg).
   `(mode-line-inactive ((,class (:foreground ,mono6 :background ,mono1))))
   `(mode-line-buffer-id ((,class (:weight unspecified))))
   `(header-line ((,class (:foreground ,mono6 :background ,mono3 :weight unspecified))))
   `(tab-bar ((,class (:foreground ,mono7 :background ,mono2))))
   `(tab-bar-tab ((,class (:foreground ,mono7 :background ,mono0 :box unspecified))))
   ;; tab inactive tabs sit "below" the bar (mono2) using mono1. This is a
   ;; chrome recess, not a content selection. Kept at mono1 for layer
   ;; coherence even with the compressed low end.
   `(tab-bar-tab-inactive ((,class (:foreground ,mono6 :background ,mono1))))
   `(tab-bar-tab-group-current ((,class (:inherit tab-bar-tab :weight bold))))
   `(tab-bar-tab-group-inactive ((,class (:inherit tab-bar-tab-inactive))))
   ;; tab-line lives closer to content. Its bar bg at mono1 and inactive at
   ;; mono1 are chrome-adjacent.
   `(tab-line ((,class (:foreground ,mono7 :background ,mono1))))
   `(tab-line-tab ((,class (:foreground ,mono6 :background ,mono1))))
   `(tab-line-tab-current ((,class (:foreground ,mono7 :background ,mono0 :box unspecified))))
   `(tab-line-tab-inactive ((,class (:foreground ,mono5 :background ,mono1))))
   `(tab-line-tab-modified ((,class (:inherit tab-line-tab-current :weight bold))))

   ;; --- Gutter, dividers, borders (additional vertical/horizontal layering) ---
   ;; These provide extra "slab" and "grout" elements with almost zero added
   ;; decoration primitives, purely via mono ramp assignment.
   ;; Gutter (line numbers) acts as a vertical pillar on the left.
   ;;
   ;; Divider choice for clean layered feel:
   ;; Setting the divider to the main content color (mono0) produces the nicest
   ;; layered look without a visible seam line artifact. When using a
   ;; differentiated side panel (e.g. treemacs at mono1), the transition to the
   ;; main mono0 editor is seamless — the panel stands out through its tone
   ;; and content, not through an extra contrasting border.
   ;;
   ;; This is a common de-facto approach for quiet, modern slate/dark themes:
   ;; let the face (plane) tone difference and the content itself define areas,
   ;; rather than relying on a bright divider line that can fight the plane
   ;; expression.
   ;;
   ;; For regular content-to-content splits, enabling `window-divider-mode`
   ;; can still give a very gentle separation using close tones in the ramp.
   ;; Enable with `(window-divider-mode 1)` + the width variables.
   ;;
   ;; child-frame-border keeps popups framed consistently with other chrome.
   `(line-number ((,class (:foreground ,mono4 :background ,mono0))))
   `(line-number-current-line ((,class (:foreground ,mono6 :background ,mono1 :weight bold))))
   `(line-number-major-tick ((,class (:foreground ,mono3 :background ,mono0 :weight bold))))
   `(line-number-minor-tick ((,class (:foreground ,mono4 :background ,mono0))))
   `(window-divider ((,class (:foreground ,mono0))))
   `(window-divider-first-pixel ((,class (:foreground ,mono1))))
   `(window-divider-last-pixel ((,class (:foreground ,mono0))))
   `(child-frame-border ((,class (:background ,mono2))))

   ;; --- Font-lock (syntax primitives; bases for inherits) ---
   `(font-lock-comment-face ((,class (:foreground ,mono5 :slant italic))))
   `(font-lock-string-face ((,class (:foreground ,green))))
   `(font-lock-doc-face ((,class (:foreground ,mono4))))
   `(font-lock-keyword-face ((,class (:foreground ,purple))))
   `(font-lock-builtin-face ((,class (:foreground ,red))))
   `(font-lock-variable-name-face ((,class (:foreground ,mono6))))
   `(font-lock-function-name-face ((,class (:foreground ,magenta))))
   `(font-lock-type-face ((,class (:foreground ,cyan))))
   `(font-lock-constant-face ((,class (:foreground ,blue))))
   `(font-lock-warning-face ((,class (:foreground ,yellow))))

   ;; --- Search, jump, isearch (interactive highlights) ---
   `(isearch ((,class (:foreground ,mono0 :background ,orange))))
   `(lazy-highlight ((,class (:foreground ,mono0 :background ,mono2))))
   `(avy-lead-face ((,class (:foreground ,mono0 :background ,blue))))
   `(avy-lead-face-0 ((,class (:foreground ,mono0 :background ,orange))))
   `(avy-lead-face-1 ((,class (:foreground ,mono0 :background ,red))))
   `(avy-lead-face-2 ((,class (:foreground ,mono0 :background ,magenta))))

   ;; --- Completion & narrowing (modern UIs) ---
   `(vertico-current ((,class (:background ,mono1))))
   `(orderless-match-face-0 ((,class (:weight unspecified :foreground ,orange))))
   `(orderless-match-face-1 ((,class (:weight unspecified :foreground ,magenta))))
   `(orderless-match-face-2 ((,class (:weight unspecified :foreground ,green))))
   `(orderless-match-face-3 ((,class (:weight unspecified :foreground ,red))))
   `(consult-buffer ((,class (:foreground ,mono6))))
   `(consult-file ((,class (:foreground ,mono5))))
   `(corfu-default ((,class (:background ,mono1))))
   `(corfu-current ((,class (:foreground ,mono6 :background ,mono1))))
   `(corfu-bar ((,class (:background ,mono5))))

   ;; --- Navigation & project (dired, bookmark, etc.) ---
   `(dired-directory ((,class (:inherit font-lock-type-face))))
   `(dired-perm-write ((,class (:foreground ,mono4 :underline t))))
   `(bookmark-face ((,class (:foreground ,mono5 :distant-foreground ,mono5 :background unspecified))))
   `(deadgrep-filename-face ((,class (:inherit font-lock-builtin-face))))
   `(treemacs-root-face ((,class (:height unspecified))))
   ;; Sidebar slab: give the whole treemacs window a distinct layer (mono1)
   ;; so it reads as a side panel next to the main content plane (mono0).
   ;; With `vertical-border` at mono0, the transition is clean (no extra seam
   ;; line). The panel stands out through its tone + distinct content.
   ;; If the mono1 step feels strong vs main mono0, you can override this face
   ;; to mono0 in your config; distinction will come from content, hl-line,
   ;; and the clean divider.
   ;; hl-line inside the panel uses the next step (mono2) for subtle selection.
   `(treemacs-window-background-face ((,class (:background ,mono1))))
   `(treemacs-hl-line-face ((,class (:background ,mono2))))
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
   ;; directory listing background remains the normal content plane (mono0 /
   ;; `default') because dirvish re-uses dired buffers and does not expose a
   ;; dedicated window-background-face like treemacs. Distinction for the pane
   ;; comes from header-line (mono3), our hl-line faces, window dividers (which
   ;; blend to panel tone when next to a mono1 area), and optional multi-pane
   ;; layout. This matches the design constraints of the package. See README
   ;; for a user hook example if you want mono1 for the whole side pane.
   ;; Recommended dired-native alternative to treemacs (for users who prefer
   ;; dired-native navigation with built-in preview).
   `(dirvish-hl-line ((,class (:background ,mono2 :extend t))))
   `(dirvish-hl-line-inactive ((,class (:background ,mono1 :extend t))))
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
   ;; for dir, underline for write), consistent with the low-key
   ;; dired-perm-write precedent (see above).  Leverages :inherit heavily
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
   `(marginalia-file-priv-write ((,class (:inherit shadow :underline t))))
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
   `(eglot-mode-line ((,class (:weight unspecified))))
   `(compilation-info ((,class (:weight unspecified))))
   `(compilation-mode-line-fail ((,class (:weight unspecified))))
   `(compilation-mode-line-exit ((,class (:weight unspecified))))

   ;; --- Evil / vim-emulation ---
   `(evil-snipe-first-match-face ((,class (:background ,mono3))))

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
   `(org-document-title ((,class (:foreground ,mono7))))
   `(org-document-info ((,class (:foreground ,mono6))))

   ;; TODO / DONE
   `(org-todo ((,class (:inverse-video t :foreground ,red :background ,mono0))))
   `(org-done ((,class (:inverse-video t :foreground ,green :background ,mono0))))
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
   `(org-table-header ((,class (:foreground ,mono7 :background ,mono2))))
   `(org-column ((,class (:foreground ,mono7 :background ,mono2))))
   `(org-column-title ((,class (:foreground ,mono7 :background ,mono2))))
   `(org-tag ((,class (:weight unspecified))))

   ;; Timestamps / dates
   `(org-time-stamp ((,class (:foreground ,mono5))))
   `(org-date ((,class (:foreground ,mono5))))
   `(org-sexp-date ((,class (:foreground ,mono5))))
   ;; org-date-selected: defface has :inverse-video t. Override with unspecified
   ;; so bg/fg show directly (orange badge). No child face inherits this.
   `(org-date-selected ((,class (:foreground ,mono0 :background ,orange :inverse-video unspecified))))

   ;; Formula / footnote
   `(org-formula ((,class (:foreground ,yellow))))
   `(org-footnote ((,class (:foreground ,mono5))))

   ;; Agenda - structure & dates
   `(org-agenda-structure ((,class (:foreground ,mono6))))
   `(org-agenda-current-time ((,class (:foreground ,mono6 :weight bold))))
   `(org-agenda-date-today ((,class (:foreground ,mono6))))
   `(org-agenda-date-weekend ((,class (:foreground ,mono4))))
   `(org-agenda-clocking ((,class (:slant italic))))
   `(org-time-grid ((,class (:inherit font-lock-comment-face))))

   ;; Scheduling
   `(org-scheduled ((,class (:foreground ,mono6))))
   `(org-scheduled-today ((,class (:foreground ,mono6))))
   `(org-scheduled-previously ((,class (:foreground ,mono5))))
   `(org-upcoming-deadline ((,class (:inherit org-scheduled-previously))))

   ;; Habits
   `(org-habit-clear-face ((,class (:foreground ,mono0 :background ,blue))))
   `(org-habit-clear-future-face ((,class (:foreground ,blue :background ,mono2))))
   `(org-habit-ready-face ((,class (:foreground ,mono0 :background ,green))))
   `(org-habit-ready-future-face ((,class (:foreground ,green :background ,mono2))))
   `(org-habit-alert-face ((,class (:foreground ,mono0 :background ,yellow))))
   `(org-habit-alert-future-face ((,class (:foreground ,yellow :background ,mono2))))
   `(org-habit-overdue-face ((,class (:foreground ,mono0 :background ,red))))
   `(org-habit-overdue-future-face ((,class (:foreground ,orange :background ,mono3))))

   ;; Other org (low-frequency)
   `(org-clock-overlay ((,class (:foreground ,mono7 :background ,mono2))))
   `(org-mode-line-clock-overrun ((,class (:foreground ,mono0 :background ,red))))
   `(org-dispatcher-highlight ((,class (:foreground ,mono7 :background ,mono2))))
   `(org-latex-and-related ((,class (:foreground ,mono5))))
   `(org-agenda-restriction-lock ((,class (:foreground ,mono7 :background ,mono2))))

   ;; Extensions (org-around packages)
   `(org-roam-header-line ((,class (:inherit header-line))))
   `(org-noter-notes-exist-face ((,class (:foreground ,mono6))))
   `(org-noter-no-notes-exist-face ((,class (:foreground ,mono5))))
   `(deft-header-face ((,class (:inherit font-lock-builtin-face))))
   `(deft-title-face ((,class (:inherit font-lock-constant-face))))

   ;; --- Magit (Git porcelain; rich derived mode) ---
   ;; Follows design notes: "Org/Magit/Agenda and similar rich modes inherit the
   ;; font-lock and mono decisions heavily; hues only for key status indicators".
   ;; All specs use the variant-specific mono*/accent vars bound in the enclosing
   ;; let*, so no explicit dark/light branching is needed here (unlike many
   ;; magit deffaces).  This also works well with rustcity's higher-pop
   ;; (accents will pop more due to high sat in neon variant).
   ;; Prefer :inherit + mono* over direct colors for harmony and DRY.
   ;; :extend t for full-width lines (Emacs 27+).
   `(magit-section-highlight ((,class (:background ,mono1 :extend t))))
   `(magit-section-heading ((,class (:inherit font-lock-keyword-face :weight bold))))
   `(magit-section-secondary-heading ((,class (:weight bold))))
   `(magit-section-heading-selection ((,class (:inherit magit-section-highlight :foreground ,orange :weight bold))))
   `(magit-diff-file-heading ((,class (:weight bold))))
   `(magit-diff-file-heading-highlight ((,class (:inherit magit-section-highlight :weight bold))))
   `(magit-diff-file-heading-selection ((,class (:inherit magit-diff-file-heading-highlight :foreground ,orange))))
   `(magit-diff-hunk-heading ((,class (:background ,mono2 :foreground ,mono6 :extend t))))
   `(magit-diff-hunk-heading-highlight ((,class (:background ,mono3 :foreground ,mono7 :extend t))))
   `(magit-diff-hunk-heading-selection ((,class (:inherit magit-diff-hunk-heading-highlight :foreground ,orange))))
   `(magit-diff-conflict-heading ((,class (:inherit magit-diff-hunk-heading))))
   `(magit-diff-revision-summary ((,class (:inherit magit-diff-hunk-heading))))
   `(magit-diff-lines-heading ((,class (:background ,orange :foreground ,mono0 :extend t))))
   `(magit-diff-context ((,class (:foreground ,mono5))))
   `(magit-diff-context-highlight ((,class (:background ,mono1 :foreground ,mono6 :extend t))))
   `(magit-diff-added ((,class (:background ,mono1 :foreground ,green :extend t))))
   `(magit-diff-added-highlight ((,class (:background ,mono2 :foreground ,green :extend t))))
   `(magit-diff-removed ((,class (:background ,mono1 :foreground ,red :extend t))))
   `(magit-diff-removed-highlight ((,class (:background ,mono2 :foreground ,red :extend t))))
   `(magit-diff-base ((,class (:background ,mono1 :foreground ,yellow :extend t))))
   `(magit-diff-base-highlight ((,class (:background ,mono2 :foreground ,yellow :extend t))))
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
   `(magit-blame-highlight ((,class (:background ,mono2 :extend t))))
   `(magit-blame-heading ((,class (:background ,mono2 :foreground ,mono6 :extend t
                                               :box (:color ,mono2 :line-width 2)))))
   `(magit-blame-summary ((,class (:foreground ,mono7))))
   `(magit-blame-hash ((,class (:foreground ,mono4))))
   `(magit-blame-name ((,class (:foreground ,mono6))))
   `(magit-blame-date ((,class (:foreground ,mono5))))

   ;; --- Calendar / eww (other apps) ---
   `(calendar-today ((,class (:inherit font-lock-warning-face))))
   `(calendar-weekend-header ((,class (:inherit font-lock-type-face))))
   `(holiday ((,class (:background ,mono2))))
   `(diary ((,class (:inherit font-lock-string-face))))
   `(eww-valid-certificate ((,class (:weight unspecified :foreground ,mono6))))))

(defconst rustcity--export-name-map
  '((mono0   . background)
    (mono0   . brightcyan)
    (mono1   . black)
    (mono2   . brightblack)
    (mono3   . brightblue)
    (mono4   . brightgreen)
    (mono5   . white)
    (mono6   . brightyellow)
    (mono7   . foreground)
    (mono7   . brightwhite)
    (red     . red)
    (orange  . brightred)
    (yellow  . yellow)
    (green   . green)
    (cyan    . cyan)
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
         (ordered-keys '(black red green yellow blue magenta cyan white
                               brightblack brightred brightgreen brightmagenta
                               brightblue brightyellow brightcyan brightwhite)))
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
