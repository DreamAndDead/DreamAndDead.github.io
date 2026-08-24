---
title: llama.cpp 完整部署（Windows + RTX2070 8G + GGUF 代码模型 + HTTP 服务 + Neovim blink.cmp）
---

# llama.cpp 完整部署（Windows + RTX2070 8G + GGUF 代码模型 + HTTP 服务 + Neovim blink.cmp）

llama.cpp 底层原生，无多余封装，占用显存最低，适合你 8G 2070，自带内置 HTTP 服务（server），替代 LM Studio/ollama-cpp。

## 一、环境依赖

1. VS2022（Desktop C++ 开发组件）
2. CUDA Toolkit 12.x（匹配 RTX2070 驱动）
3. Git
4. GGUF 模型：`deepseek-coder-v2-7b-lite-instruct.Q4_K_M.gguf`

## 二、拉取源码 & 编译 CUDA 版本

```bash
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp
```

### Windows 编译（启用 CUDA）

```bash
make CUDA=1
```

- 编译产出：`main.exe`、`server.exe`、`llama.cpp.dll`
- 若没有 make，用 CMake 方案：

```bash
mkdir build
cd build
cmake .. -DLLAMA_CUDA=ON
cmake --build . --config Release
```

Release 程序在 `build/Release/`

## 三、启动内置 HTTP 服务（核心，OpenAI 兼容接口）

新建 `start_server.bat`，放在 llama.cpp 根目录

```batch
@echo off
chcp 65001
:: 你的模型绝对路径
set MODEL=D:\AI\Models\deepseek-coder-v2-7b-lite-instruct.Q4_K_M.gguf

server.exe ^
-m %MODEL% ^
--host 127.0.0.1 ^
--port 11434 ^
-c 32768 ^
--n-gpu-layers 35 ^
-t 8 ^
--temp 0.1 ^
--max-seq-len 32768 ^
--batch-size 512 ^
--api-key dummy
```

### 参数说明（RTX2070 8G 专用）

- `-m`：GGUF 模型路径
- `-c / --max-seq-len`：上下文窗口 32768，OOM 则改为 16384
- `--n-gpu-layers 35`：2070 安全 GPU 卸载层数，爆显存降到 20~30
- `-t 8`：CPU 线程数
- `--port 11434`：和 Ollama 端口一致，Neovim 配置不用改
- `--api-key dummy`：任意字符串，本地服务无需真实密钥

双击脚本运行，出现 `Listening on http://127.0.0.1:11434` 即启动成功。

## 四、接口连通测试

```bash
curl http://127.0.0.1:11434/v1/chat/completions ^
-H "Content-Type: application/json" ^
-d "{
    \"model\": \"deepseek-coder-v2-7b-lite-instruct.Q4_K_M.gguf\",
    \"messages\": [
        {\"role\":\"user\",\"content\":\"写一段C++ ImGui窗口代码\"}
    ],
    \"temperature\":0.1
}"
```

正常返回代码代表服务可用。

## 五、对接 Neovim（blink.cmp + codecompanion.nvim）

### 1. blink.cmp 配置 AI 补全源

```lua
sources = {
  default = { "lsp", "path", "snippets", "buffer", "llama" },
  providers = {
    lsp = { weight = 100 },
    path = { weight = 90 },
    snippets = { weight = 80 },
    buffer = { weight = 70 },
    llama = {
      weight = 60,
      module = "blink.cmp.sources.openai",
      opts = {
        api_key = "dummy",
        base_url = "http://127.0.0.1:11434/v1",
        model = "deepseek-coder-v2-7b-lite-instruct.Q4_K_M.gguf",
        max_tokens = 256,
        temperature = 0.05,
        timeout = 2000,
      },
    },
  },
}
```

### 2. codecompanion.nvim 适配器

```lua
adapters = {
  openai_compatible = function()
    return require("codecompanion.adapters").extend("openai_compatible", {
      env = {
        url = "http://127.0.0.1:11434/v1",
        api_key = "dummy",
      },
      schema = {
        model = { default = "deepseek-coder-v2-7b-lite-instruct.Q4_K_M.gguf" },
        max_tokens = { default = 1024 },
        temperature = { default = 0.1 },
        num_ctx = { default = 32768 },
      },
    })
  end,
},
strategies = {
  chat = { adapter = "openai_compatible" },
  inline = { adapter = "openai_compatible" }
}
```

## 六、RTX2070 显存优化 & 排错

1. 启动直接 OOM（显存溢出）
   - `--n-gpu-layers 20` 降低 GPU 层
   - `-c 16384` 缩小上下文
   - 更换 Q3_K_M 更低量化 GGUF
2. 推理速度慢
   - 确认编译时 `CUDA=1`，无 CUDA 则全 CPU 运行极卡
   - 关闭后台 GeForce Experience、录屏、游戏释放显存
3. Neovim 无 AI 补全
   - 确认 `server.exe` 保持运行
   - 模型名称和配置里**完全一致**（文件名大小写、后缀不能错）
4. 单次推理卡顿严重
   - 降低 `blink.cmp` 里 `max_tokens=128`，减少单次生成长度

## 七、工作流程

1. 运行 `start_server.bat` 启动 llama.cpp HTTP 服务
2. 打开 Neovim
   - blink.cmp 混合 LSP + 本地 AI 行内实时补全
   - `<leader>cp` 选中代码修复、解释、生成 CMake
   - `<leader>cc` 打开对话窗口，处理长代码、编译报错、架构分析

## 八、对比其他方案

1. llama.cpp server：最轻量、显存占用最低，适合长期常驻开发（推荐你 2070）
2. LM Studio：可视化模型管理，调试参数方便，后台 GUI 占显存
3. ollama/ollama-cpp：封装层多，额外内存开销，没必要使用