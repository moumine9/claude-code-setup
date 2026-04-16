# Claude Code — Personal Environment Setup

Backup of all custom agents, commands, skills, plugins, and configurations for this Claude Code environment.
Use this repo to recreate the full setup on a new machine.

---

## Directory Structure

```
claude-code-setup/
├── .claude/
│   └── commands/               → Project-scoped commands (copy to <project>/.claude/commands/)
├── agents/                     → User-level subagents   → ~/.claude/agents/
├── commands/                   → User-level slash commands → ~/.claude/commands/
├── config/
│   └── settings-template.json  → Template for ~/.claude/settings.json
├── hooks/                      → Hook scripts (auto-synced to ~/.claude by auto-sync.sh)
├── skills/                     → Installable skills → ~/.claude/skills/<name>/SKILL.md
├── sync.sh                     → Syncs all skills and commands to ~/.claude/
└── README.md
```

> **Sync system:** `sync.sh` copies every skill directory and command file from this repo into `~/.claude/`. It is triggered automatically via a `PostToolUse` hook on `Write|Edit` whenever any file under `skills/`, `commands/`, or `hooks/` is saved. Run `/sync-claude-setup` manually for a full resync. Uses real symlinks if Windows Developer Mode is enabled, otherwise copies.

---

## Agents

> Custom subagents — specialized AI assistants with their own context window, tools, and system prompts.
> Install to: `~/.claude/agents/`

| File | Name | Color | Model | Description |
|------|------|-------|-------|-------------|
| [agents/code-review-frontend.md](./agents/code-review-frontend.md) | code-reviewer | blue | sonnet | Frontend code review for quality, security, and maintainability |
| [agents/lint.md](./agents/lint.md) | lint | yellow | haiku | Runs `yarn lint --fix` + prettier, fixes issues per eslint/prettier config |
| [agents/cypress-test.md](./agents/cypress-test.md) | cypress-test | green | sonnet | Generates comprehensive Cypress E2E tests, runs them to verify |

### Agent frontmatter reference

Fields used in this repo (from [source code analysis](https://buildingbetter.tech/p/i-read-the-claude-code-source-code)):

| Field | Purpose |
|-------|---------|
| `name` | Agent identifier |
| `description` | What the agent does — used by Claude to decide when to invoke |
| `tools` | Comma-separated list of allowed tools |
| `model` | `haiku`, `sonnet`, or `opus` — overrides the calling model |
| `effort` | `low`, `medium`, `high`, `max` — controls reasoning depth |
| `color` | `red\|orange\|yellow\|green\|blue\|purple\|pink\|gray` — UI color coding |
| `memory` | `user\|project\|local` — persistent memory across invocations |
| `context` | `fork` — run as background forked subagent |
| `omitClaudeMd` | `true` — skip project instruction hierarchy |
| `requiredMcpServers` | MCP server patterns that must be configured |

---

## Commands

> User-level slash commands. Install to `~/.claude/commands/` (available in all projects).
> Project-scoped commands live in `.claude/commands/` (available in that project only).

| File | Trigger | Description |
|------|---------|-------------|
| [commands/commit.md](./commands/commit.md) | `/commit` | Conventional Commits 1.0.0 compliant commit — stages files and commits |
| [commands/list-tasks-frontend.md](./commands/list-tasks-frontend.md) | `/list-tasks-frontend` | Generates French summary of frontend work (Fonctionnalites / Correctifs / Optimisations) |
| [commands/plan-realisation-fe.md](./commands/plan-realisation-fe.md) | `/plan-realisation-fe` | Generates French plan document (Problematique / Solution / Caveat) — fetches Jira ticket context via `acli` |
| [commands/sync-claude-setup.md](./commands/sync-claude-setup.md) | `/sync-claude-setup` | Syncs all skills and commands from `D:/claude-code-setup` to `~/.claude/` |
| [.claude/commands/cypress-test.md](./.claude/commands/cypress-test.md) | `/cypress-test` | Adds meaningful Cypress E2E tests for modified files (project-scoped) |

---

## Skills

> Installable skills. Install to `~/.claude/skills/<skill-name>/SKILL.md`.

| Folder | Trigger | Model | Description |
|--------|---------|-------|-------------|
| [skills/acli-auth/](./skills/acli-auth/SKILL.md) | `/acli-auth` | haiku | Manages Atlassian CLI authentication — login, logout, status, switch accounts |
| [skills/acli-search/](./skills/acli-search/SKILL.md) | `/acli-search` | haiku | Searches Jira work items by JQL; lists projects, boards, filters, dashboards |
| [skills/acli-sprint/](./skills/acli-sprint/SKILL.md) | `/acli-sprint` | haiku | Lists, creates, and updates sprints; shows work items in a sprint |
| [skills/acli-workitem/](./skills/acli-workitem/SKILL.md) | `/acli-workitem` | haiku | Creates, views, edits, transitions, assigns, and comments on Jira issues |
| [skills/create-merge-request/](./skills/create-merge-request/SKILL.md) | `/create-merge-request` | inherit | Creates a GitLab MR using `glab` CLI with the Familiprix French template |
| [skills/humanizer/](./skills/humanizer/SKILL.md) | `/humanizer` | inherit | Removes AI writing patterns from text — fixes inflated language, em dashes, sycophancy, filler, and adds human voice |
| [skills/plan-realisation-fe/](./skills/plan-realisation-fe/SKILL.md) | `/plan-realisation-fe` | inherit | French plan document — Problematique / Solution / Caveat; auto-fetches Jira ticket context via `acli-workitem` |
| [skills/react-doctor/](./skills/react-doctor/SKILL.md) | `/react-doctor` | haiku | Runs `npx react-doctor` to scan React code and output a quality score |
| [skills/update-merge-request/](./skills/update-merge-request/SKILL.md) | `/update-merge-request` | inherit | Syncs the "Travail effectué" section of the current branch's MR with its actual commits — only touches that section |

### Skill frontmatter reference

| Field | Purpose |
|-------|---------|
| `name` | Skill identifier |
| `description` | What the skill does — used for auto-invocation matching |
| `user-invocable` | `true` — allows manual `/skill-name` invocation |
| `disable-model-invocation` | `true` — prevents auto-invocation, requires explicit `/skill-name` |
| `allowed-tools` | List of tools the skill can use |
| `model` | `haiku\|sonnet\|opus` — override which model runs the skill |
| `effort` | `low\|medium\|high\|max` — control reasoning depth |
| `argument-hint` | Placeholder shown in autocomplete (e.g. `"[target-branch]"`) |
| `hooks` | Define hooks active only during skill execution |
| `agent` | Delegate skill to a custom agent |
| `shell` | `bash` — specify execution shell |

> **Cache tip:** Using different `model` values on forked skills breaks prompt cache. Omit the field or use `model: inherit` when cache efficiency matters.

---

## Plugins

> Installed via `/plugin install`. Marketplace must be added first.

### claude-hud

Real-time statusline HUD showing context usage, git status, model, and optional tools/agents/todos.

**Install steps:**
```bash
/plugin marketplace add jarrodwatts/claude-hud
/plugin install claude-hud
/reload-plugins
/claude-hud:setup
```

The `/claude-hud:setup` skill auto-detects platform, runtime (node/bun), and writes `statusLine` to `~/.claude/settings.json`.

---

## MCP Servers

> Model Context Protocol servers extend Claude Code with external tool access.
> Configured via `claude mcp add` — stored in `~/.claude/settings.json` under `mcpServers`.

| Name | Scope | Type | Command / URL | Notes |
|------|-------|------|--------------|-------|
| chrome-devtools | User (all projects) | stdio | `npx chrome-devtools-mcp@latest` | Browser automation — navigate, screenshot, evaluate JS, intercept network |
| figma-desktop | Local (per project) | http | `http://127.0.0.1:3845/mcp` | Auto-configured by Figma desktop app when running — no manual setup needed |
| claude.ai Gmail | Remote | — | `https://gmail.mcp.claude.com/mcp` | Requires re-authentication after install |
| claude.ai Google Calendar | Remote | — | `https://gcal.mcp.claude.com/mcp` | Requires re-authentication after install |

**To reinstall chrome-devtools on a new machine:**
```bash
claude mcp add chrome-devtools -s user -- npx chrome-devtools-mcp@latest
```

**Figma desktop MCP** is added automatically when you open Figma desktop — nothing to do manually.

**Remote MCP servers** (Gmail, Google Calendar) are added via the Claude Code settings UI or:
```bash
claude mcp add-json "claude.ai Gmail" '{"type":"remote","url":"https://gmail.mcp.claude.com/mcp"}' -s user
claude mcp add-json "claude.ai Google Calendar" '{"type":"remote","url":"https://gcal.mcp.claude.com/mcp"}' -s user
```
Then re-authenticate via `/mcp` in a Claude Code session.

---

## Hooks

Hooks live in `D:/claude-code-setup/hooks/` and are wired into `~/.claude/settings.json`.
`~/.claude/hooks/` scripts are thin forwarders that call the D:/ source files so updates are automatic.

### Hook system reference

Hook types available in Claude Code:

| Hook Type | When it fires | Key return fields |
|-----------|--------------|-------------------|
| `SessionStart` | Session begins | `watchPaths`, `initialUserMessage`, `additionalContext` |
| `PreToolUse` | Before a tool runs | `updatedInput`, `permissionDecision`, `permissionDecisionReason`, `additionalContext` |
| `PostToolUse` | After a tool runs | `updatedMCPToolOutput`, `additionalContext` |
| `PermissionRequest` | Permission prompt | `decision`, `updatedInput`, `updatedPermissions` |

Undocumented hook fields:

| Field | Effect |
|-------|--------|
| `once: true` | Fire exactly once, then auto-remove |
| `async: true` | Run in background without blocking |
| `asyncRewake: true` | Non-blocking normally, blocks if exit code 2 |

### auto-sync.sh

**Trigger:** `PostToolUse` on `Write | Edit`

**What it does:**
- Reads the tool input JSON from stdin and extracts `file_path`
- Normalizes Windows-style paths (`D:\...` → `/d/...`)
- Fires only when the edited file is under `D:/claude-code-setup/skills/`, `commands/`, or `hooks/`
- Runs `sync.sh` to push the change to `~/.claude/` immediately
- Returns the sync output as `additionalContext` so Claude sees what was synced

**Registered in:** `~/.claude/settings.json` → `hooks.PostToolUse`

---

### session-context.sh (NEW)

**Trigger:** `SessionStart`

**What it does:**
- Injects current git branch, uncommitted changes count, and recent commits as `additionalContext`
- Returns `watchPaths` for config files (`package.json`, `tsconfig.json`, `.eslintrc.*`, etc.) so Claude gets `FileChanged` events when they're modified

### protect-sensitive-files.sh

**Trigger:** `PreToolUse` on `Read | Edit | Write`

**Blocks access to:**

| Category | Examples |
|----------|---------|
| `.env` files | `.env`, `.env.production`, `.env.local`, `.env.staging`, `.env.test`, ... |
| Deployment configs | Any path containing `/deployments/` |
| Secret stores | `/secrets/`, `/.secrets/`, `/.aws/`, `/.ssh/`, `/.gnupg/`, `/vault/` |
| Credential files | `credentials.json`, `service-account*.json`, `.npmrc`, `.netrc`, `.htpasswd` |
| Keys & certificates | `*.pem`, `*.key`, `*.p12`, `*.pfx`, `*.jks`, `id_rsa*`, `id_ed25519*`, ... |
| Infrastructure secrets | `kubeconfig*`, `vault-token`, `terraform.tfvars`, `terraform.tfvars.json` |

**To allow a specific path** (override for a project), add to `<project>/.claude/settings.local.json`:
```json
{ "permissions": { "allow": ["Read(./.env.local)"] } }
```

### dry-run-guard.sh (NEW)

**Trigger:** `PreToolUse` on `Bash`

**What it does:**
- Intercepts destructive git commands (`git push --force`, `git reset --hard`, `git clean -f`)
- For `git push`: rewrites the command to add `--dry-run` via `updatedInput`, so Claude sees what would happen first
- For `reset --hard` / `clean -f`: injects `additionalContext` telling Claude to ask the user before proceeding
- Non-destructive commands pass through unchanged

### auto-update-mr-on-commit.sh

**Trigger:** `PostToolUse` on `Bash`

**What it does:**
- Detects when a `git commit` was just executed
- Checks if an open MR exists for the current branch via `glab mr view`
- If yes, injects `additionalContext` prompting Claude to run `/update-merge-request` to sync the "Travail effectué" section
- Fails silently (no output, exit 0) when not a commit, no repo, no open MR, or glab unavailable

### Setup on a new machine

```bash
mkdir -p ~/.claude/hooks

# Option A — forwarders (keeps D:/claude-code-setup as source of truth)
for hook in protect-sensitive-files.sh session-context.sh dry-run-guard.sh auto-update-mr-on-commit.sh; do
  cat > ~/.claude/hooks/$hook << EOF
#!/usr/bin/env bash
exec /d/claude-code-setup/hooks/$hook
EOF
  chmod +x ~/.claude/hooks/$hook
done

# Option B — standalone copies (no D: dependency)
cp /d/claude-code-setup/hooks/*.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh
```

Then merge the hooks section from `config/settings-template.json` into `~/.claude/settings.json`.

---

## Settings

### Template

See [config/settings-template.json](./config/settings-template.json) for a reference template.

### Key settings explained

#### `permissions.allow` — auto-approved operations
Patterns that Claude can execute without asking. Uses glob syntax:
- `Bash(git checkout:*)` — any git checkout command
- `Read(src/**)` — read anything under src/
- `WebFetch(domain:usehooks-ts.com)` — fetch from specific domains
- `mcp__slack__post_message` — specific MCP tool access

#### `permissions.soft_deny` — confirmation required
Operations that require user confirmation before executing. Claude will ask before running these:
- `Bash(git push --force:*)` — force pushes
- `Bash(git reset --hard:*)` — hard resets
- `Bash(rm -rf:*)` — recursive deletes
- `Write(.env*)` — writing to env files

#### `permissions.environment` — classifier context
Plain English descriptions that help Claude's auto-mode permission classifier make better decisions:
```json
"environment": [
  "This is a frontend development environment using React, TypeScript, and Yarn",
  "GitLab is used for version control — use glab CLI for MR operations",
  "Sensitive files (.env, credentials, keys) must never be read or committed"
]
```

#### `autoMemoryEnabled` — learning loop
When `true`, Claude automatically extracts durable memories from sessions. Combined with `autoDreamEnabled: true`, it runs background consolidation every 24 hours after 5+ sessions.

#### `alwaysThinkingEnabled` + `effortLevel`

```json
"alwaysThinkingEnabled": true,
"effortLevel": "high"
```

Enables extended thinking and sets reasoning effort to high on every request.

### Manual configuration steps performed on this machine

#### 1. `statusLine` — claude-hud

Generated by running `/claude-hud:setup` after installing the plugin. The command is platform/runtime specific — re-run the skill on the new machine rather than copy-pasting this value.

#### 2. Permissions allow-list

Key entries added over time (in `~/.claude/settings.json`):
```json
"permissions": {
  "allow": [
    "Bash(git checkout:*)",
    "Bash(git remote:*)",
    "Bash(git push:*)",
    "Bash(glab --version)",
    "Read(/Users/<username>/**)",
    "WebFetch(domain:usehooks-ts.com)"
  ]
}
```

#### 3. `additionalDirectories`

Points to any project-local skill directories you want Claude to load automatically:
```json
"additionalDirectories": [
  "c:\\repos\\<project>\\frontend\\.claude\\skills"
]
```

Update to match the project path on the new machine.

#### 4. Project-level settings (`<project>/.claude/settings.local.json`)

For projects using `glab` (GitLab), add these permissions:
```json
{
  "permissions": {
    "allow": [
      "Bash(glab --version)",
      "Bash(glab mr:*)",
      "Bash(git reset:*)",
      "Bash(git cherry-pick:*)",
      "Bash(git push:*)",
      "Bash(git fetch:*)",
      "Bash(git checkout:*)",
      "Bash(git apply:*)",
      "Bash(git commit:*)"
    ]
  }
}
```

---

## Prerequisites (new machine checklist)

### Tools
- [ ] [Claude Code CLI](https://claude.ai/code) installed
- [ ] [Node.js LTS](https://nodejs.org/) installed (required for claude-hud statusline)
- [ ] [`glab` CLI](https://gitlab.com/gitlab-org/cli) installed (required for `/create-merge-request`)
- [ ] [`acli` CLI](https://developer.atlassian.com/cloud/acli/) installed (required for acli-* skills and `/plan-realisation-fe`)
- [ ] [Figma desktop](https://www.figma.com/downloads/) installed (auto-configures figma-desktop MCP when open)

### Files to copy

**Skills, commands, and hooks — run the sync script:**

```bash
# Bootstrap: copy sync-claude-setup command manually (one-time only)
cp /d/claude-code-setup/commands/sync-claude-setup.md ~/.claude/commands/sync-claude-setup.md

# Then run the full sync
bash /d/claude-code-setup/sync.sh
```

After that, `/sync-claude-setup` keeps everything in sync. On subsequent runs just use the command.

**Remaining manual steps:**
- [ ] Merge `config/settings-template.json` into `~/.claude/settings.json` (hooks, permissions, plugins)
- [ ] Copy `agents/` → `~/.claude/agents/` (agents are not managed by sync.sh)

### Manual setup
- [ ] Authenticate acli: `acli jira auth login --web`
- [ ] Install claude-hud plugin and run `/claude-hud:setup`
- [ ] Set `alwaysThinkingEnabled: true` and `effortLevel: "high"` in `~/.claude/settings.json`
- [ ] Add chrome-devtools MCP: `claude mcp add chrome-devtools -s user -- npx chrome-devtools-mcp@latest`
- [ ] Add remote MCP servers (Gmail, Google Calendar) and authenticate via `/mcp`
- [ ] Add project-level `settings.local.json` for any projects using `glab`
- [ ] Enable Windows Developer Mode for real symlinks (optional — sync.sh falls back to copies)

---

## References

- [Claude Code Source Analysis](https://buildingbetter.tech/p/i-read-the-claude-code-source-code) — undocumented features reference
- [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
- [Claude Code Docs](https://docs.anthropic.com/en/docs/claude-code)
- [claude-hud plugin](https://github.com/jarrodwatts/claude-hud)
- [glab CLI](https://gitlab.com/gitlab-org/cli)
