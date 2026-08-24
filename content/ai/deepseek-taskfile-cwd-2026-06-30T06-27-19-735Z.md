# DeepSeek Export
Conversation: Taskfile设置cwd
URL: https://chat.deepseek.com/a/chat/s/4fe535d5-6083-44a6-aac9-67d78a0c6713
Exported: 2026-06-30T06:27:19.735Z

## User

taskfiles.yml  设置cwd

## Assistant

在 Taskfile 中，你可以通过多种方式设置 `cwd`（当前工作目录）。以下是几种常见的方法：

## 1. **在任务级别设置 `dir`**

这是最常用的方式，在单个任务中指定工作目录：

yaml

```yaml
version: '3'

tasks:
build:
dir: ./backend          # 切换到 backend 目录执行命令
cmds:
- go build -o app .

test:
dir: ./frontend
cmds:
- npm test
```

## 2. **在任务中使用 `cd` 命令**

如果需要在任务中切换目录并执行多个命令：

yaml

```yaml
version: '3'

tasks:
deploy:
cmds:
- cd ./deploy && ./deploy.sh
# 或者使用多行
- |
cd ./deploy
./deploy.sh
docker-compose up -d
```

## 3. **使用变量设置动态路径**

yaml

```yaml
version: '3'

vars:
PROJECT_ROOT: .
BACKEND_DIR: '{{.PROJECT_ROOT}}/backend'

tasks:
backend:
dir: '{{.BACKEND_DIR}}'
cmds:
- go mod tidy
- go run main.go
```

## 4. **在 Taskfile 全局设置默认目录**

虽然 Taskfile 本身没有全局 `cwd` 设置，但你可以通过环境变量或使用 `includes` 来组织：

yaml

```yaml
version: '3'

includes:
backend: ./backend/Taskfile.yml
frontend: ./frontend/Taskfile.yml

tasks:
build-all:
deps:
- backend:build
- frontend:build
```

然后在子目录的 Taskfile 中分别设置各自的 `dir`。

## 5. **结合 `--dir` 命令行参数**

运行时也可以指定工作目录：

bash

```bash
# 在指定目录执行任务
task --dir ./backend build

# 或使用环境变量
TASK_DIR=./backend task build
```

## 6. **使用 `env` 配合 `cwd`**

某些命令可能需要环境变量配合：

yaml

```yaml
version: '3'

tasks:
docker-compose:
dir: ./docker
env:
COMPOSE_PROJECT_NAME: myapp
cmds:
- docker-compose up -d
```

## 完整示例

yaml

```yaml
version: '3'

vars:
ROOT: .
API_DIR: '{{.ROOT}}/api'
WEB_DIR: '{{.ROOT}}/web'

tasks:
# 在 api 目录执行
api-dev:
dir: '{{.API_DIR}}'
cmds:
- go mod download
- go run main.go

# 在 web 目录执行
web-dev:
dir: '{{.WEB_DIR}}'
cmds:
- npm install
- npm run dev

# 混合使用多个目录
full-stack:
cmds:
- task: api-dev
- task: web-dev

# 在项目根目录执行，但某些命令需要切换目录
build-all:
cmds:
- echo "Building API..."
- cd {{.API_DIR}} && go build
- echo "Building Web..."
- cd {{.WEB_DIR}} && npm run build
```

**注意事项：**

-
`dir` 是相对于 Taskfile 所在目录的路径
-
如果 `dir` 指定的目录不存在，Task 会报错
-
使用 `dir` 时，所有 `cmds` 中的命令都会在该目录下执行
-
多个任务可以共享相同的 `dir` 设置

你想在什么场景下使用 `cwd`？我可以提供更具体的配置建议。
