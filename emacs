;;; -*- mode: lisp; -*-
;;; .emacs --- Startup file GNU Emacs 24.0.92.1

;; Copyright (C) 2011 Free Software Foundation, Inc.
;;
;; Author: Mindaugas <mindeunix@gmail.com>
;; Maintainer: Mindaugas <mindeunix@gmail.com>
;; Created: 2011-12-17
;; Version: 0.01
;; Keywords:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:

;; VIM mode
(add-to-list 'load-path "/home/asido/.emacs.d/vim-mode/")
    (require 'vim)
    (vim-mode 1)

;; stop brain-damaging indentation
(setq c-default-style "linux"
	  c-basic-offset 4)

;; ELPA repositories.

(require 'package)
(package-initialize)
(add-to-list 'load-path "~/.emacs.d/elpa")
(setq package-archives '(("ELPA" . "http://tromey.com/elpa/") 
			 ("gnu" . "http://elpa.gnu.org/packages/")
			 ("marmalade" . "http://marmalade-repo.org/packages/")))

;; Edit all lines matching a given regexp
(require 'all-autoloads)
;; Activation org-mode
(add-to-list 'load-path "/home/asido/.emacs.d/org-mode/lisp")
(add-to-list 'load-path "/home/asido/.emacs.d/org-mode/contrib/lisp")

;; org-mode
(require 'org-install)
(add-to-list 'auto-mode-alist '("\\.org$" . org-mode))
(define-key global-map "\C-cl" 'org-store-link)
(define-key global-map "\C-ca" 'org-agenda)
(setq org-log-done t)
(setq org-agenda-files (list "/home/asido/.emacs.d/org/awesome.org"
                             "/home/asido/.emacs.d/org/work.org" 
                             "/home/asido/.emacs.d/org/zshrc.org"
			     "/home/asido/.emacs.d/org/startup.org")
)
;; specialiai del awesome wm widgeto
;; update agenda file after changes to org files

;; update agenda file after changes to org files
(defun th-org-mode-init ()
  (add-hook 'after-save-hook 'th-org-update-agenda-file t t))

(add-hook 'org-mode-hook 'th-org-mode-init)

;; that's the export function
(defun th-org-update-agenda-file (&optional force)
  (interactive)
  (save-excursion
    (save-window-excursion
      (let ((file "/tmp/org-agenda.txt"))
        (org-agenda-list)
	;; org-agenda-write yra ant git org-mode
	;; ant senesnes org-write-agenda
        (org-agenda-write file)))))

;; do it once at startup
(th-org-update-agenda-file t)


;; major mode for editing Apache configuration files
(require 'apache-mode-autoloads)
;; Exuberant Ctags utilities for Emacs
(require 'ctags-autoloads)
(require 'ctags)
;; YASnippet. snippet extension
(provide 'yasnippet-autoloads)
(require 'yasnippet)
(custom-set-variables
 '(yas/also-auto-indent-first-line t)
 '(yas/choose-keys-first nil)
 '(yas/choose-tables-first t)
 '(yas/global-mode t nil (yasnippet))
 '(yas/indent-line (quote auto))
 '(yas/initialize t)
 '(yas/next-field-key (quote ("TAB" "<tab>")))
 '(yas/prev-field-key (quote ("<backtab>" "<S-tab>")))
 '(yas/root-directory "~/.emacs.d/snippets" nil (yasnippet))
 '(yas/skip-and-clear-key "C-d")
 '(yas/trigger-key "TAB")
 '(yas/trigger-symbol " =>")
 '(yas/use-menu (quote abbreviate))
)
;; Auto Complete Mode
(add-to-list 'load-path "~/.emacs.d/elpa/auto-complete/")
(require 'auto-complete-autoloads)
(require 'auto-complete-etags-autoloads)
(require 'auto-complete-config)
(ac-config-default)
(require 'auto-complete-etags)
(custom-set-variables
 ; Non-nil means completion menu will be automatically shown
 '(ac-auto-show-menu 0.8)
 ; Positive integer means if a length of a word you entered is larger than the value,
 ; completion will be started automatically.
 ; If you specify nil, never be started automatically.
 '(ac-auto-start 2)
 ; Limit number of candidates. Non-integer means no limit.
 '(ac-candidate-limit 50)
 ; Completion history file name
 '(ac-comphist-file "/opt/elisp/auto-complete/ac-comphist.dat")
 ; Delay to completions will be available
 '(ac-delay 0.1)
 ; Dictionary directories
 '(ac-dictionary-directories (quote ("/opt/elisp/auto-complete/dict")))
 ; Dictionary files
 '(ac-dictionary-files (quote ("/opt/elisp/auto-complete/dict")))
 ; Non-nil means auto-complete works based on Do What I Mean
 '(ac-dwim t)
 ; Non-nil means expand whole common part on first time auto-complete.
 '(ac-expand-on-auto-complete t)
 ; If this value is smart, auto-complete ignores case only when
 ; a prefix doen't contain any upper case letters.
 '(ac-ignore-case nil)
 ; Max height of candidate menu
 '(ac-menu-height 10)
 ; Major modes auto-complete-mode can run on.
 '(ac-modes (quote (
                    emacs-lisp-mode
                    lisp-mode
                    lisp-interaction-mode
                    c-mode
                    cc-mode
                    c++-mode
                    perl-mode
                    cperl-mode
                    python-mode
                    ruby-mode
                    makefile-mode
                    sh-mode
                    lua-mode 
                    org-mode
                    )))
 ; Non-nil means menu will be showed immediately on auto-complete
 '(ac-show-menu-immediately-on-auto-complete t)
 ; Non-nil means disble flymake temporarily on completing.
 '(ac-stop-flymake-on-completing t)
 ; Non-nil means use intelligent completion history
 '(ac-use-comphist t)
 ; Non-nil means a buffer related dictionary will be thought of as stop words
 '(ac-use-dictionary-as-stop-words t)
 ; Non-nil means use fuzzy matching
 '(ac-use-fuzzy t)
)
(custom-set-variables
 '(ac-sources
   '(ac-source-abbrev
     ac-source-dictionary
     ac-source-filename
     ac-source-files-in-current-dir
     ac-source-gtags
     ac-source-imenu
     ac-source-semantic
     ac-source-words-in-same-mode-buffers
     ac-source-etags
     ac-source-yasnippet)
   )
 )



;; automatically extracted autoloads
(require 'autopair-autoloads)
(require 'autopair)
;(require 'auto-pair+)
;; to enable in all buffers
(autopair-global-mode) 

;; Quote text with a semi-box.
(require 'boxquote-autoloads)
;; major-mode for editing CMake sources
(require 'cmake-mode-autoloads)
(setq auto-mode-alist
      (append '(("CMakeLists\\.txt\\'" . cmake-mode)
		("\\.cmake\\'" . cmake-mode))
	      auto-mode-alist))

;; bookmarks for compilation commands
(require 'compile-bookmarks-autoloads)
;; Major mode for editing crontabs.
(require 'crontab-mode-autoloads)
(add-to-list 'auto-mode-alist '("\\.cron\\(tab\\)?\\'" . crontab-mode))
(add-to-list 'auto-mode-alist '("cron\\(tab\\)?\\."    . crontab-mode))

;; The Emacs Multimedia System
(require 'emms-autoloads)
(require 'emms-setup)
(emms-all)
;; Same frame speedbar
(require 'sr-speedbar-autoloads)
(require 'sr-speedbar)
;; Colorize color names in buffers
(require 'rainbow-mode-autoloads)
;; Highlight nested parens, brackets, braces a different color at each depth
(require 'rainbow-delimiters-autoloads)
(global-rainbow-delimiters-mode)
;; Interface between Emacs Lisp and Python
(require 'pymacs-autoloads)
;; minor mode for editing parentheses
(require 'paredit-autoloads)
;; control Git from Emacs.
(require 'magit-autoloads)
;; Magit extensions for using GitHub
(require 'magithub-autoloads)
;; Magit extension for support for org links
(require 'org-magit-autoloads)
;; New TERMinal emulator
(require 'nterm-autoloads)
;; Emacs mode for IDE-like navigation of directories
(require 'nav-autoloads)
;; Muse - Authoring and publishing environment
(require 'htmlize)
(require 'outline)       ; I like outline-style faces
(require 'muse)          ; load generic module
(require 'muse-colors)   ; load coloring/font-lock module
(require 'muse-mode)     ; load authoring mode
(require 'muse-blosxom)  ; load blosxom module
;(require 'muse-docbook)  ; load DocBook publishing style
(require 'muse-html)     ; load (X)HTML publishing style
;(require 'muse-latex)    ; load LaTeX/PDF publishing styles
;(require 'muse-latex2png) ; publish <latex> tags
(require 'muse-project)  ; load support for projects
;(require 'muse-texinfo)  ; load Info publishing style
(require 'muse-wiki)     ; load Wiki support
;(require 'muse-xml)      ; load XML support
;(require 'muse-message)  ; load message support (experimental)
(require 'htmlize-hack)
;; pages style
;;(muse-derive-style "my-xhtml" "xhtml"
;;                   :header "/home/minde/public_html/lib/header.html"
;;                   :footer "/home/minde/public_html/lib/footer.html")
;; Blog style
(muse-derive-style "my-blosxom" "blosxom-xhtml"
		   :final 'my-muse-blosxom-finalize)
;; Pages
(setq muse-project-alist
      `(
	;; Webas
;        ("Web" ("/home/minde/Documents/muse/pages" :default "index")
;         (:base "my-xhtml"
;                :base-url "http://minde.unix-systems.info/"
;                :path "/home/minde/public_html")
;	 (:base "docbook" :path "/home/minde/public_html")
;	 (:base "pdf" :path "/home/minde/public_html")
;	 )
	;; Blogas
        ("Blog" (,@(muse-project-alist-dirs "/home/minde/Documents/webpage/pyblosxom/muse")
                 :default "index")
         ;;   1. Source directory
         ;;   2. Output directory
         ;;   3. Publishing style
         ,@(muse-project-alist-styles "/home/minde/Documents/webpage/pyblosxom/muse"
				      "/home/minde/Documents/webpage/pyblosxom/entries"
                                      "my-blosxom"
                                      :base-url "http://minde.unix-systems.info/blog"))
        ))
;; blosxom finalize
(defun my-muse-blosxom-finalize (file output-path target))
;;; Custom variables
(custom-set-variables
 '(mime-update-field-decoder-cache (quote mime-update-field-decoder-cache) t)
 '(mime-w3m-display-inline-images t)
 '(muse-blosxom-base-directory "/home/minde/Documents/webpage/pyblosxom/muse")
; '(muse-blosxom-extension ".txt")
 '(muse-colors-inline-image-method (quote muse-colors-use-publishing-directory))
 '(muse-completing-read-function (quote ido-completing-read))
 '(muse-publish-comments-p t)
 '(muse-publish-date-format "%b. %e, %Y")

)

;; A major-mode for editing PHP
(require 'php-mode-autoloads)
(require 'php-mode)
(add-hook 'php-mode-hook
           (lambda ()
             (require 'php-completion)
             (php-completion-mode t)
             (define-key php-mode-map (kbd "C-o") 'phpcmp-complete)))
(add-hook  'php-mode-hook
            (lambda ()
              (when (require 'auto-complete nil t)
                (make-variable-buffer-local 'ac-sources)
                (add-to-list 'ac-sources 'ac-source-php-completion)
                ;; if you like patial match,
                ;; use `ac-source-php-completion-patial' instead of `ac-source-php-completion'.
                ;; (add-to-list 'ac-sources 'ac-source-php-completion-patial)
                (auto-complete-mode t))))


;; Move current line or region with M-up or M-down.
(require 'move-text-autoloads)
;;  a major-mode for editing Lua scripts
(require 'lua-mode-autoloads)
;; highlight surrounding parentheses
(require 'highlight-parentheses-autoloads)
;; Function for highlighting indentation
(require 'highlight-indentation-autoloads)
;; graphically indicate the fill column fci-mode
(require 'fill-column-indicator-autoloads)
(require 'fill-column-indicator)

;; gentoo syntax
(add-to-list 'load-path "/usr/share/emacs/site-lisp/gentoo-syntax")
(autoload 'ebuild-mode "gentoo-syntax"
  "Major mode for Portage .ebuild and .eclass files." t)
(autoload 'eselect-mode "gentoo-syntax" "Major mode for .eselect files." t)
(autoload 'gentoo-newsitem-mode "gentoo-syntax"
  "Major mode for Gentoo GLEP 42 news items." t)

(add-to-list 'auto-mode-alist
	     '("\\.\\(ebuild\\|eclass\\|eblit\\)\\'" . ebuild-mode))
(add-to-list 'auto-mode-alist '("\\.eselect\\'" . eselect-mode))
(add-to-list 'auto-mode-alist
	     '("/[0-9]\\{4\\}-[01][0-9]-[0-3][0-9]-.+\\.[a-z]\\{2\\}\\.txt\\'"
	       . gentoo-newsitem-mode))
(add-to-list 'interpreter-mode-alist '("runscript" . sh-mode))
(modify-coding-system-alist
 'file "\\.\\(ebuild\\|eclass\\|eblit\\|eselect\\)\\'" 'utf-8)

(setq ebuild-mode-portdir "/usr/portage")
;; Handling of comment boxes in various styles.
(require 'rebox2)
;; ERC. Powerful, modular, and extensible IRC client
(require 'erc)
(setq erc-timestamp-only-if-changed-flag nil
      erc-timestamp-format "%H:%M:%S "
      erc-fill-prefix "      "
      erc-insert-timestamp-function 'erc-insert-timestamp-left)


(fset 'yes-or-no-p 'y-or-n-p)
;; Galimi varijantai: t, nil, box, hollow, bar, (bar . WIDTH), hbar,
;; (hbar. HEIGHT); see the docs for set-cursor-type
(setq djcb-read-only-color       "#C00000")
(setq djcb-read-only-cursor-type 'hbar)
(setq djcb-overwrite-color       "#0000FF")
(setq djcb-overwrite-cursor-type 'box)
(setq djcb-normal-color          "#324EDC")
(setq djcb-normal-cursor-type    'bar)

;; Ir pakeisk spalva cursoriaus
(set-mouse-color "#808080")
;; nemirksesk
(blink-cursor-mode nil)
(defun djcb-set-cursor-according-to-mode ()
  "change cursor color and type according to some minor modes."

  (cond
    (buffer-read-only
      (set-cursor-color djcb-read-only-color)
      (setq cursor-type djcb-read-only-cursor-type))
    (overwrite-mode
      (set-cursor-color djcb-overwrite-color)
      (setq cursor-type djcb-overwrite-cursor-type))
    (t 
      (set-cursor-color djcb-normal-color)
      (setq cursor-type djcb-normal-cursor-type))))

(add-hook 'post-command-hook 'djcb-set-cursor-according-to-mode)



;;;;FONCTIONS
;;list-colors-display to display all color
; Conversion des fins de lignes du format MS-DOS au format Unix
(defun dos2unix ()
  (interactive)
  (goto-char (point-min))
  (while (search-forward "\r" nil t)
    (replace-match "")
  )
)


    
;(setq mouse-wheel-scroll-amount '(1 ((shift) . 3))) ;; one line at a time

(setq mouse-wheel-progressive-speed nil) ;; don't accelerate scrolling

;(setq mouse-wheel-follow-mouse 't) ;; scroll window under mouse

(setq scroll-step 1) ;; keyboard scroll one line at a time

;; Maintain a menu of recently opened files
(recentf-mode 1)

; Man patinka ideja su "scratch
;(kill-buffer-and-window "*scratch*")
; dabar kai *scratch* buffer nebeliko open maniski kuri galiu saugoti,
; ir kaskarta paleides emacs matysiu tai ka esu isaugojas jame.
(find-file "/home/asido/.emacs.d/org/startup.org")

;; move stupid *~ files to some common place, should be /dev/null
(setq backup-directory-alist '((""."/home/asido/elisp/backups")))
;; always end a file with a newline
(setq require-final-newline 'query)

;; Default major mode
(setq default-major-mode 'text-mode)

;; Always paste at the cursor
(setq mouse-yank-at-point t)

;; Delete selection on a key press
(delete-selection-mode t)

(global-set-key "\C-c>" 'comment-region)
(global-set-key "\C-c<" 'uncomment-region)

;; GMANE is about the only free news server I've seen.
;; I set it to my primary server so I can read a few Free software mailing lists.
(setq gnus-select-method
     '(nntp "news.gmane.org"))
;; Mostly, though, I just want to read my mail.
;; This setup uses a standard SSL-based connection to read the mail for the accounts I have through
;; UC Berkeley:
(setq gnus-secondary-select-methods
      '((nnimap "donaraz" ; primary email
		(nnimap-address "imap.gmail.com")
		(nnimap-server-port 993)
		(nnimap-authenticator login)
		(nnimap-expunge-on-close 'never)
		(nnimap-stream ssl))
	(nnimap "mindeunix" ; secondary account
		(nnimap-address "imap.gmail.com")
		(nnimap-server-port 993)
		(nnimap-authenticator login)
		(nnimap-expunge-on-close 'never)
		(nnimap-stream ssl))))

(setq gnus-fetch-old-headers t)

(require 'w3-autoloads)
(require 'w3)
(require 'w3-parse)
(require 'w3-display)
(require 'w3-auto)
(require 'w3-emulate)
(require 'w3-menu)
(require 'w3-mouse)
(require 'ioccur)


(require 'cedet)
(require 'semantic)
(require 'ede)
(require 'srecode)
(global-ede-mode 1)
(semantic-mode 1)
(global-ede-mode t)
(setq semantic-default-submodes
      '(global-semanticdb-minor-mode
        global-semantic-idle-scheduler-mode
        global-semantic-idle-summary-mode
        global-semantic-idle-completions-mode
        global-semantic-decoration-mode
        global-semantic-highlight-func-mode
        global-semantic-stickyfunc-mode))


;; load custom.el 
(setq custom-file "~/.emacs.d/custom.el")
(load custom-file 'noerror)



(require 'semantic/analyze)
(provide 'semantic-analyze)
(provide 'semantic-ctxt)
(provide 'semanticdb)
(provide 'semanticdb-find)
(provide 'semanticdb-mode)
(provide 'semantic-load)

(add-to-list 'load-path "/home/asido/.emacs.d/ecb")
(require 'ecb)
;(require 'ecb-autoloads)
(setq stack-trace-on-error t)
(ecb-activate)
;(ecb-byte-compile)


