---
created: 2024-06-24T22:00
draft: true
tags: 
- card
- blender
- geometry-node
---

object info node，选择一个 object，输出 transform 信息
transform 可分为 original 与 relative


两个 sphere 和 geo node 修饰的 object 都有自己相对于 world origin 的 transform

在 geo node 中引用 start 时，
- 选择 original 模式，则输出的 transform 信息是 start 相对于 world origin 的信息
- 选择 relative 模式，则输出 start 相对于 self object 的信息

# original

![[Pasted image 20240624220247.png]]

![[Pasted image 20240624220305.png]]

使用 original 模式，在 self object 中得到 world origin 数值，再套入 self object 的 local 坐标系

# relative

![[Pasted image 20240624220708.png]]
![[Pasted image 20240624220717.png]]

使用 relative 模式，得到相对于 self object local 坐标系的 transform 数值，再代入 self object local 坐标系

# set parent

如果 self object 作为 start end 的 parent，问题会如何？

其实没有任何影响

这个问题只涉及 world 坐标系 和 相对坐标系，没有 parent 坐标系

如果有父子关系，有一点好处是，移动 self object，整体会一起移动

没有父子关系，移动 self object，完全没有任何影响