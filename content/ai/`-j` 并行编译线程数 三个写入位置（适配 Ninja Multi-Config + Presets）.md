---
title: "`-j` 并行编译线程数 三个写入位置（适配 Ninja Multi-Config + Presets）"
---

# `-j` 并行编译线程数 三个写入位置（适配 Ninja Multi-Config + Presets）

## 1. 写在 `buildPresets`（**最推荐、现代标准写法，永久固化**）

直接在 build preset 配置 `jobs` 字段，等价命令行 `-jN`，CMake Tools 界面构建自动生效。

```json
"buildPresets": [
  {
    "name": "build-clang-debug",
    "configurePreset": "clang-multi-win64",
    "configuration": "Debug",
    "jobs": 12    // 对应 ninja -j12
  },
  {
    "name": "build-clang-release",
    "configurePreset": "clang-multi-win64",
    "configuration": "Release",
    "jobs": 16
  }
]
```

命令行执行自动带线程数：

```bash
cmake --build --preset build-clang-debug
# 底层等价 ninja -j12
```

## 2. VSCode CMake Tools 全局配置（界面默认并行数）

`.vscode/settings.json`，全局默认 jobs，所有 build 共用：

```json
{
  "cmake.parallelJobs": 12
}
```

优先级：`buildPresets.jobs` > 全局 `parallelJobs`。

## 3. 命令行临时手动指定（临时测试，不固化）

```powershell
# --parallel 简写 -j
cmake --build --preset build-clang-debug --parallel 12
```

## 补充规则

1. **Ninja 会自动识别 CPU 核心** 设置 `jobs: 0` 代表使用全部 CPU 核心自动并行。

```json
"jobs": 0
```

2. Multi-Config 完全通用，Debug/Release 可以设置不同线程数。
3. 不要写进 configurePreset /toolchain/ CMakeLists`-j` 属于**构建阶段参数**，不属于配置阶段缓存变量，放 configure preset 完全无效。

## 常用线程参考

- 6 核 12 线程 CPU：`jobs: 12`
- 8 核 16 线程 CPU：`jobs: 16`
- 内存偏小：适当降低线程数，避免编译 OOM。