# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-30T02:02:49.851Z

## User

保存的对象如何在之后继续使用

## Assistant

在 C\+\+ 端保存脚本对象指针后继续使用，核心原则就是**管理好引用计数**。只要对象指针有效，你就能像操作普通 C\+\+ 对象一样，通过它来读取属性、调用方法。

### 🔑 正确保存并长期持有

当你从 Context 获取对象指针时，**必须立即调用 `AddRef()`**，这样对象就能独立于 Context 而存在，保证后续使用时不会崩溃。

cpp

```cpp
asIScriptObject* obj = /* 从上下文获取的对象 */;
if (obj) {
// 增加引用计数，声明持有权
obj->AddRef();
// 将指针存储到C++容器中
myObjectList.push_back(obj);
}
```

### 🛠️ 后续使用方式

保存好指针后，在游戏循环的任意时刻，你都可以通过这个指针来操作脚本对象：

-
**读取和修改属性**：通过 `GetAddressOfProperty()` 获取属性地址，再根据类型 ID 进行读写。
cpp

```cpp
// 假设要修改名为 "health" 的 int 类型属性
int healthPropIdx = obj->GetPropertyIndexByName("health");
if (healthPropIdx >= 0) {
int typeId = obj->GetPropertyTypeId(healthPropIdx);
void* addr = obj->GetAddressOfProperty(healthPropIdx);
// 判断类型 ID 后进行操作
if (typeId == engine->GetTypeIdByDecl("int")) {
*(int*)addr = newHealthValue;
}
}
```
-
**调用对象的方法**：你需要从对象所属的模块中获取 `asIScriptFunction`，然后通过 Context 来执行它。
cpp

```cpp
// 获取对象所属的类型
asITypeInfo* type = obj->GetObjectType();
// 从类型中查找方法
asIScriptFunction* method = type->GetMethodByDecl("void TakeDamage(int)");
if (method) {
// 通过 Context 执行该方法，并将 obj 作为 this 指针传入
ctx->Prepare(method);
ctx->SetArgObject(0, obj); // 注意：这需要先 AddRef
ctx->SetArgDWord(1, damage);
ctx->Execute();
}
```

### 🧹 释放与清理

当你不再需要这个对象时（例如对象被销毁、关卡卸载），**必须调用 `Release()`** 来释放你的引用。这是防止内存泄漏的关键。

cpp

```cpp
for (auto* obj : myObjectList) {
if (obj) {
obj->Release(); // 释放引用，计数归零时对象被销毁
}
}
myObjectList.clear();
```

### 💡 进阶管理：使用句柄（Handle）系统

对于更复杂的项目，建议不要直接暴露原始指针，而是实现一个“句柄”系统来提供一层间接访问。

-
**核心思路**：在 C\+\+ 端维护一个 `ID -> asIScriptObject*` 的映射表。当你保存脚本对象时，给它分配一个唯一的整数 ID，并将 `(ID, 对象指针)` 存入映射表，同时调用 `AddRef()`。在外部，你只传递这个整数 ID。
-
**使用时**：通过 ID 从映射表中查找指针，如果找到则使用，否则说明对象已被销毁。
-
**销毁时**：从映射表中移除条目，并调用 `Release()`。

这种模式非常灵活，能有效避免悬空指针问题，而且方便序列化（因为 ID 是整数，可以轻松保存到文件）。AngelScript 官方提供的 `scripthelper` 也有类似的管理功能，你可以参考它的实现。

你目前是打算把脚本对象绑定到游戏实体里使用吗？了解具体的使用场景（比如是管理几百个敌人单位，还是单个全局对象），我可以给你更具体的代码结构建议。😊
