# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-29T15:54:40.551Z

## User

registerobjecttype

## Assistant

`RegisterObjectType` 是 AngelScript 中用于向脚本环境注册 C\+\+ 类型的核心 API。通过它，你可以将 C\+\+ 类、结构体或基本类型暴露给脚本使用。

这个 API 的原型是 `virtual int RegisterObjectType(const char *obj, int byteSize, asDWORD flags) = 0`[-1](http://contagion-game.com/api/manual/doc_reg_basicref.html)。它的核心思想很简单：**告诉 AngelScript 你的 C\+\+ 类型叫什么名字（`obj`）、占多少内存（`byteSize`），以及它有什么行为特性（`flags`）**。

要正确使用这个 API，关键在于理解 `flags` 参数，它决定了这个类型在脚本世界里将以什么形态存在。

### 先确定类型：值类型 vs. 引用类型

首先，你需要决定你的 C\+\+ 类型在脚本中应该作为**值类型（Value Type）** 还是**引用类型（Reference Type）** 存在[-11](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_register_type.html)。

-
**值类型（`asOBJ_VALUE`）**：行为类似 `int`、`float`，在脚本中复制开销小、生命周期明确。适合 `Vector3`、`Matrix` 等轻量级数据结构。如果类型是“简单旧数据”（POD），可以加上 `asOBJ_POD` 标志让 AngelScript 自动优化管理[-3](https://angelcode.com/angelscript/sdk/docs/manual/doc_register_val_type.html?_x_tr_sch=http)[-9](https://www.cancapture.com/script_doc/doc_register_val_type.html)。
-
**引用类型（`asOBJ_REF`）**：行为类似脚本中定义的类，通过句柄（`@`）引用，有引用计数管理生命周期。适合资源、管理器等大对象[-1](http://contagion-game.com/api/manual/doc_reg_basicref.html)。

### 核心 flags 参数解读

`flags` 参数由基础类型标志和若干行为修饰标志组合而成。

#### 值类型的关键标志

注册值类型时，通常需要告诉 AngelScript 这个 C\+\+ 类型的具体实现特征，以便它能正确地按值传递参数和返回值。这时就需要 `asOBJ_APP_*` 系列标志[-3](https://angelcode.com/angelscript/sdk/docs/manual/doc_register_val_type.html?_x_tr_sch=http)。

cpp

```cpp
// 示例：注册一个 C++ 类作为值类型
// 假设你的 C++ 类型叫 Vector3，它有默认构造函数、析构函数和赋值操作符
r = engine->RegisterObjectType("Vector3", sizeof(Vector3),
asOBJ_VALUE | asOBJ_APP_CLASS_CDA); // CDA 表示 Construct, Destruct, Assignment
assert( r >= 0 );
```

> 如果不用这些标志，脚本引擎在按值传递该类型时，可能因不知道如何正确处理C\+\+对象而报错[-3](https://angelcode.com/angelscript/sdk/docs/manual/doc_register_val_type.html?_x_tr_sch=http)。如果你的 C\+\+ 类型是 `int`、`float` 这样的原生基本类型，则使用 `asOBJ_PRIMITIVE` 或 `asOBJ_FLOAT` 标志[-9](https://www.cancapture.com/script_doc/doc_register_val_type.html)。

#### 引用类型的关键标志

注册引用类型时，主要关注引用计数的管理方式。

-
**标准引用类型 \(`asOBJ_REF`\)**：必须配合注册 `asBEHAVE_ADDREF` 和 `asBEHAVE_RELEASE` 行为，AngelScript 通过它们来管理对象的生命周期[-1](http://contagion-game.com/api/manual/doc_reg_basicref.html)。
-
**不计数引用类型 \(`asOBJ_REF | asOBJ_NOCOUNT`\)**：如果你的 C\+\+ 对象生命周期不由引用计数管理（比如由你手动 `new`/`delete`），可以使用这个标志，但务必谨慎，避免悬空指针[-1](http://contagion-game.com/api/manual/doc_reg_basicref.html)。
-
**作用域引用类型 \(`asOBJ_REF | asOBJ_SCOPED`\)**：生命周期跟随脚本变量作用域，一旦变量离开作用域，对象就会被销毁。这种类型不允许脚本创建指向它的句柄（Handle）[-2](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_adv_scoped_type.html)。

### 一个简单的注册流程示例

下面这个例子展示了注册一个简单的引用类型的完整流程，包括类型注册和必要行为的绑定[-1](http://contagion-game.com/api/manual/doc_reg_basicref.html)：

cpp

```cpp
// 假设你的 C++ 类叫 MyRefType
int r;

// 1. 注册类型
r = engine->RegisterObjectType("MyRefType", 0, asOBJ_REF);
assert( r >= 0 );

// 2. 注册工厂函数 (用于脚本创建对象)
// 工厂函数返回一个 MyRefType*，AngelScript 会将其包装为句柄
r = engine->RegisterObjectBehaviour("MyRefType", asBEHAVE_FACTORY,
"MyRefType @f()", asFUNCTION(MyRefType_Factory), asCALL_CDECL);
assert( r >= 0 );

// 3. 注册增加/减少引用的行为
r = engine->RegisterObjectBehaviour("MyRefType", asBEHAVE_ADDREF,
"void f()", asMETHOD(MyRefType, AddRef), asCALL_THISCALL);
assert( r >= 0 );
r = engine->RegisterObjectBehaviour("MyRefType", asBEHAVE_RELEASE,
"void f()", asMETHOD(MyRefType, Release), asCALL_THISCALL);
assert( r >= 0 );
```

完成上述注册后，脚本中就可以这样使用了：

angelscript

```angelscript
MyRefType@ obj = MyRefType(); // 调用你注册的工厂函数
```

### 高级用法：模板类型

`RegisterObjectType` 也支持注册模板类型，格式如 `Array<class T>`[-6](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_template.html)。这通常用于实现脚本的动态数组等泛型容器，注册时需要加上 `asOBJ_TEMPLATE` 标志[-6](https://angelcode.com/angelscript/sdk/docs/manual/doc_adv_template.html)。

> 需要注意的是，`RegisterObjectType` 本身只是注册了类型，这能让脚本“知道”这个类型的存在。要使用它的成员函数、属性或运算符，你还需要使用 `RegisterObjectMethod`、`RegisterObjectProperty` 或 `RegisterObjectBehaviour` 等API来进一步注册[-4](https://cloud.tencent.cn/developer/information/%E5%A6%82%E4%BD%95%E5%90%91AngelScript%E6%B3%A8%E5%86%8CSFML%20Vector2%E8%BF%90%E7%AE%97%E7%AC%A6%EF%BC%9F-ask)。
