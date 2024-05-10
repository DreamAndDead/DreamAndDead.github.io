---
type: card
created: 2024-04-08T17:16
draft: true
tags:
- ue
- als
- animation
---

- [ ] 换一种角度出发，以功能的角度，这个功能如何实现，需要哪些变量

5 个核心方向
角色的正面朝向
角色速度方向
角色加速度方向
玩家输入加速度方向
相机朝向

是各种trans的关键，以及其它衍生数据


在不使用 rm 的情况下，动画是被动呈现的

动画要做的，就是确保 cap 在各种移动时，有一个有说服力的动作呈现
在这个基础上，动画系统需要知道运动系统在正做什么，才能选择合适的pose表现

人物空间相关

速度
3d 速度
水平速度
垂直速度
水平速率
是否在移动

实际加速度
(cur frame v - prev frame v) / delta time
水平垂直划分



旋转相关
当前朝向
存储在 controller 中

通常决定相机朝向
比较被动，时刻处于一个平滑到目标旋转位置的状态，没有参考意义
目标旋转位置才有意义

当前旋转速度
yaw 水平旋转
和 prev frame 的 delta / time


输入相关
输入vector
character movement comp -> get current acceleration
输入方向，单位向量
输入量的大小，和 max 相比，归一化到 0-1
是否有输入




状态相关

movement direction
前 后 左 右

在非速度旋转模式下，人物移动的方向，相对于相机朝向而言
用于 6 向状态机的转移

速度模式下，始终为 forward，只使用向前跑动画
冲刺状态下，也为 forward，只用向前跑动画（没有做其它方向的冲刺）


tracked hips direction
当前 hip 的朝向
用在 6 向状态机的 state event 中


relative acceleration
相对角色正面朝向的加速度，归一化到 0-1

is moving
是否在水平移动

rotate l r
在相机角度和人物朝向偏离一定范围时，开启原地转身

rotate rate
原地旋转的动画播放速率
以 aim yaw 为基础进行 map range

rotation scale?
用于 turn in place

