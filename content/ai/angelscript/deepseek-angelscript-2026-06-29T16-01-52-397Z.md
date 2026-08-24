# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-29T16:01:52.397Z

## User

angelscript 支持函数重载

## Assistant

AngelScript **支持**函数重载，这一点和C\+\+是类似的。不管是你在C\+\+端注册的函数，还是直接在脚本里写的函数，都可以有多个同名但参数不同的版本[-1](https://contagion-game.com/api/manual/doc_register_func.html#doc_register_func_4)[-2](http://angelcode.com/angelscript/sdk/docs/manual/doc_script_func_overload.html)。

### 📝 在脚本中使用函数重载

在脚本代码中，你可以直接像在C\+\+里一样，定义多个同名的函数：

angelscript

```angelscript
void Process(int value) {
// 处理整数
}

void Process(float value) {
// 处理浮点数
}

void Process(string value) {
// 处理字符串
}
```

脚本引擎会根据你调用时传入的**参数类型和数量**，自动选择最匹配的那个版本执行[-2](http://angelcode.com/angelscript/sdk/docs/manual/doc_script_func_overload.html)。

> **重要限制**：重载函数**不能只有返回值类型不同**。因为引擎是根据调用上下文（传入的参数）来选择函数的，返回值类型不参与这个匹配过程[-2](http://angelcode.com/angelscript/sdk/docs/manual/doc_script_func_overload.html)。

### 🔧 在C\+\+端注册重载函数

当你要在C\+\+端注册多个同名的全局函数或类方法时，由于C\+\+本身也支持重载，你需要用特定的宏来告诉AngelScript你要注册的是哪一个C\+\+函数。

-
**全局函数用 `asFUNCTIONPR`**：普通的 `asFUNCTION` 宏在函数重载时会因为指针不明确而报错。使用 `asFUNCTIONPR` 并明确指定**参数列表**和**返回值类型**，就能精确地拿到对应函数的指针了[-1](https://contagion-game.com/api/manual/doc_register_func.html#doc_register_func_4)[-5](https://www.cancapture.com/script_doc/doc_register_func.html)。
例如，要注册两个重载的全局函数 `void log(int)` 和 `void log(float)`：
cpp

```cpp
// 注册 void log(int)
r = engine->RegisterGlobalFunction("void log(int)", asFUNCTIONPR(log, (int), void), asCALL_CDECL);
// 注册 void log(float)
r = engine->RegisterGlobalFunction("void log(float)", asFUNCTIONPR(log, (float), void), asCALL_CDECL);
```
-
**类方法用 `asMETHODPR`**：类似地，注册类中重载的方法时，需要使用 `asMETHODPR` 宏，并指定类名、方法名、参数列表和返回值类型[-4](https://angelcode.com/angelscript/sdk/docs/manual/doc_reg_opbeh.html?_x_tr_sch=http)[-5](https://www.cancapture.com/script_doc/doc_register_func.html)。
例如，要注册 `MyClass` 中两个重载的 `setValue` 方法：
cpp

```cpp
// 注册 void setValue(int)
engine->RegisterObjectMethod("MyClass", "void setValue(int)", asMETHODPR(MyClass, setValue, (int), void), asCALL_THISCALL);
// 注册 void setValue(float)
engine->RegisterObjectMethod("MyClass", "void setValue(float)", asMETHODPR(MyClass, setValue, (float), void), asCALL_THISCALL);
```

### 💡 额外说明：重载与虚继承

搜索结果中还提到，AngelScript **不直接支持**通过虚拟继承（Virtual Inheritance）得到的C\+\+类的方法注册。如果遇到这种情况，你需要手动编写一个简单的“代理（Proxy）”函数来调用正确的方法，再进行注册[-1](https://contagion-game.com/api/manual/doc_register_func.html#doc_register_func_4)。不过，对于绝大多数普通的类和继承结构，这个限制不会影响到你。

掌握了重载的用法后，如果你想进一步了解更进阶的特性，比如**变参函数（variadic function）**如何在AngelScript中实现，或者想在脚本中自定义**操作符重载**，我可以再为你详细展开。
