# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-29T08:01:10.358Z

## User

weakref

## Assistant

在 AngelScript 中，`weakref` 是一种用于解决**循环引用**问题的智能句柄。它的作用和 C\+\+ 中的 `std::weak_ptr` 非常相似：它像一个“观察者”，指向一个对象，但**不会增加对象的引用计数**。

---

### 💡 `weakref` 为什么重要？

AngelScript 使用**引用计数**进行垃圾回收。当两个对象互相持有对方的强引用（即普通句柄 `@`）时，就会形成**循环引用**，导致它们的引用计数永远不为 0，从而无法被回收，造成**内存泄漏**。

angelscript

```angelscript
class Child;
class Parent {
Child@ child;  // 强引用
}
class Child {
Parent@ parent;  // 强引用，形成循环！
}
```

`weakref` 就是专门用来打破这种循环的。将其中一方改为弱引用，就可以让垃圾回收器正常回收它们。

---

### 📝 如何使用 `weakref`？

#### 1. 声明一个弱引用句柄

angelscript

```angelscript
class MyClass { }

weakref<MyClass> g_Wref;  // 声明一个弱引用句柄
```

#### 2. 赋值与使用

赋值时，你可以直接将一个普通句柄（强引用）赋值给 `weakref`。**但在使用它之前，必须通过 `get()` 方法将其“提升”为一个安全的强引用**，因为原对象可能已经被销毁了。

angelscript

```angelscript
void main() {
MyClass@ obj = MyClass();   // 创建对象，引用计数为 1
weakref<MyClass> wref = obj; // wref 指向 obj，但不增加计数

// 安全使用方式：先提升为强引用
MyClass@ safeRef = wref.get();
if (safeRef !is null) {
// 对象仍然存活，可以安全使用
safeRef.DoSomething();
} else {
// 对象已被销毁
print("对象已不存在");
}
}
```

#### 3. 典型场景：父子关系

这是最经典的用法。让子节点持有父节点的弱引用，避免循环引用导致内存泄漏。

angelscript

```angelscript
class Parent {
array<Child@> children;  // 子节点用强引用
}

class Child {
weakref<Parent> parent;  // 父节点用弱引用！

Parent@ GetParent() {
return parent.get();  // 使用时临时提升
}
}
```

---

### 🎯 弱引用与强引用的对比

| 特性 | 强引用 \(`@`\) | 弱引用 \(`weakref<T>`\) |
| --- | --- | --- |
| **增加引用计数** | ✅ 是 | ❌ 否 |
| **阻止对象被回收** | ✅ 是 | ❌ 否 |
| **能否直接访问成员** | ✅ 可以 \(如 `obj.DoSomething()`\) | ❌ 不可以，必须先 `get()` |
| **安全性** | 安全（对象一定存活） | 不安全（对象可能已被销毁） |

---

### ⚠️ 重要注意事项

1.
**`weakref` 只对引用类型有效**：它只能用于那些注册为 `asOBJ_REF` 的对象类型。对于值类型（`asOBJ_ALUE`，如 `Vector3`），它们存在栈上，没有引用计数，因此**无法使用 `weakref`**。
2.
**注册时需要启用弱引用支持**：如果你的 C\+\+ 对象类型需要在脚本中使用弱引用，在注册时必须包含 `asOBJ_WEAKREF` 标志。
cpp

```cpp
engine->RegisterObjectType("MyClass", sizeof(MyClass), asOBJ_REF | asOBJ_WEAKREF);
```
3.
**`get()` 的开销**：每次调用 `weakref.get()` 都会进行安全检查和临时增加引用计数，有一定的性能开销。如果对象一定存活（比如在对象自身的成员函数中），可以缓存强引用结果以避免重复调用。
4.
**检查是否为 `null`**：在释放对象时，需要将 `weakref` 变量置空（`wref = null`），防止它指向悬空对象。

---

### 🔧 与 C\+\+ 的交互

当你在 C\+\+ 中处理 AngelScript 对象时，也可以通过 `asIScriptObject` 的弱引用机制来安全地持有脚本对象：

cpp

```cpp
// C++ 侧持有脚本对象的弱引用
asIScriptObject* obj = ...; // 来自脚本
obj->AddRef(); // 作为强引用持有

// 如果你只想“观察”而不阻止回收，可以使用弱引用行为
// 这通常需要更底层的API操作
```

但在大多数集成场景中，更推荐让 C\+\+ 使用**整数 ID** 或**句柄管理器**来引用脚本对象，而不是直接持有 `weakref`。

---

### 💎 总结

`weakref` 是 AngelScript 中**打破循环引用的标准解决方案**。它的使用模式非常固定：

1.
用 `weakref<T>` 声明弱引用变量。
2.
赋值时直接用强引用句柄赋值。
3.
使用时先调用 `get()` 提升为强引用，并检查是否为 `null`。

如果你在调试时发现脚本对象无法回收导致内存泄漏，检查是否存在循环引用，并把其中一端的强引用改为 `weakref` 通常就能解决问题。😊
