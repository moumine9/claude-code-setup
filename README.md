# Personal setup for claude-code tool


## Agents

> Custom subagents in Claude Code are specialized AI assistants that can be invoked to handle specific types of tasks. They enable more efficient problem-solving by providing task-specific configurations with customized system prompts, tools and a separate context window.

- [Code-review-frontend](./agents/code-review-frontend.md): agents to do code review for frontend code.
- [lint](./agents/lint.md): run linting and prettier commands to flag and fix lint issue and finish with prettier.
- [cypress-test](./agents/cypress-test.md): agent to add cypress test(s) whenever needed. Also run tests to verify if nothing broke.

## Commands

> Custom slash commands allow you to define frequently-used prompts as Markdown files that Claude Code can execute. Commands are organized by scope (project-specific or personal) and support namespacing through directory structures.

- [/commit](./commands/commit.md): generate commit messages based on [conventionalcommits](https://www.conventionalcommits.org/fr/v1.0.0/) references.
- [/cypress-test](./.claude/commands/cypress-test.md): add meaningful Cypress E2E tests to any modified files detected in git.

## Settings

### [Excluding sentivie files/folders](https://docs.claude.com/en/docs/claude-code/settings#excluding-sensitive-files)

```JSON
{
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)",
      "Read(./config/credentials.json)",
      "Read(./build)"
    ]
  }
}

```

## References

