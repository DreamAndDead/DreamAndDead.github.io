---
created: 2024-04-06T22:28
tags:
- card
- ue 
---

# 不同软件的坐标系对比 

不同软件的空间坐标系有些许区别

首先是左手系，右手系的区别，其次是哪个轴为 up 轴的区别(一般不使用 x 轴为 up 轴)


| 软件               | Z-UP                                                           | Y-UP                                            |
| ---------------- | -------------------------------------------------------------- | ----------------------------------------------- |
| **left handed**  | unreal                                                         | unity, c4d, zbrush, directx                     |
| **right handed** | cry engine, source engine, blender, 3ds max, autocad, sketchup | godot, maya, houdini, substance painter, opengl |

unreal 是独特的存在，使用左手坐标系，Z-UP

# 移动  

![[Pasted image 20240406223957.png]]

rgb 3 个颜色对应 xyz 3 个轴

x 轴指向人物前方，对应 +forward -backward
y 轴指向人物右方，对应 +right -left
z 轴指向人物上方，对应 +up -down

3 个轴的正方向都非常符合直觉

# 旋转

![[Pasted image 20240406224309.png]]

rgb 分别对应围绕 xyz 3 个轴的旋转

理论上左手系应该使用左手法则进行旋转，大拇指指向箭头方向，手指方向为旋转正方向

而 ue 为了保持直觉性，使用不同的方式

| 轴   | 名称    | 正向旋转    | 法则  |
| --- | ----- | ------- | --- |
| x   | roll  | 人物向右手侧倒 | 右手  |
| y   | pitch | 人物向上看   | 右手  |
| z   | yaw   | 人物向右转   | 左手  |

# euler family

欧拉角存在一个解析顺序的问题，
xyz 顺序，意味着以世界坐标系轴为基准（外旋）
先绕 x 轴旋转，再 y 轴，再 z 轴
x 只影响本身，y 轴旋转影响了之前 x 轴的旋转，z 轴旋转影响了 x y 轴的旋转

![[UE4Editor_XPrp8Pt0sT.gif]]

xyz 有 6 种可能的顺序
- yxz
- zxy
- xyz
- zyx
- xzy
- yzx 
ue使用 xyz 顺序

## 万向锁

 欧拉角存在万向锁的问题，即中间轴旋转90度之后，剩下两个轴的旋转效果相同

以xyz为例，y=90，此时旋转x 和 z效果相同

![[UE4Editor_ZE7fAEmQYi.gif]]

所以对不同的欧拉角顺序，推荐使用的方法是锁定中间轴为0，用 1轴表示旋转，3 轴表示朝向

比如在骨架中每个骨骼的xyz轴向，尽量不使用y轴
x 轴和骨骼方向一致，z 轴表示骨骼沿关节的旋转

![[Pasted image 20240407121320.png]]
比如表示轮胎的行为



