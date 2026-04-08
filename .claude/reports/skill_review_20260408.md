# Skill Review Report — gh-review

**Date**: 2026-04-08
**Target**: `/Users/zhengfan/cc_manager/packer/gh-review/skills/gh-review/SKILL.md`
**Pipeline**: S1 (Definition) + S2 (Orchestration) + S3 (Research) + S4 (Usability) -> Challenger (opus) -> Reporter

---

## Quality Rating: 🟡 Usable (with defects)

**Rationale**: 3 confirmed P1 findings remain after Challenger review. No P0 (workflow crash) issues, but P1 items affect core functionality for plugin portability and scan reliability.

---

## Summary

| Category | Count |
|----------|-------|
| Total findings | 17 |
| CONFIRMED P1 | 3 |
| CONFIRMED P2 | 9 |
| CONFIRMED P3 | 5 |
| DISPUTED (downgraded) | 1 (P1→P2) |
| Directly fixed by Reporter | 2 |
| Suggestions (manual action) | 15 |

---

## 🔴 CONFIRMED P1 — Functional Defects (require manual fix)

### P1-1: Hardcoded project-slug paths break portability [S2]
**File**: SKILL.md, lines 15-18 (path table)
**Issue**: All memory file paths (`GH_PENDING`, `GH_ACTIVITY_LOG`, `GH_REFERENCE`) use the hardcoded slug `-Users-zhengfan-cc-manager`, which only works on the author's machine.
**Status**: Suggestion — requires design decision on portable path strategy
**Suggested fix**: Replace hardcoded paths with a dynamic resolution note, e.g.:
```
| GH_PENDING | `~/.claude/projects/<PROJECT_SLUG>/memory/gh-pending.md` |
```
And add a "路径解析" section explaining: "PROJECT_SLUG 为当前项目路径的 Claude Code 内部编码，运行时由 Claude 自动解析。"

Alternatively, move data files to `~/.claude/skills/gh-review/data/` which doesn't depend on project slug.

### P1-2: No gh auth pre-flight check [S4]
**File**: SKILL.md, scan mode section
**Issue**: No authentication verification before scan. Users without `gh auth` configured will see cryptic API errors.
**Status**: **DIRECTLY FIXED** — Added auth check at start of scan mode
**Fix applied**: Added pre-flight auth check paragraph before Step 1

### P1-3: comment-reply dependency not pre-verified [S2]
**File**: SKILL.md, Step 3
**Issue**: The skill depends on `comment-reply` Skill but doesn't verify availability before scanning. Fallback exists but primary value (draft generation) is silently lost.
**Status**: **DIRECTLY FIXED** — Added pre-flight dependency note in scan mode intro
**Fix applied**: Added comment-reply availability check guidance before Step 1

---

## 🟡 CONFIRMED P2 — Quality/Consistency Issues (suggestions)

### P2-1: Description mixes trigger signals with negative scope [S1]
**Suggestion**: Restructure description to front-load positive triggers, separate exclusion clause.

### P2-2: Hardcoded "easyfan" org limits plugin reusability [S1]
**Suggestion**: Parameterize GitHub user/org identity or explicitly document as author-specific tool.

### P2-3: GitHub Search API pagination not addressed [S3]
**Suggestion**: Add `--paginate` or `per_page=100` to `gh api` search calls.

### P2-4: Search API vs REST API rate limit not differentiated [S3]
**Suggestion**: Document that search API has 30 req/min limit vs REST's 5000 req/hr.

### P2-5: N+1 query pattern for PR details [S3, downgraded from P1]
**Suggestion**: Consider batch listing with `gh pr list --json` per repository.

### P2-6: Cron log lacks zero-action terminal summary [S2]
**Suggestion**: Add "=== scan completed: 0 pending items ===" line.

### P2-7: No GH_PENDING schema validation on read [S2]
**Suggestion**: Add basic markdown heading parser validation when reading GH_PENDING.

### P2-8: Edit flow lacks cancel option [S4]
**Suggestion**: Add "取消" option to return to [发布/编辑/跳过] menu.

### P2-9: Progress feedback lacks timing [S4]
**Suggestion**: Add elapsed time to step completion messages.

---

## 🟢 CONFIRMED P3 — Style/Documentation (optional)

### P3-1: No version tracking in SKILL.md [S1]
### P3-2: Interactive scan step ordering ambiguous [S2]
### P3-3: No GitHub Notifications API integration [S3]
### P3-4: No batch draft operations [S4]
### P3-5: "跳过" semantics could confuse users [S4]

---

## ✅ Passed Items

- YAML front-matter well-formed with all required fields
- name matches parent directory ("gh-review")
- description length within limits (304 chars)
- Good trigger phrase variety (Chinese + English)
- Clear mode branching (interactive vs cron)
- Safe automation pattern (no auto-publishing in cron mode)
- GH_PENDING fixed header convention
- Rate limit handling with [RATE_LIMITED] annotation
- 7-day expiry for stale drafts
- Error handling for notify-pending.sh failure
- Use of gh CLI (best practice for auth)
- Diff-based change detection via GH_REFERENCE

---

## Modification Log

| Field | File | Change | Reason |
|-------|------|--------|--------|
| Scan pre-flight | SKILL.md | Added gh auth check | P1-2: prevent cryptic auth errors |
| Scan pre-flight | SKILL.md | Added comment-reply dependency note | P1-3: surface missing dependency |
