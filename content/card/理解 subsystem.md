---
created: 2024-05-22T19:01
draft: true
tags: 
- card
- ue
- gameplay
---

[[ue subsystem.drawio]]

subsystem 的本质是 uobject，不过被引擎自动管理生命周期
- 自动创建
- 自动销毁

根据继承父类的不同，从而跟随不同 outer 的生命周期

# 生命周期

- editor 模式，运行 ue editor 程序
- PIE 模式，在编辑器中点击 play
- runtime 模式，运行打包后的程序

| 生命周期                                | Editor 模式           | PIE 模式        | Runtime 模式                                             |
| ----------------------------------- | ------------------- | ------------- | ------------------------------------------------------ |
| UEngine，代表引擎，数量 1                   | 全局唯一，进程启动创建，进程退出销毁  | ？？？           | 全局唯一，进程启动创建，进程退出销毁                                     |
| UEditorEngine，代表编辑器，数量 1            | 全局唯一，编辑器启动时创建，退出时销毁 | 不存在？          | 不存在                                                    |
| UGameInstance，代表一场游戏， 数量 1          |                     | 游戏启动时创建，退出时销毁 | 游戏启动时创建，退出时销毁                                          |
| UWorld，代表一个世界，数量 >= 1               | 视口场景是个World         |               | world 创建时，world 销毁时                                    |
| ULocalPlayer，代表本地玩家，数量 >= 1（本地分屏游戏） |                     |               | 添加 player 时创建，删除 player 时销毁（单人模式下几乎和 game instance 一致） |

world 是和 gamemode 关联的，可以包含多个 level

EWorldType其实有多个类型：Game，Editor，PIE，EditorPreview，GamePreview等。编辑器下的视口场景也是个World!


# VS blueprint library

blueprint library 本质是 static 函数的集合，不存在状态

subsystem 是 uobject，内部可存在状态，并有自动生命周期管理

# VS component

subsystem 在设计思想上，和 component 有相似之处

不过 component 用于 actor，不限制数量

建议在使用时
- 将业务逻辑放在 subsystem
	- 计分系统
	- 对话系统
- 可复用功能放到 component
	- 移动
	- 输入


参考
- [《InsideUE4》GamePlay架构（十一）Subsystems](https://zhuanlan.zhihu.com/p/158717151)
