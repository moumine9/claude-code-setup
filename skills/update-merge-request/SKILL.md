---
name: update-merge-request
description: Sync the "Travail effectué" section of the current branch's GitLab MR with its actual commits. Compares commits to the existing bullet list and updates only that section if they diverge. Use when the user wants to update or sync the MR work description with the real commits.
user-invocable: true
---

## Task

Compare the commits on the current branch against the "👷 **Travail effectué**" section of its GitLab merge request. If they match, do nothing. If they diverge, rewrite only that section — leave every other section untouched.

## Steps

### 1. Get the current branch

```bash
git branch --show-current
```

Save as `<current_branch>`.

### 2. Find the merge request

**Primary strategy** — look up by branch name directly:

```bash
glab mr view <current_branch> --output json
```

From the JSON output, extract:
- `description` — the full MR body (this is what you will partially rewrite if needed)
- `target_branch` — used to scope the commit range
- `web_url` — print this at the end so the user can navigate directly to the MR
- `iid` — MR number, used if you need to update by ID

**Fallback strategy** — if the primary fails or returns no open MR, extract the ticket ID from the branch name (e.g. `PV2-16031-some-description` → `PV2-16031`) and look it up in Jira:

```bash
acli jira workitem view <TICKET-ID> --fields "key,summary,development"
```

The "Development" field on the Jira issue lists linked MRs. Use the MR URL found there to identify the MR, then run `glab mr view <iid> --output json` with the numeric MR ID.

If no MR is found through either strategy, stop and inform the user.

### 3. Get the commits

```bash
git log origin/<target_branch>..HEAD --oneline
```

This is the authoritative list of what was done. Each line is a commit.

### 4. Extract the "Travail effectué" section

From the `description`, isolate the content between:

- **Start marker**: the line `👷 **Travail effectué**` (followed by a blank line)
- **End marker**: the line `_Notes additionnelles:_` (preceded by a blank line)

Everything between these two markers (exclusive) is the current "Travail effectué" content.

If either marker is missing in the description, stop and warn the user — the MR body doesn't follow the expected template. Do not proceed with edits.

### 5. Compare commits vs. current bullets

Semantically compare the commit list (step 3) with the bullets in the "Travail effectué" section (step 4).

Ask yourself:
- Are all meaningful changes from the commits represented in the current bullets?
- Are there bullets that no commit supports (stale content)?
- Is the phrasing roughly equivalent, or is something meaningfully missing or wrong?

**If they match** (all commits are accounted for, nothing stale): print a message confirming the section is up to date and the MR URL, then stop. Do not modify anything.

**If they diverge**: continue to step 6.

### 6. Generate a new bullet list

Write a new bullet list in **French** that accurately represents the commit history from step 3. Rules:

- Each bullet should map to one or more related commits, grouped by concern
- Order: fixes and features first, then improvements and refactors last
- Use plain, direct language — not marketing copy
- Keep bullets short: one action per line
- Do not invent anything not supported by a commit

### 7. Humanize the new bullets

Invoke the `/humanizer` skill on the new bullet list to remove any AI-sounding language. Use the humanized final version as the replacement content.

### 8. Reconstruct the full MR body

Take the original `description` and replace **only** the content between the two markers from step 4 with the humanized bullets from step 7. Everything outside those markers must be byte-for-byte identical to the original.

The result should look like this (markers shown for clarity — preserve their exact wording and emoji):

```
...everything above unchanged...

👷 **Travail effectué**

<new humanized bullet list>

_Notes additionnelles:_

...everything below unchanged...
```

### 9. Update the MR

```bash
glab mr update <current_branch> --description "<reconstructed_body>"
```

Use the branch name, not the MR ID, for clarity.

When passing the description, write it to a temp file and use `--description "$(cat /tmp/mr_body.txt)"` if the body contains special characters or newlines that would break shell quoting.

### 10. Output

Print:
- A short summary of what changed in the "Travail effectué" section (added, removed, or reworded bullets)
- The MR URL so the user can verify the result directly
