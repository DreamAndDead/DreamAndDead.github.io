---
title: DeepSeek Export
---

# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-30T01:46:28.317Z

## User

getfactorybydecl

## Assistant

`GetFactoryByDecl` 是 AngelScript 中 `asITypeInfo` 接口提供的一个关键方法，用于根据**声明字符串**来获取脚本类的**工厂函数**。这个工厂函数本质上是一个特殊的全局函数，它的职责是创建并返回指定脚本类的新实例[-1](https://angelcode.com/angelscript/sdk/docs/manual/doc_use_script_class.html?_x_tr_sch=http)[-2](https://www.gamedev.net/forums/topic/625489-component-system/4944218/)。

简单来说，当你在 C\+\+ 端需要动态地创建某个脚本类的对象时，正确的做法不是直接去调用它的构造函数，而是通过这个 `GetFactoryByDecl` 获取到它的工厂函数，然后通过一个 `asIScriptContext` 来执行这个工厂函数。

### 核心用法：获取并调用工厂函数

要创建一个脚本类的实例，通常遵循下面这个标准流程：

1.
**获取模块和对象类型**：首先，你需要从编译好的模块中找到目标类。
cpp

```cpp
asIScriptModule* module = engine->GetModule("MyModule");
asITypeInfo* type = module->GetTypeInfoByDecl("MyClass");
```
2.
**获取工厂函数**：这是最关键的一步。使用 `GetFactoryByDecl` 并传入一个格式正确的声明字符串。这个字符串的格式通常是 `"ClassName @ClassName()"`，表示这是一个返回 `ClassName` 句柄的无参工厂函数[-1](https://angelcode.com/angelscript/sdk/docs/manual/doc_use_script_class.html?_x_tr_sch=http)[-9](https://gamedev.net/forums/topic/626496-class-instanes-breaking-outside-scope/4949950/)。
cpp

```cpp
asIScriptFunction* factory = type->GetFactoryByDecl("MyClass @MyClass()");
// 别忘了检查 factory 是否为空
```
3.
**执行工厂函数**：准备一个上下文，执行工厂函数。执行完成后，从上下文的返回值地址中取出新创建的对象指针[-1](https://angelcode.com/angelscript/sdk/docs/manual/doc_use_script_class.html?_x_tr_sch=http)。
cpp

```cpp
asIScriptContext* ctx = engine->CreateContext();
ctx->Prepare(factory);
ctx->Execute();

// 关键：从返回值地址获取对象指针
asIScriptObject* obj = *(asIScriptObject**)ctx->GetAddressOfReturnValue();

// 非常重要：将对象保存在 C++ 侧时，必须增加引用计数，防止被销毁
obj->AddRef();
```

### 为什么不用 `CreateScriptObject`？

官方文档和社区都指出，使用工厂函数是创建脚本对象的**推荐方式**。旧的 `CreateScriptObject` 方法存在一些限制，最主要的是它只能调用默认的无参构造函数。而 `GetFactoryByDecl` 配合执行上下文的方式非常灵活，你可以通过 `ctx->SetArgDWord`、`SetArgObject` 等方法来调用**带有任意参数**的工厂函数[-5](https://www.gamedev.net/forums/topic/645507-proper-way-of-creating-as-class-in-c/5078471/)。

### ⚠️ 一个关键细节：对象生命周期管理

在使用 `GetFactoryByDecl` 时，有一个新手极容易踩的坑：**引用计数管理**。

当你通过 `ctx->GetAddressOfReturnValue()` 获取到对象指针后，这个对象此刻是由 AngelScript 上下文（Context）持有的。如果你将这个指针保存在 C\+\+ 的变量中，但**没有调用 `obj->AddRef()`**，那么当这个上下文被 `Prepare` 用于执行下一个函数时，上下文会释放它对对象的引用，导致对象的引用计数归零而被销毁。之后你再去使用这个指针，就会导致程序崩溃[-4](https://gamedev.net/forums/topic/642385-why-i-cant-call-a-script-member-function-successfully/?langid=1&langurlbits=topic/642385-why-i-cant-call-a-script-member-function-successfully/&setlanguage=1)[-10](https://gamedev.net/forums/topic/650268-getting-assert-upon-calling-script-function/#main-content)。

因此，**只要你的 C\+\+ 代码打算长期持有这个脚本对象指针，在获取到它的第一时间就应该调用 `AddRef()`**。当不再需要这个对象时，也要记得调用 `Release()` 来释放引用，避免内存泄漏。

### 更复杂的情况：使用带参数的工厂

如果你的脚本类定义了带参数的构造函数，获取工厂函数的方式会稍有不同。你需要构造一个包含参数类型的声明字符串。例如，如果构造函数接受一个 `int` 和一个 `string`，工厂函数的声明可能是：

cpp

```cpp
asIScriptFunction* factory = type->GetFactoryByDecl("MyClass @MyClass(int, string)");
```

然后在准备执行时，通过上下文来设置这些参数的值。
