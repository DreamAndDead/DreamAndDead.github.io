# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-29T14:23:41.275Z

## User

需要多少个context

## Assistant

需要多少个 Context（执行上下文）并没有一个绝对的答案，它完全取决于你的项目需求。但可以确定的是，**通常情况下你不需要为每个脚本对象或每个逻辑创建一个全新的 Context**。

它更像一个可复用的“执行器”，具体需要多少，取决于你的并发模型和性能要求。下面我会从官方建议、核心机制、以及不同使用场景来帮你分析。

### 📖 官方建议：没有数量限制，但要学会复用

AngelScript 官方文档明确指出，应用可以拥有任意数量的 Context，但“绝大多数应用可能只需要一个”[-1](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_overview.html)。之所以推荐复用，是因为 Context 是一个“重量级”对象，设计上就是为了重复使用，而不是频繁创建和销毁[-3](https://angelcode.com/angelscript/sdk/docs/manual/doc_finetuning.html?_x_tr_sch=http)[-5](https://developer.baidu.com/article/detail.html?id=7000845)[-6](https://git.p-epsilon.com/Deukhoofd/Angelscript/raw/commit/c1aea152542dbfbf868b6531d7eddb211d6aa0c8/docs/manual/doc_finetuning.html#doc_finetuning_3)。

### 🔧 核心机制：一个 Context 同一时间只能做一件事

理解这个机制对决定数量至关重要。一个 `asIScriptContext` 实例在任意时刻只能执行一个脚本函数。如果你尝试在它还没执行完上一个任务时，就调用 `Prepare` 准备执行新任务，引擎会报错 `asCONTEXT_ACTIVE`[-2](https://gamedev.net/forums/topic/292679-multiple-contexts/)[-4](https://gamedev.net/forums/topic/719615-how-to-fully-reset-a-context/5472946/)。

因此，需要多少个 Context，本质上取决于你期望**同时执行**多少个脚本任务。

### 🧩 场景一：串行执行（推荐方案）

如果你的游戏逻辑是顺序执行的，比如主循环里依次更新 AI、物理、UI，那么**一个 Context 就足够了**。你可以复用这一个 Context 来调用不同的脚本函数，这会最大程度地节省资源。

这种模式也支持 **“嵌套调用” \(Nested Calls\)**。比如，当脚本调用的 C\+\+ 函数内部需要再次执行另一个脚本函数时，可以通过 `PushState` 和 `PopState` 暂停当前状态，复用同一个 Context 来完成这次嵌套调用，而无需创建新的 Context[-3](https://angelcode.com/angelscript/sdk/docs/manual/doc_finetuning.html?_x_tr_sch=http)[-6](https://git.p-epsilon.com/Deukhoofd/Angelscript/raw/commit/c1aea152542dbfbf868b6531d7eddb211d6aa0c8/docs/manual/doc_finetuning.html#doc_finetuning_3)。

### 🧵 场景二：并发与协程（按需分配）

如果你的游戏需要“同时”运行多个独立的脚本（例如，几十个敌人的 AI 脚本），就需要考虑多个 Context。

-
**并发执行 \(Concurrency\)**：多个 Context 可以模拟“并行”效果。你可以在游戏循环的每一帧，依次让每个 Context 执行一小段时间（例如调用 `ctx->Execute()`），从而实现类似多线程的效果。需要注意的是，AngelScript 的 Context 本身**不是线程安全**的，不能在一个线程中执行一个 Context，同时在另一个线程中执行另一个[-7](http://contagion-game.com/api/manual/doc_adv_multithread.html)。通常的用法是在单帧内轮流执行它们[-2](https://gamedev.net/forums/topic/292679-multiple-contexts/)。
-
**协程 \(Co-routines\)**：使用多个 Context 还可以轻松实现协程。每个协程拥有自己的 Context，通过主动 `Suspend`（挂起）自己，让出执行权给下一个协程，从而实现协作式多任务[-9](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_adv_coroutine.html)。

### 💡 量化参考与最佳实践

虽然没有精确的公式，但可以参照以下建议来规划：

1.
**从“Context 池 \(Context Pool\)”开始**：这是官方最推荐的做法。不要直接 `new` Context，而是维护一个池子[-3](https://angelcode.com/angelscript/sdk/docs/manual/doc_finetuning.html?_x_tr_sch=http)[-6](https://git.p-epsilon.com/Deukhoofd/Angelscript/raw/commit/c1aea152542dbfbf868b6531d7eddb211d6aa0c8/docs/manual/doc_finetuning.html#doc_finetuning_3)。需要执行脚本时，从池子里“借”一个空闲的 Context；执行完毕，重置并“归还”到池中。这能显著降低频繁创建销毁的开销。

-
一个简单的实现可以参考官方文档，通过 `RequestContextCallback` 和 `ReturnContextToPool` 来管理[-3](https://angelcode.com/angelscript/sdk/docs/manual/doc_finetuning.html?_x_tr_sch=http)[-6](https://git.p-epsilon.com/Deukhoofd/Angelscript/raw/commit/c1aea152542dbfbf868b6531d7eddb211d6aa0c8/docs/manual/doc_finetuning.html#doc_finetuning_3)。
2.
**处理返回的对象**：当你通过 Context 执行脚本，并且脚本返回了一个对象句柄时，需要注意：Context 本身在 `Release` 之前会持有该对象的一个引用[-4](https://gamedev.net/forums/topic/719615-how-to-fully-reset-a-context/5472946/)。正确的做法是，在 `Release` Context 之前，先将返回的对象添加到你的 C\+\+ 引用中（例如调用 `obj->AddRef()`），然后再释放 Context。
3.
**使用辅助管理器**：对于复杂的多脚本管理场景，AngelScript 官方提供了一个 `CContextMgr` 辅助类（位于 `add_on/contextmgr/`），它可以帮你管理多个 Context 的调度、休眠和协程，你不需要完全从头开始实现[-8](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_addon_ctxmgr.html)。
4.
**性能与复杂度的权衡**：最后，也要考虑开发的实际情况。如果一个游戏对象真的需要一个独立的、长期运行的 Context 才符合你的设计，那也可以这样做。官方论坛的讨论中也提到，“如果你的性能需求没那么极致，为每次调用创建新 Context 完全可行”[-4](https://gamedev.net/forums/topic/719615-how-to-fully-reset-a-context/5472946/)，这可以简化代码逻辑，用轻微的运行时开销换取更清晰的架构[-4](https://gamedev.net/forums/topic/719615-how-to-fully-reset-a-context/5472946/)。

你的项目中大概需要同时执行多少个脚本？如果方便描述一下具体场景（比如几十个敌人AI，还是少数几个系统脚本），我可以帮你分析一个更具体的数量方案。
