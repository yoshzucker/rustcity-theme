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
       (foreground-near (alist-get (if lightp 'black 'brightwhite) colors)))

  (custom-theme-set-faces
   'rustcity
   `(default ((,class (:foreground ,foreground :background ,background))))
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
   `(link ((,class (:foreground ,brightgreen :underline t))))
   `(link-visited ((,class (:foreground ,green :underline t))))
   `(minibuffer-prompt ((,class (:foreground ,foreground))))
   `(cursor ((,class (:background ,background-far))))
   `(region ((,class (:background ,background-near :extend t))))
   `(fringe ((,class (:background ,background-far))))
   `(vertical-border ((,class (:foreground ,foreground :background ,background-far))))
   `(mode-line ((,class (:foreground ,foreground :background ,background-far))))
   `(mode-line-inactive ((,class (:foreground ,foreground :background ,background-far))))
   `(header-line ((,class (:foreground ,foreground :background ,background-far))))
   `(highlight ((,class (:background ,background-near))))
   `(shadow ((,class (:foreground ,white))))
   `(match ((,class (:foreground ,background :background ,brightgreen))))
   `(warning ((,class (:foreground ,yellow))))
   `(error ((,class (:foreground ,red))))
   `(success ((,class (:foreground ,green))))
   `(tooltip ((,class (:foreground ,foreground :background ,brightyellow))))))

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
