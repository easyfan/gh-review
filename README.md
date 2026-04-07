[English](README.md) | [Chinese](README-zh.md)

# gh-review

Daily GitHub activity review for Claude Code — scans your plugin repos, generates reply drafts, and lets you confirm each response before publishing.

```
/gh-review                    # review pending drafts, or scan if none
/gh-review --mode=cron        # non-interactive scan (for crontab)
```

---

## What it does

**Interactive mode** (`/gh-review`):
- If there are pending drafts in the queue → shows them one by one for confirmation
- If no pending drafts → scans all open PRs and Issues, generates reply drafts interactively

**Cron mode** (`/gh-review --mode=cron`):
- Scans all open PRs and Issues silently
- Writes reply drafts to a queue file (`gh-pending.md`)
- Triggers a macOS notification via `notify-pending.sh` (if configured)
- Never publishes comments directly — all publishing requires human confirmation

### Scan steps

| Step | Action |
|------|--------|
| 1 | Scan open PRs — new comments, review status, merge state |
| 2 | Scan open Issues — new comments, close/bot-close detection |
| 3 | Identify items needing action (reply, clarify, or log only) |
| 4 | Generate reply drafts via `comment-reply` skill |
| 5 | Update `reference_gh_activity.md` with current state snapshot |

### Draft queue

Pending drafts are stored in:
```
~/.claude/projects/<cwd>/memory/gh-pending.md
```

Each draft entry:
```markdown
### 2026-04-08 09:03 | easyfan/my-plugin#12

**Trigger**: @user: "This is great, any plans for v2?"

**Strategy**: topic lead

**Draft reply**:
> Thanks! V2 is on the roadmap. What feature would be most useful for you?
```

Drafts persist until you explicitly **publish** or **skip** them. Entries older than 7 days are flagged `[expired]`.

---

## Prerequisites

- [Claude Code](https://claude.ai/code) CLI installed
- [GitHub CLI](https://cli.github.com/) (`gh`) installed and authenticated (`gh auth login`)
- `comment-reply` skill installed (for reply draft generation)

---

## Install

### Option A — Claude Code plugin (recommended)

```bash
/plugin marketplace add gh-review
/plugin install gh-review@gh-review
```

### Option B — install script

```bash
git clone https://github.com/easyfan/gh-review
cd gh-review
bash install.sh

# custom install location
CLAUDE_DIR=/path/to/.claude bash install.sh
```

### Option C — manual

```bash
cp -r skills/gh-review ~/.claude/skills/
```

---

## Usage

```
/gh-review [--mode=cron]
```

| Argument | Description | Default |
|----------|-------------|---------|
| _(none)_ | Interactive: show pending drafts or scan | interactive |
| `--mode=cron` | Non-interactive batch scan, writes to queue, no prompts | off |

**Examples:**

```bash
/gh-review                    # interactive: pending drafts → confirm & publish
/gh-review --mode=cron        # non-interactive: scan → write queue → exit
```

---

## Crontab setup (optional, for daily automation)

Add to your crontab (`crontab -e`):

```
# gh-review daily at 9:03 AM
3 9 * * * claude -p "/gh-review --mode=cron" --cwd ~/your-project >> /tmp/gh-review-cron.log 2>&1
```

For macOS persistent notifications on scan completion, see the [notify-pending.sh pattern](https://github.com/easyfan/gh-review).

---

## Files installed

```
~/.claude/
└── skills/
    └── gh-review/
        └── SKILL.md        # skill definition
```

---

## Evals

Trigger-accuracy eval suite: `evals/evals.json` — 7 cases (5 positive triggers, 2 negative).

Run with [`skill-test`](https://github.com/easyfan/skill-test):
```bash
/skill-test packer/gh-review
```

---

## Changelog

### v1.0.0 (2026-04-08)
- Initial release
- Interactive and cron modes
- Pending draft queue with 7-day expiry
- `comment-reply` skill integration for draft generation
- Trigger phrases refined per Anthropic skill-building guide (bilingual CN+EN, negative triggers added)
