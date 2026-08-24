---
title: Neovim 完整的 4 大类映射写法
---

# Neovim 完整的 4 大类映射写法

分为 **Vimscript 老式命令、Lua 原生 `vim.keymap.set`、缓冲区局部映射、表达式映射、插件封装映射**，同时区分**六大模式**，一次性讲全所有写法。

## 一、先认清 6 大映射模式（所有 map 都对应模式）

mode 简写，对应场景：

| 简⁠写 | 模⁠式⁠全⁠称 | 场⁠景 |
| --- | --- | --- |
| `n` | Normal 普⁠通⁠模⁠式 | 最⁠常⁠用，默⁠认⁠编⁠辑⁠模⁠式 |
| `i` | Insert 插⁠入⁠模⁠式 | 打⁠字⁠输⁠入⁠时 |
| `v` | Visual 可⁠视⁠模⁠式（字⁠符 + 行） | 选⁠中⁠文⁠字 |
| `x` | Visual 严⁠格⁠字⁠符⁠模⁠式 | 推⁠荐⁠代⁠替 v，排⁠除⁠选⁠择⁠模⁠式 |
| `o` | Operator-pending 操⁠作⁠符⁠等⁠待⁠模⁠式 | 自⁠定⁠义⁠文⁠本⁠对⁠象⁠专⁠属（d/c/y 之⁠后） |
| `t` | Terminal 终⁠端⁠模⁠式 | toggleterm/nvim 内⁠置⁠终⁠端 |

---

# 一、老式 Vimscript 命令映射（2 组：递归 map / 非递归 noremap）

一共 12 条基础命令，格式：`命令  lhs rhs`

## 1. 非递归 noremap（推荐日常使用，不会递归）

```vim
nnoremap  普通模式非递归
inoremap  插入模式非递归
vnoremap  可视模式非递归
xnoremap  严格可视模式
onoremap  操作符等待模式（自定义文本对象必用）
tnoremap  终端模式
```

## 2. 递归 map（极少用，会解析二次映射）

```vim
nmap imap vmap xmap omap tmap
```

示例：

```vim
" 普通模式 <leader>w 保存
nnoremap <leader>w :w<CR>
" 插入模式 jj 退出
inoremap jj <Esc>
```

## 配套全局特殊映射

- `map`：等价 `nvo` 三模式（普通 + 可视 + 操作符）递归
- `noremap`：等价 `nvo` 三模式非递归
- `imap` / `inoremap` 仅插入
- `cmap`/`cnoremap`：命令行模式映射（` :  `输入时）

---

# 二、现代 Lua 标准写法：`vim.keymap.set`（Neovim 0.7+ 官方首选）

## 标准语法

```lua
vim.keymap.set(mode,  lhs,  rhs,  opts)
```

1. mode：字符串 / 数组，支持多模式 `{"n", "v"}`
2. lhs：触发按键
3. rhs：目标（字符串按键 / 回调函数）
4. opts 核心参数：
   - `noremap: boolean`  是否非递归（必开 true）
   - `silent: boolean`   静默，不回显命令（必开 true）
   - `buffer: number|boolean`  缓冲区局部映射
   - `expr: true` 表达式映射
   - `desc: "描述"` 方便 which-key 展示

## 两种 rhs 写法

### 写法 1：右侧为按键字符串（模拟按键）

```lua
local opts = { noremap = true, silent = true }
vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", opts)
-- <cmd>xxx<CR> 是 lua 最优写法，等价 :xxx 命令，比 : 更稳定
```

### 写法 2：右侧直接 Lua 回调函数（最灵活）

```lua
vim.keymap.set("n", "<F5>", function()
  vim.notify("按键触发")
  require("lazy.core.loader").reload("my-plugin")
end, opts)
```

## 多模式同时映射

```lua
-- 普通+可视模式同时生效
vim.keymap.set({"n", "v"}, "<leader>q", "<cmd>q<CR>", opts)
```

---

# 三、局部缓冲区映射（只在当前文件生效，高频）

只作用于当前打开的 buffer，切换文件自动失效，**写 ft 专属快捷键必备**。

## 1. Lua 写法

```lua
-- buffer = 0 代表当前缓冲区
vim.keymap.set("n", "<F9>", "<cmd>ClangdSwitchSourceHeader<CR>", {
  noremap = true,
  silent = true,
  buffer = 0
})
```

常在 `FileType` 自动命令里使用：打开 cpp 文件才注册该快捷键。

## 2. Vimscript 老式写法

```vim
nnoremap <buffer> <F9> :ClangdSwitchSourceHeader<CR>
```

---

# 四、表达式映射 expr 映射（高级玩法）

开启 `expr = true`，**右侧是函数，返回按键字符串**，常用于动态按键、自定义操作符、智能跳转。

## 示例 1：智能回车，换行自动缩进

```lua
vim.keymap.set("i", "<CR>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-n>" -- 补全弹窗时回车选候选项
  end
  return "<CR>"
end, { expr = true, noremap = true })
```

## 示例 2：自定义操作符必备（g@ 配合 onoremap）

就是你之前做自定义操作符、自定义文本对象的底层写法。

---

# 五、临时一次性映射 / 脚本动态映射

1. 运行时动态增删映射

```lua
-- 获取当前映射
vim.api.nvim_get_keymap("n")
-- 删除映射
vim.keymap.del("n", "<leader>w")
```

2. 无头脚本、插件内部动态注册销毁按键。

---

# 六、插件封装的高阶映射方式（日常开发常用）

## 1. which-key.nvim 分组映射

给快捷键分组、带提示，批量配置：

```lua
require("which-key").register({
  ["<leader>t"] = { name = "终端", t = { "<cmd>ToggleTerm<cr>", "打开终端" } }
})
```

## 2. Lazy.nvim 插件内 keys 配置（插件懒加载绑定）

在插件 spec 里写 `keys`，按下按键才加载插件，属于懒加载映射：

```lua
{
  "nvim-telescope/telescope.nvim",
  keys = {
    { "<leader>sf", "<cmd>Telescope find_files<cr>", desc = "查找文件" }
  }
}
```

## 3. mini.nvim/hydra.nvim 前缀映射、多键临时模式

比如长按 `s` 进入临时窗口操作模式，属于封装后的高级映射。

---

# 七、特殊冷门映射（了解即可）

1. **命令行模式 `c` 模式映射**`cnoremap` / `vim.keymap.set("c", ...)`，用于 `:` 命令输入时的快捷键。
2. **插入模式特殊按键 `<C-o>` 临时普通模式**，配合映射使用。
3. `<Plug>` 插件公共映射接口 插件对外暴露 `<Plug>(xxx)`，让用户二次映射，是插件标准规范写法。

---

# 八、选型总结（日常怎么选）

1. **个人配置全局快捷键**：一律用 `vim.keymap.set` Lua 写法，`{noremap=true,silent=true}`。
2. **文件类型专属快捷键**：用 `buffer = 0` 局部缓冲区映射。
3. **自定义文本对象 / 操作符**：`o` 模式 onoremap + expr 表达式映射。
4. **插件懒加载**：使用 Lazy 的 `keys` 配置。
5. **老式 Vimscript 写法**：仅阅读旧脚本时看懂，新项目完全不用。
6. **永远少用递归 map (nmap)**，只用 noremap，避免递归死循环。