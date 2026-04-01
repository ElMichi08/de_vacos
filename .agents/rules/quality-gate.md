# Quality Gate Rule

## Purpose

This rule defines a procedural quality gate that the PM (Project Manager) must follow before any commit/push. It aggregates checks from multiple existing skills to ensure code quality, testing, security, and design standards are met. This is a **warning** gate (not blocking) but includes escalation steps for failures.

## When to Invoke

- **After Developer sub-agent** completes implementation (before QA)
- **Before commit/push** (final PM review)
- **After QA sub-agent** reports (optional re-check)
- **Before deployment** (production readiness)

## Checklist

### 1. Static Analysis

**Command:** `flutter analyze`

**Expected outcome:** 0 issues (no errors, no warnings)

**Reference skill:** `flutter-dart-code-review` (Section 15: Static Analysis)

**Action if fails:**
- Log issue in Engram (`mem_save` with type "bugfix")
- Notify Developer sub-agent to fix analyzer issues
- Do not proceed until resolved

### 2. Testing

**Command:** `flutter test`

**Expected outcome:** All tests pass (0 failures)

**Reference skill:** `flutter-testing-apps` (Core Testing Strategies)

**Action if fails:**
- Identify failing tests
- Notify Developer sub-agent to fix tests
- If test failure indicates regression, log issue and escalate

### 3. Security Review

**Check:** Run security-review skill on changed files

**Command:** Load `security-review` skill and execute review

**Expected outcome:** No HIGH confidence vulnerabilities

**Reference skill:** `security-review` (Security Review Process)

**Action if fails:**
- If Critical/High severity found: block commit, require fix
- If Medium/Low: log warning, proceed with note

### 4. Code Quality Review

**Check:** Apply `flutter-dart-code-review` checklist to changed files

**Reference skill:** `flutter-dart-code-review` (Full checklist)

**Key items:**
- No business logic in widgets
- Proper separation of concerns
- No `print()` statements in production
- Const constructors used where possible
- State management follows project patterns

**Action if fails:**
- Log suggestions in Engram
- Notify Developer for improvements (non-blocking)

### 5. Design Principles

**Check:** Apply `flutter-clean-solid-dry` principles

**Reference skill:** `flutter-clean-solid-dry` (DRY, SOLID, Clean Code)

**Key items:**
- No duplication (DRY)
- Single Responsibility Principle
- Proper abstraction

**Action if fails:**
- Suggest refactoring in code review
- Log tech debt if accepted

### 6. Documentation

**Check:** Ensure relevant documentation updated (if applicable)

**Reference skill:** `code-documenter`

**Key items:**
- README updated if public API changed
- Architecture docs updated if structure changed
- Code comments added for complex logic

**Action if fails:**
- Log documentation debt
- Schedule doc update

### 7. Commit Message

**Check:** Ensure conventional commit format

**Reference skill:** `git-commit`

**Expected:** Type, scope, description following Conventional Commits

**Action if fails:**
- PM generates appropriate commit message using `git-commit` skill

## Commands Summary

| Check | Command | Threshold | Reference Skill |
|-------|---------|-----------|-----------------|
| Static Analysis | `flutter analyze` | 0 issues | `flutter-dart-code-review` |
| Testing | `flutter test` | 0 failures | `flutter-testing-apps` |
| Security | Load skill + review | No HIGH vulns | `security-review` |
| Code Quality | Manual checklist | Pass | `flutter-dart-code-review` |
| Design | Manual checklist | Pass | `flutter-clean-solid-dry` |
| Documentation | Manual check | Updated | `code-documenter` |
| Commit Message | Conventional format | Valid | `git-commit` |

## Escalation Steps

### If Static Analysis or Testing fails:

1. **Immediate:** Log failure in Engram with details
2. **Notify:** Use `Question tool` to ask Developer to fix
3. **Block:** Do not proceed to commit until resolved
4. **Retry:** After fix, re-run checks

### If Security vulnerabilities found:

1. **Critical/High:** Block commit, require immediate fix
2. **Medium/Low:** Log warning, proceed with note in commit message
3. **Document:** Add security review results to commit footer

### If Code Quality or Design issues found:

1. **Log:** Create Engram observation with improvement suggestions
2. **Notify:** Inform Developer for future improvement
3. **Proceed:** Non-blocking, but track tech debt

### If Documentation missing:

1. **Log:** Create documentation debt issue
2. **Schedule:** Plan doc update in next iteration
3. **Proceed:** Unless critical docs missing

## Integration with Pipeline

### After Developer Sub-agent:

1. Developer returns code + unit tests
2. PM runs quality gate checklist
3. If passes: proceed to QA
4. If fails: return to Developer with specific issues

### Before Commit/Push:

1. PM runs final quality gate
2. Generate conventional commit message
3. If all checks pass: commit and push
4. If fails: log issues, do not commit

### After QA Sub-agent:

1. QA returns test report
2. PM re-runs testing check
3. If new failures: return to Developer
4. If all green: proceed to commit

## Output Contract for PM

When PM runs quality gate, produce:

```
## Quality Gate Report

### Checks Run
- [x] Static Analysis: 0 issues
- [x] Testing: 42 passed, 0 failed
- [x] Security: No HIGH vulnerabilities
- [ ] Code Quality: 2 suggestions (non-blocking)
- [x] Design: Pass
- [x] Documentation: Updated
- [x] Commit Message: feat(order): add payment validation

### Verdict: PASS / WARNINGS / BLOCK

### Issues Found
- [List any issues]

### Actions Taken
- [List actions taken]

### Next Steps
- [Proceed to commit / Return to Developer / etc.]
```

## Notes

- This gate is **warning** not blocking for non-critical issues
- Critical issues (analyzer errors, test failures, security vulns) are blocking
- **Pre-commit hook:** A blocking hook is configured (`.git/hooks/pre-commit`) that runs `flutter analyze --no-pub` and `flutter test --no-pub`. It will prevent commits if either check fails. To bypass temporarily, use `git commit --no-verify`.
- PM should use discretion for edge cases
- All decisions logged in Engram for audit trail