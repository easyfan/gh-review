# S3: External Research & Best Practices Audit — gh-review SKILL.md

## Reviewed Files
- /Users/zhengfan/cc_manager/packer/gh-review/skills/gh-review/SKILL.md

## Findings

### [P2] GitHub API search endpoint pagination not addressed

**File**: SKILL.md, Step 1 and Step 2
**Issue**: The `gh api "search/issues?q=author:easyfan+type:pr+state:open"` call uses GitHub's Search API. Per GitHub API docs, search results are paginated (default 30 items per page, max 100). The skill does not specify `--paginate` or `per_page` parameters. For users with many open PRs/Issues (>30), later items will be silently missed.
**Impact**: For prolific users, the scan may miss open PRs/Issues beyond the first page, leading to incomplete review coverage.
**Recommendation**: Either add `--paginate` flag to the gh api call, or add `per_page=100` parameter, or document the limitation explicitly.

### [P2] gh search API rate limiting is stricter than REST API — skill doesn't differentiate

**File**: SKILL.md, Step 1 and "注意事项" section
**Issue**: GitHub's Search API has a separate, stricter rate limit (30 requests/minute for authenticated users) compared to the REST API. The skill mentions rate limiting in the notes section but treats it as a generic skip-and-log scenario. With multiple repos and detailed per-PR/Issue queries, a single scan session could easily exhaust the search rate limit before completing all checks, especially if cron runs frequently.
**Impact**: In practice, frequent cron runs or many open items could cause partial scans without the user being aware of the incompleteness.
**Recommendation**: Add a brief note about search API rate limits being different from REST, and consider implementing a brief delay between API calls in the scan steps, or switching from Search API to listing endpoints (e.g., `gh pr list --author easyfan --state open`) which use the more generous REST rate limit.

### [P1] Using `gh pr view` per-PR is N+1 query pattern — could use batch listing instead

**File**: SKILL.md, Step 1
**Issue**: The scan first searches for all open PRs, then loops through each to call `gh pr view`. This is a classic N+1 query pattern. GitHub's `gh pr list` with `--json` can return all needed fields (state, comments, reviews) in a single call per repository. The current approach makes 1 + N API calls where N = number of open PRs, unnecessarily consuming rate limit quota.
**Impact**: Increased API call count leading to faster rate limit exhaustion and slower scan times. With 10 open PRs across 5 repos, this means ~55 API calls vs. ~6 with batch approach.
**Recommendation**: Use `gh pr list --repo <repo> --author easyfan --state open --json number,title,state,comments,reviews` per repository, or use GraphQL to fetch all data in a single query.

### [P3] No reference to GitHub notification API as complementary signal

**File**: SKILL.md
**Issue**: GitHub provides a Notifications API (`/notifications`) that could supplement the search-based approach by surfacing mentions, review requests, and other activity that the current search query might miss (e.g., PRs where easyfan is a reviewer but not the author).
**Impact**: The skill only tracks PRs/Issues authored by easyfan, missing scenarios where the user is tagged, assigned, or requested for review on others' PRs.
**Recommendation**: Consider adding an optional step to check GitHub notifications for a more complete activity picture.

## Passed Items
- Use of `gh` CLI rather than raw curl/API calls is best practice for auth handling
- Cron scheduling approach aligns with standard automation patterns
- GH_REFERENCE as a state snapshot for diff-based change detection is a solid pattern
- The draft-then-confirm workflow follows safe automation principles (no auto-publishing)
