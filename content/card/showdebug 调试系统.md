---
created: 2024-05-23T15:44
draft: true
tags: 
- card
- ue
- debug
---

showdebug 是一个 console cmd，经常用于调试各个系统模块
本质是 AHUD::ShowDebug 的 UFunction(exec)，参数是一个 FName

[[ue showdebug.drawio]]

目前已经演化成一个入口，具体 debug draw 需要由各模块来实现

这个规范有些陈旧，接口老，设计的不是特别合理
另外，用 cpp 代码绘图，效率是很低的


- [ ] 命令本身的记忆性是如何实现的
	- reset 可以清空当前记忆

```cpp
/** Array of names specifying what debug info to display for viewtarget actor. */
UPROPERTY(globalconfig)
TArray<FName> DebugDisplay;
```


# 模块接入

模块实现方法，接入 delegate

```cpp
AHUD::OnShowDebugInfo.AddStatic(&FEnhancedInputModule::OnShowDebugInfo);
```

每当 showdebug cmd 调用时，都会收到 broadcast

## cmd 提示

在模块的 ini 配置文件中，新增 complete 描述

```ini
[/Script/EngineSettings.ConsoleSettings]
+ManualAutoCompleteList=(Command="ShowDebug EnhancedInput",Desc="Displays debug information about the current state of any Enhanced Input Mapping Contexts")
```

