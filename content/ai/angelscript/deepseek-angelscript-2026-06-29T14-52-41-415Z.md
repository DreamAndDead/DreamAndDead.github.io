# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-29T14:52:41.416Z

## User

还有其他类似的宏吗

## Assistant

除了 `#include`，AngelScript 本身还支持一些其他的预处理指令。不过它的预处理器系统相对轻量，和 C/C\+\+ 的预处理器功能上有所区别。`CScriptBuilder` 这个辅助类提供了一套基础的预处理功能，主要包括下面这些：

| 指令 | 用途 | 说明 |
| --- | --- | --- |
| `#include` | 文件包含 | 你已经在用的指令，用于将其他脚本文件的内容包含进来[-1](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_samples_incl.html)[-3](https://angelcode.com/angelscript/sdk/docs/manual/doc_addon_build.html?_x_tr_sch=http)。 |
| `#if` / `#endif` | 条件编译 | 用于根据条件包含或排除代码块。常与通过 `CScriptBuilder::DefineWord()` 定义的宏配合使用[-3](https://angelcode.com/angelscript/sdk/docs/manual/doc_addon_build.html?_x_tr_sch=http)。 |
| `#ifdef` / `#ifndef` | 条件编译 | 检查某个宏是否已被定义，以决定是否编译后续代码[-2](https://deepwiki.com/cvet/fonline/5.4-native-and-mono-scripting)[-10](https://deepwiki.com/cvet/fonline/5.4-preprocessor-system)。 |
| `#pragma` | 编译器指令 | 用于向编译器传递特定的指令，需要你在回调函数中自行处理逻辑[-3](https://angelcode.com/angelscript/sdk/docs/manual/doc_addon_build.html?_x_tr_sch=http)。 |
| `#error` / `#warning` / `#message` | 诊断信息 | 用于在编译时主动触发错误、警告或输出提示信息，帮助调试[-2](https://deepwiki.com/cvet/fonline/5.4-native-and-mono-scripting)[-10](https://deepwiki.com/cvet/fonline/5.4-preprocessor-system)。 |

### 🔧 几个核心指令的补充说明

-
**条件编译 \(`#if` / `#endif` 系列\)**：这个功能在你需要针对不同环境（比如开发环境和发布环境）编译不同脚本时非常有用[-3](https://angelcode.com/angelscript/sdk/docs/manual/doc_addon_build.html?_x_tr_sch=http)。你可以先在 C\+\+ 端通过 `builder.DefineWord("ENABLE_DEBUG_LOG")` 定义一个宏，然后在脚本里这样用：
angelscript

```angelscript
#if ENABLE_DEBUG_LOG
Print("当前状态: " + status);
#endif
```
这样，`Print` 语句就只在定义了 `ENABLE_DEBUG_LOG` 时才会被编译进去[-3](https://angelcode.com/angelscript/sdk/docs/manual/doc_addon_build.html?_x_tr_sch=http)。
-
**自定义 `#pragma` 指令**：`CScriptBuilder` 提供了 `SetPragmaCallback` 接口，让你可以自己处理 `#pragma` 指令。如果你的引擎需要一些特殊的编译指示（比如“这个脚本需要多少栈空间”），你可以通过这个机制来实现[-3](https://angelcode.com/angelscript/sdk/docs/manual/doc_addon_build.html?_x_tr_sch=http)。
-
**关于 `#define`**：官方提供的 `CScriptBuilder` **默认不支持 `#define`**[-3](https://angelcode.com/angelscript/sdk/docs/manual/doc_addon_build.html?_x_tr_sch=http)。这个功能相对复杂，官方将它留给了开发者自行扩展，以保持核心功能的轻量。你可以在网上找到社区成员提供的增强版 `CScriptBuilder`，它增加了对 `#define` 和 `#undef` 的支持，但需要注意它对于复杂的宏定义（比如带参数的宏）支持程度可能有限[-7](https://gamedev.net/forums/topic/640629-cc-like-define-directive-patch-attached/?_k=880ea6a14ea49e853634fbdc5015a024&forceDownload=1)。

总的来说，`CScriptBuilder` 提供了一套基础的 C 风格预处理器功能，能够满足大部分脚本组织的需求。不过它为了保持简洁，在功能上（例如 `#define`）做了一定的取舍和简化。

你是想实现类似 `#define` 这样的常量定义功能吗？我可以针对你的具体需求，帮你看看是可以用现有功能替代，还是需要参考社区方案进行定制。
