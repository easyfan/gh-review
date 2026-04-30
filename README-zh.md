[English](README.md) | [中文](README-zh.md)

# gh-review

Claude Code 每日 GitHub 活动回顾——扫描插件仓库的 PR/Issue 动态，生成回复草稿，逐条让你确认后发布。

```
/gh-review                    # 查看待处理草稿，或直接扫描
/gh-review --mode=cron        # 非交互扫描（供 crontab 使用）
```

---

## 功能介绍

**交互模式**（`/gh-review`）：
- 若 pending 队列中有草稿 → 逐条展示，等待你确认发布
- 若无待处理草稿 → 扫描所有 open PR/Issue，生成回复草稿，实时互动处理

**Cron 模式**（`/gh-review --mode=cron`）：
- 静默扫描所有 open PR/Issue
- 将回复草稿写入队列文件（`gh-pending.md`）
- 触发 macOS 通知（需配置 `notify-pending.sh`）
- 绝不直接发布评论——所有发布操作均需人工确认

### 扫描步骤

| 步骤 | 操作 |
|------|------|
| 1 | 扫描 open PR——新评论、review 状态、merge 状态 |
| 2 | 扫描 open Issue——新评论、关闭/bot 自动关闭检测 |
| 3 | 识别需要行动的项目（回复、澄清或仅记录） |
| 4 | 通过 `comment-reply` skill 生成回复草稿 |
| 5 | 更新 `reference_gh_activity.md` 状态快照 |

### 草稿队列

待处理草稿存储在：
```
~/.claude/projects/<cwd>/memory/gh-pending.md
```

每条草稿格式：
```markdown
### 2026-04-08 09:03 | easyfan/my-plugin#12

**触发评论**：@用户名："评论内容摘要..."

**建议策略**：话题引导

**草稿回复**：
> 感谢！V2 正在规划中，最希望看到哪个功能？
```

草稿保留直到你明确选择**发布**或**跳过**。超过 7 天的条目标注 `[过期]`。

---

## 前置条件

- 已安装 [Claude Code](https://claude.ai/code) CLI
- 已安装 [GitHub CLI](https://cli.github.com/)（`gh`）并完成认证（`gh auth login`）
- 已安装 `comment-reply` skill（用于生成回复草稿）

---

## 安装

### 方式 A — Claude Code 插件（推荐）

```bash
/plugin marketplace add easyfan/gh-review
/plugin install gh-review@gh-review
```

### 方式 B — 安装脚本

```bash
git clone https://github.com/easyfan/gh-review
cd gh-review
bash install.sh
```

### 方式 C — 手动

```bash
cp -r skills/gh-review ~/.claude/skills/
```

---

## 用法

```
/gh-review [--mode=cron]
```

| 参数 | 说明 | 默认值 |
|------|------|--------|
| _（无）_ | 交互：展示待处理草稿或扫描 | 交互模式 |
| `--mode=cron` | 非交互批处理：扫描 → 写队列 → 静默退出 | 关 |

**示例：**

```bash
/gh-review                    # 交互：查看草稿 → 确认发布
/gh-review --mode=cron        # 非交互：扫描 → 写队列 → 退出
```

---

## Crontab 配置（可选，用于每日自动化）

编辑 crontab（`crontab -e`）并添加：

```
# gh-review 每日 9:03 自动扫描
3 9 * * * claude -p "/gh-review --mode=cron" --cwd ~/your-project >> /tmp/gh-review-cron.log 2>&1
```

### macOS 持久化通知

默认情况下，cron 输出静默写入日志文件，容易被忽略。如需在扫描完成后弹出持久弹窗、点击后自动打开 Claude 并注入上下文，参见：

**[Wake me up, when cronjob ends](https://zhengeasyfan.blogspot.com/2026/04/wake-me-up-when-cronjob-ends.html)** — 完整方案：`notify-pending.sh` + `open-cc.sh`，实现 `display alert` 持久弹窗、iTerm2 AppleScript 窗口控制，以及根据 pending 草稿数量注入 Claude 启动上下文。

---

## 已安装文件

```
~/.claude/
└── skills/
    └── gh-review/
        └── SKILL.md        # skill 定义
```

---

## 更新日志

### v1.1.0（2026-04-30）

自动跳过已处理项目：

| 变更项 | 说明 |
|--------|------|
| 跳过自己的评论 | 最后一条评论作者是 `easyfan` 本人时，跳过该条目，不生成草稿 |
| 去重优化 | 避免为已回复的 PR/Issue 重复生成草稿 |

See [README.md](README.md) for full English release notes.

### v1.0.0（2026-04-08）
- 首次发布
- 支持交互模式和 cron 模式
- 待处理草稿队列，7 天自动标记过期
- 集成 `comment-reply` skill 生成草稿
- 根据 Anthropic skill 构建指南优化触发词（中英双语，加入否定触发）
