# __declspec (allocate (".state")) 与 CR_STATE 完整底层原理

`CR_STATE` 本质就是对 `__declspec(allocate(".state"))` 的封装，**把所有标记变量统一放进 `.state` 自定义 PE 段**，是 cr.h Windows 平台实现热重载变量持久化的底层核心。

## 一、宏展开真相（Windows MSVC）

原版 cr.h 的 `CR_STATE` 完整展开代码：

```cpp
// 插件DLL端（未定义 CR_HOST）
#define CR_STATE  __declspec(allocate(".state")) static
```

你写的代码：

```cpp
static int CR_STATE count = 0;
```

预处理后等价于原生写法：

```cpp
__declspec(allocate(".state")) static int count = 0;
```

### 配套段声明（cr.h 内置）

头文件自带段定义，无需手动写 pragma：

```cpp
#pragma section(".state", readwrite) // 可读可写数据段
```

作用：告诉 MSVC 链接器，把变量**脱离默认的 .data 全局数据段**，单独归集到专属 `.state` 段内。

## 二、.state 段实现热重载保数据完整流程

1. **编译阶段归集变量**
   所有带 `CR_STATE / __declspec(allocate(".state"))` 的静态变量，**严格按照源码从上到下的书写顺序**，紧凑排布在 `.state` 段，形成一块连续内存缓冲区。宿主端（定义`CR_HOST`）会解析 DLL 的 PE 文件，读取 `.state` 段的**起始地址、总大小、变量排布顺序**。
2. **卸载旧 DLL（CR_UNLOAD）**
   宿主在 FreeLibrary 销毁旧插件库前，**完整拷贝整块 .state 段内存到宿主 EXE 的堆内存缓存**。
   普通全局变量在默认.data 段，随 DLL 模块一起释放；但`.state`段的内存快照被宿主提前存下。
3. **加载新编译的 DLL（CR_LOAD）**
   新 DLL 依然会生成同名 `.state` 段，变量**顺序、数量、类型必须和旧版完全对应**。宿主直接把缓存的旧内存整块回填到新 DLL 的 `.state` 段起始地址，变量数值自动恢复，完成持久化。

## 三、手动原生写法（不用 CR_STATE 宏，直接用 allocate）

可以脱离 CR 宏，手写实现一模一样的持久效果，方便调试：

```cpp
#include "cr.h"

// 1. 自定义.state段（cr.h内部已自带，可省略）
#pragma section(".state", readwrite)

// 手动指定放入.state段，等价 CR_STATE
__declspec(allocate(".state")) static int counter = 0;
__declspec(allocate(".state")) static float camera[3] = {0,0,5};

CR_EXPORT int cr_main(struct cr_plugin* ctx, enum cr_op op)
{
    switch(op)
    {
    case CR_LOAD:
        counter++; // 重载后数值保留
        break;
    }
    return 0;
}
```

## 四、核心硬性规则（决定成败）

### 1. 变量顺序绝对不能乱

CR 依靠**声明顺序**一一映射内存，和变量名无关：

- ✅ 新增变量必须写在所有 CR_STATE 变量**末尾**
- ❌ 中间插入、删除、调换变量顺序 → 内存错位、数值错乱、直接崩溃
- ❌ 变量类型修改（int 改 bool）→ 内存解析错误

### 2. 仅支持 POD 纯数据类型

✅ 合法：int /float/bool / 定长 char 数组 / 无构造析构纯 C 结构体
 ❌ 禁止：`std::string`/`vector`、带虚函数类、指针、函数指针
 容器内部堆内存属于旧 DLL 模块，卸载时释放，新模块指针悬空必定崩溃。

### 3. CR_HOST 编译宏必须区分

- **宿主 EXE**：`#define CR_HOST` 再 include cr.h，负责读取、缓存、回填 `.state` 段内存
- **插件 DLL**：不能定义 CR_HOST，只负责定义 `.state` 段变量 搞反会直接导致 `.state` 逻辑失效。

## 五、常见问题排查

### 1. CR_STATE 失效，变量每次重载归零

1. 宿主 / 插件 `CR_HOST` 宏配置颠倒；
2. 手动定义了 `#define CR_MODE CR_DISABLE`，关闭了状态同步；
3. 混用非 POD 的 STL 容器作为 CR_STATE 变量。

### 2. 新版重载后数值错乱

大概率修改了旧变量的顺序、类型、数量，解决方案：

1. 所有新增持久变量追加到末尾；
2. 重大结构改动时，清空编译缓存，配合文件序列化做版本兼容。

### 3. Linux GCC 对应写法

Windows 用`__declspec(allocate(".state"))`，GCC Linux 用 GNU 属性实现同功能：

```cpp
static int __attribute__((section(".state"))) counter = 0;
```

## 六、优缺点与选型

### 优点

极简零耦合，插件端仅需修饰变量，**完全不需要宿主导出函数、共享内存**，开发效率极高，适合编辑器 UI 开关、摄像机坐标、计数这类轻量运行状态。

### 缺点

1. 变量顺序约束严格，大型结构体重构麻烦；
2. 无法保存引擎指针、AngelScript 上下文、动态容器；
3. 仅进程生命周期有效，程序重启数据丢失。

### 搭配你的 SDL+ImGui+AngelScript 编辑器最佳方案

1. **UI 开关、临时计数、摄像机坐标**：`.state`段 + CR_STATE 首选；
2. **AngelScript 引擎、ImGui 上下文、动态数组**：全部放到宿主 EXE 内存，插件只持有指针；
3. 需要程序重启存档：在`CR_UNLOAD`回调里，将.state 段变量序列化写入 JSON / 二进制文件。