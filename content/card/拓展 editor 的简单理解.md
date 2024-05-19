---
created: 2024-05-17T17:47
draft: true
tags: 
- card
- ue
- editor
---

对 editor 的拓展，分为两类 action
- action to asset
- action to actor

对 asset 的操作，通过继承 UAssetActionUtility，定义相关方法来实现

对 actor 的操作，通过继承 UActorActionUtility 定义方法来实现

子类化的方法，可以通过 cpp，也可以通过 bp，达到相同的效果

也可以通过 python 来实现


cpp 来实现，效率太低
推荐使用 bp 实现 gui 界面，用 py 实现逻辑，通过 bp 的 py 节点来调用




