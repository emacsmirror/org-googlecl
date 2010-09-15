(defcustom googlecl-blogname "My Blog Name"
  "The name of the default blogger/blogspot blog you wish to blog to."
  :group 'org-googlecl
  :type 'string)

(defcustom googlecl-username "changeme@googlemail.com"
  "The google user id you wish to authenticate with. e.g mydevusername@googlemail.com"
  :group 'org-googlecl
  :type 'string)

(defcustom googlecl-default-labels "emacs,elisp"
  "default labels"
  :group 'org-googlecl
  :type 'string)

(defcustom googlecl-blog-exists nil
  "Set to t if you wish to be informed if the item is already blogged. If set and the items exists you be prompted to post again or to browse the existing blog entry."
  :group 'org-googlecl
  :type 'boolean)

(defcustom googlecl-footer "<br/>-- <br/><a href='http://github.com/rileyrg'>My Emacs Files At GitHub</a>"
  "footer for the post"
  :group 'org-googlecl
  :type 'string)

(defcustom googlecl-prompt-footer nil
  "whether to prompt with the footer"
  :group 'org-googlecl
  :type 'boolean)

(defcustom googlecl-blog-exists nil
  "Set to t if you wish to be informed if the item is already blogged. If set and the items exists you be prompted to post again or to browse the existing blog entry."
  :group 'org-googlecl
  :type 'boolean)

(defcustom googlecl-blog-tag "blogged"
  "org entries that are blogged are tagged with this tag. Leave empty if you dont want your org entry tagged."
  :group 'org-googlecl
  :type 'string)

(defcustom googlecl-blog-auto-del nil
  "If set to t then will auto delete any existing blog entries with the same title"
  :group 'org-googlecl
  :type 'boolean)

(defcustom googlecl-blog-exists t
  "Set to t if you wish to be informed if the item is already blogged."
  :group 'org-googlecl
  :type 'boolean)

(defun googlecl-prompt-blog ()
  "If in an org buffer prompt whether to blog the entire entry or to perform a  normal text blog."
  (interactive)
  (if (eq major-mode 'org-mode)
      (if (yes-or-no-p "Blog the Org Entry?")
	    (org-googlecl-blog) 
	(googlecl-blog))
    (googlecl-blog)))
     
(defun googlecl-blog (&optional borg btitle blabels bbody)
  "Generalised googlecl blog. Only prompt for blog,title and
labels if an org item as the rest comes from the org item at
point. If you wish to blog current org item set borg parameter to
t"
  (setq googlecl-blogname (read-from-minibuffer "Blog Name:" googlecl-blogname))
  (setq btitle (read-from-minibuffer "Title:" btitle))

  ;; If the option flag googlecl-blog-exists is set to true we check if there is already an entry with this title.
  ;; If a blog with the same title exists then give the option to view it via the default browser.
  (if googlecl-blog-exists
      (with-temp-buffer
	(let* ((blogrc (call-process-shell-command  (concat "google blogger  list --blog '" googlecl-blogname "' --title '" btitle "' url") nil (current-buffer)))
	     (blogurl (buffer-string)))
	  (if (not (zerop(length blogurl)))
	      (progn
		(if (and googlecl-blog-exists (y-or-n-p (concat "Blog entry exists :" blogurl ". View existing?")))
		    (browse-url (nth 0 (org-split-string blogurl))))
		(setq blogurl (nth 0 (org-split-string blogurl)))
		(if (or googlecl-blog-auto-del (y-or-n-p "Delete existing blog entry?"))
		    (let ((delcommand  (format "yes y | google blogger delete --blog '%s'  --title '%s'"  googlecl-blogname  btitle)))
		      (message "Delete command is : %s" delcommand)
		      (call-process-shell-command delcommand))))))))
  
  (unless borg (setq bbody 
		     (if (use-region-p) 
			 (region-or-word-at-point) 
		       (read-from-minibuffer "Body:" ))))


  (if blabels
      (setq blabels (string-trim blabels)))

  (setq googlecl-default-labels 
	(setq blabels 
	      (read-from-minibuffer 
	       "Labels:" 
	       (if (zerop (length blabels))
		   googlecl-default-labels
		   blabels
		 ))))

  (if googlecl-prompt-footer (setq googlecl-footer
	(read-from-minibuffer
	 "Footer:"
	 googlecl-footer)))

  (let* ((tmpfile (make-temp-file "googlecl"))
	 (bhtml (if borg (org-export-as-html 5 nil nil 'string t) bbody))
	 (blog-command (concat 
			"google blogger post --blog \"" googlecl-blogname "\""
			(if (length btitle) (concat " --title \"" btitle "\"")) " --user \"" googlecl-username "\" " 
			(if (length blabels) (concat " --tags \"" blabels "\" "))  
			tmpfile)))
    
    (message "blog command is %s" blog-command)

    (with-temp-file  tmpfile
      (insert bhtml)
      (goto-char (buffer-end 1))
      (insert googlecl-footer))

    (start-process-shell-command "googlecl-pid" nil blog-command)))


(defun org-googlecl-blog  ()
  "Post the current org item to blogger/blogspot.
   Tags are converted to blogger labels. If you wish to alter the default blog name prefix the function call (C-u)."
  (interactive)
  (if current-prefix-arg
      (setq googlecl-blogname (read-from-minibuffer "Blog Name:")))

  (save-excursion
      (set-mark (goto-char (org-entry-beginning-position)))
      (let*((btags  (org-get-tags)))
	(save-excursion
	  (set-mark (goto-char (org-entry-beginning-position)))
	  (let ((btitle (nth 4 (org-heading-components))))
	    (org-forward-same-level 1 t)
	    (googlecl-blog t btitle (mapconcat  'identity  (remove googlecl-blog-tag btags) ","))))
       
	(if (not(zerop(length googlecl-blog-tag)))
	    (org-set-tags-to (add-to-list 'btags googlecl-blog-tag))))))
	       

(provide 'org-googlecl)
