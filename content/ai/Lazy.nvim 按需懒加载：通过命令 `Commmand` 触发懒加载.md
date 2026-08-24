---
title: Lazy.nvim 按需懒加载：通过命令 `:Commmand` 触发懒加载
---

# Lazy.nvim 按需懒加载：通过命令 `:Commmand` 触发懒加载

Lazy.nvim 核心懒加载规则：**只有定义 `cmd`，插件不会启动时加载，只有执行对应 Ex 命令时，才自动加载插件并执行命令**。
 下面完整讲写法、原理、示例、避坑，适配你 Windows Neovim 整套环境。

## 一、核心语法

```lua
{
  "插件地址",
  cmd = { "命令1", "命令2" }, -- 触发命令列表，执行命令才懒加载
  config = function()
    -- 插件加载完成后执行初始化配置
  end
}
```

1. 启动 nvim **完全不加载插件**；
2. 手动输入 `:命令1`，Lazy 自动下载 / 加载插件，运行 `config`，再执行命令；
3. 后续再次执行命令，插件已常驻内存，不会重复加载。

## 二、实战示例（你常用的插件案例）

### 示例 1：todo-comments 命令懒加载

只有执行 `:TodoTrouble` / `:TodoTelescope` 才加载，启动不占用内存

```lua
return {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = { "TodoTrouble", "TodoTelescope", "TodoQuickFix" }, -- 触发命令
  config = function()
    require("todo-comments").setup({
      -- 你的配置
    })
  end,
  keys = {
    { "<leader>xt", "<cmd>TodoTrouble toggle focus=false<cr>", desc = "Todo Trouble" },
  }
}
```

按下快捷键 `<leader>xt` 本质执行 `:TodoTrouble`，命中 `cmd`，触发懒加载。

### 示例 2：Tagbar 大纲，仅 `:TagbarToggle` 加载

```lua
{
  "preservim/tagbar",
  cmd = { "TagbarToggle" },
  keys = { { "<leader>o", "<cmd>TagbarToggle<cr>" } },
  config = function()
    vim.g.tagbar_ctags_bin = "ctags.exe"
  end
}
```

### 示例 3：cmake-tools 命令懒加载

```lua
{
  "Civitasv/cmake-tools.nvim",
  cmd = {
    "CMakeToolsToggle",
    "CMakeGenerate",
    "CMakeBuild",
    "CMakeDebug",
  },
  config = function()
    require("cmake-tools").setup({
      use_preset = true,
      symbolic_link_compile_commands = false,
    })
  end,
  keys = {
    { "<leader>cm", "<cmd>CMakeToolsToggle<CR>" },
    { "<leader>cg", "<cmd>CMakeGenerate<CR>" },
  }
}
```

## 三、搭配 `keys` 快捷键完全兼容

快捷键绑定的 `<cmd>xxx` 命令，**完全可以触发 cmd 懒加载**，工作流程：

1. 启动 nvim：插件未加载、快捷键映射**预先注册**；
2. 按下快捷键 → 执行 Ex 命令；
3. Lazy 检测到命令属于 `cmd` 列表 → 加载插件 + 执行 config；
4. 执行命令逻辑。

## 四、高级组合：多条件懒加载（cmd + event + ft 混用）

1. `cmd`：命令触发（手动调用）
2. `event = "VeryLazy"`：nvim 启动空闲后加载（后台预加载）
3. `ft = { "cpp", "c", "h" }`：打开对应文件类型才加载

```lua
-- C/C++ 文件打开 或 手动命令 二选一触发加载
{
  "xxx/xxx-plugin",
  cmd = { "CppHelper" },
  ft = { "cpp", "c", "h" },
  config = function() end
}
```

## 五、关键避坑（高频踩坑点）

### 坑 1：自定义 Lua 函数快捷键，不会触发 `cmd`

错误写法：直接调用 lua 函数，不走 Ex 命令，`cmd` 失效，无法懒加载

```lua
-- 无效，无法触发cmd懒加载
keys = {
  { "]t", function() require("todo-comments").jump_next() end }
}
```

**解决两种方案**
 方案 A：把内部函数封装成自定义 Ex 命令，写入 `cmd`

```lua
config = function()
  local todo = require("todo-comments")
  vim.api.nvim_create_user_command("TodoNext", function() todo.jump_next() end, {})
end,
cmd = { "TodoNext", "TodoTrouble" },
keys = { { "]t", "<cmd>TodoNext<cr>" } }
```

方案 B：改用 `lazy = true` + 延迟 require，不依赖 cmd。

### 坑 2：插件内置命令名称写错，懒加载失效

命令名必须和插件暴露的**原始命令全名完全一致**，大小写敏感。
 查看插件自带命令：插件文档 / 加载后 `:command` 查看。

### 坑 3：config 里依赖其他插件，懒加载顺序问题

dependencies 里的插件，**会在本插件加载前预先加载**，无需手动处理顺序。

```lua
dependencies = { "nvim-lua/plenary.nvim" } -- 先加载依赖
cmd = { "TodoTrouble" }
```

### 坑 4：内置默认命令，不要自己造命令名

比如 telescope 内置 `Telescope`，cmd 就写 `"Telescope"`，不要乱写名字。

## 六、查看插件加载状态命令

```vim
:Lazy profile       查看启动加载耗时，看哪些插件启动加载
:Lazy status        查看插件是否已加载（Loaded / Not Loaded）
```

执行一次绑定的命令后，状态会从 Not Loaded 变为 Loaded。

## 七、补充：纯自定义命令懒加载完整模板

```lua
{
  "作者/仓库名",
  dependencies = {},
  -- 触发命令
  cmd = { "MyCmd" },
  keys = {
    { "<leader>mm", "<cmd>MyCmd<cr>", desc = "自定义命令" }
  },
  config = function()
    local lib = require("xxx")
    -- 注册自定义用户命令
    vim.api.nvim_create_user_command("MyCmd", function(opts)
      lib.run()
    end, { nargs = "*" })
  end
}
```

## 总结

1. `cmd = { "命令名" }` 是**命令触发懒加载标准写法**，执行 Ex 命令才载入插件；
2. `<cmd>命令` 快捷键完美适配，日常最常用；
3. 插件内部 lua 直接调用 `require()` 不会触发 cmd 懒加载，必须封装成 Ex 命令；
4. 适合非高频插件：todo、tagbar、cmake-tools、lazygit 等，大幅加快 nvim 启动速度。