# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-30T04:32:30.766Z

## User

getglobalpropertycount

## Assistant

`GetGlobalPropertyCount` 是 `asIScriptEngine` 接口中的一个方法，它的作用是**返回通过 `RegisterGlobalProperty` 从 C\+\+ 端注册到整个脚本引擎中的全局属性的总数**[-1](https://www.contagion-game.com/api/manual/doc_adv_reflection.html)[-2](https://angelcode.com/angelscript/sdk/docs/manual/classas_i_script_engine.html?_x_tr_sch=http)[-7](https://angelcode.com/angelscript/sdk/docs/manual/doc_register_prop.html)。

### 🆚 核心区别：`GetGlobalPropertyCount` vs `GetGlobalVarCount`

这两个名字相似的方法，分别属于不同的接口，访问的是完全不同来源的全局变量。

| 接口与方法 | 所属接口 | 统计的对象 | 如何注册 |
| --- | --- | --- | --- |
| **`GetGlobalPropertyCount`** | `asIScriptEngine`[-2](https://angelcode.com/angelscript/sdk/docs/manual/classas_i_script_engine.html?_x_tr_sch=http) | 在 **C\+\+ 端**注册的全局属性[-1](https://www.contagion-game.com/api/manual/doc_adv_reflection.html)[-7](https://angelcode.com/angelscript/sdk/docs/manual/doc_register_prop.html) | `engine->RegisterGlobalProperty(...)`[-7](https://angelcode.com/angelscript/sdk/docs/manual/doc_register_prop.html) |
| **`GetGlobalVarCount`** | `asIScriptModule`[-5](https://angelcode.com/angelscript/sdk/docs/manual/classas_i_script_module.html#ab16a29831b08294423390a8170605523) | 在 **脚本文件**里定义的全局变量[-1](https://www.contagion-game.com/api/manual/doc_adv_reflection.html)[-3](https://www.gamedev.net/forums/topic/592841-angelscript-variable-decomposition/4758803/&quot;http://www.angelcode.com/angelscript/sdk/docs/manual/&quot;http://www.angelcode.com/angelscript/sdk/docs/manual/doc_debug.html&quot;) | 脚本中的 `int myGlobal;` 声明 |

所以，`GetGlobalPropertyCount` 是针对由宿主程序（你的 C\+\+ 代码）**统一注册**、对所有模块可见的全局属性。例如，你可以用 `engine->RegisterGlobalProperty("int appVersion", &g_version);` 注册后，所有脚本模块就都能访问 `appVersion` 这个变量了。

### 💡 相关方法与典型用途

获取总数量通常是为了遍历它们，具体使用时会配合 `GetGlobalPropertyByIndex` 来获取每个属性的名称、类型、指针等信息[-2](https://angelcode.com/angelscript/sdk/docs/manual/classas_i_script_engine.html?_x_tr_sch=http)。一个典型的遍历模式是：

cpp

```cpp
asUINT count = engine->GetGlobalPropertyCount();
for (asUINT i = 0; i < count; i++) {
const char *name;
int typeId;
void *pointer;
engine->GetGlobalPropertyByIndex(i, &name, nullptr, &typeId, nullptr, nullptr, &pointer, nullptr);
// 现在可以处理每个全局属性了...
}
```

### ⚠️ 重要提示：关于“属性”的生命周期

一个需要留意的细节是：**通过 `RegisterGlobalProperty` 注册的属性，其对应的 C\+\+ 变量生命周期必须比 AngelScript 引擎更长**[-7](https://angelcode.com/angelscript/sdk/docs/manual/doc_register_prop.html)。如果你注册了一个指向某个对象的指针，但这个对象后来被销毁了，而脚本仍然持有这个指针，就会导致悬空指针访问和崩溃。

如果需要动态管理这些属性（比如为不同的场景注册不同的全局变量），官方文档推荐使用 **配置组（Configuration Groups）** 来实现[-8](https://gamedev.net/forums/topic/628377-global-properties-and-modules/)。通过 `BeginConfigGroup` 和 `EndConfigGroup` 将属性分组成不同的逻辑单元，方便后续的批量添加和删除。
