# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-29T06:52:10.848Z

## User

狭义的脚本接口怎么使用

## Assistant

AngelScript 中的 `interface`（接口），是脚本世界里的一个纯粹概念，用于定义行为契约[-3](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_global_interface.html)。它主要服务于一个目的：**实现多态**，让不同的脚本类可以被统一地处理和调用。

### 核心用法：定义与实现

接口的使用逻辑和C\#或Java类似，分为两步：

1.
**定义接口**：使用 `interface` 关键字声明一组方法，只声明不实现[-3](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_global_interface.html)。
angelscript

```angelscript
// 定义一个叫 "MyInterface" 的接口
interface MyInterface {
void DoSomething();  // 只有声明
int GetValue();
}
```
2.
**实现接口**：一个脚本类通过 `:` 符号后跟接口名来声明实现它，然后必须提供接口中所有方法的具体实现[-3](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_global_interface.html)。
angelscript

```angelscript
// MyClass 类实现了 MyInterface 接口
class MyClass : MyInterface {
void DoSomething() {
// 在这里编写具体逻辑
}
int GetValue() {
return 42;
}
}
```

### 多态与类型安全

这是接口最强大的地方。你可以编写不关心具体类型，只关心对象是否遵循特定“契约”的代码。

angelscript

```angelscript
// 一个处理任何实现了 MyInterface 的对象的函数
void ProcessObject(MyInterface@ obj) {
if (obj !is null) {
obj.DoSomething(); // 调用接口方法
}
}

void main() {
MyClass@ instance = MyClass(); // 创建 MyClass 实例
ProcessObject(instance);       // 可以传入，因为 MyClass 实现了 MyInterface
}
```

在这个例子中，`ProcessObject` 函数接受一个 `MyInterface@` 句柄，它不在乎传入的是 `MyClass` 还是其他任何实现了此接口的类，只要它保证有 `DoSomething` 方法就行[-3](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_global_interface.html)。

### ⚠️ 重要限制：脚本接口 vs C\+\+ 接口

这是一个非常关键的区别，必须牢记：**AngelScript 的脚本接口 \(`interface`\) 是纯脚本层的概念，你不能让一个 C\+\+ 对象去实现一个脚本接口，反之亦然**[-7](https://gamedev.net/forums/topic/717128-application-class-implementing-interface/#main-content)。

原因是，脚本类和C\+\+对象的底层内存结构和函数调用机制完全不同，它们之间不存在直接的ABI兼容性[-7](https://gamedev.net/forums/topic/717128-application-class-implementing-interface/#main-content)。

-
**如果你尝试在 C\+\+ 中注册一个类，并声明它实现了某个脚本接口**，这是不支持的。你需要使用其他方式，比如在C\+\+函数中通过类型ID \(`typeId`\) 判断传入参数的具体类型，或者注册类型转换行为 \(`opImplCast`\) 来实现类似的效果[-7](https://gamedev.net/forums/topic/717128-application-class-implementing-interface/#main-content)。

### 进阶特性：Mixin 类实现接口

AngelScript 还支持更灵活的 **Mixin（混入）** 类。简单理解，Mixin 类可以包含一些预置的实现，并实现一个或多个接口。然后，其他类可以继承这个 Mixin 类，从而自动获得这些实现以及“实现了接口”的身份。

angelscript

```angelscript
interface Intf {}
interface Intf2 {}

mixin class Mix : Intf, Intf2 {
// 可以包含一些公共的、可复用的实现
void SharedMethod() { }
}

// Clss 通过继承 Mix，间接地实现了 Intf 和 Intf2
class Clss : Mix {}
```

这让代码复用和接口组合变得非常灵活。但要注意，Mixin 类**不能继承自普通类**，只能实现接口。
