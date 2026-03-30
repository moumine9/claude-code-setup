---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git commit:*)
description: Create a Conventional Commits compliant git commit
---

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## Your task

Generate a commit message following the Conventional Commits 1.0.0 specification for the staged changes in this repository. Then stage all modified files and create the commit.

STRUCTURE:
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]

TYPES (REQUIRED):
- feat: new feature (correlates with MINOR in semantic versioning)
- fix: bug fix (correlates with PATCH in semantic versioning)
- docs: documentation only changes
- style: formatting, missing semi colons, etc (no code change)
- refactor: code change that neither fixes a bug nor adds a feature
- perf: code change that improves performance
- test: adding or correcting tests
- build: changes to build system or external dependencies
- ci: changes to CI configuration files and scripts
- chore: other changes that don't modify src or test files
- revert: reverts a previous commit

RULES:
1. Description MUST be in imperative mood (e.g., 'add' not 'added' or 'adds')
2. No period at end of description
3. Keep subject line under 72 characters
4. Scope is optional and describes the code section affected, e.g., feat(parser):
5. Body is optional, starts after blank line, provides context on WHY not WHAT
6. Footer is optional for metadata like 'Refs: #123'
7. Do not include Copilot signature or Claude Code signature in commit messages
8. Create multiple commits if needed to separate concerns.
9. No Co-authored-by trailer of any kind (Copilot, Claude, or other AI tools)

BREAKING CHANGES:
- Add ! after type/scope: feat!: or feat(api)!:
- OR add footer: BREAKING CHANGE: description
- Breaking changes correlate with MAJOR in semantic versioning

Do not include `.claude/settings.local.json` in the commit unless it is the only change.

Stage all relevant modified files and create the commit in a single step. Do not send any other text or explanation.