---
created: 2024-05-17T16:58
draft: true
tags: 
- card
- ue
- asset
---

点击运行键时，从Level开始，通过资源的引用关系，引擎可以加载所有相关的资源，一切都是自动运行的。

有些情况，开发者需要手动管理资源的加载和释放，优化内存，于是引擎提供了AssetManager类来完成。

AssetManager 是一个单例类，在C++中继承自定义子类，在引擎设置中进行覆盖
