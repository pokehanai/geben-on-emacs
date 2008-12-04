(require 'geben-common)
(require 'geben-dbgp)
(require 'geben-dbgp-util)
(require 'geben-dbgp-start)
(require 'geben-bp)
(require 'geben-backtrace)
(require 'geben-redirect)
(require 'geben-context)

;;==============================================================
;;  geben-mode
;;==============================================================

(defvar geben-mode-map nil)
(unless geben-mode-map
  (setq geben-mode-map (make-sparse-keymap "geben"))
  ;; control
  (define-key geben-mode-map " " 'geben-step-again)
  (define-key geben-mode-map "g" 'geben-run)
  ;;(define-key geben-mode-map "G" 'geben-Go-nonstop-mode)
  (define-key geben-mode-map "t" 'geben-set-redirect)
  ;;(define-key geben-mode-map "T" 'geben-Trace-fast-mode)
  ;;(define-key geben-mode-map "c" 'geben-continue-mode)
  ;;(define-key geben-mode-map "C" 'geben-Continue-fast-mode)

  ;;(define-key geben-mode-map "f" 'geben-forward) not implemented
  ;;(define-key geben-mode-map "f" 'geben-forward-sexp)
  ;;(define-key geben-mode-map "h" 'geben-goto-here)

  ;;(define-key geben-mode-map "I" 'geben-instrument-callee)
  (define-key geben-mode-map "i" 'geben-step-into)
  (define-key geben-mode-map "o" 'geben-step-over)
  (define-key geben-mode-map "r" 'geben-step-out)

  ;; quitting and stopping
  (define-key geben-mode-map "q" 'geben-stop)
  ;;(define-key geben-mode-map "Q" 'geben-top-level-nonstop)
  ;;(define-key geben-mode-map "a" 'abort-recursive-edit)
  (define-key geben-mode-map "v" 'geben-display-context)

  ;; breakpoints
  (define-key geben-mode-map "b" 'geben-set-breakpoint-line)
  (define-key geben-mode-map "B" 'geben-breakpoint-menu)
  (define-key geben-mode-map "u" 'geben-unset-breakpoint-line)
  (define-key geben-mode-map "\C-cb" 'geben-show-breakpoint-list)
  ;;(define-key geben-mode-map "B" 'geben-next-breakpoint)
  ;;(define-key geben-mode-map "x" 'geben-set-conditional-breakpoint)
  ;;(define-key geben-mode-map "X" 'geben-set-global-break-condition)

  ;; evaluation
  (define-key geben-mode-map "e" 'geben-eval-expression)
  ;;(define-key geben-mode-map "\C-x\C-e" 'geben-eval-last-sexp)
  ;;(define-key geben-mode-map "E" 'geben-visit-eval-list)

  ;; views
  (define-key geben-mode-map "w" 'geben-where)
  ;;(define-key geben-mode-map "v" 'geben-view-outside) ;; maybe obsolete??
  ;;(define-key geben-mode-map "p" 'geben-bounce-point)
  ;;(define-key geben-mode-map "P" 'geben-view-outside) ;; same as v
  ;;(define-key geben-mode-map "W" 'geben-toggle-save-windows)

  ;; misc
  (define-key geben-mode-map "?" 'geben-mode-help)
  (define-key geben-mode-map "d" 'geben-show-backtrace)

  ;;(define-key geben-mode-map "-" 'negative-argument)

  ;; statistics
  ;;(define-key geben-mode-map "=" 'geben-temp-display-freq-count)

  ;; GUD bindings
  (define-key geben-mode-map "\C-c\C-s" 'geben-step-into)
  (define-key geben-mode-map "\C-c\C-n" 'geben-step-over)
  (define-key geben-mode-map "\C-c\C-c" 'geben-run)

  (define-key geben-mode-map "\C-x " 'geben-set-breakpoint-line)
  (define-key geben-mode-map "\C-c\C-d" 'geben-unset-breakpoint-line)
  (define-key geben-mode-map "\C-c\C-t" 'geben-set-breakpoint-line)
  (define-key geben-mode-map "\C-c\C-l" 'geben-where))

;;;###autoload
(define-minor-mode geben-mode
  "Minor mode for debugging source code with GEBEN.
The geben-mode buffer commands:
\\{geben-mode-map}"
  nil " *debugging*" geben-mode-map
  (setq buffer-read-only geben-mode)
  (setq left-margin-width (if geben-mode 2 0))
  ;; when the buffer is visible in a window,
  ;; force the window to notice the margin modification
  (let ((win (get-buffer-window (current-buffer))))
    (if win
	(set-window-buffer win (current-buffer)))))
  
(add-hook 'geben-source-visit-hook 'geben-enter-geben-mode)

(defun geben-enter-geben-mode (session buf)
  (with-current-buffer buf
    (geben-mode 1)
    (set (make-local-variable 'geben-current-session) session)))

(add-hook 'geben-source-release-hook
	  (lambda () (geben-mode 0)))

(defun geben-where (session)
  "Move to the current breaking point."
  (interactive)
  (geben-with-current-session session
    (if (geben-session-stack session)
	(let* ((stack (second (car (geben-session-stack session))))
	       (fileuri (geben-source-fileuri-regularize (cdr (assq 'filename stack))))
	       (lineno (cdr (assq 'lineno stack))))
	  (geben-session-cursor-update session fileuri lineno))
      (when (interactive-p)
	(message "GEBEN is not started.")))))

(defun geben-mode-help ()
  "Display description and key bindings of `geben-mode'."
  (interactive)
  (describe-function 'geben-mode))

(defvar geben-step-type :step-into
  "Step command of what `geben-step-again' acts.
This value remains the last step command type either
`:step-into' or `:step-out'.")

(defun geben-step-again ()
  "Do either `geben-step-into' or `geben-step-over' what the last time called.
Default is `geben-step-into'."
  (interactive)
  (case geben-step-type
    (:step-over (geben-step-over))
    (:step-into (geben-step-into))
    (t (geben-step-into))))
     
(defun geben-step-into ()
  "Step into the definition of the function or method about to be called.
If there is a function call involved it will break on the first
statement in that function"
  (interactive)
  (setq geben-step-type :step-into)
  (geben-with-current-session session
    (geben-dbgp-command-step-into session)))

(defun geben-step-over ()
  "Step over the definition of the function or method about to be called.
If there is a function call on the line from which the command
is issued then the debugger engine will stop at the statement
after the function call in the same scope as from where the
command was issued"
  (interactive)
  (setq geben-step-type :step-over)
  (geben-with-current-session session
    (geben-dbgp-command-step-over session)))

(defun geben-step-out ()
  "Step out of the current scope.
It breaks on the statement after returning from the current
function."
  (interactive)
  (geben-with-current-session session
    (geben-dbgp-command-step-out session)))

(defun geben-run ()
  "Start or resumes the script.
It will break at next breakpoint, or stops at the end of the script."
  (interactive)
  (geben-with-current-session session
    (geben-dbgp-command-run session)))

(defun geben-stop ()
  "End execution of the script immediately."
  (interactive)
  (geben-with-current-session session
    (geben-dbgp-command-stop session)))

(defun geben-breakpoint-menu (arg)
  "Set a breakpoint interactively.
Script debugger engine may support a kind of breakpoints, which
will be stored in the variable `geben-dbgp-breakpoint-types'
after a debugging session is started.

This command asks you a breakpoint type and its options.
Optionally, with a numeric argument you can specify `hit-value'
\(number of hits to break); \\[universal-argument] 2 \
\\<geben-mode-map>\\[geben-breakpoint-menu] will set a breakpoint
with 2 hit-value.
With just a prefix arg \(\\[universal-argument] \\[geben-breakpoint-menu]), \
this command will also ask a
hit-value interactively.
"
  (interactive "P")
  (geben-with-current-session session
    (let ((candidates (remove nil
			      (mapcar
			       (lambda (x)
				 (if (member (car x)
					     (geben-breakpoint-types (geben-session-bp session)))
				     x))
			       '((:line . "l)Line")
				 (:call . "c)Call")
				 (:return . "r)Return")
				 (:exception . "e)Exception")
				 (:conditional . "d)Conditional")
				 (:watch . "w)Watch"))))))
      (when (null candidates)
	(error "No breakpoint type is supported by the debugger engine."))
      (let* ((c (read-char (concat "Breakpoint type: "
				   (mapconcat
				    (lambda (x)
				      (cdr x))
				    candidates " "))))
	     (x (find-if (lambda (x)
			   (eq c (elt (cdr x) 0)))
			 candidates))
	     (fn (and x
		      (intern-soft (concat "geben-set-breakpoint-"
					   (substring (symbol-name (car x)) 1))))))
	(unless x
	  (error "Cancelled"))
	(if (fboundp fn)
	    (call-interactively fn)
	  (error (concat (symbol-name fn) " is not implemented.")))))))

(defun geben-set-breakpoint-common (session hit-value cmd)
  (setq hit-value (if (and (not (null hit-value))
			   (listp hit-value))
		      (if (fboundp 'read-number)
			  (read-number "Number of hit to break: ")
			(string-to-number
			 (read-string "Number of hit to break: ")))
		    hit-value))
  (plist-put cmd :hit-value (if (and (numberp hit-value)
				     (<= 0 hit-value))
				hit-value
			      0))
  (geben-dbgp-command-breakpoint-set session cmd))

(defun geben-set-breakpoint-line (fileuri lineno &optional hit-value)
  "Set a breakpoint at the current line.
Optionally, with a numeric argument you can specify `hit-value'
\(number of hits to break); \\[universal-argument] 2 \
\\<geben-mode-map>\\[geben-set-breakpoint-line] will set a breakpoint
with 2 hit-value.
With just a prefix arg \(\\[universal-argument] \\[geben-set-breakpoint-line]), \
this command will also ask a
hit-value interactively."
  (interactive (list nil nil current-prefix-arg))
  (geben-with-current-session session
    (let ((local-path (if fileuri
			  (geben-session-source-local-path session fileuri)
			(buffer-file-name (current-buffer)))))
      (geben-set-breakpoint-common session hit-value
				   (geben-bp-make
				    session :line
				    :fileuri (or fileuri
						 (geben-session-source-fileuri session local-path)
						 (geben-session-source-fileuri session (file-truename local-path))
						 (geben-source-fileuri session local-path))
				    :lineno (if (numberp lineno)
						lineno
					      (geben-what-line))
				    :local-path local-path
				    :overlay t)))))

(defvar geben-set-breakpoint-call-history nil)
(defvar geben-set-breakpoint-fileuri-history nil)
(defvar geben-set-breakpoint-exception-history nil)
(defvar geben-set-breakpoint-condition-history nil)

(defun geben-set-breakpoint-call (name &optional fileuri hit-value)
  "Set a breakpoint to break at when entering function/method named NAME.
For a class method, specify NAME like \"MyClass::MyMethod\".
For an instance method, do either like \"MyClass::MyMethod\" or
\"MyClass->MyMethod\".
Optionally, with a numeric argument you can specify `hit-value'
\(number of hits to break); \\[universal-argument] 2 \
\\<geben-mode-map>\\[geben-set-breakpoint-call] will set a breakpoint
with 2 hit-value.
With just a prefix arg \(\\[universal-argument] \\[geben-set-breakpoint-call]),
this command will also ask a
hit-value interactively."
  (interactive (list nil))
  (geben-with-current-session session
    (when (interactive-p)
      (setq name (read-string "Name: " ""
			      'geben-set-breakpoint-call-history))
      (setq fileuri
	    (unless (member (geben-session-language session) '(:php :ruby))
	      ;; at this present some debugger engines' implementations is buggy:
	      ;; some requires fileuri and some don't accept it.
	      (let ((local-path (file-truename (buffer-file-name (current-buffer)))))
		(read-string "fileuri: " 
			     (or (geben-session-source-fileuri session local-path)
				 (geben-source-fileuri session local-path))
			     'geben-set-breakpoint-fileuri-history))))
      (setq hit-value current-prefix-arg))
    (when (string< "" name)
      (geben-set-breakpoint-common session hit-value
				   (geben-bp-make session :call
						  :function name
						  :fileuri fileuri)))))

(defun geben-set-breakpoint-return (name &optional fileuri hit-value)
  "Set a breakpoint to break after returned from a function/method named NAME.
For a class method, specify NAME like \"MyClass::MyMethod\".
For an instance method, do either like \"MyClass::MyMethod\" or
\"MyClass->MyMethod\".
Optionally, with a numeric argument you can specify `hit-value'
\(number of hits to break); \\[universal-argument] 2 \
\\<geben-mode-map>\\[geben-set-breakpoint-return] will set a breakpoint
with 2 hit-value.
With just a prefix arg \(\\[universal-argument] \\[geben-set-breakpoint-return]),
this command will also ask a
hit-value interactively."
  (interactive (list nil))
  (geben-with-current-session session
    (when (interactive-p)
      (setq name (read-string "Name: " ""
			      'geben-set-breakpoint-call-history))
      (setq fileuri
	    (unless (member (geben-session-language session) '(:php :ruby))
	      ;; at this present some debugger engines' implementations are buggy:
	      ;; some requires fileuri and some don't accept it.
	      (let ((local-path (file-truename (buffer-file-name (current-buffer)))))
		(read-string "fileuri: " 
			     (or (geben-session-source-fileuri session local-path)
				 (geben-source-fileuri session local-path))
			     'geben-set-breakpoint-fileuri-history))))
      (setq hit-value current-prefix-arg))
    (when (string< "" name)
      (geben-set-breakpoint-common session hit-value
				   (geben-bp-make session :return
						  :function name
						  :fileuri fileuri)))))

(defun geben-set-breakpoint-exception (name &optional hit-value)
  "Set a breakpoint to break at when an exception named NAME is occurred.
Optionally, with a numeric argument you can specify `hit-value'
\(number of hits to break); \\[universal-argument] 2 \
\\<geben-mode-map>\\[geben-set-breakpoint-exception] will set a breakpoint
with 2 hit-value.
With just a prefix arg \(\\[universal-argument] \\[geben-set-breakpoint-exception]),
this command will also ask a
hit-value interactively."
  (interactive (list
		(read-string "Exception type: "
			     "Exception"
			     'geben-set-breakpoint-exception-history)
		current-prefix-arg))
  (geben-with-current-session session
    (geben-set-breakpoint-common session hit-value
				 (geben-bp-make session :exception
						:exception name))))
   
(defun geben-set-breakpoint-conditional (expr fileuri &optional lineno hit-value)
  "Set a breakpoint to break at when the expression EXPR is true in the file FILEURI.
Optionally, with a numeric argument you can specify `hit-value'
\(number of hits to break); \\[universal-argument] 2 \
\\<geben-mode-map>\\[geben-set-breakpoint-conditional] will set a breakpoint
with 2 hit-value.
With just a prefix arg \(\\[universal-argument] \\[geben-set-breakpoint-conditional]),
this command will also ask a
hit-value interactively."
  (interactive (list nil nil))
  (geben-with-current-session session
    (when (interactive-p)
      (setq expr (read-string "Expression: " ""
			      'geben-set-breakpoint-condition-history))
      (setq fileuri
	    (let ((local-path (file-truename (buffer-file-name (current-buffer)))))
	      (or (geben-session-source-fileuri session local-path)
		  (geben-source-fileuri session local-path))))
      (setq lineno (read-string "Line number to evaluate (blank means entire file): "
				(number-to-string (geben-what-line))))
      (setq hit-value current-prefix-arg))
    
    (geben-set-breakpoint-common session hit-value
				 (geben-bp-make session :conditional
						:expression expr
						:fileuri fileuri
						:lineno (and (stringp lineno)
							     (string-match "^[0-9]+$" lineno)
							     (string-to-number lineno))))))

(defun geben-set-breakpoint-watch (expr &optional hit-value)
  "Set a breakpoint to break on write of the variable or address.
Optionally, with a numeric argument you can specify `hit-value'
\(number of hits to break); \\[universal-argument] 2 \
\\<geben-mode-map>\\[geben-set-breakpoint-conditional] will set a breakpoint
with 2 hit-value.
With just a prefix arg \(\\[universal-argument] \\[geben-set-breakpoint-conditional]),
this command will also ask a
hit-value interactively."
  (interactive (list nil))
  (geben-with-current-session session
    (when (interactive-p)
      (setq expr (read-string "Expression: " ""
			      'geben-set-breakpoint-condition-history))
      (setq hit-value current-prefix-arg))
    (geben-set-breakpoint-common session hit-value
				 (geben-bp-make session :watch
						:expression expr))))

(defun geben-unset-breakpoint-line (fileuri path lineno)
  "Clear a breakpoint set at the current line."
  (interactive (list nil nil nil))
  (geben-with-current-session session
    (when (interactive-p)
      (setq path (buffer-file-name (current-buffer)))
      (when (stringp path)
	(setq lineno (and (get-file-buffer path)
			  (with-current-buffer (get-file-buffer path)
			    (geben-what-line))))
	(setq fileuri (or (geben-session-source-fileuri session path)
			  (geben-source-fileuri session path)
			  (concat "file://" (file-truename path))))))
    (let* ((bp (find-if (lambda (bp)
			  (and (eq :line (plist-get bp :type))
			       (eq lineno (plist-get bp :lineno))
			       (equal fileuri (plist-get bp :fileuri))))
			(geben-breakpoint-list (geben-session-bp session))))
	   (bid (and bp (plist-get bp :id))))
      (if bid
	  (geben-dbgp-command-breakpoint-remove session bid)))))

(defun geben-show-breakpoint-list ()
  "Display breakpoint list.
The breakpoint list buffer is under `geben-breakpoint-list-mode'.
Key mapping and other information is described its help page."
  (interactive)
  (geben-breakpoint-list-refresh t))

(defvar geben-eval-history nil)

(defun geben-eval-expression (expr)
  "Evaluate a given string EXPR within the current execution context."
  (interactive
   (progn
     (list (read-from-minibuffer "Eval: "
				 nil nil nil 'geben-eval-history))))
  (geben-with-current-session session
    (geben-dbgp-command-eval session expr)))

(defun geben-open-file (fileuri)
  "Open a debugger server side file specified by FILEURI.
FILEURI forms like as \`file:///path/to/file\'."
  (interactive (list (read-string "Open file: " "file://")))
  (geben-with-current-session session
    (geben-dbgp-command-source session fileuri)))

(defun geben-show-backtrace ()
  "Display backtrace list.
The backtrace list buffer is under `geben-backtrace-mode'.
Key mapping and other information is described its help page."
  (interactive)
  (geben-with-current-session session
    (geben-backtrace session)))

(defun geben-set-redirect (target &optional arg)
  "Set the debuggee script's output redirection mode.
This command enables you to redirect the debuggee script's output to GEBEN.
You can select redirection target from \`stdout', \`stderr' and both of them.
Prefixed with \\[universal-argument], you can also select redirection mode
from \`redirect', \`intercept' and \`disabled'."
  (interactive (list (case (read-char "Redirect: o)STDOUT e)STRERR b)Both")
		       (?o :stdout)
		       (?e :stderr)
		       (?b :both))
		     current-prefix-arg))
  (unless target
    (error "Cancelled"))
  (let ((mode (if arg
		  (case (read-char "Mode: r)Redirect i)Intercept d)Disable")
		    (?r :redirect)
		    (?i :intercept)
		    (?d :disable))
		:redirect)))
    (unless mode
      (error "Cancelled"))
    (geben-with-current-session session
      (when (memq target '(:stdout :both))
	(geben-dbgp-command-stdout session mode))
      (when (memq target '(:stderr :both))
	(geben-dbgp-command-stderr session mode)))))

(defun geben-display-context (&optional depth)
  (interactive (list (cond
		      ((null current-prefix-arg) 0)
		      ((numberp current-prefix-arg)
		       current-prefix-arg)
		      ((listp current-prefix-arg)
		       (if (fboundp 'read-number)
			   (read-number "Depth: " 0)
			 (string-to-number (read-string "Depth: " "0"))))
		      (t nil))))
  (geben-with-current-session session
    (geben-context-display session (or depth 0))))

(provide 'geben-mode)