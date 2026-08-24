# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-30T04:39:05.597Z

## User

如何一起使用，给一个示例

## Assistant

在 AngelScript 中，**配置组（Config Group）** 和 **访问掩码（Access Mask）** 的分工非常明确：配置组负责“打包和卸载”，访问掩码负责“权限控制”。它们配合使用，既能实现接口的动态加载/卸载，又能精细控制不同模块的访问权限。

下面我通过一个“插件系统”的示例，来演示它们是如何协同工作的。

---

### 📝 场景：一个包含“公共”和“开发者”两种角色的插件系统

假设我们有一个插件系统，其中的 API 分为两类：

-
**公共 API**：所有插件都能使用。
-
**开发者 API**：仅对部分高级插件开放。

我们希望在运行时动态加载/卸载这些插件，并控制它们的权限。

---

### 🧩 第一步：注册接口时，用配置组打包，用掩码标记权限

cpp

```cpp
// 1. 注册公共 API（所有脚本都可访问）
engine->BeginConfigGroup("PublicAPI");   // ① 开始一个配置组
engine->SetDefaultAccessMask(1 << 0);     // ② 设置掩码：bit 0 = 公共权限
engine->RegisterGlobalFunction("void log(string msg)", asFUNCTION(Log), asCALL_CDECL);
engine->RegisterObjectType("Vector3", ...);
engine->EndConfigGroup();                 // ③ 结束配置组

// 2. 注册开发者 API（仅对特权插件开放）
engine->BeginConfigGroup("DevAPI");
engine->SetDefaultAccessMask(1 << 1);     // bit 1 = 开发者权限
engine->RegisterGlobalFunction("void setDevMode(bool)", asFUNCTION(SetDevMode), asCALL_CDECL);
engine->RegisterGlobalProperty("int g_engineVersion", &g_engineVersion);
engine->EndConfigGroup();
```

> **关键点**：每个配置组内，通过 `SetDefaultAccessMask` 标记了该组接口的“权限标签”。一个配置组内的所有接口，可以被统一移除；而掩码则决定了哪些模块可以使用这些接口。

---

### 🧩 第二步：编译脚本模块时，设置其访问掩码

cpp

```cpp
// 1. 编译一个“普通插件”，只能访问公共 API
asIScriptModule* modCommon = engine->GetModule("CommonPlugin", asGM_ALWAYS_CREATE);
modCommon->SetAccessMask(1 << 0);          // 只允许访问 bit 0 标记的接口
// ... 添加脚本代码并编译 ...

// 2. 编译一个“开发者插件”，可以同时访问公共和开发者 API
asIScriptModule* modDev = engine->GetModule("DevPlugin", asGM_ALWAYS_CREATE);
modDev->SetAccessMask((1 << 0) | (1 << 1)); // 组合掩码：允许访问 bit 0 或 bit 1
// ... 添加脚本代码并编译 ...
```

> **关键点**：模块的掩码决定了它能访问哪些“标签”的接口。只有接口的掩码与模块的掩码按位与（`&`）结果不为 0，该模块才能使用该接口。

---

### 🧩 第三步：动态卸载时，用配置组批量移除

cpp

```cpp
// 当插件 "DevPlugin" 被卸载时
void UnloadDevPlugin() {
// 1. 丢弃使用这些接口的模块
engine->DiscardModule("DevPlugin");
// 2. 强制垃圾回收，清理可能存活的脚本对象
engine->GarbageCollect(asGC_FULL_CYCLE);
// 3. 移除配置组，卸载接口
engine->RemoveConfigGroup("DevAPI"); // 只卸载开发者 API
// 注意：PublicAPI 仍然保留，供其他模块使用
}
```

> **关键点**：`RemoveConfigGroup("DevAPI")` 只会移除 `DevAPI` 组中注册的所有接口，而不会影响 `PublicAPI` 组。这实现了“精确卸载”，而不是一刀切地清理所有接口。

---

### 🧩 第四步：验证与调试

-
**权限验证**：如果 `CommonPlugin` 的脚本中错误地调用了 `setDevMode(true)`，`Build()` 会失败并返回错误码，你可以通过消息回调捕获并定位。
-
**安全卸载**：如果 `RemoveConfigGroup` 返回 `asCONFIG_GROUP_IS_IN_USE`，说明仍有脚本对象或模块在引用该组的接口，你需要先清理它们。

---

### 💎 总结

这个示例展示了配置组和访问掩码最典型的协作模式：

1.
**配置组负责“生命周期”**：`BeginConfigGroup` / `EndConfigGroup` 将相关接口打包，`RemoveConfigGroup` 实现批量卸载。
2.
**访问掩码负责“权限控制”**：在配置组内通过 `SetDefaultAccessMask` 为接口设置标签，在编译模块时通过 `SetAccessMask` 控制它能访问哪些标签的接口。

这种组合让你既能动态加载/卸载接口，又能精细控制不同模块的权限，非常适合构建插件系统或需要热更新的游戏脚本环境。😊
