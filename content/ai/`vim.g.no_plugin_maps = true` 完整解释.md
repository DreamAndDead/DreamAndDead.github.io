---
title: "`vim.g.no_plugin_maps = true` 完整解释"
---

# `vim.g.no_plugin_maps = true` 完整解释

## 核心作用

全局变量，**关闭绝大多数 Vim 旧式 ftplugin / 脚本自带的自动内置按键映射**，阻止各类语言文件自带的默认快捷键覆盖你手动配置的按键，把快捷键的控制权完全收归自己。

`g` = global 全局变量，这是 Vim 遗留的全局开关，专门针对老式 vimscript 插件。

## 详细拆解

### 1. 原本会自动加载的默认映射（开启后全部禁用）

很多语言的内置 `ftplugin`（文件类型脚本）会自动给对应文件类型绑定一堆快捷键，举例子：

- C/CPP 文件自动绑定 `<F1>` `<F2>`、`K`、`[i`、`]i` 等原生功能键
- Markdown、Python、Lua 等 ftplugin 自带专属快捷键
- 老式第三方 vim 插件会自动注册一堆全局 / 文件类型快捷键

设置 `vim.g.no_plugin_maps = true` 后：

> 内置 ftplugin **不会自动创建任何自带快捷键**，只会加载语法、缩进配置，**不自动映射按键**。

### 2. 和你日常配置的关系

1. **只影响老式 vimscript 内置 ftplugin，不影响你 Lazy.nvim 手动写的 `vim.keymap.set()`** 你自己写的所有快捷键、Telescope、Trouble、treesitter、cmake-tools 等 lua 插件的按键，完全不受影响，照常生效。
2. 解决按键冲突（你之前配 treesitter textobject、段落跳转最容易踩坑） 比如原生 C 文件 ftplugin 自带 `K` 快捷键，你想把 `K` 映射为段落上跳，不开这个开关，内置脚本会**覆盖你的自定义映射**，导致按键不生效。 开启后，内置自带映射全部失效，你的自定义映射优先级最高。

### 3. 边界：哪些东西不受控制？

1. ✅ **不受禁用**
   - 你手动写的 `vim.keymap.set` 映射
   - Lazy 插件配置里的 `keys = {}` 自动映射
   - Neovim Lua 新生态插件（treesitter、telescope、trouble 等现代插件）的内置按键
2. ❌ **会被禁用** Vim 原生自带 ftplugin 的自动按键、老旧 vim 脚本插件自动注册的映射。

## 优缺点

### 优点（日常开发必开）

1. 杜绝隐形的默认按键抢占，解决莫名其妙按键失效、快捷键错乱；
2. 完全手动掌控所有快捷键，适合高度自定义的纯键盘流配置；
3. 完美适配 `nvim-treesitter-textobjects`、自定义段落跳转、LSP 按键，是高阶自定义标配。

### 缺点

1. Vim 原生部分语言专属快捷按键会消失（平时几乎用不到）；
2. 极少数老旧 vim 脚本插件依赖自带映射，会功能异常（现代 lua 插件完全不用考虑）。

## 使用写法

放在你的 `init.lua` 最顶部，**越早声明越好**，必须在插件加载前执行：

```lua
-- 写在init.lua最开头
vim.g.no_plugin_maps = true
```

## 补充区分易混变量（别搞混）

1. `vim.g.no_plugin_maps`：禁用**ftplugin 自动按键**（今天讲的）
2. `vim.g.no_load_plugin_maps`：范围更广，禁用**所有插件的自动映射**，慎用
3. `vim.g.mapleader`：设置 leader 键，和这个开关无关。