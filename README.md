# Claude Code — Personal Environment Setup

Backup of all custom agents, commands, skills, plugins, and configurations for this Claude Code environment.
Use this repo to recreate the full setup on a new machine.

---

## Directory Structure

```
claude-code-setup/
├── .claude/
│   └── commands/               → Project-scoped commands (currently empty)
├── agents/                     → User-level subagents   → ~/.claude/agents/
├── commands/                   → User-level slash commands → ~/.claude/commands/
├── config/
│   └── settings-template.json  → Template for ~/.claude/settings.json
├── hooks/                      → Hook scripts (auto-synced to ~/.claude by auto-sync.sh)
├── scripts/                    → Helper scripts invoked by commands
├── skills/                     → Installable skills → ~/.claude/skills/<name>/SKILL.md
├── sync.sh                     → Syncs all skills and commands to ~/.claude/
└── README.md
```

> **Sync system:** `sync.sh` copies every skill directory and command file from this repo into `~/.claude/`. It does **not** copy `hooks/` — hook scripts must be placed in `~/.claude/hooks/` manually on a new machine, before the `settings.json` hook entries that reference them will work. It is triggered automatically via a `PostToolUse` hook on `Write|Edit` whenever any file under `skills/`, `commands/`, or `hooks/` is saved. Run `/sync-claude-setup` manually for a full resync. Uses real symlinks if Windows Developer Mode is enabled, otherwise copies.

> **Pruning:** `sync.sh` writes `~/.claude/.claude-code-setup-manifest` listing everything it installed. On the next run, anything in the previous manifest that no longer exists in this repo is deleted from `~/.claude`. Pruning is driven strictly by that manifest, so skills and commands installed from plugins or by hand are never touched — delete a skill here and the next sync removes it there too.
>
> **First run:** the manifest is created by the first sync that has this feature, and the prune step is
> skipped on that run (there is no previous manifest to compare against). Anything deleted from the repo
> *before* the manifest existed is therefore never pruned automatically — on a machine restoring this setup,
> remove those leftovers from `~/.claude/skills` and `~/.claude/commands` by hand once. From the second run
> onward, deleting here removes it there.
>
> Because pruning deletes, it refuses to run whenever it cannot trust its own input. `sync.sh` aborts before touching anything if `skills/` or `commands/` is missing (the source drive is not mounted), and it skips the prune step — leaving the old manifest in place — if nothing synced or if any item failed. Without those guards, running the script with `D:` unmounted would see an empty source, conclude every skill had been deleted, and wipe the lot.

---

## Agents

> Custom subagents — specialized AI assistants with their own context window, tools, and system prompts.
> Install to: `~/.claude/agents/`

| File | Name | Color | Model | Description |
|------|------|-------|-------|-------------|
| [agents/code-review-frontend.md](./agents/code-review-frontend.md) | code-reviewer | blue | sonnet | Frontend code review for quality, security, and maintainability |
| [agents/update-merge-request.md](./agents/update-merge-request.md) | update-merge-request | blue | haiku | Syncs the MR's "Travail effectué" section with its commits — fired automatically after a commit |

### Agent frontmatter reference

Fields used in this repo (from [source code analysis](https://buildingbetter.tech/p/i-read-the-claude-code-source-code)):

| Field | Purpose |
|-------|---------|
| `name` | Agent identifier |
| `description` | What the agent does — used by Claude to decide when to invoke |
| `tools` | Comma-separated list of allowed tools |
| `model` | `haiku`, `sonnet`, or `opus` — overrides the calling model |
| `effort` | `low`, `medium`, `high`, `xhigh`, `max` — controls reasoning depth |
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
| [commands/opus.md](./commands/opus.md) | `/opus [effort]` | Switches the model to Opus. Effort defaults to `medium` |
| [commands/sonnet.md](./commands/sonnet.md) | `/sonnet [effort]` | Switches the model to Sonnet. Effort defaults to `medium` |
| [commands/haiku.md](./commands/haiku.md) | `/haiku [effort]` | Switches the model to Haiku. Effort defaults to `medium` |
| [commands/gitlab-inline-comments.md](./commands/gitlab-inline-comments.md) | `/gitlab-inline-comments` | Reference for posting inline diff comments on GitLab MRs via `glab` |
| [commands/plan-realisation-fe.md](./commands/plan-realisation-fe.md) | `/plan-realisation-fe` | Generates French plan document (Problématique / Solution / Caveat) — fetches Jira ticket context via the `acli-skills` plugin |
| [commands/plugin-usage.md](./commands/plugin-usage.md) | `/plugin-usage` | Reports plugin, command, and skill usage statistics — used to decide what to prune |
| [commands/sync-claude-setup.md](./commands/sync-claude-setup.md) | `/sync-claude-setup` | Syncs all skills and commands from `D:/claude-code-setup` to `~/.claude/` |

### Model-switch commands

`/opus`, `/sonnet`, and `/haiku` all delegate to [scripts/set-model.sh](./scripts/set-model.sh), which writes
`model` and `effortLevel` into `~/.claude/settings.json` — the same store the built-in `/model` and `/effort`
commands persist to.

```bash
/sonnet          # model → sonnet, effort → medium (the default)
/sonnet high     # model → sonnet, effort → high
/haiku low       # model → haiku,  effort → low
```

| | Accepted values |
|---|---|
| Model | `opus`, `sonnet`, `haiku`, `fable` |
| Effort | `low`, `medium`, `high`, `xhigh`, `max` |

`auto` is deliberately not accepted — it is a directive the built-in `/effort` command understands, not a value
that belongs in `effortLevel`. Use `/effort auto` for that.

Both arguments are validated against those lists — an unrecognized value exits non-zero and writes nothing,
rather than putting arbitrary text into `settings.json`. Only the first whitespace-separated token of the
argument is read, so trailing prose is ignored. The script backs up to `settings.json.bak-set-model` and
swaps the new file in atomically.

> **Scope:** this sets the model for **new** sessions. To switch the session you are currently in, use the
> built-in `/model <name>`. The script prints this reminder after every run.

### `/plugin-usage`

Wraps [scripts/plugin-usage.sh](./scripts/plugin-usage.sh). Claude Code records usage in three places, and no
single one answers every question — the command prints all of them.

| Source | What it records | Blind spot |
|--------|-----------------|------------|
| `~/.claude.json` -> `pluginUsage` | Per-plugin activation counts and last-used date | Per plugin, not per skill — cannot say which skill inside a plugin earned the count |
| `~/.claude/history.jsonl` | Every prompt you typed, so every `/command` you ran | Misses skills the model invoked on its own |
| `projects/**/*.jsonl` | `Skill` tool invocations | Slower; needs the right pattern (see below) |
| `~/.claude/stats-cache.json` | Daily message/session/tool volume | Volume only, no attribution |

```bash
/plugin-usage                 # last 30 days, top 25, all sources
/plugin-usage --days 90       # widen the history window
/plugin-usage --no-skills     # skip the transcript scan
```

**Two traps worth knowing**, both of which produce confident and wrong answers:

1. **Do not count skill names in transcripts.** Every session's system prompt lists all available skills, so
   grepping for a name scores every skill identically — during the 2026-08-17 cleanup this returned a flat
   `102` for all of them. Count `"skill":"<name>"` invocations instead, as the script does.
2. **`pluginUsage` counters do not survive a rename.** A repackaged plugin restarts at zero under its new
   name, so `glab@inline` (228) and `glab-skills@inline` are the same tool before and after — the real total
   is the sum. Reading either alone understates it by roughly half.

Neither trap is theoretical: the first nearly deleted skills in daily use, the second nearly flagged the most
used plugin in this setup as a removal candidate.

---

## Skills

> Installable skills. Install to `~/.claude/skills/<skill-name>/SKILL.md`.

| Folder | Trigger | Model | Description |
|--------|---------|-------|-------------|
| [skills/create-merge-request/](./skills/create-merge-request/SKILL.md) | `/create-merge-request` | inherit | Creates a GitLab MR using `glab` CLI with the Familiprix French template |
| [skills/humanizer/](./skills/humanizer/SKILL.md) | `/humanizer` | inherit | Removes AI writing patterns from text — fixes inflated language, em dashes, sycophancy, filler, and adds human voice |
| [skills/plan-realisation-fe/](./skills/plan-realisation-fe/SKILL.md) | `/plan-realisation-fe` | inherit | French plan document — Problématique / Solution / Caveat; auto-fetches Jira ticket context via the `acli-skills` plugin |
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

### Currently installed

Usage counts below come from `pluginUsage` in `~/.claude.json`, as of 2026-08-17.

| Plugin | Marketplace | Enabled | Uses | Purpose |
|--------|-------------|---------|------|---------|
| `glab-skills` | [moumine9/glab-skills](https://github.com/moumine9/glab-skills) | yes | 178 | GitLab via `glab` — `/glab:mr`, `/glab:issue`, `/glab:ci`, `/glab:auth` |
| `acli-skills` | inline | yes | 163 | Jira via `acli` — replaced the local `acli-*` skills that used to live in this repo |
| `figma` | `claude-plugins-official` | yes | 11 | Figma MCP — design-to-code, Code Connect, FigJam diagrams |
| `claude-hud` | [jarrodwatts/claude-hud](https://github.com/jarrodwatts/claude-hud) | yes | 2 | Statusline HUD — context usage, git status, model |
| `frontend-design` | `claude-plugins-official` | yes | 1 | Visual design guidance for new UI work |
| `buddy` | [rsts-dev/claude-buddy-marketplace](https://github.com/rsts-dev/claude-buddy-marketplace) | **no** | 0 | Spec/plan/tasks workflow + personas. Disabled — never used, and its ~20 skills crowded the skill list |
| `typescript-lsp` | `claude-plugins-official` | **no** | 0 | TypeScript language server. Disabled — never used |

Enable/disable state lives in `enabledPlugins` in `~/.claude/settings.json`. The two disabled plugins are still
installed on disk; flip them back to `true` there to bring them back.

### Disabled but still installed

`buddy` and `typescript-lsp` are set to `false` in `enabledPlugins` rather than uninstalled. Disabling already
achieves the point — buddy's ~20 skills no longer crowd the skill list — and the whole plugin cache is only
16 MB, so removing them from disk would reclaim ~4 MB while making a reinstall harder. Flip either back to
`true` in `~/.claude/settings.json` to restore it; no re-download needed.

Note that most of that cache is stale versions rather than active plugins: `figma` alone keeps six cached
releases at ~2 MB each. Clearing old versions is a separate housekeeping job from disabling a plugin.

### Marketplaces added without installs

`karpathy-skills` ([forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills))
is registered in `extraKnownMarketplaces` but has nothing installed from it.

### claude-hud setup

```bash
/plugin marketplace add jarrodwatts/claude-hud
/plugin install claude-hud
/reload-plugins
/claude-hud:setup
```

The `/claude-hud:setup` skill auto-detects platform, runtime (node/bun), and writes `statusLine` to `~/.claude/settings.json`.

---

## Retired

Removed on 2026-08-17/18 after a usage audit (`/plugin-usage`). Everything here is recoverable with
`git show <commit>:<path>`; nothing was deleted that is not in git history.

| Item | Kind | Uses | Idle at removal | Reason |
|------|------|-----:|-----------------|--------|
| `acli-auth`, `acli-search`, `acli-sprint`, `acli-workitem` | skills | 21 combined | 81 days | Superseded by the `acli-skills` plugin (171 uses, active) |
| `react-doctor` | skill | 12 | 89 days | Never model-invoked; stopped being used by hand |
| `list-tasks-frontend` | command | 13 | 160 days | Superseded in practice by `/plan-realisation-fe` |
| `lint` | agent | 21 | 152 days | Linting moved into hooks/CI |
| `cypress-test` | agent + project command | 2 | 304 days | Never adopted |

**Method note.** Raw invocation totals are not sufficient on their own — `react-doctor` (12) and
`list-tasks-frontend` (13) both looked healthy on volume and were kept in a first pass, then removed once
recency was checked. Idle time is the better signal. Conversely a low count is not proof of disuse:
`humanizer` shows only 4 typed invocations but 16 model-invoked ones, and `gitlab-inline-comments` had zero
because it had only just shipped. Run `/plugin-usage` and check the last-used column before removing anything.

The `lint-and-validate` skill in `~/.claude/skills` is also long idle, but it is not managed by this repo,
so it was left alone.

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

#### `model` + `alwaysThinkingEnabled` + `effortLevel`

```json
"model": "opus",
"alwaysThinkingEnabled": true,
"effortLevel": "medium"
```

`alwaysThinkingEnabled` turns on extended thinking; `effortLevel` sets how much reasoning effort each request
gets (`low`, `medium`, `high`, `xhigh`, `max`).

`model` and `effortLevel` are the two keys the built-in `/model` and `/effort` commands write to, and the same
two the `/opus`, `/sonnet`, and `/haiku` commands in this repo set — see
[Model-switch commands](#model-switch-commands). Editing them here by hand is equivalent; it just takes effect
on the next session rather than immediately.

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
- [ ] [`acli` CLI](https://developer.atlassian.com/cloud/acli/) installed (required for the `acli-skills` plugin and `/plan-realisation-fe`)
- [ ] [Figma desktop](https://www.figma.com/downloads/) installed (auto-configures figma-desktop MCP when open)
- [ ] `python` on PATH (required by `scripts/set-model.sh` and `scripts/plugin-usage.sh`)

### Files to copy

**Skills and commands — run the sync script:**

```bash
# Bootstrap: copy sync-claude-setup command manually (one-time only)
cp /d/claude-code-setup/commands/sync-claude-setup.md ~/.claude/commands/sync-claude-setup.md

# Then run the full sync
bash /d/claude-code-setup/sync.sh
```

After that, `/sync-claude-setup` keeps everything in sync. On subsequent runs just use the command.

**Remaining manual steps** — `sync.sh` handles only `skills/` and `commands/`; everything below is on you:

- [ ] Merge `config/settings-template.json` into `~/.claude/settings.json` (hooks, permissions, plugins)
- [ ] Copy `agents/` → `~/.claude/agents/` (agents are not managed by sync.sh)
- [ ] Copy `hooks/` → `~/.claude/hooks/` (also not managed by sync.sh):
```bash
mkdir -p ~/.claude/hooks && cp /d/claude-code-setup/hooks/*.sh ~/.claude/hooks/
```
  The `settings.json` hook entries reference `${CLAUDE_CONFIG_DIR}/hooks/...` and fail silently if the
  scripts are missing. The one exception is the `Write|Edit` auto-sync entry, which points straight at
  `/d/claude-code-setup/hooks/auto-sync.sh` so it always runs the current version from the repo.

### Manual setup
- [ ] Authenticate acli: `acli jira auth login --web`
- [ ] Authenticate glab: `glab auth login`
- [ ] Install the plugins in active use:
```bash
/plugin marketplace add jarrodwatts/claude-hud
/plugin marketplace add moumine9/glab-skills
/plugin install claude-hud
/plugin install glab-skills
/plugin install figma@claude-plugins-official
/plugin install frontend-design@claude-plugins-official
/reload-plugins
```
- [ ] Run `/claude-hud:setup` to generate the `statusLine` value for this machine
- [ ] Install the `acli-skills` plugin for Jira (it replaced the local `acli-*` skills)
- [ ] Set `alwaysThinkingEnabled: true` and `effortLevel: "medium"` in `~/.claude/settings.json`
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
