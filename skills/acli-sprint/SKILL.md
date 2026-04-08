---
name: acli-sprint
description: List sprints and sprint work items using the Atlassian CLI. Use when the user wants to view sprint data, active sprints, or items in a sprint.
user-invocable: true
argument-hint: "[list|items] [options]"
model: haiku
effort: low
---

## Task

View sprints and sprint work items via the Atlassian CLI (`acli`).

## Steps

### 1. Determine the action

Parse `$ARGUMENTS` to decide what to do. If unclear, **ask the user**.

---

### 2. Execute the action

#### List sprints for a board

First, find the board ID if the user only knows the project or board name:

```bash
acli jira board search --project "<PROJECT_KEY>" --json
```

Then list sprints:

```bash
acli jira board list-sprints --id <BOARD_ID> [--state "<active|future|closed>"] [--json|--csv]
```

- `--state "active"` — show only the active sprint
- `--state "active,future"` — show active and upcoming sprints
- `--paginate` — fetch all sprints

#### List work items in a sprint

Requires both `--board` and `--sprint` IDs:

```bash
acli jira sprint list-workitems --board <BOARD_ID> --sprint <SPRINT_ID> [--fields "<fields>"] [--json|--csv] [--jql "<filter>"]
```

- `--fields "key,summary,status,assignee"` — pick specific columns
- `--jql "assignee = currentUser()"` — filter sprint items by JQL
- `--paginate` — fetch all items beyond the default 50 limit

---

### 3. Workflow example

If the user asks "show me my current sprint items", follow this sequence:

1. Find the board: `acli jira board search --project "<KEY>" --json`
2. Get the active sprint: `acli jira board list-sprints --id <BOARD_ID> --state active --json`
3. List items: `acli jira sprint list-workitems --board <BOARD_ID> --sprint <SPRINT_ID>`

### 4. Output

- Present sprint data in a readable format.
- For sprint items, highlight status distribution (how many To Do / In Progress / Done).
