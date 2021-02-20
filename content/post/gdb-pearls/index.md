---
title: gdb pearls
date: "2020-10-26T09:10:00Z"
categories:
- Gdb
tags:
- linux
- C
- debug
featured_image: images/gdb.gif
aliases:
- /2020/10/26/gdb-pearls.html
---

GDB is a life saver when you debug programs or assist to inspect
when reading source code.

Here is a little list about some useful things about gdb.

<!--more-->

# help

- `help CMD`, hit when curious
- you can find everything in [gdb manual][manual], `Ctrl-F` it

[manual]: https://sourceware.org/gdb/current/onlinedocs/gdb/


# gui

- using [cgdb][cgdb], a concise ncurses interface
- ddd is buggy, leave it
- typing `M-x gdb` in emacs

[cgdb]: https://cgdb.github.io/docs/cgdb.html


# print

- `set print pretty on`, pretty print
- `set print array on`, pretty print array
- `p *array@N`, print array of length N
- `p *pointer`, pretty print struct
- `display VAR`, display when stop
- `ptype EXP`, type of EXP

# breakpoint

- `inf b`, list all
- `d N`, del the N
- `d br`, del all
- `en/dis N`, enable/disable the N
- `tb`, temporary, del when hit
- `b WHERE if COND`, conditional break
- `commands N`, eval cmd when hit

```
(gdb) commands 1
>print argc
>del 1
>end
```

clear commands

```
(gdb) commands 1
>end
```


# jump

- `s`, step in
- `fin`, step out
- `record` first, then use `rn`, `rs`, `rc` to do [reverse debugging][rev]


[rev]: https://www.sourceware.org/gdb/wiki/ProcessRecord/Tutorial


# stack

- `bt`, show stack
- `up/down N`, change to up/down N-th level
- `n 0`, back to top level
- `inf locals`, view locals in current stack level
- `thread apply all bt full`, inspect all threads


# args

- `$ gdb a.out --args ...`, passing args
- `run ...`, start with args
- `inf args`, show args


# macro

- `CFLAGS = -ggdb3` with gcc, then you can debug macros (the `#define` things)
- `inf macros`
- `inf macro NAME`
- `macro expand NAME`


# remote

- install `gdbserver`, [debug remotely][server]
- `$ gdbserver ip:port prog`, start server
- `$ gdb prog`, start client
- `target remote ip:port`, connect server


[server]: https://www.thegeekstuff.com/2014/04/gdbserver-example/


# hackable

- custom `~/.gdbinit` file
- extending with [gdb sequence][script]
  - [stl][stl] is a good example
- extending with [python][py]

[script]: https://sourceware.org/gdb/current/onlinedocs/gdb/Sequences.html#Sequences
[stl]: https://sourceware.org/gdb/wiki/STLSupport?action=AttachFile&do=view&target=stl-views-1.0.3.gdb
[py]: https://sourceware.org/gdb/current/onlinedocs/gdb/Python.html#Python


# other resource

- [gdb cheat sheet][sheet]

[sheet]: http://www.yolinux.com/TUTORIALS/GDB-Commands.html#STLDEREF


