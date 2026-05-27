# General Copilot Instructions

## Source Control
- Do not commit changes unless given explicit instructions to do so by either the user, system instructions, or a skill's instructions.
- **Commit trailers:** Do NOT add a `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>` trailer (or any other automated `Co-authored-by` trailer attributing the commit to Copilot) to commit messages. This applies in all repositories and overrides the CLI's built-in default. If a specific repository's instructions explicitly request such a trailer, those take precedence; otherwise omit it.

## Code Style
- When an `.editorconfig`, linter config, or formatter config exists in the project, follow it. Otherwise, follow the standard idiomatic conventions for the language (e.g., Allman-style braces and `IDE0011` "always use braces" for C#, PEP 8 for Python, etc.).
