---
title: 插入模式光标不变竖线（始终方块 block）完整排查方案（Windows Terminal + PowerShell 环境）
---

# 插入模式光标不变竖线（始终方块 block）完整排查方案（Windows Terminal + PowerShell 环境）

## 一、标准正确配置（先把配置写对）

在你的 `init.lua` 基础选项里写入**完整 guicursor**，这是模式切换光标的核心配置：

```lua
-- 必须开启真彩色（WT必备）
vim.opt.termguicolors = true

-- 光标规则：普通/可视=方块，插入=细竖线，替换=下划线
vim.opt.guicursor = "n-v-c:block,i:ver25,r:hor20"
```

参数说明：

- `n-v-c:block`：Normal、Visual、命令行 = 实心方块
- `i:ver25`：Insert 插入模式，**竖线光标，宽度 25% 字符**
- `r:hor20`：Replace 覆盖模式，下划线光标

写完执行 `:source $MYVIMRC` 重载配置测试。

## 二、最常见 4 个失效原因，按顺序排查

### 1. 插件覆盖 / 重置了 guicursor（最高发）

你装的插件会强行覆盖光标设置，常见嫌疑：
`toggleterm、snacks、LazyVim预设、cursorline插件、状态栏插件`

#### 验证方法

执行命令查看当前生效配置：

```vim
:set guicursor?
```

如果输出不是你写的 `n-v-c:block,i:ver25,r:hor20`，说明被插件覆盖。

#### 永久锁定配置（强制不被篡改）

```lua
-- 监听配置被修改，自动还原光标设置
vim.api.nvim_create_autocmd("OptionSet", {
  pattern = "guicursor",
  callback = function()
    vim.opt.guicursor = "n-v-c:block,i:ver25,r:hor20"
  end
})
```

### 2. Windows Terminal 全局设置强制锁定光标样式

WT 本身的配置优先级**高于 Neovim**，全局固定了方块光标，NVim 发送的 ANSI 光标指令被终端忽略。

1. 打开 Windows Terminal 设置 → 打开 JSON 文件 `settings.json`
2. 搜索 `cursorShape`，大概率写死为 `"block"`

```json
// 错误写法（全局强制方块）
"cursorShape": "block",
```

3. **删掉整行 cursorShape 全局配置**，让程序（Neovim）接管光标控制；
4. 重启 WT，重新打开 nvim 测试。

### 3. TERM 环境变量不对，终端不识别光标切换指令

Windows PowerShell 默认 `TERM=windows`，**不兼容 xterm 光标序列**，Neovim 无法下发切换指令。

#### 解决：启动时指定 TERM

打开 VS PowerShell（你的常用终端），执行：

```powershell
$env:TERM="xterm-256color"
nvim
```

临时测试光标是否恢复正常。
 如需永久生效，写入 PowerShell 的 `$PROFILE`：

```powershell
$env:TERM="xterm-256color"
```

### 4. 误开启 Replace 覆盖模式（Insert 键）

按键盘 `Insert` 键，会进入**覆盖模式 (Replace)**，光标固定为方块，很容易误以为是插入模式异常。
 再按一次 `Insert` 切回正常 Insert 插入模式，光标立刻变回竖线。

## 三、ToggleTerm 内嵌终端额外注意

内嵌终端窗口本身光标由 PowerShell/WT 控制，**只有编辑代码缓冲区才走 nvim 的 guicursor**，属于正常现象：

1. 编辑 C++ 代码文件：正常切换方块 / 竖线；
2. 进入 ToggleTerm 终端窗口：光标样式跟随 Windows 终端设置，不受 nvim 控制。

## 四、终极兜底方案（WT 完美兼容）

如果上面设置依旧无效，手动启用终端光标序列兼容：

```lua
-- 手动指定光标切换转义码（WT专用兼容）
vim.opt.t_SI = "\27[6 q"  -- 进入插入：竖线bar
vim.opt.t_EI = "\27[2 q"  -- 退出插入：方块block
vim.opt.t_SR = "\27[4 q"  -- 替换模式：下划线
```

## 五、快速自检流程

1. `:set guicursor?` 核对配置是否正确
2. 检查 WT 的 settings.json 是否写死 `cursorShape`
3. 临时 `$env:TERM="xterm-256color"` 启动 nvim 测试
4. 确认没有误按 Insert 进入 Replace 模式
5. 加 autocmd 防止插件篡改光标配置