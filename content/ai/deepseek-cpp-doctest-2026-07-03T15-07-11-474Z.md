# DeepSeek Export
Conversation: cpp doctest
URL: https://chat.deepseek.com/a/chat/s/77c96571-6096-40c1-8bdd-a8897a80baf7
Exported: 2026-07-03T15:07:11.474Z

## User

如何判断两个结构体相等

## Assistant

在 doctest 中判断两个结构体相等，有几种方法，从简单到复杂依次是：

---

## 🎯 方法一：逐字段比较（最常用）

直接比较结构体的每个成员：

cpp

```cpp
struct Point {
int x;
int y;
};

TEST_CASE("测试 Point 相等") {
Point p1{1, 2};
Point p2{1, 2};

// 逐字段比较
CHECK(p1.x == p2.x);
CHECK(p1.y == p2.y);

// 或者组合成表达式
CHECK((p1.x == p2.x && p1.y == p2.y));
}
```

---

## 🎯 方法二：重载 `operator==`（推荐）

为结构体实现 `operator==`，然后直接用 `CHECK`：

cpp

```cpp
struct Point {
int x;
int y;

// 重载相等运算符
bool operator==(const Point& other) const {
return x == other.x && y == other.y;
}

// 可选：重载不等运算符
bool operator!=(const Point& other) const {
return !(*this == other);
}
};

TEST_CASE("测试 Point 相等") {
Point p1{1, 2};
Point p2{1, 2};
Point p3{3, 4};

CHECK(p1 == p2);  // ✅ 通过
CHECK(p1 == p3);  // ❌ 失败，显示详细信息
}
```

**失败时的输出**（doctest 会分解表达式）：

text

```text
CHECK(p1 == p3) failed with lhs=Point{1,2}, rhs=Point{3,4}
```

---

## 🎯 方法三：自定义比较函数

如果不想重载运算符，可以写一个比较函数：

cpp

```cpp
struct Point {
int x;
int y;
};

bool points_equal(const Point& a, const Point& b) {
return a.x == b.x && a.y == b.y;
}

TEST_CASE("测试 Point 相等") {
Point p1{1, 2};
Point p2{1, 2};

CHECK(points_equal(p1, p2));
}
```

---

## 🎯 方法四：使用 `CHECK_EQ` \+ 自定义 `operator==`

结合快速断言宏：

cpp

```cpp
struct Point {
int x;
int y;

bool operator==(const Point& other) const {
return x == other.x && y == other.y;
}
};

TEST_CASE("使用快速断言") {
Point p1{1, 2};
Point p2{1, 2};

CHECK_EQ(p1, p2);  // 需要 DOCTEST_CONFIG_SUPER_FAST_ASSERTS
}
```

---

## 🎯 方法五：嵌套结构体

对于嵌套结构体，同样需要递归比较：

cpp

```cpp
struct Point {
int x;
int y;

bool operator==(const Point& other) const {
return x == other.x && y == other.y;
}
};

struct Rectangle {
Point top_left;
Point bottom_right;
int area;

bool operator==(const Rectangle& other) const {
return top_left == other.top_left &&
bottom_right == other.bottom_right &&
area == other.area;
}
};

TEST_CASE("测试 Rectangle 相等") {
Rectangle r1{{0, 0}, {10, 10}, 100};
Rectangle r2{{0, 0}, {10, 10}, 100};

CHECK(r1 == r2);  // ✅
}
```

---

## 🎯 方法六：使用 C\+\+20 的默认比较（现代 C\+\+）

如果你的编译器支持 C\+\+20，可以使用默认的 `operator==`：

cpp

```cpp
struct Point {
int x;
int y;

// C++20: 自动生成所有比较运算符
auto operator<=>(const Point&) const = default;
};

TEST_CASE("C++20 默认比较") {
Point p1{1, 2};
Point p2{1, 2};

CHECK(p1 == p2);
CHECK(p1 != Point{3, 4});
}
```

---

## 🔍 方法七：失败时打印详细信息

使用 `CAPTURE` 或 `INFO` 在失败时显示更多信息：

cpp

```cpp
struct Point {
int x;
int y;

bool operator==(const Point& other) const {
return x == other.x && y == other.y;
}
};

TEST_CASE("详细失败信息") {
Point p1{1, 2};
Point p2{3, 4};

CAPTURE(p1.x, p1.y, p2.x, p2.y);
CHECK(p1 == p2);
// 失败时会输出:
// CAPTURED: p1.x=1, p1.y=2, p2.x=3, p2.y=4
}
```

---

## 📊 各方法对比

| 方法 | 优点 | 缺点 | 适用场景 |
| --- | --- | --- | --- |
| 逐字段比较 | 简单直观，无侵入 | 代码冗长 | 临时测试 |
| 重载 `operator==` | 代码简洁，可复用 | 需要修改结构体 | 经常比较 |
| 自定义函数 | 不侵入结构体 | 不够直观 | 不能修改结构体 |
| C\+\+20 默认比较 | 最简洁 | 需要 C\+\+20 | 现代项目 |
| `CAPTURE` \+ 断言 | 失败信息详细 | 代码稍多 | 调试复杂结构 |

---

## 💡 最佳实践

### 推荐方案：重载 `operator==`

cpp

```cpp
struct MyStruct {
int id;
std::string name;
std::vector<int> values;

bool operator==(const MyStruct& other) const {
return id == other.id &&
name == other.name &&
values == other.values;  // vector 支持 ==
}
};

TEST_CASE("完整示例") {
MyStruct actual{1, "test", {1, 2, 3}};
MyStruct expected{1, "test", {1, 2, 3}};

CHECK(actual == expected);
}
```

### 处理浮点数

如果结构体有浮点数，需要带精度比较：

cpp

```cpp
struct Vector3D {
float x, y, z;

bool operator==(const Vector3D& other) const {
const float epsilon = 1e-6f;
return std::abs(x - other.x) < epsilon &&
std::abs(y - other.y) < epsilon &&
std::abs(z - other.z) < epsilon;
}
};

TEST_CASE("浮点数比较") {
Vector3D v1{1.0f, 2.0f, 3.0f};
Vector3D v2{1.000001f, 2.000001f, 3.000001f};

CHECK(v1 == v2);  // ✅ 在误差范围内相等
}
```

### 处理指针/动态内存

cpp

```cpp
struct Node {
int value;
Node* next;

bool operator==(const Node& other) const {
if (value != other.value) return false;
if (next == nullptr && other.next == nullptr) return true;
if (next == nullptr || other.next == nullptr) return false;
return *next == *other.next;  // 递归比较
}
};
```

---

## 🚨 常见陷阱

### 1. 忘记重载比较运算符

cpp

```cpp
struct Point { int x, y; };
// 没有 operator==

TEST_CASE("错误示例") {
Point p1{1, 2};
Point p2{1, 2};
CHECK(p1 == p2);  // ❌ 编译错误！没有 == 运算符
}
```

### 2. 只重载了部分运算符

cpp

```cpp
struct Point {
int x, y;
bool operator==(const Point& other) const { /* ... */ }
// 忘记重载 !=
};

CHECK(p1 != p2);  // ❌ 编译错误！没有 != 运算符
```

**解决**：使用 `CHECK(!(p1 == p2))` 或同时重载 `!=`。

---

## 🎯 总结

对于 doctest 中结构体相等比较：

1.
**最简单**：在结构体中重载 `operator==`
2.
**最直接**：逐字段比较
3.
**最现代**：C\+\+20 默认比较
4.
**最灵活**：自定义比较函数

推荐使用**重载 `operator==`** 方式，既简洁又易于维护。如果有浮点数，记得加容差比较。
