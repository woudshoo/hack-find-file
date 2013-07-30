(require 'f)
(require 's)

(defvar hack-find-file-fallback
  'ido-find-file
  "Set this to the defun to fallback to when nothing specific matches.")

(defun hff/find-file-in-directories ( filename directories )
  ""
  (interactive)
  (let (absolute-filename
        found)
    (while (and directories
                (not found))
      (setq absolute-filename (f-join (pop directories) filename))
      (message "Checking %s" absolute-filename)
      (when (f-exists? absolute-filename)
        (setq directories nil
              found t)))
    (when found
      absolute-filename)))

(defun hff/perl-cmd-to-buffer ( perl-cmd output-buffer )
  ""
  (interactive)
  (with-temp-buffer
    (let ((error-buffer (current-buffer)))
      (with-temp-buffer
        (insert perl-cmd)
        (call-process-region (point-min) (point-max) "perl" nil output-buffer)))))

(defun hff/perl-cmd-to-string ( perl-cmd )
  ""
  (interactive)
  (with-temp-buffer
    (hff/perl-cmd-to-buffer perl-cmd (current-buffer))
    (buffer-substring-no-properties (point-min) (point-max))))

(defun hff/perl-filename-for-library-name ( library-name )
  ""
  (interactive)
  (concat (s-join "/" (split-string library-name "::" t)) ".pm" ))

(defun hff/perl-cmd-for-getting-path-to-library-name ( library-name )
  ""
  (interactive)
  (concat "use " library-name "; print $INC{\"" (hff/perl-filename-for-library-name library-name) "\"};"))

(defun hff/find-perl-library-file-using-call-process-on-region ( library-name )
  "This defun does work on Windows, however when performed on a
non-existing LIBRARY-NAME displays an error in the minibuffer."
  (interactive)
  (let ((absolute-filename (hff/perl-cmd-to-string (hff/perl-cmd-for-getting-path-to-library-name library-name))))
    (if (and (> (length absolute-filename) 0)
             (f-exists? absolute-filename))
        (progn
          (find-file absolute-filename)
          t)
      nil)))

(defun hff/find-file-use-at-point ()
  ""
  (interactive)
  (let ((library-name (thing-at-point 'symbol t)))
    (when library-name
      (hff/find-perl-library-file-using-call-process-on-region library-name))))

(defun hff/find-file-require-at-point ()
  "Figure out whether we're on a 'require' and if so, open the associated file."
  (interactive)
  (let ((list (list-at-point)))
    (if (and list
               (equal (car list) 'require))
        (progn
          (find-library (symbol-name (cadadr (list-at-point))))
          t)
      nil)))

(defun hff/find-filename-at-point ()
  "Checks wheter point is on an existing filename, and just opens that if that is the case.
Otherwise calls ido-find-file."
  (interactive)
  (let ((filename (thing-at-point 'filename t)))
    (if (and filename
             (file-exists-p filename))
        (progn
          (find-file (thing-at-point 'filename t))
          t)
      nil)))

;;;###autoload
(defun hack-find-file ()
  "Try to open file at point with different strategies, eventually falling back on ido-find-file."
  (interactive)
  (let ((strategies (list 'hff/find-file-use-at-point 'hff/find-file-require-at-point 'hff/find-filename-at-point hack-find-file-fallback)))
    (while strategies
      (when (funcall (pop strategies))
        (setq strategies nil)))))

(global-set-key (kbd "C-x C-f") 'hack-find-file)

(provide 'hack-find-file)
