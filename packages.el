;;; packages.el --- custom-swift layer packages file for Spacemacs.
;;
;; Copyright (c) 2012-2016 Sylvain Benner & Contributors
;;
;; Author: Amber Star <amber@Ambers-iMac>
;; URL: https://github.com/syl20bnr/spacemacs
;;
;; This file is not part of GNU Emacs.
;;
;;; License: GPLv3

;;; Commentary:

;; See the Spacemacs documentation and FAQs for instructions on how to implement
;; a new layer:
;;
;;   SPC h SPC layers RET
;;
;;
;; Briefly, each package to be installed or configured by this layer should be
;; added to `custom-swift-packages'. Then, for each package PACKAGE:
;;
;; - If PACKAGE is not referenced by any other Spacemacs layer, define a
;;   function `custom-swift/init-PACKAGE' to load and initialize the package.

;; - Otherwise, PACKAGE is already referenced by another Spacemacs layer, so
;;   define the functions `custom-swift/pre-init-PACKAGE' and/or
;;   `custom-swift/post-init-PACKAGE' to customize the package as it is loaded.

;;; Code:
(setq custom-swift-packages
  '(
    auto-completion
    company
    flycheck
    swift-mode
    (company-sourcekit :location (recipe :fetcher github :repo "nathankot/company-sourcekit" :files "company-sourcekit.el"))
    )
  )

;;; packages.el ends here

 (when (configuration-layer/layer-usedp `auto-completion)
  (defun custom-swift/post-init-company()
    (spacemacs|add-company-hook swift-mode))

  (defun custom-swift/init-company-sourcekit ()
    (use-package company-sourcekit
      :if (configuration-layer/layer-usedp `company)
      :defer t
      :init
      (push `company-sourcekit company-backends-swift-mode))))

(defun custom-swift/post-init-flycheck()
  (spacemacs|use-package-add-hook flycheck-color-mode-line-error-face
             :post-config (add-to-list `flycheck-checkers `swift)))

(defun custom-swift/init-swift-mode ()
  (use-package swift-mode
    :mode ("\\.swift\\'" . swift-mode)
    :defer t
    :init
    (progn
      (spacemacs|advise-commands "store-initial-buffer-name"
                                 (swift-mode-run-repl) around
       "Store current buffer bane in bufffer local variable,
before activiting or switching to REPL."
       (let ((initial-buffer (current-buffer)))
         ad-do-it
         (with-current-buffer swift-repl-buffer
           (setq swift-repl-mode-previous-buffer initial-buffer))))

      (defun spacemacs/swift-repl-mode-hook ()
        "Hook to run when starting an interactive swift mode repl"
        (make-variable-buffer-local 'swift-repl-mode-previous-buffer))
      (add-hook 'swift-repl-mode-hook 'spacemacs/swift-repl-mode-hook)

      (defun spacemacs/swift-repl-mode-switch-back ()
        "Switch back to from REPL to editor."
        (interactive)
        (if swift-repl-mode-previous-buffer
            (switch-to-buffer-other-window swift-repl-mode-previous-buffer)
          (message "No previous buffer"))))
    :config
    (progn
      (spacemacs/set-leader-keys-for-major-mode 'swift-mode
        "sS" 'swift-mode-run-repl      ; run or switch to an existing swift repl
        "ss" 'swift-mode-run-repl
        "sb" 'swift-mode-send-buffer
        "sr" 'swift-mode-send-region)

      (with-eval-after-load 'swift-repl-mode-map
        ;; Switch back to editor from REPL
        (spacemacs/set-leader-keys-for-major-mode 'swift-repl-mode
          "ss"  'spacemacs/swift-repl-mode-switch-back)
        (define-key swift-repl-mode-map
          (kbd "C-c C-z") 'spacemacs/swift-repl-mode-switch-back)))))
