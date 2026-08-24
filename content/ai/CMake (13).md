# Windows CMake 现代方案，**彻底规避手动写 POST_BUILD 复制 dll**

先讲底层硬性前提：
**Windows 操作系统原生没有 Linux 的 RPATH 运行时嵌入路径机制**，exe 运行时只会固定搜索：`exe当前目录 → 系统System32 → 全局PATH环境变量`，CMake**无法在编译阶段写入自定义 dll 搜索路径到 exe 二进制内**。
 所以「完全不拷贝、不复制文件」只有两类正统现代方案，外加行业标准工程化方案，按推荐优先级排序：

## 方案 1：同源构建，SDL 源码纳入当前 CMake 编译（最优现代方案）

把 SDL 源码放进你的`thirdparty/SDL`，用`add_subdirectory`纳入当前工程一起编译，**SDL 编译产出的 SDL2.dll，会自动和你的 exe 输出到同一个 bin 目录**，完全不需要任何复制脚本。

### 完整配置

1. 统一全局输出目录（核心）

```cmake
# 放在最顶层CMake开头
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin/$<CONFIG>) # exe + dll 统一输出这里
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib/$<CONFIG>)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib/$<CONFIG>)
```

2. 引入 SDL 源码子目录

```cmake
# thirdparty/SDL 为SDL完整源码根目录，自带官方CMakeLists.txt
add_subdirectory(thirdparty/SDL EXCLUDE_FROM_ALL)

# 链接目标
add_executable(App src/main.cpp)
target_link_libraries(App PRIVATE SDL2::SDL2) # 动态库
```

### 效果

Ninja 编译完成后：
`out/build/xxx/bin/Debug/App.exe`
`out/build/xxx/bin/Debug/SDL2.dll`
 两者天然同级，Windows 自动识别，直接运行正常。
 ✅ 优点：

- 纯现代 CMake 目标管理，导入目标、依赖完全托管，无硬编码路径、无手动复制命令；
- Debug/Release 自动区分`SDL2d.dll`/`SDL2.dll`，架构 x64 自动对齐；
- 后续升级 SDL 只需要替换源码，CMake 逻辑完全不用改。

## 方案 2：开发环境把 SDL 的 bin 目录永久加入 Preset 环境 PATH（纯调试免复制）

编译用的第三方预编译 SDL（外部二进制），不在项目内编译，**配置 Presets.json，给当前构建预设注入 PATH 环境变量**，Ninja 构建时自动继承 SDL 的 dll 目录，运行时进程 PATH 自带 SDL 路径，不用拷贝 dll。

### CMakePresets.json 配置（你的 clang/msvc ninja 预设）

```json
{
  "name": "clang-ninja-debug",
  "generator": "Ninja",
  "binaryDir": "${sourceDir}/out/build/${presetName}",
  "environment": {
    "PATH": "${sourceDir}/thirdparty/SDL/bin/x64;$env{PATH}"
  },
  "toolchainFile": "${sourceDir}/toolchain/clang-win.toolchain.cmake",
  "cacheVariables": {
    "CMAKE_EXPORT_COMPILE_COMMANDS": "ON"
  }
}
```

### 使用规则

1. 每次用该 preset 配置、编译、运行程序，**必须在该预设对应的终端环境内启动 exe**；
2. 进程启动时会读取预设注入的 PATH，直接找到`SDL2.dll`； ✅ 适合本地开发调试，零文件复制；❌ 打包发布不能用，别的电脑没有这个 PATH。

## 方案 3：彻底根除 dll 依赖：链接 SDL 静态库（终极免 dll 方案）

动态 dll 报错的根源是动态链接，改用 SDL 静态编译，把 SDL 代码编译打包进 exe 内部，**运行完全不需要 SDL2.dll**，也是现代工程正式发布首选方案。

### CMake 写法

#### 方式 A：子源码编译静态 SDL

```cmake
# 进入SDL子目录前，强制开启静态、关闭动态
set(SDL_SHARED OFF CACHE BOOL "" FORCE)
set(SDL_STATIC ON CACHE BOOL "" FORCE)
add_subdirectory(thirdparty/SDL EXCLUDE_FROM_ALL)

# 链接静态目标
target_link_libraries(App PRIVATE SDL2::SDL2-static)
# Windows静态SDL必须补齐系统依赖库
target_link_libraries(App PRIVATE winmm imm32 version setupapi)
```

#### 方式 B：find_package 链接预编译静态 SDL

```cmake
find_package(SDL2 REQUIRED CONFIG)
target_link_libraries(App PRIVATE SDL2::SDL2-static)
```

编译产物只有单一`App.exe`，不存在 dll 缺失问题。

## 方案 4：现代 CMake 官方标准化部署：install 运行时依赖收集（发布标准方案）

很多人误以为`POST_BUILD复制`是正规方案，实际上 CMake 官方现代部署标准是 **`install(RUNTIME_DEPENDENCY_SET)`**（CMake 3.21+），自动扫描所有导入第三方目标的运行时 dll（SDL、ImGui 以外的所有第三方动态库），打包安装时自动归集所有依赖，**构建调试阶段不用复制，发布打包一键收集全部 dll**。

### 完整 CMake 代码

```cmake
# 1. 注册可执行程序，生成依赖集合
install(TARGETS App
    RUNTIME_DEPENDENCY_SET App_RuntimeDeps
    RUNTIME DESTINATION bin
)

# 2. 自动收集所有运行时dll，安装到打包目录bin
install(RUNTIME_DEPENDENCY_SET App_RuntimeDeps
    DESTINATION bin
    # 可选：排除系统VC运行库、系统自带dll，只收集第三方库
    POST_EXCLUDE_REGEXES "^(vcruntime|ucrtbase|kernel32|user32)"
)
```

### 执行打包命令

```bash
# 安装收集所有dll到out/install目录
cmake --install out/build/clang-ninja-debug --prefix out/install/clang-debug
```

执行完毕，`out/install/clang-debug/bin` 内同时存在 `App.exe` + `SDL2.dll`，打包直接分发。
 适用场景：**开发调试依然用方案 1/2，打包发布用这套官方依赖收集，完全摒弃手写复制命令**，是工业级 CMake 的标准做法。

# 淘汰旧写法说明

1. 老式 `add_custom_command POST_BUILD + copy` 属于**临时应急写法**，硬编码 dll 路径，跨 Debug/Release、跨平台极易出错，不属于现代 CMake 规范；
2. Windows**没有任何编译参数可以让 exe 跨目录自动加载 dll**，网上的「运行时 rpath」仅 Linux/macOS 有效，Windows 不支持。

# 针对你当前 SDL+Ninja+Clang/ImGui 项目的最佳组合建议

1. **日常本地开发调试**：方案 1（SDL 子目录同源编译，统一输出 bin 文件夹），零复制、零 PATH 配置，最省心；
2. **版本打包发布**：方案 3（静态 SDL）单 exe 分发，或者方案 4 install 自动收集依赖打包；
3. 预编译第三方二进制 SDL（不想编译 SDL 源码）：用方案 2 Preset 环境 PATH，仅限本机开发。