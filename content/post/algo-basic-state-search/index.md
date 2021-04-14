---
title: "基础算法之状态空间搜索"
author: ["DreamAndDead"]
date: 2021-04-14T11:08:00+08:00
lastmod: 2021-04-14T11:15:48+08:00
tags: ["algorithm", "oj", "programing"]
categories: ["Algorithm"]
draft: true
featured_image: "images/featured.jpg"
series: ["基础算法"]
---

## 状态空间搜索 {#状态空间搜索}

路径查找

隐式图的遍历

状态空间搜索，是寻找一条路径；
回溯是逐渐构建一个最优解。

状态空间，是在所有解中间穿梭。

| 题目        | 标题  | 难度 | 启发 |
|-----------|-----|----|----|
| luogu P1379 | 八数码问题 | 1  |    |
| uva10603    | 倒水问题 | 1  |    |

BFS 是入队列，然后从队列初开始取元素

DFS 是入栈，然后从栈末尾开始取元素

DFS 也可以用实际的栈结构来实现，
不过一般在程序中，隐式使用递归的函数调用栈来实现
