# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-29T03:10:27.726Z

## User

register function in congiguration group

## Assistant

在 AngelScript 中，通过 **配置组（Configuration Group）** 来注册函数，可以让你在运行时更灵活地管理接口。这对于插件系统、关卡加载等场景非常有用，因为你可以随时注册或移除一组功能，而不需要重新初始化整个引擎[-1](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_config.html)。

### 🔧 核心方法：`BeginConfigGroup` 与 `EndConfigGroup`

使用配置组注册函数的步骤非常直接，只需将注册代码放在 `BeginConfigGroup` 和 `EndConfigGroup` 调用之间即可：

cpp

```cpp
// 开始一个名为 "MyPlugin" 的配置组
int r = engine->BeginConfigGroup("MyPlugin");
assert(r >= 0);

// 在这个组中注册函数
r = engine->RegisterGlobalFunction("void doSomething()", asFUNCTION(DoSomething), asCALL_CDECL);
assert(r >= 0);

// 还可以注册全局变量、类型等
// r = engine->RegisterGlobalProperty("int pluginVar", &myVar);
// assert(r >= 0);

// 结束配置组
r = engine->EndConfigGroup();
assert(r >= 0);
```

此后，所有在 `BeginConfigGroup` 和 `EndConfigGroup` 之间注册的接口（函数、类型、属性等）都会归属于 `"MyPlugin"` 这个组[-1](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_config.html)。

### ⚠️ 重要限制：对象类型方法的绑定

有一个关键限制需要特别注意：**对象类型（Object Type）的方法、属性和行为，会始终和该对象类型注册时所在的配置组绑定在一起**[-1](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_config.html)[-9](https://gamedev.net/forums/topic/636396-config-groups-and-object-property-accessors/)。

这意味着，如果你想为 `Player` 类动态添加 `Jump()` 方法，不能只在新的配置组里注册这个方法。正确做法是：将 `Player` 类的完整定义（包括所有方法和属性）放在一个配置组里。当需要修改时，移除整个旧组，再将新的完整 `Player` 类定义注册到一个新组中[-9](https://gamedev.net/forums/topic/636396-config-groups-and-object-property-accessors/)。

### 🧹 移除配置组

想要安全地移除一个配置组，需要确保**没有任何脚本模块或脚本对象**仍在使用该组中的任何接口[-1](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_config.html)。如果 `RemoveConfigGroup` 返回 `asCONFIG_GROUP_IS_IN_USE` 错误，通常需要按以下顺序进行清理：

1.
**丢弃所有相关的脚本模块**：调用 `engine->DiscardModule()` 丢弃所有可能编译了该组接口的模块[-1](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_config.html)[-8](https://gamedev.net:443/forums/topic/364094-issue-with-config-groups/)。
2.
**终止并释放所有正在运行的脚本上下文**：确保没有上下文正在执行使用该组接口的脚本函数[-8](https://gamedev.net:443/forums/topic/364094-issue-with-config-groups/)。
3.
**执行垃圾回收**：调用 `engine->GarbageCollect()` 来销毁那些可能还持有相关引用的脚本对象[-1](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_config.html)[-8](https://gamedev.net:443/forums/topic/364094-issue-with-config-groups/)。

cpp

```cpp
// 尝试移除配置组前进行清理
engine->DiscardModule("MyModule");
// 假设你已释放所有运行中的上下文
engine->GarbageCollect();
int r = engine->RemoveConfigGroup("MyPlugin");
if (r < 0) {
// 处理错误，可能还有引用未被释放
printf("Failed to remove config group: %d\n", r);
}
```

### 💎 总结

在 AngelScript 中使用配置组注册函数的模式是：

1.
用 `BeginConfigGroup` 声明组名。
2.
在组内完成所有需要的 `RegisterGlobalFunction` 等注册操作。
3.
用 `EndConfigGroup` 关闭组。
4.
当需要卸载时，先清理所有依赖，最后调用 `RemoveConfigGroup`。

这样做能让你的 C\+\+ 引擎与脚本的交互更加模块化，方便实现插件或关卡逻辑的加载与卸载。
