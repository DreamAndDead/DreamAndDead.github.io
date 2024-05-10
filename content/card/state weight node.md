---
type: card
created: 2024-04-06T20:47
tags:
- ue
- animation
- bp
---

![[customblend2.png]]
# 状态权重

一个状态机总体的对外输出是一个pose
状态机内部的每个状态也输出一个pose
状态机的pose是由内部状态的pose加权决定的

任何时刻，状态机内所有状态的权重和为 1

state weight 节点可以得到当前时刻相应状态的权重

# 状态变化引起的权重变化

状态机内部的状态会根据过渡条件，进行转移

任何时刻下，状态机内只存在一个 active 状态
所有过渡都相对于active状态而言

当过渡条件满足，active 状态立即切换到新状态

默认状态下，active的状态权重为 1
当状态发生过渡，权重从旧active状态向新active状态转移

如果过渡时间为0，立即进行权重的切换
如果过渡时间不为0，则权重进行曲线切换，引发pose的混合，使过渡更为平和

## 多于 2 个状态的过渡

假如状态1切换到2，过渡还没有结束，此时触发2到3的过渡，如何计算权重？

根据一些观察，可能是这样的

以 2 到 3 的过渡为准

假如 2 到 3 是时长 1s 的线性过渡，则 3 的权重在 1s 的变化是 0 0.5 1 线性变化，不受到 1 的影响

任意时刻剩余的权重，在 1 和 2 之间分配

# 使用

transition 连接 from 和 to 两个状态，当在 transition 中使用 state weight，只可以得到from状态的权重

state weight != 1 表示状态还没有完全混入

在 state 中使用，可以搜索到当前 abp 所有状态的权重
一般不推荐这么做，状态机也是有层次结构的，状态之间最好只关注同层次，不要越界，破坏层次性

## 在 conduit 中

conduit内部,无法使用 state weight

指向 conduit 的 transition, 同正常 transition，可以得到 from state 的 weight

从conduit中指出的 transition, 无法使用 state weight，因为出发的源不是一个状态，是一个 conduit


