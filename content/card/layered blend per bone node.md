---
type: card
created: 2024-04-02T16:38
tags:
- ue
- animation
---

blend multi poses base on set of bones

![[Pasted image 20240402172700.png]]

- [ ] blend root motion based on root bone 🆔 ztaxne

# branch filter

在 base pose 的基础上混合其它pose，每个混入的pose都有一个filter参数

参数是一个数组，每个元素包含 bone name  和 blend depth，指定要混合的骨骼链条与权重

bone name 指要开始作用的骨骼   

blend depth是整数，[底层计算原理](https://zhuanlan.zhihu.com/p/428242048)是以 1/depth 为权重，混合权重逐渐从 bone name 向子骨骼叠加，并对权重进行 clamp(0, 1)

分三类情况讨论

0， 1
混合权重为 1，即混合从 bone 开始的整条子链

n >= 2
混合权重为 1/n，即混合权重从 bone 开始是 1/n, 2/n, 3/n ...
比如 n=3，权重为 0.33 0.66 0.99 1 1 1 1 ...

n < 0
混合权重为负数，全部被 clamp为0，即整条子子链没有混合权重，不进行混合，完全使用 base pose


正当于正向选择和反向选择，挑选出自己想混合的骨骼链条


# mesh or local space of rotation and scale

在哪个空间进行旋转和缩放的混合

![[UE4Editor_MyK7JMiO9R.gif]]![[UE4Editor_1un0Px1PSo.gif]]

左边是local space混入腿部奔跑，右边是mesh space混入奔跑

使用哪个选项，取决于对混合的要求

# curve blend option

在理解混合之前，先明确曲线的存在

虽然定义了很多曲线名，但不是每个anim seq都会定义所有的曲线，只定义一部分，未定义的部分虽然默认值为 0（当被迫参与混合的时候） 但是并不存在

这对于理解 override 很重要，没有定义的曲线是无法参与覆盖的，相当于不存在

| option              | 作用公式 curve =                                    |
| ------------------- | ----------------------------------------------- |
| override            | 最后出现的 curve 覆盖之间的 curve, 和 blend weight 无关      |
| do not override     | 使用最前出现的 curve，和 blend weight 无关                 |
| normalize by weight | 对权重进行sum归一化再加权平均，base权重为1                       |
| blend by weight     | $1*curve + weight0 * curve0 + weight1 * curve1$ |
| use base pose       | use base，不混合                                    |
| use max value       | 用最大值，不混合，不考虑不存在                                 |
| use min value       | 用最小值，不混合，不考虑不存在                                 |

# blend mask mode in ue5

ue5引入了blend mask和 blend profile，可以更具体的分别指定不同骨骼混入的权重