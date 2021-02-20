---
date: "2019-08-12T00:00:00Z"
tags: linux Xorg xmodmap
title: How to Customize Keymap in Linux
---

最近刚开始使用 emacs ，太多 Ctrl Alt 相关的快捷键，边侧的手指不舒服，于是想法将部分键盘按键进行改键。

如果 Caps Lock 可以作为 BackSpace，删除字符的时候就不需要右侧的小指离的太远。
如果将 Menu 键改为 Ctrl，这样就可以用小指的指根来按压，方便进行快捷键操作。

针对这样的需求，开始在网上寻找相关改键的方案，搜索结果几乎一致统一的，在 Xorg 环境下，使用 xmodmap 来修改是最合适的。

<!--more-->

# key concept

在开始之前，我们先了解一下 Xorg 环境下，关于键盘的[一些概念][arch wiki]。

在 Xorg 中，有两种键盘值，分别是 keycode 和 keysym。

keycode 本质是一组数字表示，和键盘上的按键是一一对应的。
在按键被按下后，相关信号传递给内核，内核看到的就是这个 keycode 数字。

而 keysym 是和 keycode 相关联的值，可以理解为是键盘的功能，比如输入字符 a，删除字符等等。
它是内核对应相应按键所调用的处理方法。

它们两者的关系就是一个 map 结构，keycode 是 key，keysym 是value。
于是，按键就和按键的功能关联起来。

这种对应结构管理由 Xorg 来管理，被称为 keymap table，它可以用 xmodmap 来查看和修改。

所以说，修改了关联关系，就达到了改键的目的。

# browse keymap table

通过命令，我们可以查看当前的 keymap table。

	$ xmodmap -pke
	keycode   8 =
	keycode   9 = Escape NoSymbol Escape
	keycode  10 = 1 exclam 1 exclam
	keycode  11 = 2 at 2 at
	...............................................
	...............................................
	...............................................
	keycode  23 = Tab ISO_Left_Tab Tab ISO_Left_Tab
	keycode  24 = q Q q Q
	keycode  25 = w W w W
	...............................................
	...............................................
	...............................................
	keycode 254 = XF86WWAN NoSymbol XF86WWAN
	keycode 255 = XF86RFKill NoSymbol XF86RFKill

可以观察到，一个 keycode 对应了多个 keysym。

其实第一个是按键本身按下所对应的 keysym，后面的 keysym 对应于[当修饰键所按下时的情况][arch wiki cn]

1. Key
2. Shift+Key
3. Mode_switch+Key
4. Mode_switch+Shift+Key
5. etc

我们通常只需要了解前两个就足够了，即按键本身和 shift 加按键两种情况。

每个 keycode 用数字来标识，而 keysym 有相应的名称，比如 n N BackSpace，表达相应的功能含义。
如果想设置为空值，可以设置为 NoSymbol。

# check out specific key

通过 xev 工具，

	$ xev -event keyboard

可以监听到所有的键盘消息，并打印出 log。

通过这种方式，我们就可以检测出当前键盘的按键对应的 keycode 是什么，调用了什么 keysym。

比如在按下字符 d 之后，可以从 log 中看到 keycode 是 40 ，使用的 keysym 为 d，数字标识为 0x64

	KeyPress event, serial 28, synthetic NO, window 0x6e00001,
		root 0x1d5, subw 0x0, time 34680022, (634,241), root:(3198,270),
		state 0x0, keycode 40 (keysym 0x64, d), same_screen YES,
		XLookupString gives 1 bytes: (64) "d"
		XmbLookupString gives 1 bytes: (64) "d"
		XFilterEvent returns: False

	KeyRelease event, serial 28, synthetic NO, window 0x6e00001,
		root 0x1d5, subw 0x0, time 34680062, (634,241), root:(3198,270),
		state 0x0, keycode 40 (keysym 0x64, d), same_screen YES,
		XLookupString gives 1 bytes: (64) "d"
		XFilterEvent returns: False

# configure keymap table

修改按键就是使用 xmodmap 配置 keymap table 的过程。

第一种方法，可以通过命令，直接进行修改，使一行配置生效。

	$ xmodmap -e 'keycode 38 = b E'

另外一种方法，可以将配置写在文件中，载入文件进行批量修改。

	$ xmodmap ~/.Xmodmap

另外在配置的过程中，如果有修改不合适的地方，可以使用

	$ setxkbmap

来重置 keymap table 到默认状态。


## grammar

通过

	$ xmodmap -grammar

可以查看 xmodmap 配置所使用的语法规则，

```
xmodmap accepts the following input expressions:

    pointer = default              reset pointer buttons to default
    pointer = NUMBER ...           set pointer button codes
    keycode NUMBER = [KEYSYM ...]  map keycode to given keysyms
    keysym KEYSYM = [KEYSYM ...]   look up keysym and do a keycode operation
    clear MODIFIER                 remove all keys for this modifier
    add MODIFIER = KEYSYM ...      add the keysyms to the modifier
    remove MODIFIER = KEYSYM ...   remove the keysyms from the modifier

where NUMBER is a decimal, octal, or hex constant; KEYSYM is a valid
Key Symbol name; and MODIFIER is one of the eight modifier names:  Shift,
Lock, Control, Mod1, Mod2, Mod3, Mod4, or Mod5.  Lines beginning with
an exclamation mark (!) are taken as comments.  Case is significant except
for MODIFIER names.

Keysyms on the left hand side of the = sign are looked up before any changes
are made; keysyms on the right are looked up after all of those on the left
have been resolved.  This makes it possible to swap modifier keys.
```

pointer 是和鼠标事件相关的，这里先不讨论。
至于后面的 5 种规则，我们之后详细的从实践角度分析一下它们的作用。

## keycode =

首先我们来看，

    keycode NUMBER = [KEYSYM ...]  map keycode to given keysyms

这个配置是万能配置，可以将任何键盘按键映射到任何按键处理方法上。

我们在 xev 中看到键盘 a 的 keycode 是 38，我们现在将它映射到 shift 方法上。

	$ xmodmap -e 'keycode 38 = Shift_L A'

如同去前面说的，第一个是单独按键的 keysym，第二个是有 shift 修饰的时候的 keysym。

（大家可以体会一下这个示例，观察一下 a 按键的行为，修改之后变得非常微妙。记得使用 `setxkbmap` 重置成正常的布局~）

## keysym =

另外一种配置方法是

    keysym KEYSYM = [KEYSYM ...]   look up keysym and do a keycode operation

这个配置就有些微妙了。
它可以将相应 keysym 代表的处理方法，赋值给另一个　keysym。

比如

	$ xmodmap -e 'keysym a = b'
	$ xmodmap -pke | grep 38
	keycode  38 = b B b B

可以看到原来绑定的 a 方法都绑定成为了 b 方法，而且附带修饰键的 keysym 也一并修改了。
也就是我们按 a 键的时候，其实输入的是 b。

但如果

	$ xmodmap -e 'keysym a = b c'
    $ xmodmap -pke | grep 38
    keycode  38 = b c b c

它则会这样的绑定结果。
因为没有具体的文档告诉我们这样配置后的规则到底是什么，所以不推荐用这种方法来配置。


有意思的是，文档中提到，这种方法可以用来交换两个按键。

	Keysyms on the left hand side of the = sign are looked up before any changes
	are made; keysyms on the right are looked up after all of those on the left
	have been resolved.  This makes it possible to swap modifier keys.

keysym = keysym，左侧解析在前，右侧在左侧解析后再解析。

所以如果我们载入这样的配置

``` text
keysym a = b
keysym b = a
```

发现 a b 两个按键互换了。

从某种意义上，这种交换很像 python 中变量的交换。

```python
a, b = b, a
```

左侧的 a b 先解析成对象的地址，右侧的 a b 解析为对象的值，然后统一赋值。

这样来看的话，keysym 的符号表示更像是一个变量指针。

## modifier

下面来看 modifier 的部分。

一共有 8 个修饰键，通过

	$ xmodmap -pm

可以查看当前状态。

	xmodmap:  up to 4 keys per modifier, (keycodes in parentheses):

	shift       Shift_L (0x32),  Shift_R (0x3e)
	lock        Caps_Lock (0x42)
	control     Control_L (0x25),  Control_R (0x69)
	mod1        Alt_L (0x40),  Alt_R (0x6c),  Meta_L (0xcd)
	mod2        Num_Lock (0x4d)
	mod3
	mod4        Super_L (0x85),  Super_R (0x86),  Super_L (0xce),  Hyper_L (0xcf)
	mod5        ISO_Level3_Shift (0x5c),  Mode_switch (0xcb)

我们可以发现，不同于之前 keycode 和 keysym 的对应关系，修饰键是一个分类，其中包括了一些 keysym。

前 4 个我们可以轻易的看出是 shift capslock control alt 分类。

每个 keysym 有自己的含义，比如 a，当使用这个 keysym 的时候，系统会输入 a 字符。
modifier 是一个分类，当某个 keysym 归于这个分类的时候，它就同时附加了相应 modifier 的功能。

关于 modifier，语法规定可以这样修改

    clear MODIFIER                 remove all keys for this modifier
    add MODIFIER = KEYSYM ...      add the keysyms to the modifier
    remove MODIFIER = KEYSYM ...   remove the keysyms from the modifier

clear 可以清空某个 modifier 包含的全部 keysym；
add 可以添加对应的 keysym 到 modifier；
remove 可以删除相应 modifier 下的 keysym。

remove 不如 clear 常用，因为一般的修改都直接 clear 相关的 modifier，再添加相应的 keysym，这样逻辑清晰，不容易出错。

在改动 modifier 按键的时候要考虑两点：

一是，尽量不要将有一定功能含义的 keysym 加入到 modifier 中。

假如我们将 a 加入到 shift 组中，

	xmodmap -e 'add shift = a'

会发生非常不舒服的情况，单独按 a 还是会输入 a，当 a 按下，再按别的键，它又成了 shift （可以体会一下）。

所以，将像 a 这样的 keysym 加入 modifier，并不会消除它本身的含义，导致它本身的含义和 modifier 的含义发生混乱。
但是像 Shift_L 这样的 keysym，如果它不在 modifier 组中，它什么功能都没有，天生就适合作为 modifier。

二是，两种修改方法的结果有一些差异。

    keycode NUMBER = [KEYSYM ...]  map keycode to given keysyms
    keysym KEYSYM = [KEYSYM ...]   look up keysym and do a keycode operation

这两种方法都可以进行改键。
假如我们想将键盘上的 caps lock 改成 control 按键，
用第一种方法，我们先找到 caps lock 的 keycode 是 66，然后载入配置

	clear shift
	clear lock
	keycode 66 = Shift_L
	add shift = Shift_L Shift_R

打印目前的 modifier 结果，

	$ xmodmap -pm
	xmodmap:  up to 4 keys per modifier, (keycodes in parentheses):

	shift       Shift_L (0x32),  Shift_R (0x3e),  Shift_L (0x42)
	lock
	control     Control_L (0x25),  Control_R (0x69)
	mod1        Alt_L (0x40),  Alt_R (0x6c),  Meta_L (0xcd)
	mod2        Num_Lock (0x4d)
	mod3
	mod4        Super_L (0x85),  Super_R (0x86),  Super_L (0xce),  Hyper_L (0xcf)
	mod5        ISO_Level3_Shift (0x5c),  Mode_switch (0xcb)

发现 shift 中多了一个 Shift_L 键，那是新加的 caps lock 键。

假如我们用第二种方式，改变 keysym Caps_Lock 的含义。

	clear lock
	keysym Caps_Lock = Shift_L

然后查看当前 modifier 的状态，

	$ xmodmap -pm
	xmodmap:  up to 4 keys per modifier, (keycodes in parentheses):

	shift       Shift_L (0x32),  Shift_R (0x3e)
	lock
	control     Control_L (0x25),  Control_R (0x69)
	mod1        Alt_L (0x40),  Alt_R (0x6c),  Meta_L (0xcd)
	mod2        Num_Lock (0x4d)
	mod3
	mod4        Super_L (0x85),  Super_R (0x86),  Super_L (0xce),  Hyper_L (0xcf)
	mod5        ISO_Level3_Shift (0x5c),  Mode_switch (0xcb)

我们发现，shift 中只有两个按键，相当于我们将 caps lock 修改成了 shift，利用这一点，可以突破最多 4 个按键绑定的限制。

但是综合来看，我还是**建议使用 keycode 的方法**来修改，这样相对清晰，稳妥。

# modification

在具体了解 xmodmap 之后，再按照我们的想法来修改按键就很简单了。

比如我目前用的键盘，配合 emacs，很适合将 caps lock 换成 backSpace 键，右边的 menu 换成 ctrl 键。

{% include image.html url="customize-keymap/penixx-keyboard.jpg" desc="" %}

	clear lock
	clear control
	keycode 66 = BackSpace BackSpace
	keycode 135 = Control_R
	add control = Control_L Control_R

# load at boot

在修改之后，我们想在启动的时候，自动载入改键的配置。

可以在 `~/.xinitrc` 文件中，加入

	[[ -f ~/.Xmodmap ]] && xmodmap ~/.Xmodmap

而一般情况下，`.xinitrc` 中已经有了相应的配置，不需要另外再添加。

# refs

- [arch wiki][]
- [xmodmap tutorial][]
- [arch wiki cn][]
- [reset xmodmap][]

[arch wiki]: https://wiki.archlinux.org/index.php/Xmodmap
[xmodmap tutorial]: https://www.zouyesheng.com/xmodmap-usage.html
[arch wiki cn]: https://wiki.archlinux.org/index.php/Xmodmap_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)
[reset xmodmap]: https://askubuntu.com/questions/29603/how-do-i-clear-xmodmap-settings
