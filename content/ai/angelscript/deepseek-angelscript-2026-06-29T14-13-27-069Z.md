# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-29T14:13:27.069Z

## User

asiscriptobject

## Assistant

`asIScriptObject` 是 AngelScript 中代表**脚本对象实例**的核心接口。简单来说，每当你用 AngelScript 在脚本里创建一个对象（比如 `MyClass@ obj = MyClass();`），这个对象在 C\+\+ 端就对应着一个 `asIScriptObject` 指针。通过它，你可以在 C\+\+ 代码里像操作脚本一样，读取和修改脚本对象的属性、获取它的类型信息，甚至管理它的生命周期[-5](https://angelcode.com/angelscript/sdk/docs/manual/classas_i_script_object.html#a4bed3c3ac9f16294985835747aa122d3)[-7](https://angelcode.com/angelscript/sdk/docs/manual/angelscript_8h.html?_x_tr_sch=http)。

### 🔑 核心功能与用法

这个接口提供了一系列方法，主要可以帮你做几件关键的事情：

-
**管理对象生命周期**：通过 `AddRef()` 和 `Release()` 来控制脚本对象的引用计数，确保内存被正确管理。当你在 C\+\+ 侧持久化保存一个脚本对象时，必须调用 `AddRef()`；不再使用时则调用 `Release()`[-1](https://doxygen.scummvm.org/df/de5/classas_i_script_object.html)[-5](https://angelcode.com/angelscript/sdk/docs/manual/classas_i_script_object.html#a4bed3c3ac9f16294985835747aa122d3)。
-
**访问和修改对象属性**：这是 `asIScriptObject` 最核心的用途之一。你可以通过 `GetPropertyCount()` 和 `GetPropertyName()` 来遍历对象的属性名[-5](https://angelcode.com/angelscript/sdk/docs/manual/classas_i_script_object.html#a4bed3c3ac9f16294985835747aa122d3)，再用 `GetAddressOfProperty()` 获取属性在内存中的地址指针，从而直接读取或修改它的值[-3](https://www.contagion-game.com/api/manual/doc_adv_reflection.html)[-5](https://angelcode.com/angelscript/sdk/docs/manual/classas_i_script_object.html#a4bed3c3ac9f16294985835747aa122d3)。
cpp

```cpp
// 假设有脚本对象 obj，想修改它的 int 类型属性 "health"
asIScriptObject* obj = ...;
// 获取属性类型 ID 和地址
int propTypeId = obj->GetPropertyTypeId(propIndex);
void* propAddr = obj->GetAddressOfProperty(propIndex);
// 根据类型 ID 将指针转为对应类型并操作
// 注意：这里需要根据 propTypeId 判断具体类型
*(int*)propAddr = 100;
```
-
**获取类型信息**：通过 `GetObjectType()` 可以获取到对象的类型信息接口 `asITypeInfo`，进而了解这个对象的类声明、方法等信息[-5](https://angelcode.com/angelscript/sdk/docs/manual/classas_i_script_object.html#a4bed3c3ac9f16294985835747aa122d3)。`GetTypeId()` 则返回对象的类型 ID，常用于在 C\+\+ 注册的函数中识别传入对象的实际类型[-1](https://doxygen.scummvm.org/df/de5/classas_i_script_object.html)[-5](https://angelcode.com/angelscript/sdk/docs/manual/classas_i_script_object.html#a4bed3c3ac9f16294985835747aa122d3)。
-
**其他辅助功能**：`CopyFrom()` 可以从另一个相同类型的对象复制数据[-1](https://doxygen.scummvm.org/df/de5/classas_i_script_object.html)[-5](https://angelcode.com/angelscript/sdk/docs/manual/classas_i_script_object.html#a4bed3c3ac9f16294985835747aa122d3)，`GetEngine()` 可以获取到创建它的引擎实例[-1](https://doxygen.scummvm.org/df/de5/classas_i_script_object.html)[-5](https://angelcode.com/angelscript/sdk/docs/manual/classas_i_script_object.html#a4bed3c3ac9f16294985835747aa122d3)。你还可以通过 `SetUserData()` 和 `GetUserData()` 将任意 C\+\+ 数据与这个脚本对象关联起来，这对于在 C\+\+ 侧绑定额外的上下文信息非常有用[-1](https://doxygen.scummvm.org/df/de5/classas_i_script_object.html)[-5](https://angelcode.com/angelscript/sdk/docs/manual/classas_i_script_object.html#a4bed3c3ac9f16294985835747aa122d3)。

### 💡 常见使用场景

`asIScriptObject` 在集成中几乎无处不在，举几个典型的例子：

1.
**在 C\+\+ 函数中处理脚本对象**：当你注册了一个 C\+\+ 函数给脚本调用，而这个函数接收一个脚本对象作为参数时，在函数体内你拿到的就是一个 `asIScriptObject` 指针。你可以通过它来读取脚本对象的属性，或者调用该对象的方法。在使用 `asCALL_GENERIC` 调用约定时，更是需要用 `gen->GetArgObject()` 获取并强转为 `asIScriptObject*` 来处理[-8](https://angelcode.com/angelscript/sdk/docs/manual/doc_generic.html?_x_tr_sch=http)。
2.
**在 C\+\+ 侧持有脚本对象的引用**：当你的 C\+\+ 代码需要长时间持有一个脚本对象（比如把它存到一个全局列表里），你必须通过这个接口来管理引用计数，防止对象被意外销毁。

### 🧩 扩展与关联

-
**与 C 接口的关联**：AngelScript 提供了纯 C 接口，方便在不支持 C\+\+ 的语言（如 Delphi、Java）中使用。对应 `asIScriptObject` 的 C 函数前缀是 `asObject_`[-6](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_addon_clib.html)。
-
**属性枚举的补充**：对类属性的枚举，如果没有对象实例，可以通过 `asITypeInfo` 接口来查看类的声明信息；而 `asIScriptObject` 是用于操作**具体的、活的**对象实例的属性值[-3](https://www.contagion-game.com/api/manual/doc_adv_reflection.html)。

结合之前的讨论，如果你正在实现 DAP Server 或在 C\+\+ 函数中处理脚本传来的对象，`asIScriptObject` 就是你与脚本对象数据交互的核心工具。通过它配合 `GetPropertyTypeId()` 判断类型，再用 `GetAddressOfProperty()` 读写数据，就能在 C\+\+ 与脚本世界之间自由穿梭了。
