# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-29T03:12:22.328Z

## User

针对不同的脚本，暴露不同的结果

## Assistant

针对不同脚本暴露不同接口，是构建灵活脚本系统的关键。AngelScript 的配置组（Configuration Group）机制正是为此设计的，它让你能够按需为不同模块注册不同的 C\+\+ 函数、类型和全局属性。

### 🧩 核心方案：为每个脚本模块使用独立的配置组

你可以在运行时为不同的脚本集合创建独立的配置组，注册它们专属的接口。核心流程如下：

1.
**开始一个配置组**：调用 `engine->BeginConfigGroup("GroupName")`。
2.
**注册该脚本专属的接口**：在组内注册所有需要的函数、类型等。
3.
**结束配置组**：调用 `engine->EndConfigGroup()`。
4.
**在编译脚本模块时应用该组**：在编译前，让模块仅可见特定配置组。

cpp

```cpp
// 为 "Level1" 脚本注册专用接口
engine->BeginConfigGroup("Level1");
engine->RegisterGlobalFunction("void level1_specific()", asFUNCTION(Level1Func), asCALL_CDECL);
engine->EndConfigGroup();

// 为 "Level2" 脚本注册不同接口
engine->BeginConfigGroup("Level2");
engine->RegisterGlobalFunction("void level2_specific()", asFUNCTION(Level2Func), asCALL_CDECL);
engine->EndConfigGroup();

// 编译 "Level1" 脚本时，应用其配置组
asIScriptModule *modLevel1 = engine->GetModule("Level1", asGM_ALWAYS_CREATE);
modLevel1->SetDefaultAccessMask(1 << 0); // 假设 Level1 组的掩码为 1

// 编译 "Level2" 脚本时，应用其配置组
asIScriptModule *modLevel2 = engine->GetModule("Level2", asGM_ALWAYS_CREATE);
modLevel2->SetDefaultAccessMask(1 << 1); // 假设 Level2 组的掩码为 2
```

### 🔑 核心机制：访问掩码 \(Access Mask\)

实现接口隔离的关键在于 **访问掩码（Access Mask）**。它的工作原理如下：

-
**每个配置组都有一个位掩码**：调用 `BeginConfigGroup` 后，AngelScript 会为该组分配一个唯一的位掩码（从1开始，每次左移一位）。
-
**每个注册项都记录其掩码**：注册的全局函数、方法等都会“记住”它所属配置组的掩码。
-
**模块编译时设置掩码**：通过 `asIScriptModule::SetDefaultAccessMask(mask)`，你可以控制该模块**仅能访问**哪些配置组中的接口。

> **注意**：`SetDefaultAccessMask` 是一个权限“白名单”。模块编译时，只会解析其掩码**包含**的配置组中注册的接口。

### 🛠️ 进阶实践：动态接口暴露

你可以构建一个更灵活的系统，将配置组与脚本模块动态绑定。例如：

cpp

```cpp
class ScriptManager {
std::unordered_map<std::string, int> groupMasks;
public:
// 创建一个配置组并返回其掩码
int CreateGroup(const std::string& name) {
engine->BeginConfigGroup(name.c_str());
// ... 注册特定接口
engine->EndConfigGroup();
// 获取并存储该组的掩码
int mask = 1 << (groupMasks.size() + 1);
groupMasks[name] = mask;
return mask;
}

// 使用指定的配置组编译脚本
bool CompileScript(const std::string& moduleName, const std::vector<std::string>& groupNames) {
asIScriptModule* mod = engine->GetModule(moduleName.c_str(), asGM_ALWAYS_CREATE);
// 组合多个组的掩码
int combinedMask = 0;
for (const auto& name : groupNames) {
combinedMask |= groupMasks[name];
}
mod->SetDefaultAccessMask(combinedMask);
// ... 添加脚本代码并编译
return mod->Build() >= 0;
}
};
```

### 🧪 验证与调试

-
**编译错误检查**：如果脚本使用了未在其模块掩码中暴露的接口，`Build()` 时会返回 `asERROR` 并提示 "Unresolved external function"。
-
**运行时检查**：在调试阶段，可以在 `asIScriptContext::Execute()` 后检查返回值，并利用 `GetExceptionString()` 获取更多信息。

### ⚠️ 避坑指南

-
**对象类型归属**：对象类型（类）的完整定义（包括所有方法和属性）必须在同一个配置组中注册。
-
**配置组移除的清理**：如果动态加载/卸载，务必先清理使用该组的所有模块和对象，再调用 `RemoveConfigGroup`，否则会返回 `asCONFIG_GROUP_IS_IN_USE` 错误。
-
**掩码位数限制**：访问掩码是 32 位的（在某些平台可能是 64 位），这意味着你最多可以有约 32 个不同的配置组。

### 💡 替代方案思考

如果配置组的动态特性不能满足你的需求（例如需要更精细的权限控制），也可以考虑以下方案：

-
**编译时条件 \(`#if ...`\)**：在脚本中使用预处理器宏，在编译前通过 `SetEngineProperty(asEP_USE_CHARACTERS)` 等设置特定宏的值。
-
**依赖注入**：通过 C\+\+ 端传递一个上下文对象给脚本，脚本通过该对象调用特定功能，而不是直接调用全局函数。

如果你在实现过程中遇到了具体问题，比如注册对象类型时的限制，或者访问掩码设置后脚本仍报错，可以告诉我具体的代码片段和错误信息，我帮你一起排查。😊
