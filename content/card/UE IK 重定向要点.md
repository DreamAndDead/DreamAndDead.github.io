---
type: card
tags: 
  - ue
  - animation
created: 2024-03-22T20:12
---

ue5 引入的新重定向方式

# 基本流程

1. 为每个 skeleton 建立 ik rig 资产
2. 为不同 skeleton 之间建立 ik retargeter 资产
3. 不同 skeleton 的 anim 可以相互重定向


ik rig 由不同的chain组成
ik retargeter 是不同chain的映射关系

ik rig 要设置 retarget root
通常是 pelvis or hip
为了 root motion 可以正常重定向，保留给root使用
root 和 pelvis 之间存在距离变化，在人物前进途中，忽高忽低的感觉
只有 root phrase 就可以呈现这种效果

在 ik retargeter 中，对 root chain 设置 transiation mode 为 globally scaled

rtg 中，首先要校正 ref pose


- ik goal 如何使用？
effector point for ik chain
和 solver 配合，修正整个 chain的位置

- TODO stride warping 功能

[official doc 说明的很详细](https://dev.epicgames.com/documentation/en-us/unreal-engine/ik-rig-animation-retargeting-in-unreal-engine?application_version=5.3)









