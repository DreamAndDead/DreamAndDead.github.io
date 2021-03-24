---
title: "浅谈复式记账与 Beancount"
author: ["DreamAndDead"]
date: 2021-02-28T15:59:00+08:00
lastmod: 2021-03-24T22:09:02+08:00
tags: ["accounting", "beancount", "python"]
categories: ["Accounting"]
draft: true
comment: false
featured_image: "images/featured.jpg"
---

复式记账法是世界通行的会计方式。
beancount 是采用复式记账法的工具，python 编写，定位为个人记账。

本文的目的

记账清晰，了解复式记账法，与 beancount 中的小小差异。
对记账有帮助。


## 复式记账 {#复式记账}


### 交易 {#交易}

交易，是商业的本质。
无论以物易物，还是使用货币，这一点从没有发生变化。

而记账，就是记录交易。
交易必定涉及两/多方，每个主体都要准确记录交易标的，明确自身的财务情况。

主流记账方式有两种，单式记账和复式记账。
TODO 区别
由历史演变而来

复式记账是一种方法，与交易主体无关。
无论是个人还是公司，都可以采用复式记账法。
而这两种主体的交易项目不同，金额数目不同，本质没有变化。


### 账户 {#账户}

交易的记录方式，就是记录价值在不同账户间的流转过程。

```text
资产 = 负债 + 所有者权益
```

会计恒等式人尽皆知，复式记账就是在这上面做文章。
交易，左右必定相同。

恒等式的三项，理解为三类账户，记录账务的不同方面。

资产，明面上拥有的

负债，不属于你的，迟早要归还的

所有者权益，真正属于个人的。

三类账户，细分设立更多的子账户。
精细记录交易。


### 交易示例 {#交易示例}

**公司成立，创始人注入资本**

{{< figure src="images/e.g.1.png" >}}

**向银行借款**

{{< figure src="images/e.g.2.png" >}}

**购买设备，准备生产**

{{< figure src="images/e.g.3.png" >}}


### 借 vs 贷 {#借-vs-贷}

借贷，向来不清楚相应的关系

会计部分是庞大的，复杂的。 尤其在大型公司，庞大的财务部门。

会计的工作，将所有单项交易，最终整合为报表，呈现公司的财务整体面貌。

最基础的记录，分类账

T 形账户

{{< figure src="images/T.1.png" >}}

每个账户的左右均记分录

借 debit 表示左边
贷 credit 表示右边

单纯的左右关系，借 贷仅表示左右。

至于是增加/减少，是由账户的特性决定的

debit card，credit card 的由来

你的存款，进入银行的负债账户
提取存款，相当于银行
借 负债，贷 现金

对于信用卡
直接消费，相当于银行的资产，应收账款
收回时
借 现金，贷 应收账款

{{< figure src="images/T.e.g.1.png" >}}

{{< figure src="images/T.e.g.2.png" >}}

{{< figure src="images/T.e.g.3.png" >}}


### 收入 vs 费用 {#收入-vs-费用}

{{< figure src="images/T.all.png" >}}

{{< figure src="images/T.sub.png" >}}

收入 和 费用是所有者权益的子账户

收入不会为负，由语言特性决定

费用不用为正，一体两面

这两个账户存在，用来计算利润


## Beancount {#beancount}

使用复式记账法，针对个人记账。

特点，使用文本存储。

教程很多，参考 [byvoid](https://byvoid.com/zhs/series/beancount%E5%A4%8D%E5%BC%8F%E8%AE%B0%E8%B4%A6/) 和 [wzyboy](https://wzyboy.im/post/1063.html) 的 blog 文章，非常清晰。


### 账户 {#账户}

预置的账户

默认 5 个账户的安排。

向上对应。

公式区别

恒等式的变换

```text
资产 + 负债 + 所有者权益 = 0
```

正值 变 负值


### 借 vs 贷 {#借-vs-贷}

`+ -` 表示 借 贷 关系

左 右

示例


## 结语 {#结语}

```text
$ pip install beancount fava
```

《财务会计教程》

<https://book.douban.com/subject/11636434/>


## License {#license}

{{< license >}}
