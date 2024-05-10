---
created: 2024-05-03T12:57
draft: true
tags:
  - card
  - cpp
---

const 关键字，核心功能是利用编译器，在编译阶段，保证修饰变量的只读性，有助于提前发现错误。


> [!NOTE] 合理正确的使用 const，是新手和老手的分水岭


# const 普通变量

普通变量的只读性，指不能通过赋值改变变量的值

```cpp
const int n = 10;
// 错误，变量 n 不可被修改
n = 5;

// 错误, const 变量必须在声明时被初始化
const int m;
```

# const 类对象变量

对象变量的只读性，意思是
- 成员变量的只读
- 只能调用 const 成员函数

```cpp
class A
{
public:
    int a;

    void const_func() const {};
    void non_const_func(){};
};

int main()
{
    A c = A();
    c.a = 10;
    // 正确，非 const 对象可调用 const 成员函数
    c.const_func();
    c.non_const_func();

    const A n = A();
    // 错误，成员变量是只读的
    n.a = 10;
    n.const_func();
    // 错误，只能调用 const 成员函数
    n.non_const_func();
}
```

# 指针相关
## 指向 const 类型的指针

指针指向类型为 const，所指向的内容保持只读性
但指针变量本身并非 const，指针指向的地址可以被改变

```cpp
int main()
{
    int m = 10;
    int n = 20;

    const int * p = &m;
    // 错误，指针指向为 const int 类型，只读
    *p = 20;

	// 指针本身的指向可修改
    p = &n;
}
```

### 只读性是通过指针类型来判断的

```cpp
int main()
{
    int n = 10;
    const int * p;
    // 指向非 const 变量 n 的地址
    p = &n;
    // 错误，无法修改，因为指针类型为 const int
    *p = 20;

    const int m = 10;
    int * q;
	// 指向 const 变量 m 的地址
    q = (int*)&m;
    // 可以修改其值，因为指针类型不是 const
    *q = 20;
}
```

## const 指针

指针指向的类型非 const，但指针变量本身 const

即所指向的值可以改变，但指针无法改变指向

```cpp
int main()
{
    int m = 10;
    int n = 20;
    int * const p = &m;

	// 指针指向类型非 const，可修改
    *p = 20;
    // 错误，指针变量本身 const，不可修改指向
    p = &n;
}
```

## const const 指针

同时限定指针指向类型，和指针变量本身

```cpp
const int * const p = &m;
```

## 从语法上区分

右结合性，确定变量的类型

```cpp
// (const int) (*p)
// p 本身是一个指针
// 指向 const int 类型
const int *p;
// 同上
int const *p;

// (int (* (const p)))
// p 本身是 const 的变量
// 其次是一个指针
// 指向 int 类型
int * const p;
```


# const 函数参数

函数在调用时，参数进行值传递，存储在栈上

在函数内部，参数等同于变量，在声明中也可以用 const 修饰
意思是，在函数内部，此参数是只读的

对于非指针参数，const 声明对外部调用者没有影响，因为在函数调用时，参数进行了值传递的复制，函数内部对参数的修改，不会对外部造成影响

```cpp
void test_const(const int n) {};
void test_non_const(int n) {};

int main()
{
    int non_const_int = 10;
    const int const_int = 20;

    test_const(const_int);
    test_const(non_const_int);
    test_non_const(const_int);
    test_non_const(non_const_int);
}
```

对于指针参数，意义就不同了
外部在调用函数时，指针进行了值传递，相当于函数内部的指针指向了外部的值
如果参数没有 const，则函数内部随意修改外部的值
如果有 const，则确保函数内部无法修改外部的值

```cpp
void test_const(const int * n) {};
void test_non_const(int * n) {};

int main()
{
    int m = 10;
    int n = 20;

    int * non_const_int = &m;
    const int * const_int = &n;

    test_const(const_int);
    test_non_const(non_const_int);

    test_const(non_const_int);
    // 错误，const int * 和 int * 类型不匹配
    // 外部保证 const，而内部不保证，矛盾
    test_non_const(const_int);
}
```

- [ ] const 返回值
	- 多用于返回 const 引用
	- 引用是变量的别名
		- 相当于 const 指针，指向无法被修改
	- const 引用相当于 const const 指针
		- 指向和指向的内容都无法被修改

# const 成员函数

在成员函数的最后加上 const，标识其为 const 成员函数
确保在函数内部无法修改成员变量

```cpp
class A
{
public:
    void const_func() const {};
    void non_const_func() {};
};

int main()
{
    const A c;
    A n;

    c.const_func();
    // 错误，const 对象无法调用非 const 方法，因为其不确保成员变量的只读性
    c.non_const_func();

    n.const_func();
    n.non_const_func();
}
```

这一点是通过 this 指针来实现的
this 指针本身是一个 const 指针，其指向无法被修改
在 const 成员函数中，this 指针是一个 const const 指针，其指向的对象也无法被修改

> [!NOTE] this 指针的传导性
> const 成员函数内部，不能调用非 const 成员函数

## static 成员函数无法 const

原因很简单，static 成员函数属于类而不是对象，内部没有 this 指针的参与
## mutable keyword

const 成员函数不能修改任何成员变量，这是一个非常强的限定

mutable 关键字声明的成员变量，可以在 const 成员函数中进行修改，增加灵活性

```cpp
class A
{
public:
    int a;
    mutable int b;

    void const_func() const {
	    // 错误，在 const 成员函数中修改成员变量
        this->a = 10;
        // 可行
        this->b = 20;
    };
};

int main()
{
    const A c;
    c.const_func();
}
```


- [ ] 引用和 const 的结合
	- 在函数参数中，用引用作为 out 传值出来，不用 const
	- 标识为 const 引用的参数，说明其作为 in 参数，而不是 out