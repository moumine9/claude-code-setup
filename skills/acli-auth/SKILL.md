---
name: acli-auth
description: Manage Atlassian CLI authentication — login, logout, check status, or switch accounts. Use when the user needs to authenticate with Jira or check their auth status.
user-invocable: true
argument-hint: "[login|logout|status|switch]"
model: haiku
effort: low
---

## Task

Manage authentication for the Atlassian CLI (`acli`).

## Steps

### 1. Determine the action

- If `$ARGUMENTS` contains an action (`login`, `logout`, `status`, `switch`), use it.
- Otherwise, **ask the user** what they want to do.

### 2. Execute the action

#### Check status

```bash
acli jira auth status
```

#### Login with OAuth (recommended)

```bash
acli jira auth login --web
```

This opens a browser for OAuth authentication. After accepting, the user selects a site in the terminal.

#### Login with API token

Ask the user for their **site** (e.g. `mysite.atlassian.net`) and **email**, then run:

```bash
acli jira auth login --site "<site>" --email "<email>" --token
```

The user must pipe or paste their API token into stdin. Tokens are generated at https://id.atlassian.com/manage-profile/security/api-tokens

#### Logout

```bash
acli jira auth logout
```

#### Switch accounts

```bash
acli jira auth switch
```

### 3. Verify

After login or switch, confirm the session is active:

```bash
acli jira auth status
```

### 4. Output

Report whether the action succeeded and show the currently authenticated site/user.
