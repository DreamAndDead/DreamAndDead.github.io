---
title: "A little memo about pacman"
author: ["DreamAndDead"]
date: 2021-03-19T17:26:00+08:00
lastmod: 2021-03-19T17:58:48+08:00
tags: ["arch", "manjaro", "linux", "package-manager"]
categories: ["Linux"]
draft: true
comment: false
featured_image: "images/featured.jpg"
series: ["manjaro的使用"]
---

备忘的目的

不时翻阅文档

作总结之用


## name origin {#name-origin}

package manager

与游戏同名

谐音同名？多个软件如此


## 使用 {#使用}

包管理器

`pacman <operation> [options] [targets]`


### operation {#operation}


### options {#options}


### targets {#targets}


## 需求 {#需求}


### 安装软件 {#安装软件}


### 更新 {#更新}

Warning: When installing packages in Arch, avoid refreshing the
package list without upgrading the system (for example, when a package
is no longer found in the official repositories). In practice, do not
run pacman -Sy package\_name instead of pacman -Syu package\_name, as
this could lead to dependency issues.


### 卸载软件 {#卸载软件}

bin 来自哪个软件


### 查询 {#查询}

sync

local

find remote


## graph {#graph}

explict

deps

uva506

依赖的图关系


## alias {#alias}


## <span class="org-todo todo TODO">TODO</span> AUR {#aur}


## 需要安装的包 {#需要安装的包}

pacman
pacman-contrib
expac
pacutils

<https://wiki.archlinux.org/index.php/Pacman>

<https://wiki.archlinux.org/index.php/Pacman/Tips%5Fand%5Ftricks>

<https://wiki.archlinux.org/index.php/Pacman/Rosetta>

{{< license >}}
