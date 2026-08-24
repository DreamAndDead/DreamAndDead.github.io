# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-30T04:34:23.309Z

## User

详细展开配置组

## Assistant

AngelScript 的配置组（Configuration Group）是一个支持动态加载/卸载 API 集合的机制，主要用于插件系统和接口隔离[-1](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_config.html?_x_tr_sch=http)。它允许你将注册的函数、类型、全局属性等接口打包成一个逻辑单元，可以在运行时整体添加或移除，而无需重新初始化整个引擎。

### 核心用法：创建与移除

使用配置组的过程很简单，就像用括号把一组注册代码包起来：

cpp

```cpp
// 1. 开始一个配置组
engine->BeginConfigGroup("MyPlugin");

// 2. 在这个组内注册所有插件需要的接口
engine->RegisterGlobalFunction("void pluginFunc()", asFUNCTION(PluginFunc), asCALL_CDECL);
engine->RegisterObjectType("PluginType", sizeof(PluginType), asOBJ_REF);
// ...

// 3. 结束配置组
engine->EndConfigGroup();

// ... 当插件卸载时 ...
// 4. 移除整个配置组，清理所有注册的接口
engine->RemoveConfigGroup("MyPlugin");
```

### 关键行为与限制

1.
**对象类型（Object Type）的归属是“全局”的**：这是一个非常重要的规则。一个对象类型的**所有**方法、属性和行为（behaviours），都会被注册到该对象类型**首次注册时所在的配置组**[-1](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_config.html?_x_tr_sch=http)[-5](https://gamedev.net/forums/topic/636396-config-groups-and-object-property-accessors/)。这意味着你不能在 `BeginConfigGroup("GroupA")` 里注册一个类，然后又在 `BeginConfigGroup("GroupB")` 里为这个类单独添加一个方法。**如果你需要通过配置组动态管理一个类的方法，那么这个类的完整定义（包括所有方法和属性）必须放在同一个配置组中**。当你需要修改时，需要移除整个组，然后重新注册完整的类[-5](https://gamedev.net/forums/topic/636396-config-groups-and-object-property-accessors/)。
2.
**组不能被嵌套**：在调用 `EndConfigGroup()` 结束当前组之前，不能再调用 `BeginConfigGroup()` 开始新的组[-1](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_config.html?_x_tr_sch=http)。

### `RemoveConfigGroup` 的清理难题与解决之道

移除配置组时可能会遇到 `asCONFIG_GROUP_IS_IN_USE` 错误，表示该组仍在被使用[-1](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_config.html?_x_tr_sch=http)[-3](https://www.gamedev.net/forums/topic/348628-config-group-question/)。要成功移除，需要彻底清理所有依赖：

-
**丢弃相关的脚本模块**：任何编译时使用了该配置组接口的 `asIScriptModule` 都必须先被 `DiscardModule`[-1](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_config.html?_x_tr_sch=http)。
-
**销毁所有脚本对象**：所有基于该组中类型创建的 `asIScriptObject` 实例都必须释放。
-
**执行垃圾回收**：调用 `engine->GarbageCollect(asGC_FULL_CYCLE)` 强制清理可能仍持有引用的对象[-1](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_config.html?_x_tr_sch=http)。
-
**检查其他组的依赖**：确保没有其他配置组引用了本组中注册的类型[-1](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_config.html?_x_tr_sch=http)。

### 💡 演进：从配置组到访问掩码 \(Access Mask\)

配置组在早期版本中，也承担了**权限控制**的角色（`SetConfigGroupModuleAccess`），但这种方式粒度较粗。从 AngelScript 2.22.0 开始，官方引入了更灵活的**访问掩码（Access Mask）**机制[-8](https://www.gamedev.net/forums/topic/614471-angelscript-2220-is-released/4881640/)[-9](https://gamedev.net/forums/topic/614471-angelscript-2220-is-released/)。新机制使用位掩码来为每个注册的实体（函数、类型、方法等）打上“标签”，模块在编译时也设置自己的掩码，两者通过按位与（bitwise AND）运算来决定模块能否访问该实体[-10](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_adv_access_mask.html)。

> **关键区别**：
>
> -
> **配置组** 主要用于 **“逻辑分组和批量生命周期管理”**（即“一起注册，一起移除”）。
> -
> **访问掩码** 用于 **“细粒度的运行时权限控制”**（即“这个模块能看到哪些函数”）。

在较新的 AngelScript 版本中，权限控制应优先使用 `SetDefaultAccessMask` 和 `asIScriptModule::SetAccessMask` 来实现[-10](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_adv_access_mask.html)。
