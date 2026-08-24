---
title: C++ 游戏 deltaTime 时间增量完整用法
---

# C++ 游戏 deltaTime 时间增量完整用法

## 一、先搞懂 deltaTime 是什么

`deltaTime` = **上一帧渲染所耗费的时间，单位：秒 (s)**
 举例：60 帧稳定运行时，单帧耗时约 `0.01667s`

- 帧率高 → deltaTime 小
- 帧率低、卡顿 → deltaTime 变大

**核心目的：让动画、移动速度不受帧率高低影响，速度恒定。**
 不用帧数计数，所有运动公式都乘以 `deltaTime`。

## 二、标准公式（万能通用）

速度单位统一为：**单位 / 秒**（像素 /s、米 /s、角度 /s）

```cpp
// 位移
position.x += speedX * deltaTime;
position.y += speedY * deltaTime;

// 旋转
angle += rotateSpeed * deltaTime;

// 缩放、透明度、血量冷却等所有数值变化，全部乘 deltaTime
```

## 三、不同框架获取 deltaTime 的方式

### 1. Raylib（最简单）

```cpp
#include <raylib.h>

int main()
{
    InitWindow(800, 600, "DeltaTime Demo");
    Vector2 pos = { 100, 300 };
    const float speed = 200.0f; // 200 像素/秒

    while (!WindowShouldClose())
    {
        // 直接获取
        float deltaTime = GetFrameTime();

        // 左右移动
        if (IsKeyDown(KEY_D)) pos.x += speed * deltaTime;
        if (IsKeyDown(KEY_A)) pos.x -= speed * deltaTime;

        BeginDrawing();
        ClearBackground(WHITE);
        DrawCircleV(pos, 20, RED);
        EndDrawing();
    }
    CloseWindow();
    return 0;
}
```

### 2. SFML

```cpp
sf::Clock clock; // 计时器
sf::Time lastTime;

// 主循环开头
float deltaTime = clock.restart().asSeconds();
```

### 3. GLFW + OpenGL 原生手写（底层）

```cpp
float lastFrame = 0.0f;

// 循环内
float currentFrame = glfwGetTime();
float deltaTime = currentFrame - lastFrame;
lastFrame = currentFrame;
```

### 4. UE C++

```cpp
// Actor 的 Tick 函数自带参数 DeltaSeconds
virtual void Tick(float DeltaSeconds) override;
```

## 四、实战 1：帧动画配合 deltaTime（时间驱动帧切换）

不要 `if(帧数++)`，要用计时器累加时间：

```cpp
std::vector<Texture2D> frames;
int currentFrame = 0;
float animTimer = 0.0f;
const float frameDuration = 0.1f; // 每帧持续 0.1秒

void Update(float deltaTime)
{
    animTimer += deltaTime;

    // 时间达标，切换下一帧
    if (animTimer >= frameDuration)
    {
        animTimer = 0.0f;
        currentFrame = (currentFrame + 1) % frames.size();
    }
}
```

帧率忽高忽低，动画播放速度依旧匀速。

## 五、实战 2：插值缓动动画 + deltaTime

```cpp
Vector2 start = {100, 200};
Vector2 end = {500, 200};
float totalDuration = 2.0f; // 总时长2秒
float elapsed = 0.0f;
Vector2 curPos = start;

void Update(float deltaTime)
{
    if(elapsed < totalDuration)
    {
        elapsed += deltaTime;
        float t = elapsed / totalDuration; // 进度 0 ~ 1

        // 线性插值 Lerp
        curPos.x = start.x + (end.x.x - start.x) * t;
        curPos.y = start.y + (end.y.y - start.y) * t;
    }
}
```

## 六、必加优化：限制最大 deltaTime（防卡顿跳变）

当游戏卡死、切窗口、断点暂停时，`deltaTime` 会瞬间变得极大（几秒），会导致物体瞬间飞出去。
**解决方案：封顶，设置最大值 0.1s**

```cpp
float deltaTime = GetFrameTime();
if (deltaTime > 0.1f) deltaTime = 0.1f;
```

## 七、两种模式对比：帧驱动 VS 时间驱动

### ❶ 错误写法：帧驱动（速度随帧率变化）

```cpp
// 帧率高跑飞快，帧率低走得慢，绝对不要用
if(IsKeyDown(KEY_D)) pos.x += 2;
```

### ❷ 正确写法：时间驱动（恒定速度）

```cpp
pos.x += 200.0f * deltaTime;
```

## 八、拓展：固定时间步（高级进阶）

日常移动动画用上面**可变时间步**就够用。
 物理、碰撞、逻辑计算推荐**固定步长（FixedDeltaTime，如 1/60s）**，逻辑更新与渲染解耦：

```cpp
const float fixedDT = 1.0f / 60.0f;
float accumulator = 0.0f;

// 循环
accumulator += deltaTime;
while (accumulator >= fixedDT)
{
    FixedUpdate(fixedDT); // 固定频率执行物理、逻辑
    accumulator -= fixedDT;
}
Render(); // 渲染不限帧率
```

适合做物理游戏、Rigidbody 刚体运动。

## 九、常见问题

1. **移动依旧忽快忽慢？** 检查单位是不是**像素 / 秒**，不要用像素 / 帧；确认 deltaTime 获取位置在主循环最开头。
2. **deltaTime 数值很小看不懂？** 1/60 ≈ 0.01667，是正常数值，乘以几百的速度才会得到合适的移动距离。
3. **跨平台帧率不一样？** deltaTime 机制天生跨平台兼容，Windows、Linux、手机运行速度完全一致。