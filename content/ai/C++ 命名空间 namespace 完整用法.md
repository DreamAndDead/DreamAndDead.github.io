---
title: C++ 命名空间 namespace 完整用法
---

# C++ 命名空间 namespace 完整用法

命名空间作用：**解决变量、函数、类名重名冲突**，把代码划分到不同空间，隔离作用域。

## 一、定义命名空间

### 1. 普通命名空间

```cpp
#include <iostream>
// 自定义命名空间 MySpace
namespace MySpace
{
    int num = 100;
    void func()
    {
        std::cout << "MySpace 函数" << std::endl;
    }
    class Person
    {
    public:
        void show(){}
    };
}
```

### 2. 嵌套命名空间

```cpp
namespace A
{
    namespace B
    {
        int val = 200;
    }
}
```

### 3. 匿名命名空间（静态全局，仅限当前文件）

等价于 `static`，只能本 cpp 使用，无法外部引用

```cpp
namespace
{
    int temp = 99;
}
```

### 4. 命名空间可以拆分、追加定义

同一个命名空间可以写在多处

```cpp
namespace MySpace
{
    double d = 3.14; // 追加成员
}
```

## 二、4 种使用方式（重点）

### 方式 1：**完全限定名（最稳妥，推荐大型项目）**

格式：`命名空间::成员`

```cpp
int main()
{
    std::cout << MySpace::num << std::endl;
    MySpace::func();
    MySpace::Person p;

    // 嵌套空间
    std::cout << A::B::val << std::endl;
    return 0;
}
```

`std` 就是标准库命名空间，`std::cout`、`std::string` 都是标准写法。

### 方式 2：using 声明（只引入单个成员）

只导入指定成员，污染范围小

```cpp
#include <iostream>
using std::cout;   // 只引入cout
using MySpace::num;

int main()
{
    cout << num << endl;
    // 但 func() 依旧需要 MySpace::func()
    MySpace::func();
    return 0;
}
```

### 方式 3：using namespace 整个空间（简易写法，小程序常用）

一次性导入整个命名空间所有内容

```cpp
#include <iostream>
using namespace std;
using namespace MySpace;

int main()
{
    cout << num << endl;
    func();
    return 0;
}
```

**缺点**：容易名字冲突，大型工程不建议全局 `using namespace std;`。

### 方式 4：命名空间别名（简化长命名）

```cpp
namespace AB = A::B; // 给嵌套空间起别名
int main()
{
    cout << AB::val << endl;
}
```

## 三、名字冲突案例

两个空间存在同名变量，必须加限定区分：

```cpp
namespace S1{ int a = 10; }
namespace S2{ int a = 20; }

int main()
{
    // cout << a; // 报错，歧义
    std::cout << S1::a << S2::a;
    return 0;
}
```

## 四、作用域规则

1. **作用域就近原则**：局部变量 > 当前命名空间 > 全局命名空间

```cpp
using namespace MySpace;
int num = 10; // 全局
int main()
{
    int num = 20;
    cout << num;        // 局部 20
    cout << ::num;      // 全局（空命名空间::代表全局）
    cout << MySpace::num;// 自定义空间
}
```

2. `using namespace` 写在函数内，只在函数作用域生效。

## 五、实战规范建议

1. **小型练习程序**：直接 `using namespace std;` 方便快捷；
2. **项目开发、头文件 (.h)**：**禁止全局 using namespace std**，容易引发库名冲突，一律用 `std::` 全限定；
3. 第三方库尽量用别名，不要全盘引入；
4. 常量、全局工具函数建议放入自定义命名空间管理。

## 六、完整可运行示例

```cpp
#include <iostream>

namespace MyNS
{
    void print(int x)
    {
        std::cout << "数值：" << x << std::endl;
    }
}

int main()
{
    MyNS::print(666);
    return 0;
}
```