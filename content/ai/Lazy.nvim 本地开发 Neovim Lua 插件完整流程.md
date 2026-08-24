---
title: Lazy.nvim 本地开发 Neovim Lua 插件完整流程
---

# Lazy.nvim 本地开发 Neovim Lua 插件完整流程

整套流程：**创建插件目录 → Lazy 挂载本地源码 → 热重载调试 → 规范结构编写代码 → 单元测试 → 编写文档 → 发布开源**，全程不用上传 GitHub，直接本地实时开发，Windows 完全适配。

## 一、整体目录规划

### 1. 新建你的插件项目文件夹

随便放本地路径，举例 Windows：
`D:\nvim-plugins\my-demo-plugin`
 标准插件目录结构（通用规范）

```plaintext
my-demo-plugin/
├── lua/
│   └── mydemo/          -- 模块名（小写，不能带空格）
│       ├── init.lua     -- 入口主文件，必须提供 setup()
│       ├── config.lua   -- 默认配置解析
│       ├── keymap.lua   -- 快捷键
│       └── utils.lua    -- 工具函数
├── doc/
│   └── mydemo.txt       -- 帮助文档（:help mydemo）
├── spec/                -- 单元测试目录（可选）
├── .stylua.toml         -- 代码格式化配置
└── README.md
```

### 2. 在你 Lazy 配置里挂载本地插件

打开 `lua/plugins/local-dev.lua`，写入本地路径，**`dir` 指向你的本地插件文件夹**，Lazy 会直接读取本地源码，不会去拉取远程仓库。

```lua
return {
  -- 本地开发插件核心配置
  {
    dir = "D:/nvim-plugins/my-demo-plugin", -- 你的插件绝对路径
    name = "my-demo-plugin", -- 插件内部名称，后续重载要用
    lazy = false, -- 测试阶段直接启动加载，写完再改懒加载
    -- 依赖（常用 plenary，按需填写）
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      -- 启动执行插件的 setup 初始化函数，可以传入默认配置
      require("mydemo").setup({
        msg = "Hello Lazy Plugin Dev",
      })
    end,
  },
}
```

保存后执行 `:Lazy install`，Lazy 会识别本地目录，完成挂载。

## 二、编写插件核心代码

### 1. 入口文件 lua/mydemo/init.lua（必须暴露 setup）

```lua
local M = {}
local config = require("mydemo.config")
local utils = require("mydemo.utils")

-- 对外初始化函数，用户调用 require("mydemo").setup(opts)
function M.setup(user_opts)
  -- 合并用户配置与默认配置
  config.setup(user_opts)

  -- 注册快捷键、自动命令、窗口逻辑等
  vim.keymap.set("n", "<leader>dp", function()
    local text = config.options.msg
    vim.notify(utils.upper_str(text), "info")
  end, { noremap = true, silent = true, desc = "测试我的插件" })
end

-- 对外暴露公共API，供外部调用
function M.echo()
  vim.print(config.options)
end

return M
```

### 2. 配套默认配置 lua/mydemo/config.lua

```lua
local M = {}
M.options = {}

local default_config = {
  msg = "默认消息",
  enable_notify = true,
}

function M.setup(user)
  -- 合并配置，用户配置覆盖默认
  M.options = vim.tbl_deep_extend("force", {}, default_config, user or {})
end

return M
```

### 3. 工具函数 lua/mydemo/utils.lua

```lua
local M = {}

function M.upper_str(str)
  return string.upper(str)
end

return M
```

## 三、日常开发：热重载调试（核心效率）

修改插件源码后，**不需要重启 Neovim**，用 Lazy 命令重载当前插件。

### 1. 手动重载命令

```vim
:Lazy reload my-demo-plugin
```

插件名对应 `name = "my-demo-plugin"`，重载完成立刻生效。

### 2. 绑定快捷键一键重载（推荐）

加到你的 `keymaps.lua`

```lua
vim.keymap.set("n", "<F5>", function()
  require("lazy.core.loader").reload("my-demo-plugin")
  vim.notify("插件重载完成！", "info")
end, { noremap = true, silent = true })
```

改完代码按 `F5` 一键刷新。

### 3. 调试排错手段

1. 查看插件加载日志：`:Lazy` 打开面板，光标选中插件按 `L` 看加载日志、报错。
2. 打印变量：在插件代码内写 `vim.print(xxx)`，用 `:messages` 查看输出。
3. 断点调试：引入 `nvim-lua-debugger` 断点单步调试函数。
4. 隔离冲突：`:Lazy disable 插件名` 临时禁用其他插件，判断是否冲突。

## 四、进阶规范优化（正式插件必备）

### 1. 懒加载优化（开发完成后配置）

开发测试完成后，改为懒加载，提升启动速度，常用触发方式：

```lua
{
  dir = "D:/nvim-plugins/my-demo-plugin",
  name = "my-demo-plugin",
  lazy = true, -- 开启懒加载
  -- 方式1：按下指定快捷键才加载
  keys = { "<leader>dp" },
  -- 方式2：执行命令才加载
  cmd = { "MyDemoEcho" },
  -- 方式3：打开指定文件类型加载
  ft = { "lua", "cpp" },
}
```

### 2. 命令注册示例（插件自定义命令）

在 `init.lua` 的 setup 函数内添加：

```lua
vim.api.nvim_create_user_command("MyDemoEcho", function()
  require("mydemo").echo()
end, {})
```

使用：`:MyDemoEcho` 调用插件功能。

### 3. 代码格式化 stylua

项目根目录新建 `.stylua.toml`，全局安装 stylua，一键格式化整个插件代码：

```bash
stylua lua/
```

## 五、编写帮助文档 doc/mydemo.txt

用户可以执行 `:help mydemo` 查看文档，写完文档执行命令刷新帮助索引：

```vim
:helptags ALL
```

基础文档模板格式遵循 Vimdoc 规范，开源必备。

## 六、单元测试（保证稳定性）

依托 `plenary.nvim` 的 busted 测试框架，新建 `spec/` 测试用例，**无头模式运行测试，无需打开界面**。
 执行测试命令：

```vim
:PlenaryBustedDirectory spec/
```

适合测试工具函数、配置解析逻辑，避免后续改代码产生 BUG。

## 七、打包发布到 GitHub（开源流程）

1. 把完整插件项目上传 GitHub，仓库名就是插件名。
2. 远程仓库地址格式：`用户名/仓库名`
3. Lazy 本地配置替换为远程地址，即可像普通插件一样拉取安装：

```lua
return {
  "你的用户名/my-demo-plugin", -- 远程仓库地址
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("mydemo").setup({})
  end
}
```

后续其他用户可以直接通过 Lazy 安装你的插件。

## 八、完整开发日常工作流

1. 搭建本地插件目录，Lazy 挂载本地路径；
2. 编写 `init.lua` + 配套模块，实现核心功能；
3. 改代码 → `F5` 热重载，配合 `:messages` / 断点调试；
4. 功能完成，配置懒加载、优化性能；
5. 写文档、单元测试、stylua 格式化；
6. 上传 GitHub，转为远程仓库供他人使用。

## 常见坑

1. 模块名大小写错误：`require("mydemo")` 必须和文件夹名称完全小写一致。
2. require 缓存问题：Lazy reload 会自动清空缓存，无需手动修改 `package.loaded`。
3. Windows 路径：Lazy 正反斜杠都兼容，建议用 `/` 路径。
4. 懒加载时提前调用插件函数会报错，必须在触发条件后才会加载模块。

需要我给你一套**完整可直接使用的插件模板源码**，包含完整目录、配置、工具函数，你可以直接开始二次开发吗？