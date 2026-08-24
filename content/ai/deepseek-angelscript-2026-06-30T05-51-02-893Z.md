# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-30T05:51:02.893Z

## User

如果不能用来执行脚本的话，那它的作用在哪里

## Assistant

`ConfigEngineFromStream` 的存在，是为了解决一个完全不同的场景问题：**离线编译（Offline Compilation）**。

它并不是用来在运行时执行脚本的“万能恢复工具”，而是扮演了一个“接口蓝图”的角色。它的核心作用，用官方文档的话来说就是：**配置引擎以编译脚本并保存字节码，但无法用于执行脚本**[-2](https://git.p-epsilon.com/Deukhoofd/AngelscriptLanguageServer/blame/commit/fac54acbc9acd838b43105de578a68dc11882991/server/src/angelscript/extensions/scripthelper/scripthelper.h)。

### 🎯 核心应用场景：加速游戏启动

你可能熟悉一些大型游戏或引擎，在首次或更新后启动时，需要“编译着色器”或“编译脚本”，这个过程通常很耗时。

`ConfigEngineFromStream` 就是为了优化这个流程，常用于**“预编译脚本”**场景。它的典型工作流程如下：

1.
**开发阶段**：你的游戏主程序启动，通过大量 `RegisterGlobalFunction` 等 C\+\+ API 注册好所有接口。然后调用 `WriteConfigToStream`，把当前定义的**所有接口信息**（函数名、参数类型、对象类型等）导出到一个文本流或文件中[-1](https://www.gamedev.net/forums/topic/671433-documenting-registered-api/5250593/)。
2.
**构建/发布阶段**：在打包游戏时，使用一个**单独的编译工具**。这个工具会调用 `ConfigEngineFromStream` 加载之前导出的接口信息，快速“恢复”出一个接口定义一致的 AngelScript 引擎环境。
3.
**离线编译**：这个工具读取所有 `.as` 脚本文件，直接编译成字节码，并保存为 `.asc` 或 `.cache` 等缓存文件[-5](https://urho3d.io/documentation/HEAD/_scripting.html)。
4.
**最终运行**：在打包好的游戏中，AngelScript 引擎启动后，**直接加载这些预编译好的字节码文件**，完全跳过解析和编译源码的步骤。

Unreal Engine 的 AngelScript 插件就是这种方案的典型实践。它会在打包时生成一个 `PrecompiledScript.Cache` 文件，游戏运行时直接加载，显著缩短了启动时间，尤其在主机或移动设备这类 CPU 性能受限的平台上效果明显[-3](http://angelscript.hazelight.se/cpp-bindings/precompiled-data/)。

### 🏗️ 它是如何“骗过”编译器的？

你可能会有疑问：**既然不能执行，它靠什么通过编译检查？**

关键在于，编译脚本代码时，AngelScript 的 `Build()` 方法主要是在做**符号验证**和**生成字节码**。它需要知道函数的**存在**（如 `void log(string)`），而并不需要知道这个函数在 C\+\+ 端的**实际入口地址**。`ConfigEngineFromStream` 正好能提供这些“存在性”信息，成功“骗过”编译过程，生成字节码。虽然这些字节码无法执行，但作为中间产物，它完成了最重要的使命。

如果你还想了解如何将 `WriteConfigToStream` 导出的信息，用于自动生成 API 文档，或者想知道如何加载预编译好的字节码文件（例如 `LoadByteCode` 的用法），我可以继续为你展开。
