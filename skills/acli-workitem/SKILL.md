---
name: acli-workitem
description: Create, edit, view, transition, assign, or comment on Jira work items using the Atlassian CLI. Use when the user wants to manage Jira issues from the terminal.
user-invocable: true
argument-hint: "[create|edit|view|transition|assign|comment] [options]"
model: haiku
effort: low
---

## Task

Manage Jira work items via the Atlassian CLI (`acli`).

## Steps

### 1. Determine the action

Parse `$ARGUMENTS` to identify the action and any supplied details (key, summary, project, etc.). If the action is unclear, **ask the user** what they want to do.

Supported actions: `create`, `edit`, `view`, `transition`, `assign`, `comment`.

---

### 2. Execute the action

#### Create a work item

Required: `--summary`, `--project`, `--type`.

```bash
acli jira workitem create --summary "<summary>" --project "<PROJECT_KEY>" --type "<Task|Bug|Story|Epic>"
```

Optional flags:
- `--assignee "<email|@me>"` — assign immediately
- `--description "<text>"` — add a description
- `--label "<label1,label2>"` — add labels
- `--parent "<PARENT-KEY>"` — set parent (for subtasks)
- `--from-file "<file>"` — read summary/description from file
- `--from-json "<file>"` — read full definition from JSON
- `--json` — output result as JSON

If the user doesn't provide project or type, **ask them**.

#### View a work item

```bash
acli jira workitem view <KEY> [--fields "<field1,field2>"] [--json] [--web]
```

Default fields: `key,issuetype,summary,status,assignee,description`. Use `--fields "*all"` for everything.

#### Edit a work item

```bash
acli jira workitem edit --key "<KEY-1,KEY-2>" [--summary "<new>"] [--description "<new>"] [--assignee "<email>"] [--labels "<new>"] [--type "<new>"] [--yes]
```

Can also target by JQL (`--jql`) or filter (`--filter`).

#### Transition a work item

```bash
acli jira workitem transition --key "<KEY>" --status "<status>"
```

Common statuses: `To Do`, `In Progress`, `Done`. Add `--yes` to skip confirmation.

Can also target by JQL (`--jql`) or filter (`--filter`).

#### Assign a work item

```bash
acli jira workitem assign --key "<KEY>" --assignee "<email|@me|default>"
```

Use `--remove-assignee` to unassign. Can target by JQL (`--jql`) or filter (`--filter`).

#### Comment on a work item

```bash
acli jira workitem comment create --key "<KEY>" --body "<comment text>"
```

Alternative: `--body-file "<file>"` to read comment from a file.

---

### 3. Output

- Show the command output to the user.
- For `create`, highlight the new work item key.
- For `view`, present the fields in a readable format.
- For batch operations (JQL/filter), summarize how many items were affected.
