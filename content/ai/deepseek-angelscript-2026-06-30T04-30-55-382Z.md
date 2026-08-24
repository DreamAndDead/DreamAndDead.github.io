# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-30T04:30:55.382Z

## User

getglobalvar

## Assistant

`GetGlobalVar` 是 `asIScriptModule` 接口提供的一个核心方法，用于在编译后的脚本模块中，**通过索引来查询全局变量的元信息**，比如它的名字、类型、是否常量等[-1](https://www.contagion-game.com/api/manual/doc_adv_reflection.html)[-3](https://angelcode.com/angelscript/sdk/docs/manual/classas_i_script_module.html#ab16a29831b08294423390a8170605523)[-10](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_reflection.html?_x_tr_sch=http)。

### 🔧 核心用法

它的函数签名和参数含义如下：

cpp

```cpp
virtual int GetGlobalVar(
asUINT index,            // [输入] 全局变量的索引
const char **name,       // [输出] 变量名称
const char **nameSpace,  // [输出] 变量的命名空间
int *typeId,             // [输出] 变量的类型 ID
bool *isConst            // [输出] 是否为常量
) const = 0;
```

-
**通过索引查询**：你需要先用 `GetGlobalVarCount()` 获取模块中全局变量的总数，然后遍历索引或使用 `GetGlobalVarIndexByName` / `GetGlobalVarIndexByDecl` 找到特定变量的索引，最后再调用 `GetGlobalVar` 获取其详细信息[-1](https://www.contagion-game.com/api/manual/doc_adv_reflection.html)[-10](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_reflection.html?_x_tr_sch=http)。

### 🧩 关联方法

在实际使用中，`GetGlobalVar` 通常会与以下方法配合使用，共同完成对全局变量的操作：

| 方法 | 作用 | 说明 |
| --- | --- | --- |
| **`GetAddressOfGlobalVar`** | 获取全局变量的内存地址 | 获取到地址后，你可以根据 `GetGlobalVar` 返回的 `typeId` 来解析和修改它的值[-1](https://www.contagion-game.com/api/manual/doc_adv_reflection.html)[-3](https://angelcode.com/angelscript/sdk/docs/manual/classas_i_script_module.html#ab16a29831b08294423390a8170605523)[-4](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_serialization.html)。 |
| **`GetGlobalVarCount`** | 获取全局变量的总数 | 用于遍历所有全局变量[-1](https://www.contagion-game.com/api/manual/doc_adv_reflection.html)[-3](https://angelcode.com/angelscript/sdk/docs/manual/classas_i_script_module.html#ab16a29831b08294423390a8170605523)[-10](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_reflection.html?_x_tr_sch=http)。 |
| **`GetGlobalVarIndexByName`** | 通过名称获取变量索引 | 是查询特定变量的常用入口[-1](https://www.contagion-game.com/api/manual/doc_adv_reflection.html)[-3](https://angelcode.com/angelscript/sdk/docs/manual/classas_i_script_module.html#ab16a29831b08294423390a8170605523)[-10](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_reflection.html?_x_tr_sch=http)。 |
| **`ResetGlobalVars`** | 重置所有全局变量 | 将模块中的所有全局变量恢复为初始值[-3](https://angelcode.com/angelscript/sdk/docs/manual/classas_i_script_module.html#ab16a29831b08294423390a8170605523)。 |

### 💡 常见使用场景

-
**调试与反射**：在开发调试工具时，可以通过它枚举并显示所有全局变量的状态，实现类似“控制台”的功能[-1](https://www.contagion-game.com/api/manual/doc_adv_reflection.html)[-10](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_reflection.html?_x_tr_sch=http)。
-
**序列化与存档**：游戏存档或模块热加载时，需要保存和恢复所有全局变量的值。流程是先用 `GetGlobalVar` 获取变量信息，再用 `GetAddressOfGlobalVar` 读取内存数据[-4](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_serialization.html)[-12](https://angelcode.com/angelscript/sdk/docs/manual/doc_addon_serializer.html?_x_tr_sch=http)。
-
**动态检查类型**：在 C\+\+ 端处理脚本传来的变量时，通过 `typeId` 判断其具体类型，以便进行正确的数据转换或处理。

### ⚠️ 与 `RegisterGlobalProperty` 的区别

一个容易混淆的地方是，`GetGlobalVar` 查询的是**脚本中定义的全局变量**（比如你写在 `.as` 文件里的 `int MyGlobal = 10;`）；而 `RegisterGlobalProperty` 注册的是**C\+\+ 端暴露给脚本的全局变量**（比如你从引擎注册的 `engine->RegisterGlobalProperty("int AppVersion", &version);`），这两者需要通过不同的接口来访问[-9](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_global.html#doc_global_enums)[-11](https://angelcode.com/angelscript/sdk/docs/manual/doc_register_prop.html)。
