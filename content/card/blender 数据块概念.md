---
created: 2024-05-21T10:13
draft: true
tags: 
- card
- blender
---

在 blender 中，所有数据对象都是数据块(data block)

通过大纲视图，切换到 blender file，可看到所有数据块

![[Pasted image 20240521101536.png]]

![[Pasted image 20240521101700.png]]

shift a 新建物体，会新建 object mesh material 数据块，链接在一起，呈现一个 cube

![[Pasted image 20240521101833.png]]

![[blender data block simple example]]

通常，object 用橙色，mesh 用绿色，材质用红色


每个类型下的数据块名字唯一

数据块之间是引用关系，生命周期与引用计数有关

可以添加fake user，强制引用，不被删除

# 数据块的复制

- alt d 只复制物体
- shift d 只复制物体与几何数据
- ctrl c ctrl v 复制全部tree

![[blender data block copy]]


# 所有数据块的类型与图标

 ![[files_data-blocks_id-types.png]]


> [!WARNING] 并非所有概念都是数据块
> 骨骼、序列剪辑或顶点组就不是数据块，它们分别属于骨架，场景和网格类型
> 
> constraint, modifier 也不是数据块，因为它们本质是函数



