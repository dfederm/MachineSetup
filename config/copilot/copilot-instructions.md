# General Copilot Instructions

## Source Control
- Do not commit changes unless given explicit instructions to do so by either the user, system instructions, or a skill's instructions.

## Code Style
- When an `.editorconfig`, linter config, or formatter config exists in the project, follow it. Otherwise, follow the standard idiomatic conventions for the language (e.g., Allman-style braces and `IDE0011` "always use braces" for C#, PEP 8 for Python, etc.).

## Brain Repository

The user maintains a knowledge base repo ("brain") at `$env:CodeDir\brain` containing reference docs, active todos, and a daily journal. When working on a task related to topics covered there, read these for context:
- `$env:CodeDir\brain\reference\` — architecture docs, system knowledge, conventions
- `$env:CodeDir\brain\todos\` — active tasks with status and next steps

A `relay` skill is available to capture session work for the brain repo. Run `/skill relay` before closing a task session.
