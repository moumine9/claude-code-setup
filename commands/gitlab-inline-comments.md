---
name: gitlab-inline-comments
description: Use when posting inline diff comments on GitLab merge requests using glab CLI. Covers position API, diff version SHAs, draft notes (pending review), renamed file handling, and shell escaping pitfalls.
---

# GitLab Inline MR Comments via glab

## Overview

Post inline comments on specific lines of a GitLab MR diff using `glab api`. The critical detail: `glab -f` flags do NOT properly nest the `position` object — you must pipe raw JSON with an explicit `Content-Type` header.

Two modes:
- **Draft notes** (`/draft_notes`): posted as pending, user publishes from GitLab UI. Use `note` field.
- **Live discussions** (`/discussions`): immediately visible. Use `body` field.

## Quick Reference

| Step | Command |
|------|---------|
| Get diff SHAs | `glab api "projects/:id/merge_requests/:iid/versions"` |
| Get file old_path | `glab api "projects/:id/merge_requests/:iid/versions/:vid"` |
| Post inline **draft** note | Pipe JSON to `/draft_notes` with `note` field |
| Post inline **live** comment | Pipe JSON to `/discussions` with `body` field |
| Delete a draft note | `glab api "projects/:id/merge_requests/:iid/draft_notes/:id" --method DELETE` |
| Delete a live comment | `glab api "projects/:id/merge_requests/:iid/notes/:note_id" --method DELETE` |
| List discussions | `glab api "projects/:id/merge_requests/:iid/discussions"` |

## Draft Notes (Pending Review)

Draft notes are visible only to the author until published from the GitLab UI ("Finish review"). Prefer these when the user wants to review before posting.

**Key difference vs discussions**: use `note` (not `body`) as the text field.

```js
node --input-type=module << 'EOF'
import { spawnSync } from 'node:child_process';

const BASE = '<base_sha>';
const HEAD = '<head_sha>';
const MR_IID = '<IID>';
const PROJECT = 'owner%2Frepo%2Fsubgroup';  // URL-encoded

const drafts = [
  {
    old_path: 'src/old/path.ts',
    new_path: 'src/new/path.ts',
    new_line: 42,
    note: 'Your comment in **markdown**.',
  },
];

for (const c of drafts) {
  const payload = JSON.stringify({
    note: c.note,
    position: {
      base_sha: BASE,
      head_sha: HEAD,
      start_sha: BASE,
      position_type: 'text',
      old_path: c.old_path,
      new_path: c.new_path,
      new_line: c.new_line,
    },
  });

  const result = spawnSync(
    'glab',
    [
      'api', `projects/${PROJECT}/merge_requests/${MR_IID}/draft_notes`,
      '--method', 'POST',
      '--input', '-',
      '-H', 'Content-Type: application/json',
    ],
    { input: payload, encoding: 'utf8' }
  );

  if (result.status === 0) {
    const d = JSON.parse(result.stdout);
    console.log(`Draft OK: id=${d.id} line=${d.position?.new_line}`);
  } else {
    console.error('ERR:', result.stderr?.trim());
  }
}
EOF
```

## Step 1: Get Diff Version SHAs

```bash
glab api "projects/:id/merge_requests/336/versions" | node -e "
const chunks = [];
process.stdin.on('data', c => chunks.push(c));
process.stdin.on('end', () => {
  const v = JSON.parse(chunks.join(''))[0];
  console.log('head_sha:', v.head_commit_sha);
  console.log('base_sha:', v.base_commit_sha);
  console.log('start_sha:', v.start_commit_sha);
  console.log('version_id:', v.id);
});
"
```

## Step 2: Get old_path for Each File

Required because renamed files have different `old_path` vs `new_path`. For new files, both are the same.

```bash
glab api "projects/:id/merge_requests/336/versions/:version_id" | node -e "
const TARGET = 'path/to/target/file.ts';
const chunks = [];
process.stdin.on('data', c => chunks.push(c));
process.stdin.on('end', () => {
  const data = JSON.parse(chunks.join(''));
  const d = (data.diffs ?? []).find(d => d.new_path === TARGET);
  if (d) {
    console.log('old_path:', d.old_path);
    console.log('new_file:', d.new_file);
    console.log('renamed:', d.renamed_file);
  }
});
"
```

## Step 3: Post Comments

**CRITICAL**: Use Node.js `child_process` to construct JSON and pipe it. This avoids all shell escaping issues with backticks, quotes, apostrophes, and special characters in comment bodies.

```js
node --input-type=module << 'EOF'
import { spawnSync } from 'node:child_process';

const BASE = '<base_sha>';
const HEAD = '<head_sha>';
const MR_IID = '<IID>';

const comments = [
  {
    old_path: 'src/old/path.ts',  // from step 2
    new_path: 'src/new/path.ts',
    new_line: 42,                 // line in the NEW file
    body: 'Your comment in **markdown**. Backticks, quotes, accents all work.',
  },
  // ... more comments
];

for (const c of comments) {
  const payload = JSON.stringify({
    body: c.body,
    position: {
      base_sha: BASE,
      head_sha: HEAD,
      start_sha: BASE,
      position_type: 'text',
      old_path: c.old_path,
      new_path: c.new_path,
      new_line: c.new_line,
    },
  });

  const result = spawnSync(
    'glab',
    [
      'api', `projects/:id/merge_requests/${MR_IID}/discussions`,
      '--method', 'POST',
      '--input', '-',
      '-H', 'Content-Type: application/json',
    ],
    { input: payload, encoding: 'utf8' }
  );

  if (result.status === 0) {
    const note = JSON.parse(result.stdout).notes[0];
    const pos = note?.position;
    if (pos) {
      console.log(`OK: DiffNote on ${pos.new_path}:${pos.new_line}`);
    } else {
      console.warn('WARN: top-level comment (no position)');
    }
  } else {
    console.error('ERR:', result.stderr?.trim());
  }
}
EOF
```

## Position Fields

| Field | Value | Notes |
|-------|-------|-------|
| `base_sha` | From versions API | Target branch merge base |
| `head_sha` | From versions API | Source branch HEAD |
| `start_sha` | From versions API | Usually same as `base_sha` |
| `position_type` | `"text"` | Always `"text"` for code comments |
| `old_path` | From version diffs | Original path (differs for renames) |
| `new_path` | Target file path | Path in the source branch |
| `new_line` | Line number | For added/modified lines |
| `old_line` | Line number | For removed lines (use instead of `new_line`) |

## Common Mistakes

| Mistake | Symptom | Fix |
|---------|---------|-----|
| Using `glab -f "position[key]=val"` | Comment appears top-level, `position: False` | Pipe JSON with `--input -` and `-H "Content-Type: application/json"` |
| Missing `Content-Type` header | `HTTP 415 Unsupported Media Type` | Add `-H "Content-Type: application/json"` |
| Shell-escaping JSON with quotes/backticks | Malformed JSON, parse errors | Use Node.js `child_process` to build and pipe JSON |
| Wrong or missing `old_path` | Comment appears top-level | Fetch from `/versions/:vid` endpoint; renamed files have different `old_path` |
| Using `new_line` for deleted lines | `400 Bad Request` | Use `old_line` for lines only in the old file |
| Using `body` for draft notes | `400 Bad Request` | Draft notes use `note` field; discussions use `body` field |
| Using `glab --field` for draft notes without `--input -` | `HTTP 415` or top-level note | Always pipe JSON via `--input -` with `-H "Content-Type: application/json"` |

## Verifying Success

A correctly posted inline comment has:
- `notes[0].type == "DiffNote"` (NOT `"DiscussionNote"`)
- `notes[0].position` is non-null with correct file and line

If `type` is `"DiscussionNote"` or `position` is null/missing, the comment landed as a top-level thread on the MR overview page — not inline on the diff.
 