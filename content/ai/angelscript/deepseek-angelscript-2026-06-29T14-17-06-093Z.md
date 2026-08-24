# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-29T14:17:06.093Z

## User

asiscriptobject  vs  module

## Assistant

`asIScriptObject` 和 `asIScriptModule` 是 AngelScript 中两个不同层面、不同作用的核心接口。它们的关系可以类比为 **“图纸”** 与 **“产品”** ，或者 **“类”** 与 **“对象实例”** 的关系。

`asIScriptModule` 代表一个**编译后的脚本模块**，它像是一个静态的代码库，定义了所有可用的类型（类）、函数和全局变量。而 `asIScriptObject` 代表一个**在运行时基于模块中的类型创建的、有具体状态的对象实例**。

下面用表格对比它们的关键区别，能让你更直观地理解：

| 特性 | `asIScriptModule` \(模块\) | `asIScriptObject` \(脚本对象\) |
| --- | --- | --- |
| **核心职责** | 管理**编译后的代码**，作为类型和函数的“容器” | **存储数据状态**，是脚本类的“实例” |
| **创建时机** | 编译脚本时创建，通常位于程序启动或热加载阶段 | 运行时动态创建 \(`mod->CreateObjectByType()`\) |
| **生命周期** | 长期存在于引擎中，直到被 `DiscardModule` 卸载 | 随脚本逻辑创建和销毁，由引用计数管理 |
| **能否执行代码** | 不直接执行，但可提供 `asIScriptFunction` 供上下文执行 | 不执行代码，仅作为调用方法的对象 \(`this`\) |
| **主要功能** | `GetFunctionByDecl()`, `GetTypeInfoByDecl()`, `Build()` | `GetAddressOfProperty()`, `GetObjectType()`, `AddRef()/Release()` |
| **内存占用** | 较小，只存储代码元数据 | 每个实例占用一份内存，存储其所有属性的值 |

### 🔍 深入理解：它们如何协同工作？

它们在脚本执行流程中是这样配合的：

1.
**加载阶段**：通过引擎编译脚本代码，生成一个 `asIScriptModule`。这个模块就像一个“类库”或“蓝图集”，包含了 `Player`、`Enemy` 等类的定义。
2.
**实例化阶段**：当你在脚本中执行 `Player@ p = Player();` 时，AngelScript 内部会使用 `asIScriptModule` 中的 `Player` 类型信息 \(`asITypeInfo`\)，在堆上分配内存，创建一个 `asIScriptObject` 实例。
3.
**运行阶段**：脚本函数在执行时，`asIScriptContext` 会操作这个 `asIScriptObject` 实例。当你需要在 C\+\+ 端读写对象的属性时，比如获取玩家的 HP，你会拿到这个对象的 `asIScriptObject*` 指针，然后通过 `GetAddressOfProperty("hp")` 来操作它。如果需要调用对象的成员函数，则从它所在的模块中获取对应的 `asIScriptFunction`。

### 💡 常见使用场景

这两个接口在 C\+\+ 与脚本交互时各有分工：

-
**使用 `asIScriptModule` 的典型场景**：

-
**编译脚本**：将 `.as` 代码添加到模块并构建。
-
**查找函数**：在游戏主循环的某一帧，从模块中获取 `void Update(float dt)` 函数，然后交给上下文执行。
-
**获取类型信息**：在创建对象或进行类型检查前，先获取 `asITypeInfo`。
-
**使用 `asIScriptObject` 的典型场景**：

-
**数据处理**：在 C\+\+ 注册的函数中，接收脚本传过来的对象参数，读取或修改其属性。
-
**持久化引用**：将 C\+\+ 游戏对象与一个脚本对象绑定，并在 C\+\+ 侧长期持有其 `asIScriptObject*`（注意管理引用计数）。
-
**序列化**：遍历对象的所有属性，将其值保存到磁盘或网络。

### ⚠️ 常见误区：模块与对象的生命周期

一个关键的安全准则是：**模块必须先于对象存在，并且比所有从其派生的对象“活”得更久。**

-
`asIScriptObject` 内部持有指向其所属 `asITypeInfo`（由模块管理）的引用。
-
如果你 `DiscardModule`（丢弃模块）时，还有 `asIScriptObject` 实例存活，它们内部引用的类型信息会变成悬空指针，**这会导致崩溃**。
-
**正确做法**：在热加载或卸载模块前，确保释放所有来自该模块的 `asIScriptObject` 引用。通常，需要先 `Release()` 所有对象，然后调用 `engine->GarbageCollect()` 强制回收，最后才能安全地 `DiscardModule`。这在之前的“热加载”讨论中也有提到。`asIScriptObject` 和 `asIScriptModule` 是 AngelScript 中两个截然不同但又紧密协作的核心接口。简单来说，**`asIScriptModule` 是“蓝图”或“代码库”，而 `asIScriptObject` 是基于蓝图建造出来的、有具体状态的“产品”**。

### 📐 核心区别速览

| 特性 | `asIScriptModule` \(模块\) | `asIScriptObject` \(脚本对象\) |
| --- | --- | --- |
| **一句话定义** | 编译后的脚本代码容器，定义类型和函数 | 脚本类的一个具体实例，存储数据 |
| **创建时机** | 编译脚本时创建 | 运行时动态创建 \(`mod->CreateObjectByType()`\) |
| **生命周期** | 长期存在，直到被 `DiscardModule` 卸载 | 随脚本逻辑创建/销毁，由引用计数管理 |
| **主要职责** | 存储类型信息、函数、全局变量 | 存储对象属性的具体值 |
| **能否执行** | 不直接执行，但提供 `asIScriptFunction` | 不执行代码，作为 `this` 对象存在 |

### 🔗 它们如何协同工作？

它们的关系是 **“模板”与“实例”** 的关系，通过一个典型的流程就能看明白：

1.
**创建模块**：你通过 `engine->GetModule("MyModule", asGM_ALWAYS_CREATE)` 获取或创建一个 `asIScriptModule`，并将脚本代码编译到其中。此时，模块中包含了 `class Player { int hp; void TakeDamage(int); }` 这样的类型定义。
2.
**创建对象**：在你的游戏代码（或脚本）中，当你执行 `Player@ p = Player();` 时，AngelScript 内部会使用 `asIScriptModule` 中 `Player` 类型的元数据（`asITypeInfo`）来分配内存，并创建一个 `asIScriptObject` 实例。
3.
**操作对象**：创建出的 `asIScriptObject` 包含了一个具体的 `hp` 值（比如 100）。之后，你或脚本通过 `p.hp = 80` 修改的是这个 `asIScriptObject` 实例的状态。
4.
**调用方法**：当调用 `p.TakeDamage(20)` 时，`asIScriptContext` 会从 `asIScriptModule` 中查找 `Player::TakeDamage` 的 `asIScriptFunction`，并将 `asIScriptObject` 作为 `this` 指针传入执行。

### 🛠️ 各自的核心用途

-
**`asIScriptModule` 是“查询者”**：当你需要查找函数 \(`GetFunctionByDecl`\)、获取类型信息 \(`GetTypeInfoByDecl`\) 或进行模块间函数绑定时，你会用到它。它代表的是**“静态”的代码定义**。
-
**`asIScriptObject` 是“操作者”**：当你需要在 C\+\+ 侧读写某个具体脚本对象的属性 \(`GetAddressOfProperty`\)、检查它的类型 \(`GetObjectType`\)，或者像在 DAP 调试器中那样读取变量的值时，你会用到它。它代表的是**“动态”的对象状态**。

### ⚠️ 一个至关重要的安全规则

**模块必须先于对象存在，并且其生命周期必须长于所有由它派生的对象。** 这是因为 `asIScriptObject` 内部持有指向其所属 `asITypeInfo` 的引用，而 `asITypeInfo` 的生命周期由 `asIScriptModule` 管理。

如果你在仍有 `asIScriptObject` 存活的情况下调用了 `engine->DiscardModule()`，这些对象内部的类型指针会变成悬空指针，**必然导致崩溃**。因此，在热加载或卸载模块时，正确的顺序是：

1.
释放所有来自该模块的 `asIScriptObject` 引用（调用 `Release()`）。
2.
执行垃圾回收（`engine->GarbageCollect()`）。
3.
最后，才能安全地 `DiscardModule`。
