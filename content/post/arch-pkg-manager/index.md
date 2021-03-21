---
title: "了解 Arch Linux 的包管理系统"
author: ["DreamAndDead"]
date: 2021-03-19T17:26:00+08:00
lastmod: 2021-03-21T11:31:52+08:00
tags: ["arch", "manjaro", "linux", "package-manager"]
categories: ["Linux"]
draft: false
featured_image: "images/featured.jpg"
---

Linux 发行版相比 Windows 系统，富有特色的功能之一即是包管理系统。

不同 Linux 发行版的包管理系统有不同的标准，
本文关注如何在 Arch Linux 系统发行版进行管理软件包。


## 认识包管理系统 {#认识包管理系统}

包管理系统有如下几个特点，（[uva 506](https://onlinejudge.org/external/5/506.pdf) 是这些特点的简要说明）


### 依赖关系 {#依赖关系}

几乎所有软件开发的生态，都存在依赖关系。
如 node.js 中的 npm，java 中的 maven，python 中的 pip，
所解决的核心问题之一就是组件间的依赖关系。

从算法角度，依赖关系可以抽象为有向无环图(DAG)模型，

-   结点表示软件包
-   边表示依赖关系
-   依赖关系是单向的
-   没有循环依赖

依赖关系意味着，如果安装一个软件包，就必须同时安装所有其依赖的软件包。
下图是软件包 `core/pacman` 的依赖关系，意味着所有结点表示的软件包都必须安装。

{{< figure src="images/pacman-dep-tree.png" caption="Figure 1: core/pacman 软件包的依赖关系" >}}


### 远程/本地 {#远程-本地}

包管理系统通常采用 C/S 结构。
发行版维护者编译软件包，维护依赖关系，提供索引信息，在服务器端提供下载；
发行版使用者从服务器查询软件包信息，下载并安装软件到客户端(Arch 发行版)。

服务器和客户端的关系可以进一步从依赖角度来理解。
将服务器想象成普通的 Arch 系统，其中安装了所有的软件包，其中明确所有的依赖关系，构成一个宏大的图。
使用者安装特定的软件包 gcc，为了确保依赖关系，需要将所有软件包 gcc 依赖的软件包下载并安装，
相当于从服务器的依赖图中同步了部分子图到客户端，这也是安装操作命名为 `--sync` 的原因。

如下图所示，安装软件包 c 之后，等同于从服务器同步相应的子图到客户端。

{{< figure src="images/sync-sub.png" caption="Figure 2: 安装软件包 c ，即同步子图" >}}


### 显式/隐式 {#显式-隐式}

安装到本地的软件包，分为显式安装和隐式安装两种。
显式安装，指用户直接使用 `-S, --sync` 进行安装的，包含用户的主动意愿；
隐式安装，指在安装过程中，作为依赖“被迫”安装到本地的。

这个标识主要在卸载过程中发挥作用。
在卸载软件包时，如果相应的依赖不被其它包依赖，并且是隐式安装的，就可以一同被卸载。
如下图所示，当卸载软件包 a，所有相关依赖可以一同被卸载。

{{< figure src="images/exp-dep.png" caption="Figure 3: 卸载软件包 a 及其依赖，用蓝色标识" >}}


### 数据库 {#数据库}

软件包不外乎包含两类信息。
一类如名称，描述，作者，邮件等元数据信息；
另一类就是软件包中的文件，即数据信息。

所有信息都使用数据库文件来存储。
通过服务器提供的 `.db` 文件，可以使用 `-S` 查询元数据信息， `-F` 查询文件信息。
客户端另外维护了本地数据库文件，记录所有已安装软件包的元数据和文件信息，
以及显式/隐式安装标识。 `-Q` 查询的即是这部分信息。


## Pacman {#pacman}

每个发行版都提供官方工具进行软件包管理。
如 Debian 系的 apt，Gentoo 系的 emerge，RedHat 系的 yum。
相应的，Arch 系使用 pacman。

pacman 是 package manager 的缩写，各取前 3 个字母组成，
恰好和经典游戏吃豆人(pacman)同名，一语双关。

pacman 本身有两个含义。
一是软件包 `core/pacman` ，包含所有官方提供的包管理工具；
二是 `/usr/bin/pacman` ，是 `core/pacman` 的一部分。
文章之后出现的 `core/pacman` 表示第一种含义， `pacman` 表示第二种含义。

[pacman 的用法](https://man.archlinux.org/man/pacman.8)是非常清晰的

```text
$ pacman <operation> [options] [targets]
```


### operation {#operation}

不同参数(parameter)对应不同操作(operation)。

常用操作如下表如示，

| 操作  | 参数         |
|-----|------------|
| 同步/安装 | -S, --sync   |
| 文件数据库 | -F, --files  |
| 查询  | -Q, --query  |
| 删除/卸载 | -R, --remove |


### option {#option}

每个操作包含不同的选项(option)，用于精细控制行为。

少数选项是所有操作共用的，如 `--help` ；
大部分选项是各个操作独有的，如 `--changelog` 只用于 Query 操作。


### target {#target}

根据操作的不同，目标(target)可能是软件包的名称，也可能是用于查询的关键字。


## 常见任务 {#常见任务}

虽然操作和选项的组合有近百种可能，
根据 2/8 原则，下文主要关注如何使用 pacman 解决常见任务。

常见任务同管理数据库一样，无非是 CRUD。


### 查询 {#查询}

查询是最重要的一项。因为在任何操作开始之前，首先要获取足够的信息。


#### 列出所有软件包 {#列出所有软件包}

从服务器列出所有可安装包

```text
$ pacman -Sl
```

从本地列出所有已安装包

```text
$ pacman -Q
```


#### 根据名称/描述查找软件包 {#根据名称-描述查找软件包}

从服务器查找

```text
$ pacman -Ss
```

从本地查找

```text
$ pacman -Qs
```


#### 查询元信息 {#查询元信息}

从服务器查询元信息

```text
$ pacman -Si
```

从本地查询元信息

```text
$ pacman -Qi
```


#### 列出软件包中包含的文件 {#列出软件包中包含的文件}

从服务器列出软件包中包含的文件

```text
$ pacman -Fl
```

从本地列出软件包中包含的文件

```text
$ pacman -Ql
```


#### 根据文件反向查询 {#根据文件反向查询}

从服务器查询，哪个包包含相应文件名

```text
$ pacman -F
```

从本地查询，哪个包包含相应文件名

```text
$ pacman -Qo
```


### 安装 {#安装}

软件包的安装是简洁明了的，

```text
$ pacman -S
```


### 卸载 {#卸载}

`-s` 表示同时卸载无用依赖，

```text
$ pacman -Rs
```


### 更新 {#更新}

如果要更新，就整体全部更新。根据之前的图同步理论，[局部更新是非常危险的](https://wiki.archlinux.org/index.php/Pacman#Upgrading%5Fpackages)。

**Arch 发行版的软件包更新非常频繁，建议每次开机都进行更新** 。

```text
$ pacman -Syu
```


## Alias {#alias}

遇到相应任务再来文档查询非常消耗时间，可以直接将功能集成到 Shell 中。

先安装 [fuzzy finder](https://wiki.archlinux.org/index.php/Fzf#Pacman)，

```text
$ sudo pacman -S fzf
```

将以下脚本 append 到 `.bashrc` 中，

```bash
alias pkg_install="pacman -Slq | fzf --multi --reverse --preview 'cat <(pacman -Si {1}) <(pacman -Fl {1} | awk \"{print \$2}\")' | xargs -ro sudo pacman -S"
alias pkg_remove="pacman -Qq | fzf --multi --reverse --preview 'cat <(pacman -Qi {1}) <(pacman -Ql {1} | awk \"{print \$2}\")' | xargs -ro sudo pacman -Rs"
alias pkg_own="pacman -F"
alias pkg_upgrade="sudo pacman -Syu"
```

这样就可以方便的管理软件包了。

{{< figure src="images/int-shell.gif" caption="Figure 4: 方便管理软件包" >}}


## License {#license}

{{< license >}}
