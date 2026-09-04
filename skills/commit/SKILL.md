---
name: commit
description: Create a Conventional Commits compliant git commit scoped to the Jira work item (PV2-XXXXX, inferred from the branch name). Use whenever the user asks to commit, save, or check in changes — "commit this", "commit my changes", "make a commit", "commit and push" — or when a task ends with changes that the user asked to be committed.
user-invocable: true
argument-hint: "[PV2-XXXXX]"
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git commit:*)
---

## Task

Generate a commit message following the Conventional Commits 1.0.0 specification, then stage the relevant files and create the commit.

## Steps

### 1. Gather context

Run these first (in parallel):

- `git status`
- `git diff HEAD` — if this fails, there are no commits yet; everything is untracked and `git status` plus the file contents are the source of truth
- `git branch --show-current`
- `git log --oneline -10`

If there are no commits yet, this is the repository's first commit: base the message on `git status` and the actual file contents instead of a diff. That is normal — proceed as usual (typically `feat: ...` or `chore: initial commit ...`).

### 2. Resolve the Jira work item

Every commit carries a Jira work item number in the form `PV2-XXXXX`. Find it in this order:

1. **Provided by the user** — if `$ARGUMENTS` or the request names a ticket (e.g. `PV2-12493`), use it. An explicit ticket always wins over the branch.
2. **Inferred from the branch name** — the ticket is the branch prefix: `PV2-12493-fix-panier-stepper` → `PV2-12493`. Match case-insensitively on `PV2-\d+` anywhere in the branch name and normalize to uppercase.
3. **Neither** — **stop and ask the user for the ticket number before committing.** Do not guess one, do not reuse a ticket from `git log`, and do not commit without one. If the user answers that there is no ticket for this repo (a personal repo, or one with no Jira at all), commit without it and skip the scope rule below.

### 3. Write the message

STRUCTURE:

```
<type>(PV2-XXXXX: area): <description>

[optional body]

[optional footer(s)]
```

The scope holds the Jira work item resolved in step 2, then a colon, a space, and the affected code area:

```
feat(PV2-12493: panier): add quantity stepper to cart rows
fix(PV2-12510: checkout): stop the total from going negative
```

- Separator is exactly `: ` — colon then one space. Not a comma, not a slash, not a dash.
- The area is a short lowercase noun for the part of the codebase touched (`panier`, `checkout`, `auth`), the same way a plain Conventional Commits scope reads. Pick one; if the change genuinely spans several, that is usually a sign it should be more than one commit.
- If no single area fits, drop the area and the separator: `feat(PV2-12493): …`.
- If the user confirmed the repo has no Jira, drop the ticket instead and use the plain area scope: `feat(panier): …`.

TYPES (REQUIRED):

- `feat`: new feature (MINOR in semver)
- `fix`: bug fix (PATCH in semver)
- `docs`: documentation only changes
- `style`: formatting, missing semicolons, etc. (no code change)
- `refactor`: neither fixes a bug nor adds a feature
- `perf`: performance improvement
- `test`: adding or correcting tests
- `build`: build system or external dependencies
- `ci`: CI configuration files and scripts
- `chore`: other changes that don't modify src or test files
- `revert`: reverts a previous commit

RULES:

1. Description MUST be in imperative mood ("add", not "added" or "adds")
2. No period at end of the description
3. Keep the subject line under 72 characters
4. Scope is `PV2-XXXXX: area` — the Jira work item from step 2, then the affected code area. Omit the ticket only in a repo the user confirmed has no Jira
5. Body is optional, starts after a blank line, explains WHY not WHAT
6. Footer is optional, for metadata like `Refs: #123`
7. No Copilot or Claude Code signature in commit messages
8. Create multiple commits if needed to separate concerns — each one still carries the ticket scope
9. No `Co-authored-by` trailer of any kind (Copilot, Claude, or other AI tools)

BREAKING CHANGES:

- Add `!` after the scope: `feat(PV2-12493: panier)!:`
- OR add a footer: `BREAKING CHANGE: description`
- Breaking changes correlate with MAJOR in semver

### 4. Commit

Stage the relevant modified files and create the commit in a single step. Do not include `.claude/settings.local.json` unless it is the only change. Do not send any other text or explanation.
