---
created: 2024-05-21T10:37
draft: true
tags: 
- card
- blender
---

在大纲视图中，可以看到“数据块”呈现树状的组织形式

![[Pasted image 20240521103915.png]]

blender 对于数据的处理顺序和这个顺序相同

先进行 mesh 处理，再进行 constraint 处理，再进行 modifier 处理

如果有多个 constraint 和 modifier，它们的顺序很重要

最常见的，sub d modifier 在前还是在后，对结果影响很大