---
created: 2024-03-28T16:58
draft: true
tags:
- card
- ue
- animation
---

![[Pasted image 20240601145848.png]]

![[Pasted image 20240531130503.png]]

two bone ik 是一种 ik 解算器，对 3 joint chain （中间有 2 个 bone）进行 ik 解算，常用于腿部

# 参数

以下举例以腿部 ik 为示例

![[two bone ik]]

- enable debug draw
	- ![[Pasted image 20240601133711.png]]
	- 在 preview 窗口，绘制关键点和连线
		- 上图隐藏了 mesh
- ik bone
	- 选择 end bone
		- 对于腿部为 foot bone
	- 自动寻找 parent bone 和 parent parent bone，加入运算
		- 即 thigh - calf - foot
- allow stretching ^85f568
	- 是否允许拉伸 bone
	- 默认关闭
		- 默认 bone 的长度是不变的，和人体保持一致
	- 不拉伸的 ratio 为 1
	- 如果拉伸，则同比对 two bone 进行拉伸
- start stretch ratio
	- 开启 [[#^85f568]] 后可用
	- 开始拉伸的 ratio
	- 建议 >= 1
- max stretch scale
	- 开启 [[#^85f568]] 后可用
	- 最大可拉伸的 ratio
	- 大于 1 才有效果
- maintain effector rel rot
	- 比如 end 是 foot bone
	- 如果是 false，在变动 foot bone 的 transform 时，保持脚在 mesh space 下不变
		- ![[UnrealEditor_ylq3tRnclk.gif]]
	- 如果是 true，在变动 foot bone 的 transform 时，脚也受到影响
		- ![[UnrealEditor_y0GTfzlhwE.gif]]
- allow twist
	- 默认启用
	- 自动计算 bone chain 的旋转
- [ ] twist axis
	- 关闭 allow twist 可设置
- effector
	- ik bone 要移动到的目标位置
	- 如果 ik bone 可以移动到 effector 位置，则两者位置重合
	- 有可能有情况，effector 与 thigh 过近 or 过远，导致 ik bone 无法移动到 effector 位置
- effector location space
	- world space
		- 只能从pin接收位置
	- component space
		- 只能从pin接收位置
	- parent bone space
		- 选择一个 effector target 作为 parent bone，loc在这个空间进行计算
	- bone space
		- 选择一个 effector target 作为 bone，loc 在这个空间进行计算
		- 通常为 0 0 0 和 vb 一起使用
- take rotation from effector space
	- 只有 space 为 parent bone，bone 时才有
	- end bone use effector's rotation
- joint target 
	- 在 foot 位置确定的情况下，thigh 保持不动，calf 有无限个可能的位置
		- 呈现一个圆形
	- joint target 是一个位置，和 thigh, effector 一起，三点构成一个平面
	- calf 就落在这个平面上
		- 在平面上其实有两个位置
		- 选择离 joint target 最近的一个
- joint target location space
	- joint target loc 所在的空间

# 拉伸算法

```cpp
const double ScaleRange = MaxStretchScale - StartStretchRatio;
if (ScaleRange > DOUBLE_KINDA_SMALL_NUMBER && MaxLimbLength > DOUBLE_KINDA_SMALL_NUMBER)
{
	const double ReachRatio = DesiredLength / MaxLimbLength;
	// start stretch ratio 定义了 scale range 的起点
	// 如果 < 1，即使还在骨骼可到达的范围内，也进行拉伸，效果非常奇怪
	const double ScalingFactor = (MaxStretchScale - 1.0) * FMath::Clamp((ReachRatio - StartStretchRatio) / ScaleRange, 0.0, 1.0);
	// 只有 max stretch scale > 1 才能进行拉伸
	if (ScalingFactor > DOUBLE_KINDA_SMALL_NUMBER)
	{
		LowerLimbLength *= (1.0 + ScalingFactor);
		UpperLimbLength *= (1.0 + ScalingFactor);
		MaxLimbLength *= (1.0 + ScalingFactor);
	}
}
```

