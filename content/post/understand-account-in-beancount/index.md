---
title: "理解 beancount 中的账户"
author: ["DreamAndDead"]
date: 2021-02-28T15:59:00+08:00
lastmod: 2021-02-28T16:53:26+08:00
tags: ["beancount", "account"]
categories: ["Accounting"]
draft: true
comment: false
---

为什么使用复式记账
如何使用 beancount

已经有不少珠玉在前


## 会计恒等式 {#会计恒等式}

会计主体

记录交易

资产 = 负债 + 所有者权益

公司记账


## T 形记录 日记账 {#t-形记录-日记账}


### 借 贷 {#借-贷}

单纯的左右关系，至于是增加/减少，是由账户的特性决定的


### 收入 费用 账户 {#收入-费用-账户}

权益的一部分

收入不会为负，由语言特性决定

费用不用为正，一体两面

用来计算利润


## beancount 的不同 {#beancount-的不同}

个人记账

交易的条目发生变化
账户名称发生变化

恒等式的变换

-   - 表示 借 贷 关系

预置的账户
