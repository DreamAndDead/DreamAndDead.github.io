# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-29T14:50:13.574Z

## User

addsectionfromfile   多少个文件合适

## Assistant

关于 `AddSectionFromFile` 应该添加多少个文件，目前没有找到官方或社区关于数量的硬性限制和性能基准。不过，这个问题和**脚本文件如何组织成模块**直接相关。你可以根据以下原则来判断：

### 🤔 决定因素：你想如何组织脚本

调用 `AddSectionFromFile` 添加的文件，最终都会被编译到**同一个模块**里[-3](https://gamedev.net/forums/topic/628270-modules-imports/)。所以，一个模块里放多少个脚本文件，取决于你想怎么组织它们。

-
**如果逻辑高度关联：放一个模块里**。你的引擎通常会为每个独立的“功能包”创建一个模块[-2](https://gamedev.net:443/forums/topic/698152-multiple-scripts-with-the-same-function-names/)[-3](https://gamedev.net/forums/topic/628270-modules-imports/)。

-
**例子**：比如一个关卡的所有 AI 逻辑，或者一个插件的全部脚本。
-
**做法**：把这些相关的 `.as` 文件通过多次调用 `AddSectionFromFile` 添加到这个模块，然后执行一次 `Build`。
-
**效果**：在同一个模块里，所有脚本文件像写在一个大文件里一样，彼此**能直接看到对方的函数和类**，不需要复杂的导入机制[-3](https://gamedev.net/forums/topic/628270-modules-imports/)。
-
**如果需要隔离：放在不同模块**。不同模块之间默认互相隔离，需要通过 `import` 等功能来进行通信[-3](https://gamedev.net/forums/topic/628270-modules-imports/)。

-
**例子**：两个不同游戏模式的核心逻辑，它们之间没有依赖。

从社区讨论来看，一个模块包含多个脚本文件是很常见的做法，目的是为了“更好地组织项目”[-1](https://support.enovationcontrols.com/hc/en-us/articles/360052591313-6-7-Programming-Methods-Scripting)。关键不在于文件数量，而在于**逻辑内聚性**——相关的代码放到一个模块，不相关的分开。

### 💡 组织建议

1.
**从一个模块开始**：对于中小型项目，将主要脚本放在一个模块里是最简单的。当脚本增长到难以维护时，再按功能拆分模块。
2.
**善用 `#include` 拆分文件**：即使是在一个模块内，你仍然可以将**类型声明**（比如接口、类定义）放在单独的文件中，再在主脚本中 `#include`，这能有效提升代码可读性。
3.
**注意重名问题**：放在同一个模块中的文件，**全局函数和类名不能重名**，因为它们共享同一个命名空间。如果你发现需要同名函数（比如每个关卡都需要一个 `Init`），那就说明它们应该放在**不同的模块**里[-2](https://gamedev.net:443/forums/topic/698152-multiple-scripts-with-the-same-function-names/)。

另外，如果你发现每次添加几十个文件后，`Build` 编译很慢，可以考虑使用 `SaveByteCode` 保存预编译字节码，下次启动时用 `LoadByteCode` 直接加载，来优化启动速度[-6](https://developer.baidu.com/article/detail.html?id=7000845)。
