---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*)
description: Create a git commit message
---

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## Your task
Generate a commit message following Conventional Commits 1.0.0 specification for the staged changes in this repository. 

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
3. Keep subject line under 50 characters
4. Scope is optional and describes code section, e.g., feat(parser):
5. Body is optional, starts after blank line, provides context
6. Footer is optional for metadata like 'Refs: #123' or 'Reviewed-by: Name'

BREAKING CHANGES:
- Add ! after type/scope for breaking changes: feat!: or feat(api)!:
- OR add footer: BREAKING CHANGE: description of the breaking change
- Breaking changes correlate with MAJOR in semantic versioning

EXAMPLES:
feat(auth): add OAuth2 login support

fix: prevent race condition in request handling

docs: correct spelling in README

feat!: drop support for Node 14

BREAKING CHANGE: Node 14 is no longer supported

refactor(api): simplify error handling logic

Now analyze 'git diff --cached' and generate an appropriate commit message following these exact specifications. Output ONLY the commit message."