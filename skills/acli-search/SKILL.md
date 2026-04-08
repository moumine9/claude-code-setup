---
name: acli-search
description: Search Jira work items, list projects, or find boards using the Atlassian CLI. Use when the user wants to query or browse Jira data.
user-invocable: true
argument-hint: "[workitems|projects|boards] [query]"
model: haiku
effort: low
---

## Task

Search and list Jira resources via the Atlassian CLI (`acli`).

## Steps

### 1. Determine what to search

Parse `$ARGUMENTS` to identify the target resource. If unclear, **ask the user**.

---

### 2. Execute the search

#### Search work items

Use JQL to query work items:

```bash
acli jira workitem search --jql "<JQL query>" [--fields "<fields>"] [--limit <N>] [--json|--csv]
```

Common JQL examples:
- `"project = TEAM"` — all items in a project
- `"assignee = currentUser() AND status != Done"` — my open items
- `"project = TEAM AND status = 'In Progress'"` — in-progress items
- `"summary ~ 'search term'"` — text search in summaries
- `"created >= -7d"` — items created in the last 7 days

Useful flags:
- `--count` — just show the count of matching items
- `--paginate` — fetch all results (beyond the default limit)
- `--fields "key,summary,status,assignee"` — pick specific columns
- `--csv` — output as CSV
- `--json` — output as JSON
- `--web` — open results in browser

Can also search by saved filter: `--filter <FILTER_ID>`.

#### List projects

```bash
acli jira project list [--limit <N>] [--paginate] [--json] [--recent]
```

- `--recent` — show up to 20 recently viewed projects
- `--paginate` — fetch all projects

#### Search boards

```bash
acli jira board search [--name "<name>"] [--project "<KEY>"] [--type "<scrum|kanban|simple>"] [--json|--csv]
```

---

### 3. Output

- Present results in a readable format.
- For large result sets, summarize the count and show the most relevant items.
- Suggest refining the query if too many results are returned.
