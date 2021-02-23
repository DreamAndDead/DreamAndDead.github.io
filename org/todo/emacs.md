# get started with emacs

1000 people have 1000 different emacs.

configuration.

help system and package management

## help system

using emacs help system is the key to learn it.

emacs config file is located in `~/.emacs.d/init.el`


`C-h C-h` to call out the metahelp content list window. `space` to scroll content, type option key to check out the related topic.
`q` to exit.


top useful in the list:
`v VARIABLE`, type `v`, and search the `VARIABLE` in all the config variables. `cursor` to search variable start with cursor, `*cursor` to search variable contains cursor.


e.g.

stop cursor blink

`C-h v`, search `blink`, tab to complete.
we found blink-mode, enter to see its detail.
the variable is obsolete since 22.1, use blink-cursor-mode instead.

so we `C-h v`, search `blink-cursor-mode`.
mouse click the `customize`, to change this variable.
that's a feature called Easy Customization.

click toggle, and state, select save for future sessions.
so the change will be write in the init.el config file.

e.g.

hide scroll bar

same method, search scroll-bar-mode, change value to nil and save for future sessions.


e.g.

hide tool bar

same method, search tool-bar-mode, change value to nil and save for future sessions.


we check out the config file.

found these config in (custom-set-variables)

'(blink-cursor-mode nil)
'(scroll-bar-mode nil)
'(tool-bar-mode nil)


restart emacs to see if the setting works.



another useful help function
`C-h b`, list all key bindings.
`C-h c`, check the command name by the key bindings.
command name is very important. you know the name and you can control it.


`C-h d`, word list or regex, to search all command, variable that match the input.
it's powerful to search the proper configuration.

`C-h e`, to check the message window


`C-h k`, check doc that binded by the binding.

`C-h w`, search the key binding of the command.

`C-h m`, check doc of minor mode



`C-h r`, see emacs manual

`C-h t`, emacs tutorial








## package manager part

package manager part


nice analyses about emacs package.el
https://batsov.com/articles/2012/02/19/package-management-in-emacs-the-good-the-bad-and-the-ugly/

how to install package using elpa, melpa
http://ergoemacs.org/emacs/emacs_package_system.html



add melpa source, so we can install more packages

melpa getting started
https://melpa.org/#/getting-started

can also use tsinghua elpa mirrors
https://mirror.tuna.tsinghua.edu.cn/help/elpa/



gnu source is the default, add melpa source for more packaes.
that's what tsinghua mirror suggest



after changing the source, restart emacs

M-x package-refresh-contents

update the package list cache



how to use package.el
http://ergoemacs.org/emacs/emacs_package_system.html


then
M-x package-list-packages

h to see the package-menu help
or M-x package-menu-quick-help

i to install
d to remove
x to excute
U to update
enter to check out the details
f to filter


after install the package, restart emacs, it'll be loaded.






## suitable theme for you

find gruvbox-theme in package-list-packages, install and restart

M-x customize-themes RET

mouse click to try it.
click Save Theme Settings to save to emacs config file 





## emacs built-in packages

useful packages in emacs

all these packages are installed in /usr/share/emacs/26.2/lisp.
you can use `locate ido.el` to find it.

### what elisp require means

check load-path
`C-h v` `load-path` RET

http://ergoemacs.org/emacs/elisp_library_system.html





`C-h p` find topic related packages, good entry to explore the built-in packages
e.g.
version control -> vc package



### built-ins

```bash
ls -1a *.elc
```

```
abbrev.elc
align.elc
allout.elc
allout-widgets.elc
ansi-color.elc
apropos.elc
arc-mode.elc
array.elc
auth-source.elc
auth-source-pass.elc
autoarg.elc
autoinsert.elc
autorevert.elc
avoid.elc
battery.elc
bindings.elc
bookmark.elc
bs.elc
buff-menu.elc
button.elc
calculator.elc
case-table.elc
cdl.elc
char-fold.elc
chistory.elc
cmuscheme.elc
color.elc
comint.elc
completion.elc
composite.elc
cus-dep.elc
cus-edit.elc
cus-face.elc
cus-start.elc
cus-theme.elc
custom.elc
dabbrev.elc
delim-col.elc
delsel.elc
descr-text.elc
desktop.elc
dframe.elc
dired-aux.elc
dired.elc
dired-x.elc
dirtrack.elc
display-line-numbers.elc
disp-table.elc
dnd.elc
doc-view.elc
dom.elc
dos-fns.elc
dos-vars.elc
dos-w32.elc
double.elc
dynamic-setting.elc
ebuff-menu.elc
echistory.elc
ecomplete.elc
edmacro.elc
ehelp.elc
elec-pair.elc
electric.elc
elide-head.elc
emacs-lock.elc
env.elc
epa-dired.elc
epa.elc
epa-file.elc
epa-hook.elc
epa-mail.elc
epg-config.elc
epg.elc
expand.elc
ezimage.elc
facemenu.elc
face-remap.elc
faces.elc
ffap.elc
filecache.elc
filenotify.elc
files.elc
filesets.elc
files-x.elc
find-cmd.elc
find-dired.elc
finder.elc
find-file.elc
find-lisp.elc
flow-ctrl.elc
foldout.elc
follow.elc
font-core.elc
font-lock.elc
format.elc
format-spec.elc
forms.elc
frame.elc
frameset.elc
fringe.elc
generic-x.elc
help-at-pt.elc
help.elc
help-fns.elc
help-macro.elc
help-mode.elc
hexl.elc
hex-util.elc
hfy-cmap.elc
hilit-chg.elc
hi-lock.elc
hippie-exp.elc
hl-line.elc
htmlfontify.elc
ibuf-ext.elc
ibuffer.elc
ibuf-macs.elc
icomplete.elc
ido.elc
ielm.elc
iimage.elc
image-dired.elc
image.elc
image-file.elc
image-mode.elc
imenu.elc
indent.elc
info.elc
info-look.elc
informat.elc
info-xref.elc
isearchb.elc
isearch.elc
jit-lock.elc
jka-cmpr-hook.elc
jka-compr.elc
json.elc
kermit.elc
kmacro.elc
linum.elc
loadhist.elc
locate.elc
lpr.elc
ls-lisp.elc
macros.elc
makesum.elc
man.elc
master.elc
mb-depth.elc
md4.elc
menu-bar.elc
midnight.elc
minibuf-eldef.elc
minibuffer.elc
misc.elc
misearch.elc
mouse-copy.elc
mouse-drag.elc
mouse.elc
mpc.elc
msb.elc
mwheel.elc
newcomment.elc
notifications.elc
novice.elc
obarray.elc
outline.elc
paren.elc
password-cache.elc
pcmpl-cvs.elc
pcmpl-gnu.elc
pcmpl-linux.elc
pcmpl-rpm.elc
pcmpl-unix.elc
pcmpl-x.elc
pcomplete.elc
pixel-scroll.elc
plstore.elc
printing.elc
proced.elc
profiler.elc
ps-bdf.elc
ps-def.elc
ps-mule.elc
ps-print.elc
ps-samp.elc
recentf.elc
rect.elc
register.elc
registry.elc
repeat.elc
replace.elc
reposition.elc
reveal.elc
rfn-eshadow.elc
rot13.elc
rtree.elc
ruler-mode.elc
savehist.elc
saveplace.elc
sb-image.elc
scroll-all.elc
scroll-bar.elc
scroll-lock.elc
select.elc
server.elc
ses.elc
shadowfile.elc
shell.elc
simple.elc
skeleton.elc
sort.elc
soundex.elc
speedbar.elc
startup.elc
strokes.elc
subr.elc
svg.elc
tabify.elc
talk.elc
tar-mode.elc
tempo.elc
term.elc
thingatpt.elc
thumbs.elc
time.elc
time-stamp.elc
timezone.elc
tmm.elc
t-mouse.elc
tool-bar.elc
tooltip.elc
tree-widget.elc
tutorial.elc
type-break.elc
uniquify.elc
userlock.elc
vcursor.elc
version.elc
view.elc
vt100-led.elc
vt-control.elc
w32-fns.elc
w32-vars.elc
wdired.elc
whitespace.elc
wid-browse.elc
wid-edit.elc
widget.elc
windmove.elc
window.elc
winner.elc
woman.elc
xdg.elc
x-dnd.elc
xml.elc
xt-mouse.elc
xwidget.elc
```


ido.el
https://www.emacswiki.org/emacs/InteractivelyDoThings




ede mode
https://www.gnu.org/software/emacs/manual/html_node/ede/index.html#Top




