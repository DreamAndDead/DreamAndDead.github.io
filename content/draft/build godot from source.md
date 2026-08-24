---
title: godot开源引擎就应该自构建使用
tags:
  - godot
  - game-engine
---

# why需要自己构建

使用这个引擎，不少人以为只要在 Editor 中点点点，然后写入自己的 GDScript 代码，就可以做成一个完整的游戏。这样是非常错误的。

引擎提供的功能永远是有限的，它具有通用性，但是每一个游戏都有自己的特殊性。所以在大部分情况下，接触底层是必不可少的。这意味着你必须使用官方提供的 C++ 功能，而使用 C++ 功能，就必须使用其配套的编译工具链和编译器。

一旦进入 C++ 层，进行联动调试时就必须要打断点，这样就必须有一份构建版的引擎。



这是一个学习过程，用于了解引擎底层的基础运行具体是如何构建的。如果自己想构建引擎，或者直接使用库来开发游戏，就可以去除引擎的其他冗余功能，只选取自己必要的部分。


这就是开源的意义 普通使用者可以不在意，但是作为软件开发者、行业内的从业者，这一点是必要的。只看魔术而不看内部的原理。对于内部原理的深究，这正是职业人员和业余人员的区别。






# 构建过程


```sh
choose compiler
install scons

git clone https://github.com/godotengine/godot.git
cd godot
git branch -a

git worktree add ../godot-4.7-dev 4.7
cd ../godot-4.7-dev

# editor
scons platform=windows dev_mode=yes compiledb=yes accesskit=no d3d12=no winrt=no angle=no

# tempalte
scons platform=windows target=template_debug arch=x86_64 dev_mode=yes compiledb=yes accesskit=no d3d12=no winrt=no angle=no
```

去除相关冗余功能

- [ ] 官方文档链接


分为调试和发行：

对于调试，重要的目的不是效率，而是为了方便调试程序能否正确运行。它去除了不必要的功能，以便提供更多的调试信息。



Release版如果在意的话，可以使用官方发行的版本。如果要适配其他平台，可能要多多研究源码如何在其他平台上通过编译。



