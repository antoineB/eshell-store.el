;;; eshell-store.el --- Store eshell input and output into a file.  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  

;; Author:  <antoine@antoine-AB350-Gaming>
;; Keywords: 

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Record every commands (and the output) of every commands you type in eshell.

;;; Code:

(require 'esh-mode)

(defcustom eshell-store-directory
  (concat user-emacs-directory "eshell-store")
  "The directory where all history will be stored."
  :version "26.2"
  :type 'string
  :group 'eshell-store)

(defvar eshell-store-input-cmd nil)
(defvar eshell-store-start-cmd-time nil)


(defun eshell-store-filename ()
  "Return the file name where to store the commands."
  (format-time-string "%Y-%m-%d" (current-time)))

(defun eshell-store-insert-block (cmd start-time end-time cwd buffer-name output)
  "Insert into the file the current commands info and output."
  (let ((filename (concat eshell-store-directory "/" (eshell-store-filename)))
        (text (format "* ~%s~
:PROPERTIES:
:START-TIME: %s
:END-TIME: %s
:BUFFER-NAME: %s
:CWD: %s
:END:
#+BEGIN_EXAMPLE
%s
#+END_EXAMPLE
"
            cmd
            start-time
            end-time
            cwd
            buffer-name
            output)))
    (with-current-buffer (find-file-noselect filename t t)
      (goto-char (point-max))
      (insert text)
      (let ((save-silently t))
        (basic-save-buffer-1)))))


;; TODO: What to do with visual commands ?
;; eshell-visual-commands
;; eshell-visual-subcommands
;; eshell-visual-options


(defun eshell-store-pre-command-fn (&rest rest)
  (setq-local eshell-store-start-cmd-time (format-time-string "%Y-%m-%dT%H:%M:%S%z" (current-time)))
  (setq-local eshell-store-input-cmd (buffer-substring-no-properties eshell-last-output-end (1- (point)))))


(defun eshell-store-post-command-fn ()
  (when eshell-store-input-cmd
    (eshell-store-insert-block
     eshell-store-input-cmd
     eshell-store-start-cmd-time
     (format-time-string "%Y-%m-%dT%H:%M:%S%z" (current-time))
     (eshell/pwd)
     (buffer-name)
     (buffer-substring-no-properties
      (eshell-beginning-of-output)
      (eshell-end-of-output))))
  (setq-local eshell-store-input-cmd nil))


(add-hook 'eshell-mode-hook
          (lambda ()
            (make-directory eshell-store-directory t)
            ;; TODO: list all files in eshell-store-directory and .gz then if not (format-time-string "%Y-%m-%d.org" (current-time))
            (make-local-variable 'eshell-store-input-cmd)
            (make-local-variable 'eshell-store-start-cmd-time)
            (add-hook 'eshell-post-command-hook 'eshell-store-post-command-fn t t)
            (add-hook 'eshell-expand-input-functions 'eshell-store-pre-command-fn t t)))


(provide 'eshell-store)
;;; eshell-store.el ends here
