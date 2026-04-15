---
name: update-merge-request
description: Syncs the "Travail effectué" section of the current branch's GitLab MR with its actual commits. Invoked automatically after a git commit when an open MR exists. Compares commits to the existing bullet list and rewrites only that section if they diverge.
tools: Bash
model: haiku
effort: low
color: blue
---

Run the /update-merge-request skill.
