# emacs key binding


how to bind key in emacs





global-set-key
global-unset-key


define-key

map-key

defmap?



keyboard shortcut to command




M-x eval-last-sexp

可以使 .emacs 中的配置快速生效，不用重启来检验



Meta -> Alt


M-x describe-mode
binding about mode


M-x describe-bindings
all bindings


## keymap

???

The command bindings of input events are recorded in data structures called keymaps. Each entry in a keymap associates (or binds) an individual event type, either to another keymap or to a command. When an event type is bound to a keymap, that keymap is used to look up the next input event; this continues until a command is found. The whole process is called key lookup. 



key sequence (key) -> one or more input events that form a unit

(kbd keyseq-text) -> key

The kbd macro translates a human-readable key into a format Emacs can understand.

One important point to note is that you must surround function and navigation keys with < and >. Those keys include F-keys, arrow keys and home row keys, like so: <home>, <f8> and <down>. But if you want represent the key C-c p then write (kbd "C-c p").


http://ergoemacs.org/emacs/keyboard_shortcuts_examples.html

https://www.masteringemacs.org/article/mastering-key-bindings-emacs

https://wilkesley.org/~ian/xah/emacs/keyboard_shortcuts.html















## info mode

M-x info

M-x emacs-index-search
M-x elisp-index-search



## define-key


```emacs-lisp
(global-set-key key binding)

(define-key (current-global-map) key binding)


(global-unset-key key)
(global-set-key key nil)
(define-key (current-global-map) key nil)


(local-set-key key binding)

(define-key (current-local-map) key binding)


(local-unset-key key)
(local-set-key key nil)
(define-key (current-local-map) key nil)
```


```emacs-lisp
```

```emacs-lisp
```

