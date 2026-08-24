# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-29T14:48:07.600Z

## User

模块之间如何通信

## Assistant

在 AngelScript 中，模块之间默认是相互隔离的，像一个独立的“程序”，彼此看不见对方[-6](https://gamedev.net/forums/topic/628270-modules-imports/)。要让它们通信，需要通过宿主程序（你的 C\+\+ 代码）建立桥梁。

AngelScript 主要提供了三种官方机制来实现模块间通信：`import` 导入函数、`shared` 共享实体，以及通过宿主程序自定义的消息系统。

### 🔗 机制一：导入/导出函数 \(Import/Export\)

这种方式可以让一个模块显式调用另一个模块中定义的函数，适合**函数级别的调用**[-1](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_build.html?_x_tr_sch=http)[-3](https://angelcode.com/angelscript/sdk/docs/manual/doc_global_import.html)。

-
**用法**：在调用方模块中，使用 `import` 关键字声明所需函数，并指明它来自哪个源模块[-3](https://angelcode.com/angelscript/sdk/docs/manual/doc_global_import.html)[-4](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_adv_import.html)。
angelscript

```angelscript
// 在模块 "ModuleB" 中声明，要从 "ModuleA" 导入函数
import void MyFunction(int a, int b) from "ModuleA";
```
-
**关键步骤**：

1.
**确保导出模块先编译**：必须先编译“导出”函数的模块（如 ModuleA）。
2.
**编译导入模块**：编译“导入”函数的模块（如 ModuleB）。
3.
**绑定函数**：编译完成后，在 C\+\+ 端调用 `asIScriptModule::BindAllImportedFunctions()` 来完成函数引用的绑定[-1](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_build.html?_x_tr_sch=http)[-4](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_adv_import.html)。
cpp

```cpp
// 在编译 ModuleB 之后
asIScriptModule* modB = engine->GetModule("ModuleB");
modB->BindAllImportedFunctions();
```
-
**特点与场景**：

-
这是模块间最直接的通信方式，脚本代码看起来就像在调用本地函数一样。
-
宿主程序可以对导入过程进行细粒度控制，比如通过 `GetImportedFunctionDeclaration` 等方法枚举并逐个检查，决定是否允许绑定某个导入[-4](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_adv_import.html)。
-
可以实现动态重新绑定。通过 `UnbindAllImportedFunctions` 和重新 `Bind`，可以在运行时改变一个模块导入的函数指向另一个模块，实现类似插件热切换的功能[-4](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_adv_import.html)。

### 🤝 机制二：共享实体 \(Shared Entities\)

这种方式允许不同的模块**共享同一个类型或函数的定义**，适合**数据交换和类型统一**的场景[-1](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_build.html?_x_tr_sch=http)[-8](https://angelcode.com/angelscript/sdk/docs/manual/doc_script_shared.html?_x_tr_sch=http)。

-
**用法**：在模块中用 `shared` 关键字声明一个类或函数。
angelscript

```angelscript
// 在多个模块中均可包含此声明
shared class DataPacket {
int value;
}
```
-
**关键机制**：当第一个包含 `shared` 定义的模块被编译后，AngelScript 会“记住”这个定义。后续任何模块若包含相同的 `shared` 定义，引擎会直接复用第一个模块编译好的内部类型和字节码[-1](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_build.html?_x_tr_sch=http)[-8](https://angelcode.com/angelscript/sdk/docs/manual/doc_script_shared.html?_x_tr_sch=http)。
-
**特点与场景**：

-
**节省内存**：共享实体的代码和内部表示在内存中只有一份[-8](https://angelcode.com/angelscript/sdk/docs/manual/doc_script_shared.html?_x_tr_sch=http)。
-
**类型安全**：由于使用的是同一个类型，不同模块间传递 `shared` 类对象时，类型是完全兼容的，这在通过宿主程序传递数据时非常有用[-1](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_build.html?_x_tr_sch=http)[-8](https://angelcode.com/angelscript/sdk/docs/manual/doc_script_shared.html?_x_tr_sch=http)。
-
**一致性要求高**：所有模块中 `shared` 实体的声明必须完全一致，否则后编译的模块会报错。最容易的实现方式是将共享声明放在一个单独的文件中，并在各模块中 `#include` 它[-8](https://angelcode.com/angelscript/sdk/docs/manual/doc_script_shared.html?_x_tr_sch=http)。
-
**限制**：共享实体内部不能访问非共享实体，因为它会被不同模块编译，可能导致不一致[-8](https://angelcode.com/angelscript/sdk/docs/manual/doc_script_shared.html?_x_tr_sch=http)。

### 🧩 机制三：宿主程序自定义通信 \(Application-level Messaging\)

这是最灵活的方式，由你的 C\+\+ 代码建立模块间的通信管道[-1](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_build.html?_x_tr_sch=http)[-6](https://gamedev.net/forums/topic/628270-modules-imports/)。模块之间不直接交互，而是通过 C\+\+ 发送和接收消息。

-
**核心思想**：在 C\+\+ 端注册消息传递的 API，模块 A 调用 C\+\+ 函数“发送消息”，C\+\+ 代码再将消息转发给模块 B 的“接收消息”函数。
-
**特点与场景**：

-
**最大灵活性**：宿主程序可以完全控制消息的路由、过滤和安全策略。
-
**设计解耦**：模块之间不需要知道彼此的存在，只需知道消息格式即可。
-
**实现复杂**：需要在 C\+\+ 端设计和实现一整套消息机制。实际项目中，这种模式常被用来构建复杂的游戏框架，例如 `ezEngine` 中就采用了消息系统来实现组件间通信[-2](https://ezengine.net/pages/docs/custom-code/angelscript/as-messaging.html)。

### 💎 总结与选择建议

我把这三种方式的特点整理成了一个表格，方便你根据场景选择：

| 机制 | 核心操作 | 优点 | 适用场景 |
| --- | --- | --- | --- |
| **`import` 函数** | `import` 声明，C\+\+ 端 `BindAllImportedFunctions` | 直接调用，可动态绑定 | 明确的函数调用关系，如主模块调用插件模块的功能[-3](https://angelcode.com/angelscript/sdk/docs/manual/doc_global_import.html)[-4](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_adv_import.html) |
| **`shared` 共享实体** | `shared class` 声明，各模块包含相同定义 | 类型安全，节省内存 | 跨模块传递复杂数据对象，需要类型统一[-8](https://angelcode.com/angelscript/sdk/docs/manual/doc_script_shared.html?_x_tr_sch=http) |
| **宿主自定义消息** | 调用 C\+\+ 注册的消息收发 API | 架构灵活，完全解耦 | 大型项目，需要复杂的模块间事件通信[-2](https://ezengine.net/pages/docs/custom-code/angelscript/as-messaging.html)[-6](https://gamedev.net/forums/topic/628270-modules-imports/) |

需要注意的是，基础的 `#include` 预处理指令并不能实现模块间通信，它只是简单地在编译前将文件内容合并到同一个模块中，适合组织单个模块内部的代码[-10](https://www.gamedev.net/forums/topic/439660-requireinclude-type-functionality/3914933/)。
