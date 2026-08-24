---
title: Lazy.nvim 完整配置参数全集
---

# Lazy.nvim 完整配置参数全集

分为两大块：

1. **顶层全局 setup 配置参数**（`require("lazy").setup(全局配置)`）
2. **单个插件 Plugin Spec 完整参数**（写在每个 `{}` 插件项里） 附带作用、默认值、实战示例，适配本地插件开发、懒加载、热重载全套场景，完全对应官方规范lazy.nvimlazy.nvim。

## 一、顶层全局 setup 所有配置参数

```lua
require("lazy").setup(插件列表spec, {
  -- 1. 基础路径
  root = vim.fn.stdpath("data") .. "/lazy", -- 插件安装目录
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json", -- 版本锁定文件
  local_spec = true, -- 读取项目本地 .lazy.lua 项目专属插件配置
  concurrency = nil, -- 并发下载线程数，默认CPU核心数

  -- 2. 全局默认规则
  defaults = {
    lazy = false, -- 全局默认是否懒加载，true=全部插件默认懒加载
    version = nil, -- nil=拉最新commit；"*"=优先正式semver版本
    cond = nil, -- 全局条件开关 boolean|fun(plugin):boolean
  },

  -- 3. Git 下载配置
  git = {
    timeout = 120, -- git超时秒数
    url_format = "https://github.com/%s", -- 仓库地址模板
    log = { "--since=3 days ago" }, -- :Lazy log 默认日志范围
  },

  -- 4. UI面板样式（:Lazy 弹窗）
  ui = {
    size = { width = 0.8, height = 0.8 }, -- 窗口大小，小数百分比
    border = "rounded", -- 边框: none/single/double/rounded/shadow
    backdrop = 60, -- 背景透明度 0~100
    wrap = true, -- 自动换行
    title = "Lazy.nvim",
  },

  -- 5. 性能优化 performance
  performance = {
    cache = { enabled = true }, -- Lua模块缓存，大幅提速
    reset_packpath = true,
    rtp = {
      reset = true, -- 重置runtime路径，清理冗余
      disabled_plugins = {}, -- 禁用nvim内置原生插件提速
    }
  },

  -- 6. 开发模式 dev 本地插件路径映射
  dev = {
    path = "~/projects/nvim-plugins", -- 全局本地插件根目录
    patterns = {}, -- 匹配插件名自动走本地目录
    fallback = true, -- 本地不存在则自动拉远程
  },

  -- 7. 锁文件/安装行为
  lockfile = "",
  install = {
    colorscheme = { "tokyonight" }, -- 首次安装自动加载的配色
  },

  -- 8. 自定义 spec 导入
  spec = nil,
})
```

## 二、单个插件 Plugin Spec 全部参数（日常 99% 都在用）

完整标准插件格式，所有参数全覆盖，按功能分类。

```lua
{
  -- ========== 1. 仓库/本地路径（二选一必填） ==========
  -- 远程GitHub简写 [1号位置字符串]
  "作者/仓库名",
  -- 本地开发专用（你做插件开发核心）
  dir = "D:/nvim-dev/your-plugin", -- 本地绝对路径
  url = "https://gitee.com/xxx/xxx.git", -- 自定义Git仓库地址
  name = "my-plugin", -- 插件内部名称，用于:Lazy reload 重载
  dev = false, -- 标记为开发插件，自动读取全局dev路径

  -- ========== 2. 版本锁定（任选其一） ==========
  version = "^1.0.0", -- semver版本范围
  branch = "main", -- 指定分支
  tag = "v2.1.0", -- 指定标签
  commit = "xxxxxx", -- 锁定单次commit哈希

  -- ========== 3. 启用/加载控制 ==========
  enabled = true, -- 布尔/函数，false直接忽略插件不加载
  cond = true, -- 条件加载，插件存在但不加载，不会卸载
  lazy = true, -- 是否懒加载（核心）false=启动立刻加载
  priority = 50, -- 启动加载优先级，默认50；配色建议设100优先加载

  -- ========== 4. 懒加载触发条件（lazy=true时生效，满足其一即加载） ==========
  keys = { -- 快捷键触发加载
    { "<leader>sk", "<cmd>Telescope keymaps<cr>", desc = "快捷键列表" },
    "<C-\\>", -- 简写快捷键
  },
  cmd = { "Telescope", "ToggleTerm" }, -- 执行命令触发
  ft = { "lua", "cpp", "python" }, -- 打开对应文件类型触发
  event = { "BufReadPost", "VeryLazy" }, -- 内置事件触发
  -- 常用内置事件：VimEnter / BufReadPre / BufReadPost / VeryLazy / InsertEnter

  -- ========== 5. 依赖 dependencies ==========
  dependencies = {
    "nvim-lua/plenary.nvim", -- 简写依赖
    { "另一个插件", lazy = true }, -- 完整spec依赖
  },

  -- ========== 6. 生命周期钩子（执行顺序：init → 加载插件 → config） ==========
  init = function(plugin)
    -- 【启动阶段执行】插件加载**之前**运行，适合设置 vim.g、全局前置变量
  end,

  opts = { -- 插件配置项，table / function
    theme = "moon",
  },
  -- 函数形式opts，可以动态接收插件信息
  opts = function(plugin, old_opts) return {} end,

  config = function(plugin, opts)
    -- 【插件加载完成后执行】初始化入口
    -- opts会自动传入上面的opts配置
    require("插件名").setup(opts)
  end,
  -- 简写 config = true 等价自动执行 require(name).setup(opts)

  -- ========== 7. 构建脚本 build ==========
  build = ":Make", -- vim命令
  build = "npm install", -- shell命令
  build = function(plugin) -- 自定义Lua构建函数
    os.execute("stylua lua/")
  end,

  -- ========== 8. 导入分组（LazyVim常用） ==========
  import = "lazyvim.plugins.extras.lang.lua",
}
```

## 三、高频核心参数详解（重点必懂）

### 1. 懒加载四件套触发规则

1. `keys`：按下快捷键 → 加载插件并执行按键映射
2. `cmd`：执行命令时自动加载
3. `ft`：打开对应后缀文件加载（语言 LSP 必备）
4. `event`：Neovim 内置事件触发，`VeryLazy` 启动完全结束后加载，不拖启动速度

### 2. init VS config 本质区别

- `init`：**插件源码加载前执行**，只能做全局变量、前置环境，不能 `require` 插件
- `config`：**插件文件加载完毕后执行**，用来 `require(xxx).setup()` 初始化配置
- `opts` 会自动合并，专门给插件 setup 传参，不用手动合并默认配置

### 3. enabled VS cond 区别

- `enabled = false`：**彻底不纳入插件列表**，`:Lazy install` 不会安装此插件
- `cond = false`：插件文件正常存在，**只是不执行加载**，适合临时禁用（如 VSCode 内嵌 nvim 时禁用 GUI 插件）

### 4. priority 优先级

仅对 `lazy=false` 启动即加载的插件生效。

- 配色主题必须 `priority = 100`，保证最先加载，启动不会闪屏。
- 默认值 `50`，数字越大加载越早。

### 5. dir 本地开发专属（你插件开发核心）

```lua
{
  dir = "D:/nvim-dev/my-plugin",
  name = "my-plugin",
  lazy = false,
  config = function()
    require("myplugin").setup()
  end
}
```

重载命令：`:Lazy reload my-plugin`，完美热重载本地源码。

## 四、最简完整示例（可直接复制运行）

```lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- 配色（启动优先加载）
  { "folke/tokyonight.nvim", priority = 100, lazy = false },
  -- Telescope 命令懒加载
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = { defaults = { layout_config = { width = 0.8 } } },
    config = function(_, opts)
      require("telescope").setup(opts)
    end,
  },
  -- 本地开发插件
  {
    dir = "D:/nvim-dev/my-demo-plugin",
    name = "my-demo-plugin",
    lazy = false,
  }
}, {
  ui = { border = "rounded" },
  performance = { rtp = { disabled_plugins = { "netrwPlugin" } } }
})
```

## 五、常用 Lazy 配套命令

```vim
:Lazy          打开UI面板
:Lazy reload 插件名   热重载插件（本地开发必备）
:Lazy update   更新所有插件
:Lazy clean    清理无用插件
:Lazy profile  查看启动加载耗时
:Lazy log      查看插件Git日志
```

## 六、新手避坑要点

1. `lazy=true` 懒加载插件，**不会启动自动加载**，必须触发 `keys/cmd/ft/event`，否则插件永远不会运行。
2. `opts` 会自动合并继承，配合 `config=true` 可以省略手写 `require().setup()`。
3. 本地 `dir` 开发插件，重载时 Lazy 会自动清空 `package.loaded` 缓存，无需手动删缓存。
4. 不要全局开 `defaults.lazy=true` 新手极易踩坑，基础配色、核心工具建议手动 `lazy=false` 启动加载。