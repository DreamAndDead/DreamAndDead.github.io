# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-30T02:01:20.705Z

## User

当context不存在的时候，引用的脚本对象还有作用吗

## Assistant

是的，**当 Context 不存在时，你引用（持有）的脚本对象依然有效，但前提是你正确地增加了它的引用计数。** 这是 AngelScript 内存管理机制的核心：**对象的生命周期由引用计数（Reference Count）决定，而不是由创建它的 Context 决定。**

### 引用计数机制

AngelScript 主要通过引用计数来管理脚本对象的内存[-5](https://angelcode.com/angelscript/sdk/docs/manual/doc_memory.html#doc_memory_1)。一个脚本对象是否存活，取决于它的**引用计数**是否大于 0。每当一个持有对象引用的实体不再需要它时，就会减少计数；当计数归零时，对象就会被自动销毁。

-
**Context 持有引用**：当你通过 `asIScriptContext` 执行工厂函数创建一个脚本对象时，这个 Context 在返回对象指针后，会持有对该对象的一个引用[-1](https://gamedev.net/forums/topic/614863-why-is-this-not-working/?comment=4883473&do=findComment)[-5](https://angelcode.com/angelscript/sdk/docs/manual/doc_memory.html#doc_memory_1)。
-
**你持有引用**：如果你在 C\+\+ 端想要持久地持有这个对象，就必须通过 `obj->AddRef()` 来增加引用计数，声明你对这个对象的“所有权”[-1](https://gamedev.net/forums/topic/614863-why-is-this-not-working/?comment=4883473&do=findComment)[-5](https://angelcode.com/angelscript/sdk/docs/manual/doc_memory.html#doc_memory_1)[-6](http://contagion-game.com/api/manual/doc_reg_basicref.html)。

### Context 销毁的影响

当 Context 被销毁或复用（例如调用 `ReturnContext`）时，它自身的引用会被释放[-1](https://gamedev.net/forums/topic/614863-why-is-this-not-working/?comment=4883473&do=findComment)。此时：

-
**如果你调用了 `AddRef()`**：由于你持有这个额外引用，对象的引用计数不会归零，因此对象会继续存活，你的指针依然有效。
-
**如果你没有调用 `AddRef()`**：Context 释放引用后，对象的引用计数会归零，对象会被立即销毁。这时你在 C\+\+ 端保存的指针就成了一个指向无效内存的“悬空指针”，任何访问都会导致程序崩溃[-1](https://gamedev.net/forums/topic/614863-why-is-this-not-working/?comment=4883473&do=findComment)。

### 正确处理流程

cpp

```cpp
// 1. 执行脚本，创建对象
asIScriptContext* ctx = engine->CreateContext();
ctx->Prepare(factory);
ctx->Execute();

// 2. 获取对象指针
asIScriptObject* obj = *(asIScriptObject**)ctx->GetAddressOfReturnValue();

// 3. 关键步骤：增加引用计数，让对象独立于 Context
obj->AddRef(); // 现在即使 ctx 销毁，对象依然安全

// 4. 归还或销毁 Context（此时释放的是 Context 对该对象的引用）
engine->ReturnContext(ctx); // 或 ctx->Release();

// 5. ... 之后可以安全地使用 obj 指针 ...

// 6. 最终，当你不再需要这个对象时，必须释放你的引用
obj->Release();
```

这个过程是一个标准的“所有权转移”：对象的“保管权”从临时的 Context 转移到了你的 C\+\+ 代码手中[-1](https://gamedev.net/forums/topic/614863-why-is-this-not-working/?comment=4883473&do=findComment)[-6](http://contagion-game.com/api/manual/doc_reg_basicref.html)。
