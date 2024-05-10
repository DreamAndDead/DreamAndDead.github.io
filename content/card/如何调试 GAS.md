---
type: card
created: 2024-04-17T15:06
tags:
- ue
- gas
- debug
---

# plugin 方式

将原本print screen的信息，收集起来用插件面板来呈现

安装方式
- github source 安装 [gas attach editor plugin](https://github.com/Monocluar/GASAttachEditor)
- 通过 [epic marketplace](https://www.unrealengine.com/marketplace/en-US/product/gasattacheditor)安装

启用后，通过 tools-debug-debug gas 打开面板

![[Pasted image 20240417150910.png]]

其中可以实时观察到
- ability
- attribute
- tag
- gameplay effect
- event
等信息

缺点是，每次启动 PIE，都需要在面板中选择相应监听的 actor 实例



