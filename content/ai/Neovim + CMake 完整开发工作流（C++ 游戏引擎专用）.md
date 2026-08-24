---
title: Neovim + CMake 完整开发工作流（C++/ 游戏引擎专用）
---

# Neovim + CMake 完整开发工作流（C++/ 游戏引擎专用）

整套闭环：**CMake 工程管理 + LSP (clangd) 代码提示 + 一键构建 + 一键运行 + 一键 DAP 调试**，全程在 Neovim 内完成，不用切终端。
 核心主力插件：`cmake-tools.nvim`，目前 CMake 生态最成熟，完全替代手动敲 cmake 命令。

## 一、前置环境

1. 已安装：`CMake`、`Ninja`（构建速度远快于 Make）、`clangd`、`clang`/MSVC 编译器
2. Mason 提前装好依赖（可选）

```vim
:MasonInstall clangd clang-format
```

## 二、Lazy 完整 cmake-tools 配置

```lua
return {
  "Civitasv/cmake-tools.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim", -- 弹窗选择编译目标、配置
  },
  opts = {
    -- 构建生成器，首选 Ninja，速度最快
    cmake_generator = "Ninja",
    -- 编译目录：项目根目录/build
    build_directory = "build",
    install_directory = "install",
    -- 编译配置：Debug / Release
    cmake_build_type = "Debug",
    -- 开启自动生成 compile_commands.json 给 clangd LSP 使用（重中之重）
    cmake_regenerate_on_save = true, -- 修改CMakeLists自动重新配置
    export_compile_commands = true,
    compile_commands_path = "${buildDirectory}/compile_commands.json",

    -- 可执行程序运行参数
    run_args = {},
    -- 调试器：Windows用 lldb / gdb / msvc 均可
    debugger = "lldb",

    -- 侧边UI窗口设置
    ui = {
      width = 40,
      height = 12,
      position = "right",
    },
  },
  keys = {
    { "<leader>cm", "<cmd>CMakeToolsToggle<CR>", desc = "打开CMake侧边面板" },
    { "<leader>cg", "<cmd>CMakeGenerate<CR>", desc = "CMake配置生成" },
    { "<leader>cb", "<cmd>CMakeBuild<CR>", desc = "执行编译构建" },
    { "<leader>cr", "<cmd>CMakeRun<CR>", desc = "运行程序" },
    { "<leader>cd", "<cmd>CMakeDebug<CR>", desc = "DAP附加调试当前程序" },
    { "<leader>cc", "<cmd>CMakeClean<CR>", desc = "清理构建文件" },
    { "<leader>cs", "<cmd>CMakeSelectBuildTarget<CR>", desc = "选择编译目标( exe/lib )" },
    { "<leader>ct", "<cmd>CMakeSelectBuildType<CR>", desc = "切换Debug/Release" },
  },
}
```

## 三、配套 clangd LSP 适配（读取 cmake 生成的编译数据库）

修改你的 `lspconfig/clangd` 配置，指向 cmake-tools 生成的`build/compile_commands.json`：

```lua
lspconfig.clangd.setup({
  cmd = {
    "clangd",
    "--compile-commands-dir=build", -- 读取cmake产出的编译参数
    "--header-insertion=never",
    "--background-index",
  },
  on_attach = on_attach,
})
```

效果：CMake 配置变更后，自动刷新编译数据库，`clangd` 实时识别头文件、宏、第三方库路径，不会出现头文件找不到。

## 四、完整标准使用流程

### 1. 初始化工程（第一次打开项目）

1. 进入项目根目录（存在`CMakeLists.txt`）
2. 执行配置生成：`<leader>cg` 自动创建`build`文件夹，执行 `cmake -G Ninja` 配置工程，同时生成`compile_commands.json`。
3. 选择编译目标：`<leader>cs`，在弹窗选中你的可执行 exe。
4. 切换编译类型：`<leader>ct`，日常开发选`Debug`（带调试符号，用于 DAP 调试）。

### 2. 日常开发循环

1. 改 C++ 代码，`clangd`实时 LSP 补全、报错、跳转。
2. 修改`CMakeLists.txt`保存，插件**自动重新 Generate**，同步更新编译数据库。
3. 编译：`<leader>cb`，底部输出编译日志，报错直接定位代码行。
4. 运行程序：`<leader>cr`，内嵌终端直接运行 exe。
5. 调试：`<leader>cd`，**自动唤起 nvim-dap**，直接断点调试当前编译好的程序，无需手动填写 exe 路径。

### 3. 常用辅助命令

- 清理构建缓存：`<leader>cc`
- 打开 CMake 面板可视化查看状态：`<leader>cm`
- 重新完整重配工程：`:CMakeGenerate --clean`

## 五、和 DAP 联动细节（无需手动写调试配置）

`cmake-tools` 会自动对接 nvim-dap，自动传递：

- 可执行文件路径
- 工作目录 cwd
- 程序启动参数
- Debug 编译符号

你之前配好的 DAP 插件直接复用，按下 `<leader>cd` 一键启动调试，完美闭环：
**LSP 写代码 → CMake 编译 → DAP 调试**

## 六、Windows 专属注意事项

1. MSVC 编译器环境 需要提前加载 VS 的 x64 环境变量，推荐在终端启动 nvim，或配置 `cmake-tools` 指定编译器路径。
2. Ninja 安装 ```powershell
   choco install ninja
   ```
3. 调试器选择
   - MSVC 工程：调试器改为 `vsdbg`
   - MinGW/Clang：使用 `gdb` / `lldb`

## 七、常见问题解决

### 1. clangd 找不到头文件

1. 确认执行过 `:CMakeGenerate`，`build/compile_commands.json` 文件存在。
2. 重启 LSP：`:LspRestart`。
3. 不要手动删 build 文件夹，删除后重新`<leader>cg`生成。

### 2. 编译报错，提示 ninja 不存在

把 Ninja 加入系统环境变量，或者更换生成器为`Unix Makefiles`：

```lua
cmake_generator = "Unix Makefiles"
```

### 3. Debug 调试断点无效

必须使用`Debug`模式编译，CMake 会自动携带`-g`调试符号，Release 模式没有符号无法断点。

## 八、极简备选（不想装插件，原生命令）

如果你只想原生极简操作，不用插件：

1. 手动生成编译数据库

```bash
mkdir build && cd build
cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
```

2. 软链接 compile_commands.json 到项目根目录，方便 clangd 读取。 缺点：修改 CMakeLists 需要手动重新执行 cmake，没有一键构建、一键调试功能。

## 九、针对你的 Angelscript 引擎 C++ 项目优化建议

1. 多子模块大引擎工程，**Ninja 构建速度优势极大**。
2. 自定义第三方库、引擎内部宏、头文件路径，全部由 CMake 管理，`cmake-tools`自动同步给 clangd，彻底解决 LSP 头文件解析难题。
3. 结合之前的 DAP 配置，编译游戏引擎 exe 后一键附加调试，完美适配引擎开发。