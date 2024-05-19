---
created: 2024-05-17T17:51
draft: true
tags: 
- card
- ue
- py
---

开启插件
- editor scripting utilities
- python editor script plugin

![[Pasted image 20240517175315.png]]
![[Pasted image 20240517175323.png]]

project settings - plugins - python 开启 developer mode 与 remote execution

![[Pasted image 20240517175442.png]]

restart ue 会生成 `intermediate/python/unreal.py` stub file，其中是对所有可用 api 的空定义，用于 ide 提示补全

vscode 安装插件 [unreal engine python](https://marketplace.visualstudio.com/items?itemName=NilsSoderman.ue-python)

执行 `setup code completion` 将 stub file 加入 vscode 的补全路径中
