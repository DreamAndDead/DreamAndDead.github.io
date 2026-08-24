---
title: C++ namespace + extern "C" 完整结合用法
---

# C++ namespace + extern "C" 完整结合用法

核心原理：

1. `extern "C"` 的作用：**让 C++ 编译器以 C 语言规则编译函数，关闭 C++ 的名字重整（Name Mangling）**，方便 C 程序、动态库调用。
2. 命名空间是 C++ 语法作用域，**`extern "C"` 可以写在命名空间内部 / 外部**，但有严格的规则与坑点。
3. 带命名空间的 `extern "C"` 函数，**最终导出的函数名没有命名空间前缀**（C 语言没有命名空间）。

## 一、基础语法格式

### 写法 1：命名空间内部，单个函数 extern "C"

```cpp
#include <iostream>

namespace MyLib
{
    // C风格编译，关闭C++名字改编
    extern "C" void Hello()
    {
        std::cout << "Hello extern C in namespace" << std::endl;
    }

    // 普通C++函数，会被名字重整
    void CppFunc()
    {
    }
}
```

#### 调用方式（C++ 内部调用）

必须带命名空间，和普通函数一样：

```cpp
int main()
{
    MyLib::Hello();   // 正确
    MyLib::CppFunc();
    return 0;
}
```

#### 关键重点（导出动态库时）

编译成 `.so/.dll` 导出符号时：

- `MyLib::Hello` 导出函数名就是纯 `Hello`，**没有 MyLib 前缀**
- `MyLib::CppFunc` 导出为重整后的 C++ 名称（如`_ZN5MyLib7CppFuncEv`）

> 原因：C 语言不存在命名空间，`extern "C"` 强制使用 C 命名规则，会忽略外层 namespace。

### 写法 2：命名空间内，extern "C" 代码块（批量包裹）

```cpp
namespace MyLib
{
    extern "C"
    {
        void funcA(int a);
        double funcB(double b);
    }
}
```

### 写法 3：extern "C" 包裹整个命名空间（不推荐）

```cpp
extern "C"
{
    namespace MyLib
    {
        void test(){}
    }
}
```

效果等价，但是语义别扭，一般不用。

## 二、头文件标准写法（跨 C/C++ 调用必备）

头文件需要**条件编译**，保证 C 编译器看不到 C++ 语法（namespace）：

```h
// MyLib.h
#ifdef __cplusplus
extern "C" {
#endif

// C函数声明，C和C++都能识别
void Hello();

#ifdef __cplusplus
}
#endif

// C++专属内容，只有C++编译器生效
#ifdef __cplusplus
namespace MyLib
{
    void Hello(); // 命名空间内的函数声明
    void CppOnlyFunc();
}
#endif
```

实现文件 `.cpp`：

```cpp
#include "MyLib.h"
#include <iostream>

namespace MyLib
{
    extern "C" void Hello()
    {
        std::cout << "命名空间 + extern C" << std::endl;
    }

    void CppOnlyFunc()
    {
    }
}
```

## 三、核心坑点与规则（极易出错）

### 坑 1：不能出现同名冲突

下面代码**编译报错**：全局 `Hello` 和命名空间 `MyLib::Hello` 同时被 `extern "C"` 修饰，导出同名符号。

```cpp
// 错误！两个extern "C"重名
extern "C" void Hello();

namespace MyLib
{
    extern "C" void Hello(){}
}
```

### 坑 2：`extern "C"` 只能修饰**函数 / 全局变量**，不能修饰类、模板

命名空间内的类、模板无论如何都不能加 `extern "C"`，C 语言无法识别类。

```cpp
namespace MyLib
{
    // 非法！extern C 不能修饰class
    extern "C" class Test{};
}
```

### 坑 3：extern "C" 函数**无法重载**

C 语言不支持函数重载，即便放在命名空间里，两个同名 `extern "C"` 函数一定冲突：

```cpp
namespace MyLib
{
    extern "C" void fun(int);
    extern "C" void fun(double); // 报错，C不支持重载
}
```

普通 C++ 命名空间函数可以正常重载。

### 坑 4：extern "C" 函数内部可以随便用 C++ 代码

函数名是 C 风格，函数体完全可以写 C++ 代码（string、类、STL 都没问题），只是**对外函数名是 C 格式**。

```cpp
#include <string>
namespace MyLib
{
    extern "C" void ShowMsg(const char* str)
    {
        std::string s(str); // 内部正常使用C++特性
        // ...
    }
}
```

## 四、外部 C 语言调用规则

1. C 代码 `.c` 中，**看不到命名空间 MyLib**，直接调用裸函数名：

```c
// main.c
#include "MyLib.h"
int main()
{
    Hello(); // 直接写Hello，不能写MyLib::Hello（C没有namespace）
    return 0;
}
```

2. C++ 代码调用：两种写法都行

```cpp
MyLib::Hello(); // C++推荐写法
Hello();        // 全局也能找到这个extern C函数
```

## 五、命名空间别名 + extern C

别名不影响 `extern "C"` 的导出名称，导出依旧是原始函数名：

```cpp
namespace NS = MyLib;
int main()
{
    NS::Hello();
}
```

库导出名依然是 `Hello`。

## 六、匿名命名空间 + extern C（禁止使用）

匿名命名空间的符号默认内部链接（static），加 `extern "C"` 也无法导出到动态库外部：

```cpp
namespace
{
    extern "C" void test(){} // 只能本文件使用，外部无法调用
}
```

## 总结速记

1. **`extern "C"` 写在 namespace 内部**：C++ 内部调用需要命名空间前缀，对外导出**不带命名空间的 C 函数名**；
2. 头文件必须用 `#ifdef __cplusplus` 隔离，C 代码只读取 C 函数声明；
3. extern "C" 函数不能重载、不能修饰类模板，函数体可正常使用 C++ 语法；
4. 多个命名空间里的 extern "C" 函数，全局名字不能重复。