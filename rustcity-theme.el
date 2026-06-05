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
   `(vertical-border ((,class (:foreground ,mono0))))
   `(region ((,class (:background ,mono1 :extend t))))
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

   ;; --- Modeline, header-line, tab-bar (UI chrome) ---
   `(mode-line ((,class (:foreground ,mono7 :background ,mono2))))
   `(mode-line-inactive ((,class (:foreground ,mono6 :background ,mono1))))
   `(mode-line-buffer-id ((,class (:weight unspecified))))
   `(header-line ((,class (:foreground ,mono6 :background ,mono3 :weight unspecified))))
   `(tab-bar ((,class (:foreground ,mono7 :background ,mono0))))
   `(tab-bar-tab ((,class (:foreground ,mono7 :background ,mono2 :box unspecified))))
   `(tab-bar-tab-inactive ((,class (:foreground ,mono6 :background ,mono1))))

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
   `(treemacs-root-face ((,class (:height unspecified))))
   `(bookmark-face ((,class (:foreground ,mono5 :distant-foreground ,mono5 :background unspecified))))
   `(deadgrep-filename-face ((,class (:inherit font-lock-builtin-face))))

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
   `(org-headline-done ((,class (:foreground unspecified))))
   `(org-agenda-dimmed-todo-face ((,class (:inherit font-lock-comment-face))))
   `(org-todo ((,class (:inverse-video t :foreground ,red :background ,mono0))))
   `(org-done ((,class (:inverse-video t :foreground ,green :background ,mono0))))
   `(org-document-title ((,class (:foreground ,mono6 :weight bold))))
   `(org-column ((,class (:background ,mono2))))
   `(org-column-title ((,class (:inherit org-column))))
   `(org-table ((,class (:foreground ,mono6))))
   `(org-tag ((,class (:weight unspecified))))
   `(org-archived ((,class (:inherit org-headline-done))))
   `(org-drawer ((,class (:inherit font-lock-comment-face))))
   `(org-special-keyword ((,class (:inherit font-lock-comment-face))))
   `(org-date ((,class (:foreground ,mono5))))
   `(org-time-grid ((,class (:inherit font-lock-comment-face))))
   `(org-scheduled ((,class (:foreground ,mono6))))
   `(org-scheduled-today ((,class (:foreground ,mono6))))
   `(org-scheduled-previously ((,class (:foreground ,mono5))))
   `(org-upcoming-deadline ((,class (:inherit org-scheduled-previously))))
   `(org-agenda-structure ((,class (:foreground ,mono6 :weight unspecified))))
   `(org-agenda-current-time ((,class (:foreground ,mono6 :weight bold))))
   `(org-agenda-date-today ((,class (:foreground ,mono6 :weight bold))))
   `(org-agenda-date-weekend ((,class (:foreground ,mono4))))
   `(org-agenda-clocking ((,class (:slant italic))))
   `(org-habit-overdue-face ((,class (:background ,purple))))
   `(org-roam-header-line ((,class (:inherit header-line))))
   `(org-noter-notes-exist-face ((,class (:foreground ,green))))
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
   `(eww-valid-certificate ((,class (:weight unspecified :foreground ,green))))))

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
