# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-30T05:52:14.269Z

## User

生成的字节码是如何知道C++的实际地址的

## Assistant

预编译字节码并不知道 C\+\+ 函数的实际地址。这个问题的答案有点反直觉，但它正是理解 AngelScript 如何运作的关键。

### 🎯 核心答案：字节码保存的是“ID”，不是“地址”

预编译的字节码文件里，保存的并不是内存地址，而是**一个用于识别已注册函数的标识符（ID）**[-4](https://www.gamedev.net/forums/topic/535075-compiled-code-size/)[-5](https://www.gamedev.net/forums/topic/257372-saving-compiled-bytecode/?page=3)。

这其中的原理体现在两个关键步骤：

1.
**注册时建立映射**：当你在 C\+\+ 端调用 `RegisterGlobalFunction` 或 `RegisterObjectMethod` 时，AngelScript 的核心任务就是**将函数的“声明字符串”（如 `"void log(string)"`）和它在C\+\+中的“实际内存地址”绑定在一起**，并存入引擎的全局注册表中[-1](https://angelcode.com/angelscript/sdk/docs/manual/doc_register_func.html?_x_tr_sch=http)[-7](https://developer.baidu.com/article/detail.html?id=7000845)[-8](https://baike.baidu.com/item/AngelScript/1733890)。
2.
**编译时写入ID**：当你调用 `SaveByteCode` 保存字节码时，字节码里记录的并不是那个内存地址，而是对应注册项的一个稳定的**函数ID**[-4](https://www.gamedev.net/forums/topic/535075-compiled-code-size/)[-5](https://www.gamedev.net/forums/topic/257372-saving-compiled-bytecode/?page=3)。这个ID在整个系统中是唯一的。

### 🔗 关键环节：加载时的“重链接”

所以，在运行时，字节码是通过**“重链接”**来找到C\+\+函数的。这个过程是：

1.
当你调用 `LoadByteCode` 加载字节码时，AngelScript 会遍历字节码中所有的函数ID。
2.
它会拿着这些ID，去当前**已经完成注册**的引擎中查找对应的函数。只有在运行时也通过 `RegisterGlobalFunction` 等API完成了完全相同的注册（函数名、参数、返回值类型完全一致），引擎才能根据ID找到对应的函数指针[-3](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_precompile.html)。
3.
**找到 C\+\+ 的实际地址**，并完成字节码与 C\+\+ 函数地址的“链接”。这样一来，当虚拟机执行到调用指令时，才能跳转到正确的 C\+\+ 函数[-5](https://www.gamedev.net/forums/topic/257372-saving-compiled-bytecode/?page=3)。

这也是为什么之前提到 `ConfigEngineFromStream` 不能执行脚本。`ConfigEngineFromStream` 只重建了函数的“声明”，却没有注册真正有效的函数指针（或是空指针），所以字节码“重链接”时找不到实际地址，自然就无法执行。

AngelScript 通过**“编译时记录ID，加载时重链接”**的巧妙设计，使得预编译字节码可以在C\+\+函数地址可能变化（比如动态库重新加载）的情况下，依然能够准确调用到正确的函数，保证了其平台无关性和灵活性[-3](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_precompile.html)[-6](https://www.angelcode.com/angelscript/features.html)。
