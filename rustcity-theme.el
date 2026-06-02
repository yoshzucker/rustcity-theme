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
;;   (rustcity-palette)        ; current or (rustcity-palette 'neon)
;;   (rustcity-export-palette 'json 'neon)  ; for external tools

;;; Code:

(require 'hsluv)
(require 'cl-lib)

(deftheme rustcity
  "A theme inspired by a rusted industrial cityscape—silent under neon rain, and hollow in a daylight downpour.")

(defconst rustcity-downpour-hsl
  '((mono0   . (260  20  86))
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
    (magenta . (310 100  57))
    ))

(defconst rustcity-neon-hsl
  '(
    (mono0   . (260  55  14))
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
    (magenta . (310 100  63))
    ))

(defun rustcity--hex-palette (hsl-palette)
  "Convert HSL alist to hex alist using `hsluv-hsluv-to-hex'."
  (cl-loop for entry in hsl-palette
           for name = (car entry)
           for hsl = (cdr entry)
           collect `(,name . ,(hsluv-hsluv-to-hex hsl))))

(defconst rustcity-downpour
  (rustcity--hex-palette rustcity-downpour-hsl))

(defconst rustcity-neon
  (rustcity--hex-palette rustcity-neon-hsl))

;;;###autoload
(defun rustcity-palette (&optional variant)
  "Return hex color alist for VARIANT or current `frame-background-mode'.
VARIANT is `neon' or `downpour' (defaults from `frame-background-mode').
For external tools, prefer `rustcity-export-palette'."
  (let ((v (or variant
               (if (eq frame-background-mode 'light) 'downpour 'neon))))
    (if (eq v 'downpour) rustcity-downpour rustcity-neon)))

(let* ((class '((class color) (min-colors 89)))
       (colors    (rustcity-palette))
       (mono0     (alist-get 'mono0   colors))
       (mono1     (alist-get 'mono1   colors))
       (mono2     (alist-get 'mono2   colors))
       (mono3     (alist-get 'mono3   colors))
       (mono6     (alist-get 'mono6   colors))
       (mono5     (alist-get 'mono5   colors))
       (mono7     (alist-get 'mono7   colors))
       (red       (alist-get 'red     colors))
       (orange    (alist-get 'orange  colors))
       (yellow    (alist-get 'yellow  colors))
       (green     (alist-get 'green   colors))
       (cyan      (alist-get 'cyan    colors))
       (blue      (alist-get 'blue    colors))
       (purple    (alist-get 'purple  colors))
       (magenta   (alist-get 'magenta colors))
       (primary   (alist-get 'purple  colors))
       (secondary (alist-get 'blue    colors)))

  (custom-theme-set-faces
   'rustcity
   ;; --- Core ---
   `(default ((,class (:foreground ,mono7 :background ,mono0))))
   `(fixed-pitch ((,class (:family unspecified))))
   `(variable-pitch ((,class (:family unspecified))))
   `(fringe ((,class (:background ,mono0))))
   `(border ((,class (:background ,mono0))))
   `(vertical-border ((,class (:foreground ,mono1))))
   `(internal-border ((,class (:background ,mono0))))
   `(mode-line ((,class (:foreground ,mono0 :background ,primary))))
   `(mode-line-inactive ((,class (:foreground ,primary :background ,mono1))))
   `(mode-line-buffer-id ((,class (:weight unspecified))))
   `(header-line ((,class (:foreground ,primary :background ,mono2 :weight unspecified))))
   `(minibuffer-prompt ((,class (:foreground ,primary))))
   `(cursor ((,class (:background ,primary))))
   `(region ((,class (:background ,mono1 :extend t))))
   `(highlight ((,class (:background ,mono1))))
   `(show-paren-match ((,class (:background ,mono1 :weight bold))))
   `(link ((,class (:foreground ,green :underline t))))
   `(link-visited ((,class (:foreground ,purple :underline t))))
   `(shadow ((,class (:foreground ,mono5))))
   `(match ((,class (:foreground ,mono0 :background ,green))))
   `(warning ((,class (:foreground ,yellow))))
   `(error ((,class (:foreground ,red))))
   `(success ((,class (:foreground ,green))))
   `(tooltip ((,class (:foreground ,mono7 :background ,orange))))

   ;; --- Font-lock ---
   `(font-lock-comment-face ((,class (:foreground ,mono5 :slant italic))))
   `(font-lock-string-face ((,class (:foreground ,yellow))))
   `(font-lock-doc-face ((,class (:foreground ,mono5))))
   `(font-lock-keyword-face ((,class (:foreground ,purple))))
   `(font-lock-builtin-face ((,class (:foreground ,green))))
   `(font-lock-variable-name-face ((,class (:foreground ,blue))))
   `(font-lock-function-name-face ((,class (:foreground ,magenta))))
   `(font-lock-type-face ((,class (:foreground ,cyan))))
   `(font-lock-constant-face ((,class (:foreground ,orange))))
   `(font-lock-warning-face ((,class (:foreground ,red))))

   ;; --- Tab bar ---
   `(tab-bar ((,class (:foreground ,mono7 :background ,mono0))))
   `(tab-bar-tab ((,class (:foreground ,mono0 :background ,primary :box unspecified))))
   `(tab-bar-tab-inactive ((,class (:foreground ,primary :background ,mono1))))

   ;; --- Completion & search (modern) ---
   `(vertico-current ((,class (:background ,mono1))))
   `(orderless-match-face-0 ((,class (:weight unspecified :foreground ,orange))))
   `(orderless-match-face-1 ((,class (:weight unspecified :foreground ,magenta))))
   `(orderless-match-face-2 ((,class (:weight unspecified :foreground ,green))))
   `(orderless-match-face-3 ((,class (:weight unspecified :foreground ,red))))
   `(consult-buffer ((,class (:foreground ,mono6))))
   `(consult-file ((,class (:foreground ,mono5))))
   `(corfu-default ((,class (:background ,mono0))))
   `(corfu-current ((,class (:foreground ,primary :background ,mono1))))
   `(corfu-bar ((,class (:background ,primary))))

   ;; --- Search / jump ---
   `(isearch ((,class (:foreground ,mono0 :background ,orange))))
   `(lazy-highlight ((,class (:foreground ,mono0 :background ,mono3))))
   `(avy-lead-face ((,class (:foreground ,mono0 :background ,blue))))
   `(avy-lead-face-0 ((,class (:foreground ,mono0 :background ,orange))))
   `(avy-lead-face-1 ((,class (:foreground ,mono0 :background ,red))))
   `(avy-lead-face-2 ((,class (:foreground ,mono0 :background ,magenta))))

   ;; --- Evil / misc ---
   `(evil-snipe-first-match-face ((,class (:background ,mono2))))
   `(deadgrep-filename-face ((,class (:inherit font-lock-builtin-face))))

   ;; --- Major packages ---
   `(magit-section-heading ((,class (:foreground ,yellow :background ,mono0))))
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
   `(org-todo ((,class (:inverse-video t :foreground ,red :background ,mono0))))
   `(org-done ((,class (:inverse-video t :foreground ,green :background ,mono0))))
   `(org-document-title ((,class (:inherit font-lock-constant-face))))
   `(org-column ((,class (:background ,mono1))))
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
   `(org-scheduled-previously ((,class (:foreground ,orange))))
   `(org-upcoming-deadline ((,class (:inherit org-scheduled-previously))))
   `(org-agenda-structure ((,class (:foreground ,green :weight unspecified))))
   `(org-agenda-current-time ((,class (:inherit font-lock-keyword-face))))
   `(org-agenda-date-today ((,class (:inherit font-lock-variable-name-face))))
   `(org-agenda-date-weekend ((,class (:inherit font-lock-type-face))))
   `(org-agenda-clocking ((,class (:slant italic))))
   `(org-habit-overdue-face ((,class (:background ,purple))))
   `(org-roam-header-line ((,class (:inherit header-line))))
   `(org-noter-notes-exist-face ((,class (:foreground ,green))))
   `(org-noter-no-notes-exist-face ((,class (:foreground ,orange))))
   `(deft-header-face ((,class (:inherit font-lock-builtin-face))))
   `(deft-title-face ((,class (:inherit font-lock-constant-face))))

   ;; --- Calendar / compile / ein / eww ---
   `(calendar-today ((,class (:inherit font-lock-warning-face))))
   `(calendar-weekend-header ((,class (:inherit font-lock-type-face))))
   `(compilation-info ((,class (:weight unspecified))))
   `(compilation-mode-line-fail ((,class (:weight unspecified))))
   `(compilation-mode-line-exit ((,class (:weight unspecified))))
   `(ein:cell-input-area ((,class (:background ,mono1))))
   `(ein:cell-input-prompt ((,class (:foreground ,mono0 :background ,primary))))
   `(ein:cell-output-prompt ((,class (:foreground ,mono0 :background ,secondary))))
   `(eww-valid-certificate ((,class (:weight unspecified :foreground ,green))))))

;;;###autoload
(defun rustcity-export-palette (format &optional variant)
  "Export the palette for external tools.
FORMAT is `json', `alist', or `hex-list'.
VARIANT is `neon' or `downpour' (defaults from `frame-background-mode')."
  (let* ((palette (rustcity-palette variant))
         (ordered-keys '(mono1 red green yellow blue magenta cyan mono5
                               mono2 orange 
                               mono4 purple mono3 mono6
                               mono0 mono7)))
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
