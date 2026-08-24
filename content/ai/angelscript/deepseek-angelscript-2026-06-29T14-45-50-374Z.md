# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-29T14:45:50.374Z

## User

需要多少个module

## Assistant

关于需要多少个 Module，答案和 Context 类似：**没有一个固定的数字，它完全取决于你项目的架构设计**。你可以使用一个模块包含所有逻辑，也可以为不同功能创建许多独立的模块[-1](https://angelcode.com/angelscript/sdk/docs/manual/doc_overview.html?_x_tr_sch=http)[-10](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_overview.html)。

决定模块数量，关键在于你的脚本代码**如何组织**以及**是否需要在运行时动态管理**。

### 🏗️ 不同架构方案对比

你可以根据下面这几种常见情况来选择：

| 架构方案 | 适用场景 | 优点 | 缺点 |
| --- | --- | --- | --- |
| **单模块 \(Single Module\)** | 小型项目、脚本文件少、逻辑简单 | 实现简单，管理方便 | 修改任何脚本都需要重新编译整个模块；所有脚本共享一个全局命名空间，可能冲突 |
| **按功能分模块 \(Module per Feature\)** | 功能区分清晰的大型项目，如 GUI 逻辑、AI 逻辑、游戏规则等[-1](https://angelcode.com/angelscript/sdk/docs/manual/doc_overview.html?_x_tr_sch=http)[-8](http://www.contagion-game.com/api/manual/doc_adv_access_mask.html) | **接口隔离**：可以使用访问掩码（Access Mask），为不同模块暴露不同的 C\+\+ API，提高安全性[-1](https://angelcode.com/angelscript/sdk/docs/manual/doc_overview.html?_x_tr_sch=http)[-8](http://www.contagion-game.com/api/manual/doc_adv_access_mask.html) <br> **独立更新**：修改 GUI 脚本不会影响 AI 模块，可以按需单独重新编译[-6](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_build.html)[-11](https://www.gamedev.net/forums/topic/648810-dynamically-load-scripts-on-demand/) | 需要额外设计模块间的通信机制 |
| **按实体类型分模块 \(Module per Entity Type\)** | 有许多同类型游戏对象，例如大量僵尸、不同种类的敌人[-4](https://gamedev.net/forums/topic/621143-wrapping-my-head-around-angelscript/?_k=880ea6a14ea49e853634fbdc5015a024&forceDownload=1) | **高效共享**：同一个模块的代码和全局变量在所有该类型的实体间共享，适用于群体行为[-4](https://gamedev.net/forums/topic/621143-wrapping-my-head-around-angelscript/?_k=880ea6a14ea49e853634fbdc5015a024&forceDownload=1) | 每个实体类型需要一个模块，需要合理管理模块数量 |
| **动态按需创建 \(On-Demand Module\)** | 插件系统、关卡脚本、或需要在运行时动态加载和卸载的脚本[-6](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_build.html)[-11](https://www.gamedev.net/forums/topic/648810-dynamically-load-scripts-on-demand/) | **灵活**：可以随时加载或丢弃模块，实现动态扩展[-6](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_build.html)[-11](https://www.gamedev.net/forums/topic/648810-dynamically-load-scripts-on-demand/) | 实现相对复杂，需要注意模块间的依赖和资源管理 |

### 🔗 模块间的通信方式

Module 之间默认是相互隔离、看不见对方的[-3](https://gamedev.net/forums/topic/628270-modules-imports/)。如果它们需要通信，需要通过宿主程序（你的 C\+\+ 代码）来实现。AngelScript 提供了一些官方支持的机制：

1.
**导入/导出函数 \(Imports/Exports\)**：你可以让一个模块导出（Export）某个函数，然后在另一个模块中导入（Import）它。编译后需要调用 `asIScriptModule::BindAllImportedFunctions` 来完成链接[-3](https://gamedev.net/forums/topic/628270-modules-imports/)[-6](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_build.html)。
2.
**共享实体 \(Shared Entities\)**：使用 `shared` 关键字声明的类或函数，会被第一个编译它的模块创建，并被后续所有包含相同声明的模块共享。这能节省内存，并方便模块间交互[-6](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_build.html)[-7](http://www.contagion-game.com/api/manual/doc_script_shared.html#doc_script_shared_external)。

### 💡 实际项目中的常见模式

很多游戏引擎会采用一种**混合策略**：

-
将**基础工具函数、核心框架**放在一个主模块中。
-
为**每个具体的游戏玩法、关卡或敌人类型**创建独立的模块，这些模块可以动态加载或热重载（Hot Reload）[-6](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_build.html)。

例如，一个 RPG 游戏可能有 `Core` 模块（包含角色基础属性、伤害计算公式），然后每个职业（战士、法师）都有自己的模块，在玩家选择职业时按需加载。这样做的好处是，修改法师的技能逻辑时，只需要重新编译法师的模块，而不会影响到战士和其他系统。

### ⚠️ 性能与注意事项

-
**模块数量不是性能瓶颈**：社区经验表明，即使创建大量的模块，其带来的开销也可以接受[-11](https://www.gamedev.net/forums/topic/648810-dynamically-load-scripts-on-demand/)。
-
**全局变量的隔离**：每个模块都有自己独立的全局变量空间。这也是为什么为每个实体类型创建一个模块，能实现群体行为（共享代码，但全局变量独立）的原因[-4](https://gamedev.net/forums/topic/621143-wrapping-my-head-around-angelscript/?_k=880ea6a14ea49e853634fbdc5015a024&forceDownload=1)[-9](https://www.gamedev.net/forums/topic/365790-lots-of-identical-modules/)。
-
**“克隆”模块**：目前 AngelScript 没有提供直接“克隆”一个已编译模块的功能，即使使用预编译字节码（Bytecode），也需要为每个模块执行加载操作[-9](https://www.gamedev.net/forums/topic/365790-lots-of-identical-modules/)。
