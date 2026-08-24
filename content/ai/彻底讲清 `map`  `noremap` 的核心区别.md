---
title: 彻底讲清 `map` / `noremap` 的核心区别
---

# 彻底讲清 `map` / `noremap` 的核心区别

## 核心一句话

1. **`noremap = false`（默认普通 map）：递归映射** 按键触发后，**会继续解析映射**，如果目标按键也有映射，会层层递归执行。
2. **`noremap = true`（非递归 noremap）：原生执行** 触发后直接执行**Vim 原生原始按键功能**，**不会再走用户的映射规则**，不会递归。

`vim.keymap.set` 的第三个参数是配置表，`{ noremap = true/false }`。

## 一、通俗例子演示

### 场景 1：递归 map（noremap=false）

```lua
-- 1. a 映射为 b
vim.keymap.set("n", "a", "b")
-- 2. b 映射为 c
vim.keymap.set("n", "b", "c")
```

按 `a` 的执行流程：
`a → 匹配映射 → b → 匹配映射 → c`
 最终执行 `c` 的原生功能，**递归穿透所有映射**。

### 场景 2：非递归 noremap（noremap=true）

```lua
vim.keymap.set("n", "a", "b", { noremap = true })
vim.keymap.set("n", "b", "c")
```

按 `a`：
`a` 被解析为原生按键 `b`，**直接执行原生 b 的功能**，**不会触发 `b→c` 的映射**。

## 二、四组完整映射命令对应关系（Vim 旧命令 ↔ Lua keymap）

| Vimscript 命⁠令 | Lua noremap 值 | 模⁠式 | 含⁠义 |
| --- | --- | --- | --- |
| `nnmap` | `noremap=false` | 普⁠通⁠模⁠式 | 递⁠归⁠普⁠通⁠映⁠射 |
| `nnoremap` | `noremap=true` | 普⁠通⁠模⁠式 | 非⁠递⁠归⁠映⁠射（最⁠常⁠用） |
| `vnmap` | `noremap=false` | 可⁠视⁠模⁠式 | 递⁠归 |
| `vnoremap` | `noremap=true` | 可⁠视⁠模⁠式 | 非⁠递⁠归 |
| `inmap` | `noremap=false` | 插⁠入⁠模⁠式 | 递⁠归 |
| `inoremap` | `noremap=true` | 插⁠入⁠模⁠式 | 非⁠递⁠归 |

你用 `vim.keymap.set(mode, lhs, rhs, opts)`

- 等同于 `nnmap`：`opts.noremap = false`
- 等同于 `nnoremap`：`opts.noremap = true`

## 三、`silent` 顺带讲解（日常必配）

`silent = true`：执行映射命令时，**不在命令行回显命令文本**，界面干净。
 开发配置标准标配：

```lua
local default_opts = { noremap = true, silent = true }
```

## 四、什么时候用 noremap=true？（95% 的场景）

**绝大多数自定义快捷键，一律用 `noremap=true`**。
 原因：防止自定义映射被其他映射干扰、递归死循环。

### 经典坑：不加 noremap 造成死循环

```lua
-- 错误写法：递归死循环
vim.keymap.set("n", "<leader>w", ":w<CR>")
```

解析：`<leader>w` → `:w`，如果后续你把 `w` 又映射成别的功能，极易出错。
**正确写法**

```lua
vim.keymap.set("n", "<leader>w", ":w<CR>", { noremap = true, silent = true })
```

强制 `:w` 走原生保存命令，不受其他映射影响。

## 五、什么时候必须用 noremap=false（递归 map）

**只有需要「映射嵌套映射」时才用递归**。
 举例：
 我已经把 `F2` 映射好了一套功能，现在想把 `zz` 也映射成 F2，复用现有映射：

```lua
-- F2 原有映射
vim.keymap.set("n", "<F2>", "<cmd>echo '测试'<CR>", { noremap = true })

-- zz 递归映射到 F2，需要 noremap=false
vim.keymap.set("n", "zz", "<F2>", { noremap = false })
```

此时按 `zz` 会递归调用 `<F2>` 的映射逻辑。
 如果开了 `noremap=true`，只会按下原生的 F2 按键，不会执行我们的自定义 F2 映射。

## 六、补充 expr 表达式映射 与 noremap

当 `opts.expr = true` 时，右侧是**Lua 表达式函数**，返回按键字符串，
`noremap` 依旧生效：

- `noremap=true`：返回的字符串按原生按键解析
- `noremap=false`：返回的字符串继续解析用户映射

## 七、最终总结速记

1. **日常自定义快捷键、插件按键：永远 `noremap = true`**，稳定、不会递归错乱。
2. **只有复用已有自定义映射时**，才使用 `noremap = false` 递归映射。
3. 新手统一模板，直接全局用这个默认参数，几乎不会踩坑：

```lua
local opts = { noremap = true, silent = true }
```