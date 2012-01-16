;;; Commentary:

;; mediawiki.el allows you to edit pages on Mediawiki-powered wikis.
;;
;; To set up the mode, follow the installation instructions (below)
;; and then:
;;
;;   M-x customize-group RET mediawiki RET
;;   *dink* *dink*
;;   M-x mediawiki-site RET Wikipedia RET
;;
;; Open a wiki file:    M-x mediawiki-open
;; Save a wiki buffer:  C-x C-s
;; Save a wiki buffer with a different name:  C-x C-w

;;; Installation

;; If you use ELPA (http://tromey.com/elpa), you can install via the
;; M-x package-list-packages interface. This is preferrable as you
;; will have access to updates automatically.

;; Otherwise, just make sure this file is in your load-path (usually
;; ~/.emacs.d is included) and put (require 'mediawiki.el) in your
;; ~/.emacs or ~/.emacs.d/init.el file.

