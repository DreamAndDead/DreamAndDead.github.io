---
title: llama.cpp 三类 WebUI 对比（适配你 RTX2070 8G + C++ 代码开发）
---

# llama.cpp 三类 WebUI 对比（适配你 RTX2070 8G + C++ 代码开发）

分 **内置原生 WebUI（最轻）**、**Open WebUI（功能最强，推荐）**、**Oobabooga（专业调参）**，全部兼容 llama-server OpenAI 接口，和你 Neovim minuet/codecompanion 共存不冲突。

## 一、llama.cpp 内置原生 WebUI（零额外安装，首选轻量方案）

新版 llama-server 自带前端，**不用装 Python/Docker**，启动服务自动开启，显存占用最低。

![](data:image/svg+xml,%3csvg%20xmlns=%27http://www.w3.org/2000/svg%27%20version=%271.1%27%20width=%27256%27%20height=%27192%27/%3e)![image](https://p11-flow-imagex-sign.byteimg.com/labis/image/d2b6bdf92e206c200fbdb6e32610867e~tplv-be4g95zd3a-448x448.jpeg?lk3s=8e244e95&rcl=20260625125424DFA089784138EF99501E&rrcfp=b2576990&x-expires=1790139269&x-signature=9az5X6Hp73%2FWSZkLKhMtTDjhsN0%3D)

原生WebUI聊天页

![](data:image/svg+xml,%3csvg%20xmlns=%27http://www.w3.org/2000/svg%27%20version=%271.1%27%20width=%27256%27%20height=%27192%27/%3e)![image](https://p3-flow-imagex-sign.byteimg.com/labis/image/6fb7ecee478459c539463cc318511087~tplv-be4g95zd3a-448x448.jpeg?lk3s=8e244e95&rcl=20260625125424DFA089784138EF99501E&rrcfp=b2576990&x-expires=1790139269&x-signature=d34sMTqJbITkcY%2BPJ1euNV8Jel0%3D)

设置面板

### 1. Windows 启动脚本（适配 DeepSeek-Coder 7B Q4_K_M，RTX2070）

```batch
@echo off
chcp 65001
cd /d D:\llama.cpp\build\Release
set MODEL=D:\AI-Models\deepseek-coder-v2-7b-lite-instruct.Q4_K_M.gguf

:: 内置WebUI默认端口8081，自动开启；--no-webui 可关闭
llama-server.exe ^
-m %MODEL% ^
--host 127.0.0.1 ^
--port 8081 ^
--ctx-len 32768 ^
--n-gpu-layers 35 ^
-t 8 ^
--sleep-idle-seconds 120 ^
--temp 0.1 ^
--api-key dummy
```

### 2. 访问地址

浏览器打开：`http://127.0.0.1:8081`

### 优点

1. 无额外进程，只占用推理显存，8G 显卡压力最小
2. 原生支持代码高亮、多对话、系统提示词模板
3. 内置 FIM/chat 双接口，同时给 WebUI、Neovim 提供服务
4. 闲置自动卸载模型释放显存（`--sleep-idle-seconds`）

### 缺点

无 RAG 知识库、无文件上传解析、模型管理功能简单

### 适合你：日常快速查代码、临时调试 prompt、不想多开软件

## 二、Open WebUI（综合最强，代码开发推荐）

独立现代化 ChatGPT 风格网页，**单独进程，对接 llama-server API**，代码阅读 / 项目分析体验碾压内置 UI。

### 核心优势（写 C++/CMake 刚需）

- 大代码块滚动高亮、一键复制代码、折叠长日志
- 上传`.h/.cpp/CMakeLists.txt`文件，全局解析工程
- 多模型切换、对话文件夹分类、搜索历史对话
- RAG 本地知识库：把引擎源码库上传，问答时自动检索上下文
- 支持 Docker 一键部署 / Python 原生安装，Windows 友好

### 部署步骤（Windows Python 版，无需 Docker）

1. 安装依赖

```powershell
pip install open-webui
```

2. 新开终端启动 Open WebUI（独立于 llama-server）

```powershell
# 指定数据存放目录，持久保存对话
$env:DATA_DIR="D:\open-webui-data"
open-webui serve --host 127.0.0.1 --port 9000
```

3. 浏览器访问 `http://127.0.0.1:9000`，注册管理员账号
4. 对接 llama.cpp 后端 设置 → 管理设置 → 连接 → OpenAI 连接 → 添加

- Base URL：`http://127.0.0.1:8081/v1`
- API 密钥：随便填`dummy` 保存后即可加载 DeepSeek 代码模型。

### 显存注意

Open WebUI 前端几乎不吃显存，显存压力全在 llama-server，和 Neovim 可同时运行。

## 三、Text Generation WebUI (Oobabooga，专业调参专用)

老牌全能 WebUI，适合深度调试模型参数、LoRA 微调，不推荐日常写代码。

### 优点

采样参数拉满（top_p/min_p/ 重复惩罚等）、自定义对话模板、扩展插件生态

### 缺点

Python 依赖巨多、后台常驻内存大、启动慢、界面臃肿，8G 显卡额外占用资源

### 适用场景：测试不同量化、调优代码生成参数，日常开发没必要装

# 三套 WebUI 横向对比（你的使用场景优先级）

| 方⁠案 | 额⁠外⁠依⁠赖 | 显⁠存⁠额⁠外⁠开⁠销 | 代⁠码⁠解⁠析 | RAG 文⁠件⁠上⁠传 | 部⁠署⁠难⁠度 | 推⁠荐⁠度 |
| --- | --- | --- | --- | --- | --- | --- |
| llama.cpp 内⁠置 WebUI | 无 | ≈0 | 基⁠础⁠代⁠码⁠高⁠亮 | 不⁠支⁠持 | ★☆☆☆☆ | 日⁠常⁠快⁠速⁠问⁠答 |
| Open WebUI | Python/Docker | 极⁠低 | 完⁠整⁠代⁠码⁠块 + 文⁠件⁠解⁠析 | 支⁠持⁠工⁠程⁠上⁠传 | ★★☆☆☆ | **主⁠力⁠推⁠荐** |
| Oobabooga | 全⁠套 Python 环⁠境 | 高 | 代⁠码⁠功⁠能⁠弱 | 支⁠持⁠但⁠笨⁠重 | ★★★★☆ | 仅⁠模⁠型⁠调⁠参 |

# 完整工作流（你 RTX2070 + Neovim + Open WebUI）

1. 运行`start_server.bat`启动 llama-server（端口 8081，内置 WebUI）
2. 新开终端启动 Open WebUI（端口 9000，对接 8081 后端）
3. Neovim：blink.cmp + minuet 走 FIM 接口实时补全
4. 分工使用：
   - Neovim：写代码、行内实时 AI 提示
   - Open WebUI：上传整套 CMake / 源码、架构分析、批量修复报错、长对话
   - 内置 WebUI：临时快速提问，不想开 Open WebUI 时备用

# 关键避坑

1. 端口冲突：llama-server 用 8081，Open WebUI 用 9000，分开不冲突
2. OOM 显存溢出：llama-server 务必加`--sleep-idle-seconds 120`闲置自动卸载模型
3. 代码生成乱序：WebUI 里使用 DeepSeek-Coder 专用 chat 模板，开启 FIM 模式
4. 局域网手机访问：llama-server 参数改为`--host 0.0.0.0`，放行 Windows 防火墙 8081 端口