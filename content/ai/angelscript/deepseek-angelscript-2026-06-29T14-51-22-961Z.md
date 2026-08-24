# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-29T14:51:22.961Z

## User

#include 是自动解析的吗

## Assistant

是的，`#include` 是被自动解析和处理的，但这需要依靠 **`CScriptBuilder`** 这个辅助类来完成。AngelScript 核心引擎本身并不处理文件读取，是 `CScriptBuilder` 提供了这个能力[-1](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_addon_build.html#doc_addon_build_metadata)[-7](http://contagion-game.com/api/manual/doc_hello_world.html)。

它的工作方式和常见的 C/C\+\+ 预处理器类似，默认行为非常直接：

-
**自动解析与加载**：当你在脚本中使用 `#include "common.as"` 时，`CScriptBuilder` 会在执行 `BuildModule()` 时自动找到并加载这个文件，将它的内容合并到当前模块中[-1](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_addon_build.html#doc_addon_build_metadata)[-4](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_samples_incl.html)。
-
**相对路径解析**：默认情况下，`CScriptBuilder` 会以被包含文件所在的目录为基准，来解析相对路径[-1](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_addon_build.html#doc_addon_build_metadata)。也就是说，如果主脚本在 `scripts/` 目录下，`#include "utils/common.as"` 就会去加载 `scripts/utils/common.as`。
-
**防止重复包含**：它内部会进行记录，确保同一个文件不会被重复添加，避免了多重定义的问题[-1](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_addon_build.html#doc_addon_build_metadata)[-4](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_samples_incl.html)[-8](https://www.gamedev.net/forums/topic/535691-ctor-call-problem-using-scriptbuilder/4461224/)。

### 如何自定义 \#include 行为

虽然默认行为很方便，但你可能需要更复杂的逻辑，比如从内存加载，或者支持多个搜索路径。`CScriptBuilder` 为此提供了**包含回调 \(Include Callback\)** 机制[-1](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_addon_build.html#doc_addon_build_metadata)[-3](https://git.p-epsilon.com/Deukhoofd/AngelscriptLanguageServer/raw/commit/7fec8e43e9adc639179f0405fad3acdf9d4c09c4/server/src/angelscript/extensions/scriptbuilder/scriptbuilder.h)。

你可以通过 `SetIncludeCallback` 方法注册一个自己的函数。当 `CScriptBuilder` 遇到 `#include` 指令时，就会调用这个回调，让你来决定如何处理这个文件[-1](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_addon_build.html#doc_addon_build_metadata)[-2](https://www.gamedev.net/forums/topic/542021-script-builder-includes/%22http%3A//www.gamedev.net/blog/788-wavesonics-pseudo-random-journal-generator/%22)：

cpp

```cpp
// 自定义的包含回调函数
int MyIncludeCallback(const char *include, const char *from, CScriptBuilder *builder, void *userParam)
{
// include: 要包含的文件名，如 "common.as"
// from: 当前正在编译的脚本文件名
// builder: 当前的 CScriptBuilder 实例

// 你可以在这里实现自定义逻辑，例如：
// 1. 转换路径或从多个目录查找
// 2. 从内存中加载脚本内容
// 3. 动态生成脚本代码

// 最后，通过 builder 将文件内容加入编译
return builder->AddSectionFromFile("custom_path/" + std::string(include));
}

// 在构建模块前注册回调
builder.SetIncludeCallback(asFUNCTION(MyIncludeCallback), nullptr);
```

这种方式非常灵活，你可以完全控制 `#include` 的解析过程[-2](https://www.gamedev.net/forums/topic/542021-script-builder-includes/%22http%3A//www.gamedev.net/blog/788-wavesonics-pseudo-random-journal-generator/%22)[-3](https://git.p-epsilon.com/Deukhoofd/AngelscriptLanguageServer/raw/commit/7fec8e43e9adc639179f0405fad3acdf9d4c09c4/server/src/angelscript/extensions/scriptbuilder/scriptbuilder.h)。
