# S4: Usability Audit — gh-review SKILL.md

## Reviewed Files
- /Users/zhengfan/cc_manager/packer/gh-review/skills/gh-review/SKILL.md

## Findings

### [P1] No error handling for gh CLI authentication failure

**File**: SKILL.md, Step 1/Step 2
**Issue**: The scan steps assume `gh` is authenticated. If `gh auth status` would fail (expired token, not logged in), all `gh api` and `gh pr view` calls will fail with authentication errors. The skill has no pre-flight authentication check and no guidance on what happens when auth fails mid-scan.
**Impact**: Users who install the plugin but haven't configured gh auth will see cryptic API errors with no actionable guidance. The install.sh warns about missing `gh` CLI but not about auth status.
**Recommendation**: Add a pre-flight check at the start of scan mode: `gh auth status` or equivalent. If not authenticated, output a clear message: "请先运行 gh auth login 完成认证" and abort gracefully.

### [P2] Interactive mode "编辑" flow lacks cancel/undo

**File**: SKILL.md, 草稿处理模式
**Issue**: When user selects "编辑" on a draft, the flow is: show draft -> user inputs new version -> confirm publish. There is no "取消编辑" option to abort mid-edit and return to the [发布/编辑/跳过] menu. Once the user enters edit mode, the only documented exit is to confirm or deny publication.
**Impact**: Users who accidentally enter edit mode must either publish or have no documented way to go back. In practice, they could type something and then say "否" to the confirmation, but this isn't explicitly stated.
**Recommendation**: Add explicit cancel option in the edit flow, e.g., "输入\"取消\"可退出编辑模式，回到选择菜单".

### [P2] Progress feedback in scan mode lacks timing information

**File**: SKILL.md, scan mode progress requirements
**Issue**: The progress messages show step progression (Step 1/5, Step 2/5, etc.) and counts (已检查数量), but no timing information. For cron mode debugging and for interactive users, knowing "Step 1 completed in 15s" would help identify if a step is hanging or if the scan is normal.
**Impact**: Users cannot distinguish between "scan is working but slow" and "scan is hung" without timing data.
**Recommendation**: Add elapsed time to step completion messages, e.g., "Step 1/5: 扫描 open PR 完成（3 个 PR, 5.2s）".

### [P3] No batch operations for draft management

**File**: SKILL.md, 草稿处理模式
**Issue**: Drafts are processed one-by-one with [发布/编辑/跳过] per item. There is mention of "批量清除过期草稿" for expired items, but no batch operations for non-expired drafts (e.g., "全部发布", "全部跳过"). With many pending drafts, processing one-by-one is tedious.
**Impact**: UX friction when there are many pending drafts.
**Recommendation**: Add batch action options when draft count > 3: "全部发布 / 逐条处理 / 全部跳过".

### [P3] "跳过（本次）" semantics could confuse users about persistence

**File**: SKILL.md, 草稿处理模式
**Issue**: "跳过（本次）" means "keep in pending, show again next time." But "本次" could be interpreted as "skip for this session only" (which it is) or "skip permanently" (which it isn't). The 7-day expiry adds another dimension — skipped items eventually get marked [过期] but aren't auto-deleted.
**Impact**: Minor UX confusion about draft lifecycle.
**Recommendation**: Clarify skip semantics in the user-facing text: "跳过（保留在待处理列表，下次继续显示；7 天后标为过期）".

## Passed Items
- Clear mode detection logic (interactive vs cron) prevents accidental publishing
- Step-by-step progress output keeps scan visible to user
- Rate limit handling with [RATE_LIMITED] annotation
- Separate cron log file for debugging
- Non-interactive mode never publishes — safe automation pattern
- GH_PENDING fixed header prevents accidental file wipe
