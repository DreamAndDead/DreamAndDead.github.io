---
type: card
created: 2024-03-27T20:04
tags:
- ue
- animation
---

两种坐标空间在 ue 中到处可见，不过在不同的地方有不同的名字

在 skeleton 界面调整骨骼的 transform 时，切换坐标空间
此时名叫 object space 和 world space

![[UE4Editor_tYjpNK4xT1.gif]]

![[UE4Editor_5DU7nIo1bz.gif]]

world space 是相对于 root 而言的，坐标系和 root 相同
object space 是相对于 parent bone 坐标系而言的

world space 就相当于 component space
object space 就相当于 local space

动画的本质在于，在每一帧计算一个pose，一个pose就是一个骨骼矩阵数组

在 anim graph 中，pose数组数据默认是以 local space 的方式传输的（白色线条）
在有些 node 需要 component space 的pose数据格式时，再转换成相应格式（蓝色线条）

在动画蓝图的 anim graph 中提供了两个节点 local to component 和 component to local，执行转换工作

![[Pasted image 20240327202754.png]]

![[Pasted image 20240327202803.png]]

# 为什么需要 component space

local space 只能计算 self 和 parent 的关系，在涉及多个 bone 比如 ik 的计算时，需要多个 bone 在一个空间内进行解算，此时 component space 就比较方便

# 不同空间对 blend 的影响

有 5 个 bone，从下到上为 1 2 3 4 5
![[image-20210812211328059.png]]
pose A

![[image-20210812211347973.png]]
pose B

blend pose A 和 B，在 local space 下
- bone 1 rotate 90 度
- bone 2 无变化
- bone 3 rotate 180 度
- bone 4 无变化
- bone 5 无变化

得到如下混合结果

![[pose_blending_local-1.gif]]

在 component space 下混合
- bone 1 rotate 90
- bone 2 rotate 90 并移动
- bone 3 rotate 180 并移动
- bone 4 rotate 90 并移动
- bone 5 rotate 90

得到如下结果

![[pose_blending_component.gif]]

[参考链接 deeper dive into anim space](https://arrowinmyknee.com/2021/08/11/deep-dive-into-anim-pose-space-in-ue4/)

来自 games104 的动画课程图

![[Pasted image 20240331124517.png]]