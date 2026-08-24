# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-29T02:12:50.596Z

## User

cmake 引入项目  并加入addon

## Assistant

在CMake项目中集成AngelScript及其官方Add-On，最可靠的方式是通过 `add_subdirectory` 引入AngelScript的构建脚本，并将需要的Add-On源文件直接添加到你的项目中编译。下面是一套完整的配置方案。

### 📁 项目结构建议

首先，在你的项目目录下组织好AngelScript SDK。这里以一个常见的 `libs` 目录为例：

text

```text
你的项目/
├── CMakeLists.txt
├── libs/
│   └── angelscript-mirror/      # AngelScript SDK 根目录
│       └── sdk/
│           ├── angelscript/     # 核心库
│           │   ├── include/
│           │   └── projects/cmake/
│           └── add_on/          # 官方扩展
│               ├── scriptstdstring/
│               └── scriptarray/  # 如果你需要数组
└── src/
└── main.cpp
```

### ⚙️ 核心 CMakeLists.txt 配置

在你的根 `CMakeLists.txt` 中，参考以下配置。这个方案综合了社区实践，能应对大部分常见问题[-1](https://gamedev.net/forums/topic/710284-build-static-library-with-cmake-and-visual-studio/)[-3](https://gamedev.net/forums/topic/607375-integrating-angelscript-into-existing-codebase-cmake/?comment=4842180&do=findComment)[-4](https://www.gamedev.net/forums/topic/713376-trouble-compiling-test-project/5452868)。

cmake

```cmake
cmake_minimum_required(VERSION 3.10)
project(MyAngelscriptProject)

# 1. 引入 AngelScript 核心库的 CMake 构建脚本
# 这会定义一个名为 'angelscript' 的 CMake 目标 (Target)
add_subdirectory(libs/angelscript-mirror/sdk/angelscript/projects/cmake)

# 2. 创建你的可执行文件或库
add_executable(${PROJECT_NAME}
src/main.cpp
# 3. 直接将需要的 Add-On 源文件添加到你的项目中
libs/angelscript-mirror/sdk/add_on/scriptstdstring/scriptstdstring.cpp
# 如果有其他 Add-On，也在这里添加
# libs/angelscript-mirror/sdk/add_on/scriptarray/scriptarray.cpp
)

# 4. 指定头文件搜索路径
target_include_directories(${PROJECT_NAME} PUBLIC
libs/angelscript-mirror/sdk/angelscript/include    # AngelScript 核心头文件
libs/angelscript-mirror/sdk/add_on/scriptstdstring # scriptstdstring 头文件
# 其他 Add-On 头文件目录
)

# 5. 链接 AngelScript 核心库
# 注意：在社区实践中，目标名是小写的 'angelscript'，这是大小写敏感的[citation:1]
target_link_libraries(${PROJECT_NAME} PRIVATE angelscript)

# 6. (可选) 针对 Windows MSVC 编译器的特殊处理
# 社区报告指出，AngelScript 的 CMake 脚本可能对 MinGW 不友好，可以加上此判断[citation:3]
if(MSVC AND NOT MINGW)
# 某些环境下可能需要此定义来正确链接 DLL 版本
# target_compile_definitions(${PROJECT_NAME} PRIVATE ANGELSCRIPT_DLL_LIBRARY_IMPORT)
endif()
```

### 📝 配置要点与解释

1.
**引入核心库 \(`add_subdirectory`\)**: 这是最直接的方式，会利用AngelScript自带的CMake配置来构建静态库，并自动处理一些平台相关的编译选项（如Windows x64下的汇编文件）[-3](https://gamedev.net/forums/topic/607375-integrating-angelscript-into-existing-codebase-cmake/?comment=4842180&do=findComment)[-4](https://www.gamedev.net/forums/topic/713376-trouble-compiling-test-project/5452868)。
2.
**将Add-On源文件加入你自己的项目**: 与核心库不同，官方推荐的做法是将需要的Add-On源文件（如 `scriptstdstring.cpp`）**直接添加到你的项目中进行编译**，而不是将它们构建成另一个库[-1](https://gamedev.net/forums/topic/710284-build-static-library-with-cmake-and-visual-studio/)[-3](https://gamedev.net/forums/topic/607375-integrating-angelscript-into-existing-codebase-cmake/?comment=4842180&do=findComment)。这能避免复杂的依赖和链接问题。
3.
**链接核心库**: 在 `target_link_libraries` 中，你需要链接的目标名是 `angelscript`（全小写）。这是一个需要注意的细节，因为有些环境对大小写敏感[-1](https://gamedev.net/forums/topic/710284-build-static-library-with-cmake-and-visual-studio/)。
4.
**使用官方字符串扩展 \(`scriptstdstring`\)**:

-
你可以在你的C\+\+代码中包含 `<scriptstdstring.h>` 并调用 `RegisterStdString(engine)`，这样脚本就能直接使用 `string` 类型了[-5](https://angelcode.com/angelscript/sdk/docs/manual/doc_addon_std_string.html?_x_tr_sch=http)。
-
如果需要额外的字符串工具（如 `split` 方法），可以调用 `RegisterStdStringUtils(engine)`，但这需要 `scriptarray` 扩展的支持[-5](https://angelcode.com/angelscript/sdk/docs/manual/doc_addon_std_string.html?_x_tr_sch=http)。
-
你可以通过定义预处理器宏来调整其行为，例如在 `target_compile_definitions` 中添加 `AS_USE_STLNAMES=1` 来启用与C\+\+ STL相似的方法名[-5](https://angelcode.com/angelscript/sdk/docs/manual/doc_addon_std_string.html?_x_tr_sch=http)。

### ⚠️ 潜在问题与排查

-
**链接错误 \(unresolved external symbol\)**: 这通常是忘记链接 `angelscript` 库，或者Add-On的源文件未包含在项目中所致。请检查 `target_link_libraries` 和 `add_executable` 中的源文件列表[-4](https://www.gamedev.net/forums/topic/713376-trouble-compiling-test-project/5452868)。
-
**MinGW 编译错误**: 如果在Windows下使用MinGW，AngelScript自带的CMake脚本中的 `/MP` 编译选项可能不兼容。可以尝试在引入子目录前，通过 `set_target_properties` 或条件判断来处理[-3](https://gamedev.net/forums/topic/607375-integrating-angelscript-into-existing-codebase-cmake/?comment=4842180&do=findComment)。
-
**找不到头文件**: 确保 `target_include_directories` 包含了所有必要的路径，包括核心库的 `include` 目录和所有Add-On的根目录[-1](https://gamedev.net/forums/topic/710284-build-static-library-with-cmake-and-visual-studio/)[-3](https://gamedev.net/forums/topic/607375-integrating-angelscript-into-existing-codebase-cmake/?comment=4842180&do=findComment)。

这个配置提供了一个稳定且经过社区验证的基础。如果你在集成其他Add-On（如 `scriptarray` 或 `scriptdictionary`）时遇到特定的编译或链接问题，可以告诉我具体的错误信息，我帮你一起排查。
