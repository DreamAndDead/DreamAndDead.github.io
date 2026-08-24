---
title: Telescope find_files 找不到文件完整原因 + 一键修复配置
---

# Telescope find_files 找不到文件完整原因 + 一键修复配置

## 核心 4 个原因（按概率排序）

1. **被 `.gitignore` 忽略**（build 目录、编译产物、第三方库最常见）
2. **隐藏文件（点文件 `.xxx`）默认关闭**，不会显示
3. 你的 `file_ignore_patterns` 配置主动过滤了目录 / 后缀
4. 软链接目录默认不跟随、工具`fd/rg`全局`.ignore`文件拦截

## 完整修复配置（Lazy 可用，直接替换）

```lua
return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local telescope = require("telescope")
    local config = require("telescope.config").values

    telescope.setup({
      defaults = {
        -- 全局忽略列表，不要把需要搜索的目录写在这里
        file_ignore_patterns = {
          -- 只放真正不需要搜索的目录，不要把build之类需要查找的加进来
          "^%.git/",
          "^%.vs/",
        },
      },

      -- 专门针对 find_files 配置
      pickers = {
        find_files = {
          hidden = true,          -- 显示隐藏点文件 .h .gitignore 等
          follow = true,          -- 跟随软链接目录（引擎源码、第三方库必备）
          -- no_ignore = true,    -- 【临时全开】彻底无视.gitignore，所有文件全部显示（调试用）
          -- no_ignore_vcs = true,-- 仅无视gitignore，仍遵守全局ignore文件
        },
      },
    })
  end,
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files 常规" },
    -- 临时快捷键：强制无视gitignore，一键查看所有被忽略文件
    { "<leader>fF", "<cmd>Telescope find_files no_ignore=true hidden=true<cr>", desc = "Find All Files(无视gitignore)" },
  },
}
```

## 分步排查 & 解决

### 1. 文件在 .gitignore 里（90% 场景）

比如你的`build/`编译目录、第三方库文件夹被 git 忽略，默认 Telescope 不会扫描。

- **临时查看**：执行命令，强制关闭 gitignore 过滤

```vim
:Telescope find_files no_ignore=true hidden=true
```

- **永久方案二选一** 方案 A：全局开启无视 gitignore（不推荐，结果太多杂乱） 方案 B：在`.gitignore`加**取反规则**，单独放开需要搜索的目录

```gitignore
# .gitignore示例：默认忽略build，但是放开build/include目录
/build
!/build/include/
```

### 2. 隐藏文件不显示

开启 `hidden = true` 即可显示 `.h`、`.cmake`、`.env` 这类开头带点的文件。

### 3. 软链接文件夹找不到（游戏引擎常用）

开启 `follow = true`，才能扫描符号链接指向的目录文件。

### 4. 被 `file_ignore_patterns` 配置过滤

检查 defaults 里的忽略列表，**删掉你需要查找的路径**
 例：你写了 `"build"`，则所有 build 目录文件都会被屏蔽。

### 5. fd/rg 系统全局～/.ignore 拦截

Windows/Linux 存在全局忽略文件，优先级高于 gitignore。
 临时绕过：使用内置 find 命令兜底，不用 fd/rg

```vim
:Telescope find_files find_command={"find", ".", "-type", "f"} hidden=true
```

## 常用命令区分

1. `find_files`：文件搜索，**默认遵守.gitignore**
2. `git_files`：只搜索 git 跟踪的文件，**完全不会显示未加入 git 的产物**（build 文件夹必然搜不到）
3. 找不到编译产物、临时目录，**永远不要用 git_files**。

## CMake 项目专属优化（适配你的 C++ 引擎项目）

日常想要**正常遵守 gitignore，偶尔快速搜 build 编译目录**，双快捷键即可：

```lua
keys = {
  { "<leader>ff", "<cmd>Telescope find_files hidden=true follow=true<cr>", desc = "常规查找(遵循gitignore)" },
  { "<leader>fb", "<cmd>Telescope find_files cwd=build no_ignore=true hidden=true<cr>", desc = "直接搜索build目录全部文件" },
}
```

## 快速自检命令

1. 查看当前生效配置

```vim
:Telescope find_files show_config=true
```

2. 检查依赖工具

```vim
:checkhealth telescope
```

确认 fd /rg 正常安装，工具异常也会导致搜索不全。