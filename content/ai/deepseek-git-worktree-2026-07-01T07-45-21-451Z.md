# DeepSeek Export
Conversation: git worktree使用指南
URL: https://chat.deepseek.com/a/chat/s/3405e904-e5be-4102-9b01-49ce9a4eb3a6
Exported: 2026-07-01T07:45:21.451Z

## User

git worktree   怎么使用

## Assistant

`git worktree` 是一个非常强大的功能，它允许你在**同一个 Git 仓库**下，同时签出（checkout）**多个分支**到不同的目录。

简单来说，你不再需要为了切换分支而频繁 `git stash` 或关闭当前 IDE 窗口，可以在不同目录下并行开发不同功能。

---

### 1. 核心概念

-
**主工作树**：你最初克隆仓库的那个目录。
-
**链接的工作树**：通过 `git worktree add` 创建的新目录，它们共享同一个 `.git` 文件夹（实际上是通过 `.git` 文件软链接指向主仓库的 `.git` 对象库）。

---

### 2. 最常用的命令（日常开发）

#### 场景一：紧急修复 Bug（最经典用法）

假设你正在 `feature` 分支写代码，突然需要切到 `master` 修复一个紧急线上 Bug。

**传统方式**：先 `git add .` 或 `stash`，切到 master，改完再切回来，再 `pop`。
**Worktree 方式**：

bash

```bash
# 在项目根目录（/my-project）执行，当前在 feature 分支
git worktree add ../my-project-hotfix master
```

此时，你会发现在项目同级目录下多了一个 `my-project-hotfix` 文件夹，里面就是 `master` 分支的代码。

-
打开新的 IDE 窗口指向 `my-project-hotfix`，修改 Bug。
-
修改完后，直接在 `my-project-hotfix` 目录下 `git add .`，`git commit -m "fix"`，然后 `git push`。
-
修复完后，切回原 `my-project` 目录继续写你的 `feature`，**完全不受影响**。

#### 场景二：并行开发新功能

想在一个干净目录里尝试一个新想法，但又不想污染当前分支环境：

bash

```bash
git worktree add ../my-project-new-feature -b new-feature
```

这会在上级目录创建新文件夹，并基于当前分支新建并切换到 `new-feature` 分支。

---

### 3. 查看和管理所有工作树

-
**查看列表**：
bash

```bash
git worktree list
```
输出会显示所有工作树的路径、当前检出的提交哈希和分支名。
-
**删除工作树**（用完即删）：
bash

```bash
# 方式1：直接删掉文件夹（推荐）
rm -rf ../my-project-hotfix

# 方式2：用 git 命令清理（需要先进入该目录执行，或使用 prune）
git worktree remove ../my-project-hotfix
```
删除后，运行 `git worktree prune` 可以清理 `.git` 中残留的引用（`remove` 命令会自动清理，直接删文件夹则需要手动执行 `prune`）。

---

### 4. 高级技巧与注意事项

#### 1. 把工作树放在项目内部（不太推荐）

如果不指定路径，默认会放在项目根目录下的 `.git/worktrees` 里，但这样容易混淆。**建议统一放在项目外部**（如 `../` 同级目录）。

#### 2. 同一个分支只能被签出一次

Git 不允许两个工作树同时检出同一个分支。如果你想在另一个目录也看该分支的内容，可以使用 `git worktree add -b temp-branch` 基于该分支创建临时分支，或者使用 `--detach` 模式（分离头指针）：

bash

```bash
git worktree add ../my-project-detach --detach master
```

#### 3. 共享的 `.git` 文件

进入新创建的 `my-project-hotfix`，你会发现里面只有一个 `.git` **文件**（不是文件夹），里面写着 `gitdir: /原项目路径/.git/worktrees/xxx`。**千万不要修改或删除这个文件**。

#### 4. 敏感操作限制

-
在主工作树中执行 `git gc` 或 `git prune` 时，会自动处理所有链接的工作树。
-
如果某个工作树正在执行 rebase 或 merge，其他工作树无法切换该分支。

---

### 5. 终极对比：Worktree vs Stash vs 克隆

| 方式 | 适用场景 | 优点 | 缺点 |
| --- | --- | --- | --- |
| **git stash** | 改动很小，很快切回 | 无需额外目录 | 容易忘记 stash，冲突时处理麻烦 |
| **重新 Clone** | 完全隔离的环境 | 相互绝对独立 | 浪费硬盘空间，重新下载耗时，且需重新配置 remote |
| **git worktree** | **重度多分支并行开发** | **零成本切换、共享对象库（省空间）、无需 stash** | 需记住多个目录路径，IDE 需开多个窗口 |

---

### 6. 实用工作流示例（含撤销）

bash

```bash
# 1. 创建 worktree 用于修复 1.0 版本
git worktree add ../project-v1.0 v1.0

# 2. 进入目录修改代码
cd ../project-v1.0
git add . && git commit -m "hotfix"

# 3. 查看列表
git worktree list

# 4. 合并修复到主分支（在原目录操作，或者在这里操作都行）
cd ../project-main
git merge v1.0

# 5. 不再需要这个 worktree 了
git worktree remove ../project-v1.0

# 6. 如果直接 rm -rf 删除了文件夹，用下面命令清理垃圾
git worktree prune
```

如果你是在 **VS Code** 或 **IntelliJ** 等 IDE 中使用，直接 `File -> Open` 打开新创建的工作树目录即可，它们会识别为独立的项目窗口，互不影响。

如果你还想了解 `git worktree` 和 `submodule` 的区别，或者如何配合 `rebase` 使用，可以随时告诉我。😊
