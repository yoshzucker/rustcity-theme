;;; rustcity-theme.el --- Rustcity theme: neon nights and rainy days -*- lexical-binding: t; -*-

;; Author: yoshzucker
;; Maintainer: yoshzucker
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.1") (hsluv "1.0"))
;; Keywords: faces, themes, rustcity, downpour, neon
;; Homepage: https://github.com/yoshzucker/rustcity-theme
;; License: MIT

;;; Commentary:

;; rustcity is a dual light/dark theme inspired by the forgotten edges of an
;; industrial port city.
;;
;; - `neon' (dark): The heavy, rain-slicked night of an industrial district.
;;   Neon signs glow against deep shadows, but the streets are empty. The
;;   palette evokes the quiet codependence between the remaining neon-lit
;;   shops and the workers who no longer fill them after dark.
;;
;; - `downpour' (light): The pale, washed-out morning after a torrential rain.
;;   Reflections of last night's neon shimmer in puddles and gutters. No one
;;   is on the street yet; only the memory of the previous night lingers in
;;   the water and the rusted colors.
;;
;; The theme is built on perceptual HSLuv colors for consistency across
;; lightness and hue. It prioritizes readability while preserving a strong
;; emotional tone.
;;
;; Usage (standalone):
;;
;;   (setq frame-background-mode 'dark)   ; or 'light
;;   (load-theme 'rustcity t)
;;
;; Or with straight/use-package:
;;
;;   (use-package rustcity-theme
;;     :straight (:host github :repo "yoshzucker/rustcity-theme")
;;     :config
;;     (setq frame-background-mode 'dark)
;;     (load-theme 'rustcity t))
;;
;; The color palette is also available programmatically for external tools
;; (terminal emulators, dircolors, etc.):
;;
;;   (rustcity-export-palette 'json 'neon)
;;
;; This returns a JSON string with the 16 ANSI colors + foreground/background
;; that can be consumed by scripts generating Alacritty, kitty, WezTerm,
;; ghostty, or dircolors configurations.

;;; Code:

(require 'hsluv)

(deftheme rustcity
  "A theme inspired by a rusted industrial cityscape—silent under neon rain, and hollow in a daylight downpour.")

(defconst rustcity-downpour-hsl
  '((background    . (260  20  87))     ; 6 base tones
    (brightwhite   . (260  20  77))     ; 6 base tones
    (white         . (260  20  67))     ; 6 base tones
    (brightblack   . (260  20  57))     ; 6 base tones
    (black         . (260  20  47))     ; 6 base tones
    (foreground    . (260  20  37))     ; 6 base tones
    (red           . (  0 100  57))     ; 8 neon hues
    (yellow        . ( 70 100  57))     ; 8 neon hues
    (green         . (110 100  57))     ; 8 neon hues
    (cyan          . (200 100  57))     ; 8 neon hues
    (blue          . (250 100  57))     ; 8 neon hues
    (magenta       . (310 100  57))     ; 8 neon hues
    (brightred     . ( 30 100  57))     ; 8 neon hues (orange)
    (brightmagenta . (280 100  57))     ; 8 neon hues (violet)
    (brightyellow  . (  0  55  57))     ; 4 diffused hues
    (brightgreen   . (110  55  57))     ; 4 diffused hues
    (brightcyan    . (250  55  57))     ; 4 diffused hues
    (brightblue    . (280  55  57))))   ; 4 diffused hues

(defconst rustcity-neon-hsl
  '((background    . (260  55  13))     ; 6 base tones
    (black         . (260  55  23))     ; 6 base tones
    (brightblack   . (260  55  33))     ; 6 base tones
    (white         . (260  55  43))     ; 6 base tones
    (brightwhite   . (260  55  53))     ; 6 base tones
    (foreground    . (260  55  63))     ; 6 base tones
    (red           . (  0 100  63))     ; 8 neon hues
    (yellow        . ( 70 100  63))     ; 8 neon hues
    (green         . (110 100  63))     ; 8 neon hues
    (cyan          . (200 100  63))     ; 8 neon hues
    (blue          . (250 100  63))     ; 8 neon hues
    (magenta       . (310 100  63))     ; 8 neon hues
    (brightred     . ( 30 100  63))     ; 8 neon hues (orange)
    (brightmagenta . (280 100  63))     ; 8 neon hues (violet)
    (brightyellow  . (  0  55  63))     ; 4 diffused hues
    (brightgreen   . (110  55  63))     ; 4 diffused hues
    (brightcyan    . (250  55  63))     ; 4 diffused hues
    (brightblue    . (280  55  63))))   ; 4 diffused hues

(defconst rustcity-downpour
  (cl-loop for (name . hsl) in rustcity-downpour-hsl
           collect
           `(,name . ,(hsluv-hsluv-to-hex hsl))))

(defconst rustcity-neon
  (cl-loop for (name . hsl) in rustcity-neon-hsl
           collect
           `(,name . ,(hsluv-hsluv-to-hex hsl))))

(defun rustcity-colors ()
  "Return color mapping: 16 ANSI colors + foreground/background."
  (if (eq frame-background-mode 'light)
      rustcity-downpour
    rustcity-neon))

(let* ((class '((class color) (min-colors 89)))
       (colors (rustcity-colors))
       (background    (alist-get 'background    colors))
       (foreground    (alist-get 'foreground    colors))
       (red           (alist-get 'red           colors))
       (green         (alist-get 'green         colors))
       (yellow        (alist-get 'yellow        colors))
       (blue          (alist-get 'blue          colors))
       (magenta       (alist-get 'magenta        colors))
       (cyan          (alist-get 'cyan           colors))
       (black         (alist-get 'black          colors))
       (white         (alist-get 'white          colors))
       (brightblack   (alist-get 'brightblack   colors))
       (brightred     (alist-get 'brightred     colors))
       (brightgreen   (alist-get 'brightgreen   colors))
       (brightyellow  (alist-get 'brightyellow  colors))
       (brightblue    (alist-get 'brightblue    colors))
       (brightmagenta (alist-get 'brightmagenta colors))
       (brightcyan    (alist-get 'brightcyan    colors))
       (brightwhite   (alist-get 'brightwhite   colors))

       (lightp (eq frame-background-mode 'light))
       (background-near (alist-get (if lightp 'brightwhite 'black) colors))
       (background-far  (alist-get (if lightp 'white 'brightblack) colors))
       (foreground-far  (alist-get (if lightp 'brightblack 'white) colors))
       (foreground-near (alist-get (if lightp 'black 'brightwhite) colors))
       (primary         (alist-get (if lightp 'brightcyan 'brightblue) colors))
       (secondary       (alist-get 'blue colors)))

  (custom-theme-set-faces
   'rustcity
   ;; --- Core (from previous minimal + expanded) ---
   `(default ((,class (:foreground ,foreground :background ,background))))
   `(fixed-pitch ((,class (:family unspecified))))
   `(variable-pitch ((,class (:family unspecified))))
   `(fringe ((,class (:background ,background-far))))
   `(border ((,class (:background ,background))))
   `(vertical-border ((,class (:foreground ,background-near))))
   `(internal-border ((,class (:background ,background))))
   `(mode-line ((,class (:foreground ,background :background ,primary))))
   `(mode-line-inactive ((,class (:foreground ,primary :background ,background-near))))
   `(mode-line-buffer-id ((,class (:weight unspecified))))
   `(header-line ((,class (:foreground ,primary :background ,background-far :weight unspecified))))
   `(minibuffer-prompt ((,class (:foreground ,primary))))
   `(cursor ((,class (:background ,primary))))
   `(region ((,class (:background ,background-near :extend t))))
   `(highlight ((,class (:background ,background-near))))
   `(show-paren-match ((,class (:background ,background-near :weight bold))))
   `(link ((,class (:foreground ,brightgreen :underline t))))
   `(link-visited ((,class (:foreground ,green :underline t))))
   `(shadow ((,class (:foreground ,white))))
   `(match ((,class (:foreground ,background :background ,brightgreen))))
   `(warning ((,class (:foreground ,yellow))))
   `(error ((,class (:foreground ,red))))
   `(success ((,class (:foreground ,green))))
   `(tooltip ((,class (:foreground ,foreground :background ,brightyellow))))

   ;; --- Font-lock (expanded) ---
   `(font-lock-comment-face ((,class (:foreground ,white :slant italic))))
   `(font-lock-string-face ((,class (:foreground ,yellow))))
   `(font-lock-doc-face ((,class (:foreground ,white))))
   `(font-lock-keyword-face ((,class (:foreground ,brightmagenta))))
   `(font-lock-builtin-face ((,class (:foreground ,green))))
   `(font-lock-variable-name-face ((,class (:foreground ,blue))))
   `(font-lock-function-name-face ((,class (:foreground ,magenta))))
   `(font-lock-type-face ((,class (:foreground ,cyan))))
   `(font-lock-constant-face ((,class (:foreground ,brightred))))
   `(font-lock-warning-face ((,class (:foreground ,red))))

   ;; --- Tab bar ---
   `(tab-bar ((,class (:foreground ,foreground :background ,background))))
   `(tab-bar-tab ((,class (:foreground ,background :background ,primary :box unspecified))))
   `(tab-bar-tab-inactive ((,class (:foreground ,primary :background ,background-near))))

   ;; --- Completion & search (modern) ---
   `(vertico-current ((,class (:background ,background-near))))
   `(orderless-match-face-0 ((,class (:weight unspecified :foreground ,brightred))))
   `(orderless-match-face-1 ((,class (:weight unspecified :foreground ,magenta))))
   `(orderless-match-face-2 ((,class (:weight unspecified :foreground ,green))))
   `(orderless-match-face-3 ((,class (:weight unspecified :foreground ,red))))
   `(consult-buffer ((,class (:foreground ,foreground-near))))
   `(consult-file ((,class (:foreground ,foreground-far))))
   `(corfu-default ((,class (:background ,background))))
   `(corfu-current ((,class (:foreground ,primary :background ,background-near))))
   `(corfu-bar ((,class (:background ,primary))))

   ;; --- Search / jump ---
   `(isearch ((,class (:foreground ,background :background ,brightyellow))))
   `(lazy-highlight ((,class (:foreground ,background :background ,brightcyan))))
   `(avy-lead-face ((,class (:foreground ,background :background ,blue))))
   `(avy-lead-face-0 ((,class (:foreground ,background :background ,brightred))))
   `(avy-lead-face-1 ((,class (:foreground ,background :background ,red))))
   `(avy-lead-face-2 ((,class (:foreground ,background :background ,magenta))))

   ;; --- Evil / misc ---
   `(evil-snipe-first-match-face ((,class (:background ,background-far))))
   `(deadgrep-filename-face ((,class (:inherit font-lock-builtin-face))))

   ;; --- Major packages ---
   `(magit-section-heading ((,class (:foreground ,yellow :background ,background))))
   `(eglot-mode-line ((,class (:weight unspecified))))
   `(dired-directory ((,class (:inherit font-lock-type-face))))
   `(treemacs-root-face ((,class (:height unspecified))))
   `(bookmark-face ((,class (:distant-foreground ,blue :background unspecified))))

   ;; --- Outline / org (core + rich) ---
   `(outline-1 ((,class (:inherit font-lock-type-face))))
   `(outline-2 ((,class (:inherit font-lock-variable-name-face))))
   `(outline-3 ((,class (:inherit font-lock-constant-face))))
   `(outline-4 ((,class (:inherit font-lock-builtin-face))))
   `(outline-5 ((,class (:inherit font-lock-function-name-face))))
   `(outline-6 ((,class (:inherit font-lock-string-face))))
   `(outline-7 ((,class (:inherit font-lock-warning-face))))
   `(outline-8 ((,class (:inherit font-lock-keyword-face))))

   `(org-headline-done ((,class (:foreground unspecified))))
   `(org-agenda-dimmed-todo-face ((,class (:inherit font-lock-comment-face))))
   `(org-todo ((,class (:inverse-video t :foreground ,red :background ,background))))
   `(org-done ((,class (:inverse-video t :foreground ,green :background ,background))))
   `(org-document-title ((,class (:inherit font-lock-constant-face))))
   `(org-column ((,class (:background ,background-near))))
   `(org-column-title ((,class (:inherit org-column))))
   `(org-table ((,class (:foreground ,cyan))))
   `(org-tag ((,class (:weight unspecified))))
   `(org-archived ((,class (:inherit org-headline-done))))
   `(org-drawer ((,class (:inherit font-lock-comment-face))))
   `(org-special-keyword ((,class (:inherit font-lock-comment-face))))
   `(org-date ((,class (:inherit font-lock-type-face))))
   `(org-time-grid ((,class (:inherit font-lock-comment-face))))
   `(org-scheduled ((,class (:foreground ,green))))
   `(org-scheduled-today ((,class (:foreground ,blue))))
   `(org-scheduled-previously ((,class (:foreground ,brightred))))
   `(org-upcoming-deadline ((,class (:inherit org-scheduled-previously))))
   `(org-agenda-structure ((,class (:foreground ,green :weight unspecified))))
   `(org-agenda-current-time ((,class (:inherit font-lock-keyword-face))))
   `(org-agenda-date-today ((,class (:inherit font-lock-variable-name-face))))
   `(org-agenda-date-weekend ((,class (:inherit font-lock-type-face))))
   `(org-agenda-clocking ((,class (:slant italic))))
   `(org-habit-overdue-face ((,class (:background ,brightmagenta))))
   `(org-roam-header-line ((,class (:inherit header-line))))
   `(org-noter-notes-exist-face ((,class (:foreground ,green))))
   `(org-noter-no-notes-exist-face ((,class (:foreground ,brightred))))
   `(deft-header-face ((,class (:inherit font-lock-builtin-face))))
   `(deft-title-face ((,class (:inherit font-lock-constant-face))))

   ;; --- Calendar / compile / ein / eww ---
   `(calendar-today ((,class (:inherit font-lock-warning-face))))
   `(calendar-weekend-header ((,class (:inherit font-lock-type-face))))
   `(compilation-info ((,class (:weight unspecified))))
   `(compilation-mode-line-fail ((,class (:weight unspecified))))
   `(compilation-mode-line-exit ((,class (:weight unspecified))))
   `(ein:cell-input-area ((,class (:background ,background-near))))
   `(ein:cell-input-prompt ((,class (:foreground ,background :background ,primary))))
   `(ein:cell-output-prompt ((,class (:foreground ,background :background ,secondary))))
   `(eww-valid-certificate ((,class (:weight unspecified :foreground ,green))))))

;;;###autoload
(defun rustcity-export-palette (format &optional variant)
  "Export the rustcity color palette for use outside Emacs (e.g. terminal themes).

FORMAT is one of the following symbols:
  `json'      - pretty-printed JSON object
  `alist'     - Emacs alist ((color . \"#hex\") ...)
  `hex-list'  - plain list of hex strings in a conventional order

VARIANT is `neon' (dark) or `downpour' (light).
If omitted, the variant is chosen from the current value of
`frame-background-mode' (dark → neon, light → downpour).

Example:
  (rustcity-export-palette \\='json \\='neon)
  ;; => JSON string suitable for piping to a generator script

This function is intended to help generate configuration for
Alacritty, kitty, WezTerm, ghostty, dircolors, or similar tools
while keeping the canonical HSLuv values in one place."
  (let* ((variant (or variant
                      (if (eq frame-background-mode 'light)
                          'downpour
                        'neon)))
         (palette (if (eq variant 'downpour)
                      rustcity-downpour
                    rustcity-neon))
         ;; Conventional 16-color order + fg/bg for terminal tools
         (ordered-keys '(black red green yellow blue magenta cyan white
                         brightblack brightred brightgreen brightyellow
                         brightblue brightmagenta brightcyan brightwhite
                         background foreground)))
    (pcase format
      ('alist
       palette)
      ('hex-list
       (mapcar (lambda (k) (alist-get k palette)) ordered-keys))
      ('json
       (let ((json-pairs
              (mapconcat
               (lambda (k)
                 (let ((v (alist-get k palette)))
                   (format "  %S: %S" (symbol-name k) v)))
               ordered-keys
               ",\n")))
         (concat "{\n" json-pairs "\n}")))
      (_
       (error "Unsupported FORMAT: %s. Use 'json, 'alist or 'hex-list" format)))))

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-directory load-file-name)))

(provide-theme 'rustcity)
(provide 'rustcity-theme)
;;; rustcity-theme.el ends here
