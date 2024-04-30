---
type: card
created: 2024-03-28T16:58
tags:
- ue
- animation
---

![[Pasted image 20240328165901.png]]

two bone ik 节点在两根骨骼之间实现 ik 解算，常用在腿脚

原理，将 ik bone 尽力到达 effector 的位置（可选 旋转），反向计算 ik bone 向上两根骨骼的 transform

对于腿部来说，ik bone 通常是 foot，向上的 calf thigh 参与了计算并被修改
thigh 称为 root，ik bone 称为 end

由于计算的结果有无限种可能，引入限制变量 joint target
root - joint - end 组成一个平面，最终计算 calf的位置必须在这个平面上（会有两个结果，选择离 joint target 最近的结果）

运算的核心是余弦定理

已知 root calf end 三角形 3 边的长度，就可以确定角度，继而在 root joint end 平面上确定calf 的位置

![[two bone ik]]

![[Pasted image 20240331180747.png]]

![[Pasted image 20240331180927.png]]

![[Pasted image 20240331181058.png]]
- enable debug draw
	- 在 preview 中画出调试辅助线
- ik bone
- allow stretching
	- 当 effector 到 root 的距离，超过骨骼总长度（whole length of the limb）时，是否允许拉伸骨骼
- start stretch ratio
	- 当距离到达总长度的这个 ratio 时，就可以开始拉伸
	- 一般为 1，表示腿伸展到直线的极限时，才开始拉伸
	- 如果设置为 0.5 在一半距离时就可以开始拉伸，此时 joint 的位置影响很大
	- ![[UE4Editor_wm9IUBR9vd.gif]]
- max stretch scale
	- 最大伸展比例
	- 在 root 到 effector 的距离超过骨骼长度的倍数时，不再继续伸展
	- ![[UE4Editor_bt0oIcjWMm.gif]]
	- 此时所有bone都在 root - effector 的直线上
- allow twist
	- 默认启用，由 ik 解算器来计算 bone chain 的旋转
	- 如果关闭，需要在 twist axis 中手动设置
- [ ] twist axis 如何理解
- [ ] maintain effector rel rot 意义何在
- effector location space
	- world space
		- 只能从pin接收位置
	- component space
		- 只能从pin接收位置
	- parent bone space
		- 选择一个 effector target 作为 parent bone，loc在这个空间进行计算
	- bone space
		- 选择一个 effector target 作为 bone，loc在这个空间进行计算
		- 通常为 0 0 0 和vb 一起使用
- effctor target
	- 选择一个bone
- effector location
	- effector的位置，以 space 来计算
- take rotation from effector space ^2b59fe
	- 只有 space 为 parent bone and bone 时才有
	- 将 target bone 的 rotation 传递给 ik bone?
	- 这样 ik bone 就和目标在 loc rot 完全一致
- joint target 设置，同 effector，不过没有 [[#^2b59fe]]，joint 只需要一个位置即可参与运算


- [ ] 在实践中应如何选择 joint 参数？
	- https://zhuanlan.zhihu.com/p/457339033
- [ ] 更新对骨骼和joint的理解，再来更新本篇