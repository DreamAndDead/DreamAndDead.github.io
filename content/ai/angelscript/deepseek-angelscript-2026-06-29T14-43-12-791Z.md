# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-29T14:43:12.791Z

## User

build module  需要每次都执行吗

## Assistant

不一定。`BuildModule`（或 `asIScriptModule::Build`）**只需要在脚本源码发生改变时才执行**。它是一个相对耗时的操作，因为需要解析源码、构建抽象语法树并生成字节码[-2](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_build.html?_x_tr_sch=http)[-4](https://www.gamedev.net/forums/topic/382652-build-and-addscriptsection/)。

如果模块没有变化，可以通过使用**预编译字节码（Precompiled Bytecode）**来完全跳过 `Build` 步骤。

### 💡 方案一：保存并加载预编译字节码

这是最常用的优化方案。你可以在开发期或首次运行时执行一次 `Build`，然后通过 `SaveByteCode` 将编译好的字节码保存到文件中[-5](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_precompile.html)。之后程序启动时，直接调用 `LoadByteCode` 加载这个文件，就能完全跳过编译过程[-5](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_precompile.html)[-6](https://www.gamedev.net/forums/topic/379483-asibinarystream-read/)。

cpp

```cpp
// 保存字节码（通常只需执行一次）
asIScriptModule* mod = engine->GetModule("MyModule");
mod->Build();
mod->SaveByteCode(&stream); // stream 是你实现的 asIBinaryStream

// 加载字节码（每次启动时执行，跳过 Build）
asIScriptModule* mod = engine->GetModule("MyModule", asGM_ALWAYS_CREATE);
mod->LoadByteCode(&stream); // 直接从字节码恢复模块
```

**注意事项**：

-
**环境必须一致**：加载字节码时，C\+\+ 端注册的所有类型、函数、属性必须与编译时**完全一致**，否则加载会失败[-5](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_precompile.html)。
-
**安全性考虑**：预编译字节码绕过了编译时的安全检查，如果被篡改可能存在安全风险。官方建议在加载前进行身份验证或校验和检查[-5](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_precompile.html)[-7](https://gamedev.net/forums/topic/515269-how-to-get-a-bytecode-file-/?comment=4351937&do=findComment)。
-
**平台兼容性**：虽然 AngelScript 会处理大部分平台差异（如指针大小、大小端），但 `bool` 类型的大小可能因平台而异，且浮点表示法差异无法处理[-5](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_precompile.html)[-8](https://www.gamedev.net/forums/topic/515269-how-to-get-a-bytecode-file/4352200)。

### 🧩 方案二：仅在源码变更时构建

如果你的脚本是 `.as` 源文件形式存在，并且希望在开发期保持热加载能力，那么就需要在检测到文件修改时重新执行 `Build`。这种“按需构建”在需要频繁修改脚本的开发场景中非常常见[-2](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_build.html?_x_tr_sch=http)。

### ⚙️ 方案三：混合策略（生产环境的最佳实践）

很多成熟引擎会结合两种方式[-1](http://angelscript.hazelight.se/cpp-bindings/precompiled-data/)：

-
**开发阶段**：直接从 `.as` 源文件构建 \(`Build`\)，方便热加载和调试。
-
**发布版本**：打包时生成预编译字节码缓存，运行时直接 `LoadByteCode`，以优化启动速度。

此外，如果你的游戏需要编译大量脚本文件，预编译字节码可以显著减少最终用户的加载等待时间，尤其是在 CPU 和硬盘性能较慢的平台上[-1](http://angelscript.hazelight.se/cpp-bindings/precompiled-data/)。

> 注意：调用 `Build()` 会清除并重新编译模块中之前添加的所有脚本代码[-3](https://gamedev.net/forums/topic/624423-ascmodulebuild-now-deletes-previous-scripts-before-compiling-new/)[-4](https://www.gamedev.net/forums/topic/382652-build-and-addscriptsection/)，因此应当先通过 `AddScriptSection` 添加所有需要的脚本文件，最后再执行一次 `Build`。
