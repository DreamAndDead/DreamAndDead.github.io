---
created: 2024-05-21T17:19
draft: true
tags: 
- card
- ue
- input
---

modifier 本质是一个 InputActionValue 的处理函数，多个 modifier 进行链式处理，前者的输出是后者的输入


```cpp
class ENHANCEDINPUT_API UInputModifier : public UObject
{
	FInputActionValue ModifyRaw(const UEnhancedPlayerInput* PlayerInput, FInputActionValue CurrentValue, float DeltaTime);
}
```

硬件的输入值，经过 modifier 处理，得到最终的 input action value，再交给 trigger 处理

ue 本身提供了部分 modifier 

# DeadZone

![[deadzone]]

手柄摇杆默认可以在一个圆形范围内移动，输入一个 2d 向量，范围为 0-1

使用时间过长，手柄出现漂移，在静止状态，无法固定在 0 的位置，依旧进入输入，比如 0.1 这样微小的量

deadzone 就是定义一个阈值，在这个范围内的输入当作 0 0 处理，解决漂移的问题

在 deadzone 之外的区间，重新映射到 0-1
比如定义阈值为 0.2，将 (0.2, 1) 的输入映射到 (0, 1)
如果当前输入 0.4，映射后输出 0.25

将 (lower, upper) 映射到 (0, 1)，范围外的值进行 clamp 到 0 / 1 来处理
不处理 bool 类型

- lower threshold
- upper threshold
- type
	- 两种映射算法
	- axial
		- x y z 轴，每个轴的值单独进行映射处理
	- radial
		- 保持 normal 不变，对整体 size 进行映射处理

# negate

对输入值进行取反

xyz 三个轴可分别设置

x 同时代表 bool 值取反

# response curve - exponential

对输入值进行指数处理

xyz 三轴独立处理

如果设置为 2，则输出 输入值的平方

# response curve - user defined

三个轴可独立设置一个 float curve，进入输入输出的映射

不设置，则输出 0

# scalar

xyz 三个轴分别进行标量乘法

# scale by deltatime

xyz 三个轴，同时乘以 deltatime

# swizzle axis

xyz 三轴的分量，进行位置调换
默认是 xyz，可调换到其它顺序
- yxz
- zyx
- zxy
- yzx
- zxy

# to world space

一种特殊的 swizzle

三轴输入情况下，映射为 zxy 顺序
两轴输入，映射为 yx 顺序





- [ ] # smooth

在什么场景下使用？
将输入平滑到多帧？

代码太多 todo


- [ ] # FOV Scaling

对输入值进入与 FOV 相关的缩放处理？

在什么场景下使用？

- FOV scale
- scaling type
	- standard
	- ue4 backcompat
		- 用来修复 ue4 中的 bug，新项目不使用