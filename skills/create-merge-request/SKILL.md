---
name: create-merge-request
description: Create a GitLab merge request using glab CLI with the Familiprix template. Use when the user asks to create a merge request or MR.
user-invocable: true
disable-model-invocation: true
argument-hint: "[target-branch]"
---

## Task

Create a GitLab Merge Request for the current branch using `glab` CLI.

## Steps

### 1. Determine the target branch

- If `$ARGUMENTS` is provided, use it as the target branch.
- Otherwise, **ask the user** which branch to target (e.g. `develop`, `staging`, `main`).

### 2. Gather context

Run these commands to understand what the MR covers:

```
git log origin/<target_branch>..HEAD --oneline
git diff origin/<target_branch>..HEAD --stat
git diff origin/<target_branch>..HEAD
```

Also read the branch name — it often contains a ticket reference (e.g. `PV2-15523`).

### 3. Ensure branch is pushed

Check if the branch is pushed to origin. If not, push it with:

```
git push -u origin <current_branch>
```

### 4. Build the MR body

Use this exact template structure from `Familiprix.md` — **without** `/draft` and **without** `/assign_reviewer`:

```
/assign me
/target_branch <target_branch>

📖 **Description**

<A clear, concise summary of what this MR does and why — written in French>

👷 **Travail effectué**

<Bulleted list of changes made — written in French>

_Notes additionnelles:_

<Any extra context, or leave empty if none>

📓 **Référence(s)**

<Ticket ID extracted from branch name, e.g. PV2-15523>

🎉 **Résultat**

<Expected outcome after merging — written in French>
```

**Rules for filling the template:**
- All descriptive text MUST be in **French**.
- Extract the ticket reference from the branch name (e.g. `PV2-15523-fix-2` → `PV2-15523`).
- The description should explain the **why**, not just the what.
- "Travail effectué" should be a bulleted list derived from the commits and diff.
- "Résultat" should describe the user-facing or developer-facing outcome.
- Do NOT include `/draft` — the MR should be created as ready.
- Do NOT include `/assign_reviewer` — the user will add reviewers manually.

### 5. Generate MR title

- Format: `<TICKET-ID> - <short imperative description>`
- Example: `PV2-15523 - Aligner la barre d'outils avec le DataGrid`
- Keep under 72 characters.

### 6. Create the MR

```bash
glab mr create \
  --target-branch <target_branch> \
  --title "<title>" \
  --description "<body>" \
  --no-editor
```

### 7. Output

Print the MR URL so the user can access it directly.
