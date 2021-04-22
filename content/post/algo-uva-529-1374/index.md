---
title: "基础算法之 UVA 529 1374 题解"
author: ["DreamAndDead"]
date: 2021-04-22T13:27:00+08:00
lastmod: 2021-04-22T15:56:13+08:00
tags: ["algorithm", "oj", "programing"]
categories: ["Algorithm"]
draft: true
featured_image: "images/featured.png"
series: ["基础算法"]
---

uva 529 和 1374 两道题目比较相似，都是考察 迭代加深搜索 的题目。

但是网上诸多题解给出了解答方式，却没有回答为什么可以这样搜索，
本文旨在给出一种证明，回答这个问题。


## UVA 1374 {#uva-1374}

{{< figure src="images/uva1374.png" caption="Figure 1: uva 1374 题目描述" >}}

题意很简单，从 `x^1` 开始，通过 `* /` 运算，最快到达 `x^n` 的步数。

幂的乘除就是指数的加减。

将可达到的幂看作一个集合，

{{< figure src="images/1374-bfs.png" >}}

BFS 显然可以解决问题，但是状态太多，并且状态也不易存储，
这种情况下，迭代加深搜索是一个不错的选择。

<https://www.luogu.com.cn/blog/Doveqise/uva1374-kuai-su-mi-ji-suan-power-calculus-ti-xie>

-   选择最近生成的数？
    -   原因


## UVA 529 {#uva-529}

{{< figure src="images/uva529.png" caption="Figure 2: uva 529 题目描述" >}}

题意很简单，从 1 开始，递增的序列，如何最短的增长到 n 。
