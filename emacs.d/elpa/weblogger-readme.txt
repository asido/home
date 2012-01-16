;;; Commentary:

;; weblogger.el implements the Blogger, MetaWeblog, Movable Type, and
;; LiveJournal APIs to talk to server-side weblog software.
;;
;;; Starting Out:
;;
;; If you don't yet have a weblog, you can set one up for free on
;; various services.  (I suggest OpenWeblog.com, but then I run that
;; site :) )
;;
;; To set up your profile:
;;
;;    M-x weblogger-setup-weblog RET

;; You will be prompted for some information.  The URL should be the
;; one that uses the API you're using, not the one you would use for
;; typing an entry.  For instance, in wordpress, use
;; <blog-url>/xmlrpc.php.

;; *** FIXME This section is complete fantasy at the moment.
;; ;; If you already have a weblog, and your weblog supports RSD
;; ;; (http://archipelago.phrasewise.com/rsd), you can use
;; ;;
;; ;;    M-x weblogger-discover-server RET url RET
;; ;;
;; ;; where url is the URL of your weblog.  This will set up a
;; ;; ~/.webloggerrc file for you if you let it.

;; You can also set up your server information using
;;
;;    M-x customize-group RET weblogger RET
;;
