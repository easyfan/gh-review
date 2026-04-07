---
name: gh-review
description: |
  扫描 easyfan 插件仓库（packer 系列）的 PR/Issue 动态，生成待回复草稿并逐条让用户确认发布。交互模式下展示 gh-pending.md 中的待处理草稿；cron 模式下完成扫描后写入草稿队列并退出。
  用于："/gh-review"、"review github"、"检查 github"、"github 日报"、"有没有新的 PR 评论"、"github 最近有什么动静"、"待处理的评论"、"看一下 issue 状态"、"跟进一下 github"。
  cron 调用："/gh-review --mode=cron"。不适用于通用 GitHub 操作问题或非 easyfan 仓库。
---

## 路径约定

以下路径为绝对路径，正文所有引用均使用此处定义，不得使用裸文件名：

> **路径解析**：`<PROJECT_SLUG>` 由 Claude 在运行时自动推导——将当前工作目录的绝对路径中的 `/` 替换为 `-`（去掉开头的 `-`），例如 `/Users/alice/my-project` → `-Users-alice-my-project`。首次运行时请确认路径正确，或在 SKILL.md 中将占位符替换为实际值。

| 变量 | 绝对路径 |
|------|---------|
| GH_PENDING | `~/.claude/projects/<PROJECT_SLUG>/memory/gh-pending.md` |
| GH_ACTIVITY_LOG | `~/.claude/projects/<PROJECT_SLUG>/memory/gh-activity-log.md` |
| GH_REFERENCE | `~/.claude/projects/<PROJECT_SLUG>/memory/reference_gh_activity.md` |
| GH_CRON_LOG | `/tmp/gh-review-cron.log` |

**GH_ACTIVITY_LOG** 记录已发布回复的操作历史（发布时间、仓库、评论 URL）。
**GH_REFERENCE** 记录 PR/Issue 状态快照，作为"上次检查状态"基线。

**gh-pending.md 固定 header（清空时保留前两行）**：
```
# GitHub Pending Actions
<!-- DO NOT EDIT HEADER -->
```

---

# GitHub Review Skill

每日回溯所有 easyfan GitHub 活动，维护 PR/Issue 跟进记录，识别需要行动的项目。

---

## 运行模式判断（最先执行）

**在执行任何扫描前**，先检测当前是否在交互式会话中：

- **交互式**（用户直接输入 `/gh-review`）：
  1. 先检查 GH_PENDING 是否有未处理草稿（文件存在且含至少一个 `###` 草稿条目）→ 若有，进入「草稿处理模式」；若文件不存在或无有效条目，输出"暂无待处理草稿，进入扫描模式..."并直接进入扫描模式
  2. 若无 pending，进入「扫描模式」

- **非交互式**（cron 调用，无 TTY）：
  - 只执行「扫描模式」
  - 发现需回复项时写入 GH_PENDING，不发布
  - 扫描结束后运行 `bash ~/.claude/hooks/notify-pending.sh`

判断方式：检测 prompt 参数字符串是否包含 `--mode=cron`。含则为非交互式，否则为交互式。

cron 调用示例（需更新 crontab）：
```
03 09 * * * claude -p "/gh-review --mode=cron"
```

> 注意：旧的 crontab 若使用无参数形式 `claude -p "/gh-review"`，需更新为上述带 `--mode=cron` 的形式，否则 cron 将被识别为交互式并展示草稿处理界面。

---

## 草稿处理模式（交互式 + pending 存在时）

读取 GH_PENDING，逐条展示：

```
📬 发现 N 条待处理草稿（来自 YYYY-MM-DD HH:MM 的 cron 扫描）

--- 草稿 1 / N ---
仓库：easyfan/xxx#N
触发：@用户名 留言："评论内容摘要..."
策略：[comment-reply 建议的策略]
草稿回复：
  "回复内容..."

[发布] [编辑] [跳过]
```

用户选择后：
- **发布**：调用 `gh pr comment` 或 `gh issue comment` 发布，记录到 GH_ACTIVITY_LOG
- **编辑**：原文展示当前草稿内容，提示用户输入修改后的版本，收到修改内容后再次展示并请求确认（"确认发布？[是/否]"），确认后发布并记录到 GH_ACTIVITY_LOG
- **跳过（本次）**：保留在 pending，下次继续显示。草稿创建超过 7 天的条目在展示时标注 `[过期]`，用户可选择"批量清除过期草稿"将其永久移除。

所有草稿处理完毕后，将"跳过"的条目保留，将"发布"和"编辑后发布"的条目从 GH_PENDING 中移除；**不整体清空文件**，保留 header 和未处理条目。

---

## 扫描模式

### 前置检查（扫描开始前执行）

1. **gh 认证检查**：运行 `gh auth status`，若未认证则输出 `「请先运行 gh auth login 完成 GitHub 认证后再执行扫描」` 并终止扫描。
2. **comment-reply 可用性**：确认 `comment-reply` Skill 可被调用。若不可用，输出 `「⚠️ comment-reply skill 未安装，回复草稿将无法自动生成（标注为 [草稿待生成]）。建议安装 comment-reply 以获取完整功能。」`，但不中断扫描——Step 3 中调用失败时按已有 fallback 处理。

> 进度提示要求：扫描开始时输出 `「正在扫描 GitHub 活动，请稍候...」`；Step 1 开始时输出 `「Step 1/5: 扫描 open PR...」`，完成后输出已检查数量；Step 2 开始时输出 `「Step 2/5: 扫描 open Issue...」`，完成后输出已检查数量；Step 3 开始时输出 `「Step 3/5: 识别需要行动的项...」`；Step 4 开始时输出 `「Step 4/5: 写入草稿...」`，完成后输出本次写入草稿数量；Step 5 开始时输出 `「Step 5/5: 更新状态快照...」`，完成后输出 `「扫描完成」`。每处理完一个仓库输出一行进度，使扫描过程对用户可见。

### Step 1：扫描 open PR 状态

```bash
gh api "search/issues?q=author:easyfan+type:pr+state:open" --jq '.items[] | {repo: .repository_url, number: .number, title: .title}'
```

对每个 open PR：
```bash
gh pr view <number> --repo <owner/repo> --json state,mergedAt,comments,reviews
```

检查：是否已 merge、是否有新评论、review 状态

### Step 2：扫描 open Issue 状态

```bash
gh api "search/issues?q=author:easyfan+type:issue+state:open" --jq '.items[] | {repo: .repository_url, number: .number, title: .title}'
```

对每个 open Issue：
```bash
gh issue view <number> --repo <owner/repo> --json state,comments,closedAt,labels
```

检查：是否被关闭、是否有新评论、是否将被 bot 自动关闭为 duplicate

### Step 3：识别需要行动的项

首先读取 GH_REFERENCE，获取上次扫描记录的状态快照（若文件不存在则视为"首次扫描"，所有当前活动项均视为新发现）。将本次扫描结果与快照对比，找出有变化的条目（新评论、状态变更）。

对每条有新评论或状态变化的条目，判断：
- 他人留言且需要回应 → 使用 Skill tool 调用 `comment-reply`，传入评论全文和背景上下文（格式：`仓库：easyfan/xxx#N\n评论者：@用户名\n评论内容：...`），生成回复草稿。若 `comment-reply` Skill 调用失败，将原始评论内容写入 GH_PENDING 并标注 `[草稿待生成]`，确保条目不丢失。
- 将被自动 bot 关闭但不是 duplicate → 生成"澄清草稿"
- 状态变化（merge/close）→ 仅更新记录，无需草稿

### Step 4：写入草稿或直接处理

**交互式**：直接展示草稿，等待用户确认后发布。

**非交互式（cron）**：将草稿追加写入 GH_PENDING：

```markdown
### YYYY-MM-DD HH:MM | easyfan/xxx#N

**触发评论**：@用户名："评论全文"

**建议策略**：[策略名]

**草稿回复**：
> 回复内容...
```

**仅在本次扫描写入了至少 1 条草稿时**，执行通知脚本：
```bash
bash ~/.claude/hooks/notify-pending.sh
```
若脚本执行失败（退出码非 0），在 GH_CRON_LOG 末尾追加 `[NOTIFY_FAILED] 请手动检查 GH_PENDING 文件`，但不中断后续流程。

**交互式扫描完成后，输出摘要**：
```
扫描完成：N 个 PR，M 个 Issue，X 条新草稿已写入 pending（或：本次无新草稿）
```

### Step 5：更新 GH_REFERENCE（reference_gh_activity.md）

更新 GH_REFERENCE 中每条记录状态：已 merge/closed 标为 `[DONE]`，新发现项加入待跟进列表，注明最后检查时间。

---

## 扫描输出格式（写入 GH_CRON_LOG）

```
=== gh-review YYYY-MM-DD HH:MM ===
[OK] PR: easyfan/my-plugin#12 — open（+1 new comment）-> 草稿已写入 pending
[OK] Issue: easyfan/another-plugin#3 — open（无变化）
[OK] Issue: easyfan/my-plugin#9 — open（无变化）
[OK] Issue: easyfan/my-plugin#8 — open（+1 new comment）-> 草稿已写入 pending
pending 共 2 条 -> 通知已发送
```

---

## 注意事项

- 非交互式模式**绝不**直接调用 `gh comment`，只写 pending 文件
- 若 `gh` API rate limit 触发，跳过该仓库并在 log 中标注 `[RATE_LIMITED]`
- GH_PENDING 草稿保留直到用户明确选择"发布"或"跳过（本次）"，不自动清除；7 天后自动标注 `[过期]`
