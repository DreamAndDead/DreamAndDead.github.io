---
title: PowerShell 将 CMake Trace 日志输出到文件（完整命令）
---

# PowerShell 将 CMake Trace 日志输出到文件（完整命令）

## 1. 完整追踪 trace-expand（最常用，变量完全展开）

```powershell
# 标准输出 + 错误流 全部写入日志文件，同时控制台也打印
cmake --trace-expand --preset clang-multi-win64 --fresh 2>&1 | Tee-Object -FilePath cmake_trace.log -Append
```

## 2. 精简 trace（不展开变量，速度更快）

```powershell
cmake --trace --preset clang-multi-win64 --fresh 2>&1 | Tee-Object cmake_simple_trace.log
```

## 3. 只写入文件，控制台不输出

```powershell
cmake --trace-expand --preset clang-multi-win64 --fresh > cmake_trace.log 2>&1
```

## 参数说明

1. `2>&1` CMake 的警告、错误、TRACE 日志大部分走**标准错误流 stderr**，不加这句日志会丢失大半。
2. `Tee-Object` 同时屏幕打印 + 写入文件，调试首选。
3. `-Append` 追加写入，不加则每次运行覆盖旧日志。

## 4. 过滤冗余日志（只看自己项目，过滤系统 CMake 文件）

PowerShell 管道过滤路径，剔除系统 CMake 内置脚本，只保留你的源码：

```powershell
cmake --trace-expand --preset clang-multi-win64 --fresh 2>&1 | Where-Object { $_ -notmatch 'CMake\/share|Program Files' } | Tee-Object cmake_filtered.log
```

## 5. 超长日志拆分 / 限定日志级别（配合 `CMAKE_MESSAGE_LOG_LEVEL=TRACE`）

Preset 提前开启 TRACE 日志等级，再导出：

```json
"cacheVariables": {
  "CMAKE_MESSAGE_LOG_LEVEL": "TRACE"
}
```

再执行上面的导出命令。

## 6. 构建阶段（build）verbose 日志导出（编译完整命令）

```powershell
cmake --build --preset build-clang-debug --verbose 2>&1 | Tee-Object build_verbose.log
```

## 7. 快速打开日志文件

```powershell
notepad.exe cmake_trace.log
# 或者用 VS Code
code cmake_trace.log
```