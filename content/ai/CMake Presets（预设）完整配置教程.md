---
title: CMake Presets（预设）完整配置教程
---

# CMake Presets（预设）完整配置教程

CMake Presets 用 **`CMakePresets.json`** 统一管理编译环境：编译器、构建器（Ninja/VS/Make）、架构、Debug/Release、环境变量、第三方库路径、构建输出目录，一次配置全平台 / IDE（VS2022、CLion、VSCode、命令行）通用，彻底告别零散的 `-D` 参数。

## 一、基础概念

1. **两个配置文件**
   - `CMakePresets.json`：**项目公共配置**，提交 Git，团队共用
   - `CMakeUserPresets.json`：**个人本地私有配置**，`.gitignore`忽略，存放本机编译器路径、个人环境
2. 三大预设模块
   - `configurePresets`：**配置阶段预设**（核心），对应 `cmake 配置`
   - `buildPresets`：**编译构建预设**，绑定配置预设，对应 `cmake --build`
   - `testPresets`：测试预设（可选）
3. 最低版本：CMake ≥ **3.19** 支持 Presets，推荐 `version: 3` 及以上。

## 二、最简完整模板（Windows MSVC Ninja，最常用）

在项目**根目录**新建 `CMakePresets.json`，完整可直接使用：

```json
{
  "version": 3,
  "configurePresets": [
    // 基础父预设，子预设继承通用配置
    {
      "name": "base",
      "hidden": true,  // 隐藏，仅用来继承，不可直接选中
      "generator": "Ninja",  // 构建器：Ninja(最快) / Visual Studio 17 2022 / Unix Makefiles
      "binaryDir": "${sourceDir}/out/build/${presetName}", // 编译产物目录
      "installDir": "${sourceDir}/out/install/${presetName}", // install安装目录
      "architecture": {
        "value": "x64", // 架构 x64 / x86
        "strategy": "external"
      },
      "cacheVariables": {
        "CMAKE_CXX_STANDARD": "17",
        "CMAKE_CXX_STANDARD_REQUIRED": "ON",
        // MSVC运行库 MD/MDd（动态） MT/MTd（静态）
        "CMAKE_MSVC_RUNTIME_LIBRARY": "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL"
      }
    },
    // Debug子预设，继承base
    {
      "name": "debug-x64",
      "displayName": "Debug x64 MSVC",
      "inherits": "base",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug",
        "CMAKE_C_COMPILER": "cl.exe",
        "CMAKE_CXX_COMPILER": "cl.exe"
      }
    },
    // Release子预设
    {
      "name": "release-x64",
      "displayName": "Release x64 MSVC",
      "inherits": "base",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Release"
      }
    }
  ],
  // 构建预设，绑定上面的配置预设
  "buildPresets": [
    {
      "name": "build-debug",
      "displayName": "编译 Debug",
      "configurePreset": "debug-x64",
      "targets": ["all"], // 编译全部目标，可指定exe名
      "cleanFirst": false // 编译前是否清空缓存
    },
    {
      "name": "build-release",
      "displayName": "编译 Release",
      "configurePreset": "release-x64"
    }
  ]
}
```

## 三、核心常用配置详解（配置编译环境关键项）

### 1. 切换构建生成器 `generator`

```json
// 1. Ninja（跨平台最快，IDE首选）
"generator": "Ninja"
// 2. Visual Studio 2022 解决方案
"generator": "Visual Studio 17 2022"
// 3. MinGW Makefiles（Windows GCC）
"generator": "MinGW Makefiles"
// 4. Linux/macOS Make
"generator": "Unix Makefiles"
```

### 2. 指定编译器路径（MinGW/GCC/Clang 必配）

#### Windows MinGW 示例

```json
"environment": {
  "PATH": "D:/mingw64/bin;$penv{PATH}" // 临时追加mingw到环境变量
},
"cacheVariables": {
  "CMAKE_C_COMPILER": "gcc.exe",
  "CMAKE_CXX_COMPILER": "g++.exe"
}
```

#### Linux GCC

```json
"cacheVariables": {
  "CMAKE_C_COMPILER": "/usr/bin/gcc",
  "CMAKE_CXX_COMPILER": "/usr/bin/g++"
}
```

### 3. 配置第三方 DLL/Lib 路径（对接之前 dll 链接需求）

在 `cacheVariables` 配置头文件、库搜索路径，替代 CMakeLists 硬编码：

```json
"cacheVariables": {
  // 头文件目录
  "CMAKE_INCLUDE_PATH": "${sourceDir}/thirdparty/include",
  // lib库搜索目录
  "CMAKE_LIBRARY_PATH": "${sourceDir}/thirdparty/lib/Release",
  // Qt/第三方库根路径
  "CMAKE_PREFIX_PATH": "D:/Qt6.5.0/6.5.0/msvc2019_64"
}
```

### 4. 环境变量配置 `environment`

用于临时修改 PATH、动态库路径，运行时加载 dll 生效：

```json
"environment": {
  // 追加dll目录到PATH，运行自动找dll
  "PATH": "${sourceDir}/thirdparty/lib/Release;$penv{PATH}",
  "MY_LIB_ROOT": "${sourceDir}/thirdparty"
}
```

`$penv{PATH}` 代表**原有系统 PATH**，不要覆盖。

### 5. 引入工具链文件 `toolchainFile`

交叉编译、Android / 嵌入式必备，直接指定 toolchain.cmake 路径：

```json
"toolchainFile": "${sourceDir}/toolchain/arm-gcc.cmake"
```

## 四、命令行使用 Presets（万能通用）

### 1. 查看所有预设

```bash
cmake --list-presets
```

### 2. 执行配置（对应 configurePreset）

```bash
# 配置debug-x64预设
cmake --preset debug-x64
# 清空缓存重新配置
cmake --preset debug-x64 --fresh
```

### 3. 执行编译（对应 buildPreset）

```bash
cmake --build --preset build-debug
# 只编译单个目标exe
cmake --build --preset build-debug --target main.exe
# Release编译
cmake --build --preset build-release
```

### 4. 安装文件到 installDir

```bash
cmake --install out/install/debug-x64
```

## 五、主流 IDE 启用 Presets

### 1. Visual Studio 2022

1. 工具 → 选项 → CMake → 常规
2. 勾选 **Always use CMakePresets.json**![](data:image/svg+xml,%3csvg%20xmlns=%27http://www.w3.org/2000/svg%27%20version=%271.1%27%20width=%27256%27%20height=%27192%27/%3e)![image](https://p3-flow-imagex-sign.byteimg.com/labis/image/6cec0169e1ae11eaceac0b80af4ba35f~tplv-a9rns2rl98-pc_smart_face_crop-v1:512:384.image?lk3s=8e244e95&rcl=202606232145071C7F8FBE88F53F5ABD77&rrcfp=cee388b0&x-expires=2097582354&x-signature=oGM%2FBDXKZBGoa1wyEykY5IPsNA4%3D)
3. 重新打开项目，顶部下拉框直接选择预设一键配置编译。

### 2. CLion

打开项目自动识别根目录`CMakePresets.json`，右下角 CMake 配置直接读取所有预设。

![](data:image/svg+xml,%3csvg%20xmlns=%27http://www.w3.org/2000/svg%27%20version=%271.1%27%20width=%27256%27%20height=%27192%27/%3e)![image](https://p3-flow-imagex-sign.byteimg.com/labis/image/bc8c6c36ae829258bc8882cdf4485183~tplv-a9rns2rl98-pc_smart_face_crop-v1:512:384.image?lk3s=8e244e95&rcl=202606232145071C7F8FBE88F53F5ABD77&rrcfp=cee388b0&x-expires=2097582356&x-signature=vOZv7aA94QIzxT80mPVcI8iCWZU%3D)

### 3. VSCode（CMake Tools 插件）

插件会自动加载 Presets，状态栏可以切换预设、执行配置 / 构建。

## 六、进阶实用技巧

### 1. 预设继承（复用配置，减少冗余）

父预设设置公共参数，子预设仅修改差异化内容，模板中的`base`隐藏预设就是标准写法。

### 2. 平台条件判断（Windows/Linux 自动区分）

```json
{
  "name": "linux-gcc",
  "displayName": "Linux GCC Debug",
  "inherits": "base",
  "condition": {
    "type": "equals",
    "lhs": "${hostSystemName}",
    "rhs": "Linux"
  },
  "cacheVariables": {
    "CMAKE_C_COMPILER": "gcc",
    "CMAKE_CXX_COMPILER": "g++"
  }
}
```

### 3. 私有配置 CMakeUserPresets.json

本机编译器路径放这里，不和团队同步，格式完全一致：

```json
{
  "version": 3,
  "configurePresets": [
    {
      "name": "local-mingw",
      "inherits": "base",
      "environment": {
        "PATH": "E:/mingw-w64/bin;$penv{PATH}"
      }
    }
  ]
}
```

## 七、常见踩坑

1. **CMake 版本过低**：升级 CMake ≥3.19，建议 3.25+
2. **Ninja 提示找不到 cl.exe**：MSVC 必须在**x64 Native Tools 命令行**运行，或 Presets 配置正确的 PATH 环境变量
3. **Debug/Release 运行库不匹配**：Presets 的`CMAKE_MSVC_RUNTIME_LIBRARY`必须和第三方 dll 库一致
4. **路径包含中文 / 空格**：尽量使用英文路径，JSON 路径用正斜杠 `/`，不要用反斜杠 `\`
5. 修改 Presets 后**必须重载 CMake 项目**，配置才会生效。