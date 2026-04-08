# S2: Interaction & Orchestration Audit — gh-review SKILL.md

## Reviewed Files
- /Users/zhengfan/cc_manager/packer/gh-review/skills/gh-review/SKILL.md

## Findings

### [P1] comment-reply Skill dependency assumed but not verified — no fallback for missing skill

**File**: SKILL.md, Step 3
**Issue**: Step 3 instructs to "使用 Skill tool 调用 `comment-reply`" to generate reply drafts. There is a partial fallback: "若 `comment-reply` Skill 调用失败，将原始评论内容写入 GH_PENDING 并标注 `[草稿待生成]`". However, there is no pre-check verifying that the comment-reply skill is installed before starting the scan. If comment-reply is missing (which it will be for any user who installs only the gh-review plugin without separately installing comment-reply), every comment requiring a reply will produce a `[草稿待生成]` stub, making the scan results significantly less useful.
**Impact**: For users who install only the gh-review plugin, Step 3 will systematically fail to generate drafts. The fallback ensures no data loss, but the primary value proposition (auto-generated reply drafts) is lost.
**Recommendation**: Add a pre-flight check at the start of scan mode: verify comment-reply skill availability. If missing, either (a) warn the user and suggest installing it, or (b) fall back to a simpler draft generation approach (e.g., just echo the comment with a "请回复：" prefix).

### [P1] GH_PENDING path uses hardcoded project-slug notation that won't resolve for other users

**File**: SKILL.md, path table
**Issue**: The GH_PENDING path is `~/.claude/projects/-Users-zhengfan-cc-manager/memory/gh-pending.md`. This path contains a project-specific slug (`-Users-zhengfan-cc-manager`) that is derived from the author's machine path. For any other user, the projects directory slug will differ based on their username and project location. Similarly, GH_ACTIVITY_LOG and GH_REFERENCE use the same hardcoded slug.
**Impact**: Critical for plugin portability — all file I/O operations will fail silently or write to nonexistent directories when used by anyone other than the original author.
**Recommendation**: Use a dynamic path resolution mechanism (e.g., detect the current project slug at runtime) or store these files in a location that doesn't depend on project slug (e.g., `~/.claude/skills/gh-review/data/`).

### [P2] Interaction flow gap: cron mode scan results are not summarized in GH_CRON_LOG when zero items found

**File**: SKILL.md, Step 4 and "扫描输出格式" section
**Issue**: The GH_CRON_LOG format shows entries like `[OK] PR: ... — open（无变化）` for each scanned item. However, the skill only specifies running `notify-pending.sh` "仅在本次扫描写入了至少 1 条草稿时". If zero items need action, the cron log may still be written but there's no explicit "扫描完成，无需行动" terminal line. This makes it harder to distinguish "scan ran but found nothing" from "scan didn't run".
**Impact**: Minor operational visibility gap in cron mode debugging.
**Recommendation**: Add a terminal summary line to GH_CRON_LOG like `=== scan completed: 0 pending items ===` even when no drafts are generated.

### [P2] No data contract for GH_PENDING markdown schema validation

**File**: SKILL.md, Step 4 and 草稿处理模式
**Issue**: The GH_PENDING file is both written (by cron scan) and read (by interactive mode). The schema is defined implicitly via the markdown template in Step 4, but there's no validation when reading. If the file is manually edited or corrupted, the interactive parser may silently skip entries or misparse fields.
**Impact**: Edge case — only affects scenarios where GH_PENDING is corrupted, which is uncommon but possible.

### [P3] Step ordering in interactive scan mode is ambiguous

**File**: SKILL.md, Step 4
**Issue**: Step 4 says for interactive mode: "直接展示草稿，等待用户确认后发布". But it's unclear whether this happens per-item (as each draft is generated in Step 3) or batch (all drafts shown after Step 3 completes). The cron mode clearly writes to file, but interactive mode's UX flow is underspecified.
**Recommendation**: Clarify whether interactive scan shows drafts one-by-one as they're generated or in a batch after all scanning completes.

## Passed Items
- Clear mode branching (interactive vs cron) with explicit detection logic
- GH_PENDING file has a fixed header convention preventing accidental wipe
- Explicit error handling for notify-pending.sh failure (log + continue)
- Rate limit handling specified ([RATE_LIMITED] annotation)
- 7-day expiry mechanism for stale drafts
