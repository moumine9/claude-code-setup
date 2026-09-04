---
name: commit
description: Create a Conventional Commits compliant git commit. Use whenever the user asks to commit, save, or check in changes — "commit this", "commit my changes", "make a commit", "commit and push" — or when a task ends with changes that the user asked to be committed.
user-invocable: true
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

### 2. Write the message

STRUCTURE:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

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
4. Scope is optional and names the affected area, e.g. `feat(parser):`
5. Body is optional, starts after a blank line, explains WHY not WHAT
6. Footer is optional, for metadata like `Refs: #123`
7. No Copilot or Claude Code signature in commit messages
8. Create multiple commits if needed to separate concerns
9. No `Co-authored-by` trailer of any kind (Copilot, Claude, or other AI tools)

BREAKING CHANGES:

- Add `!` after type/scope: `feat!:` or `feat(api)!:`
- OR add a footer: `BREAKING CHANGE: description`
- Breaking changes correlate with MAJOR in semver

### 3. Commit

Stage the relevant modified files and create the commit in a single step. Do not include `.claude/settings.local.json` unless it is the only change. Do not send any other text or explanation.
