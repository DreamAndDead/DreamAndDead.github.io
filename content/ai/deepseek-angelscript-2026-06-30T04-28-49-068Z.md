# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-30T04:28:49.068Z

## User

compilefunction

## Assistant

`asIScriptModule::CompileFunction` 允许你在一个**已经编译好的模块**中，动态地添加一个新的函数，而无需重新编译整个模块[-1](https://angelcode.com/angelscript/sdk/docs/manual/classas_i_script_module.html#ab16a29831b08294423390a8170605523)[-2](https://angelcode.com/angelscript/sdk/docs/manual/doc_samples_console.html?_x_tr_sch=http)[-10](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_build.html?_x_tr_sch=http)。这对于实现控制台命令、调试工具或动态扩展功能非常有用[-2](https://angelcode.com/angelscript/sdk/docs/manual/doc_samples_console.html?_x_tr_sch=http)[-5](https://www.gamedev.net/forums/topic/579484-add-functions-to-module/4691517/)。

### 核心用法

它的函数签名和参数含义如下[-1](https://angelcode.com/angelscript/sdk/docs/manual/classas_i_script_module.html#ab16a29831b08294423390a8170605523)：

cpp

```cpp
virtual int CompileFunction(
const char *sectionName,    // 用于调试的代码段名称
const char *code,           // 函数体代码
int lineOffset,             // 错误报告的行偏移量
asDWORD compileFlags,       // 编译标志，如 asCOMP_ADD_TO_MODULE
asIScriptFunction **outFunc // [可选] 接收编译后的函数对象
) = 0;
```

-
**`asCOMP_ADD_TO_MODULE`**: 使用此标志，编译后的函数会被添加到模块的作用域中，后续可以通过 `GetFunctionByDecl` 等方法找到它[-9](https://www.gamedev.net/forums/topic/655527-compilefunction-question/5147073/)。
-
**`outFunc`**: 如果你只想临时执行一个函数，可以传一个指针来接收函数对象，之后手动 `Release()` 即可[-1](https://angelcode.com/angelscript/sdk/docs/manual/classas_i_script_module.html#ab16a29831b08294423390a8170605523)。

### 重要行为与限制

`CompileFunction` 与 `AddScriptSection` \+ `Build` 的工作方式有根本不同，理解这点至关重要：

-
**真正地“增量添加”**：调用 `Build()` 会清除模块中**所有**之前编译的代码（包括 `CompileFunction` 添加的），然后基于 `AddScriptSection` 的脚本片段重新构建[-9](https://www.gamedev.net/forums/topic/655527-compilefunction-question/5147073/)。而 `CompileFunction` 是在现有模块上增量添加，不会影响已有的代码[-5](https://www.gamedev.net/forums/topic/579484-add-functions-to-module/4691517/)[-10](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_build.html?_x_tr_sch=http)。
-
**可被后续调用看见**：如果用 `asCOMP_ADD_TO_MODULE` 添加的函数，可以被后续 `CompileFunction` 调用，实现逐步扩展[-9](https://www.gamedev.net/forums/topic/655527-compilefunction-question/5147073/)。
-
**无法修改类**：这是一个重要限制，`CompileFunction` 只能添加新的**全局函数**，不能用来修改已有的类或添加新类[-5](https://www.gamedev.net/forums/topic/579484-add-functions-to-module/4691517/)。

### 常见误区

一个常见的误解是，如果先用 `AddScriptSection` 添加了脚本，再用 `CompileFunction` 添加函数，最后调用 `Build()`，这些动态添加的函数会丢失。正如前文所述，**`Build()` 会清除所有动态编译的内容**，所以 `CompileFunction` 更适用于模块已经构建完成后的动态扩展[-9](https://www.gamedev.net/forums/topic/655527-compilefunction-question/5147073/)。
