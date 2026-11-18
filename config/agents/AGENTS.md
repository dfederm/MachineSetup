# General Agent Instructions

## Source Control
- Commit only when the user, system or repository instructions, or a skill explicitly call for it.

## Code Style
- When an `.editorconfig`, linter config, or formatter config exists in the project, follow it. Otherwise, follow the standard idiomatic conventions for the language (e.g., Allman-style braces and `IDE0011` "always use braces" for C#, PEP 8 for Python, etc.).

## Communication

Write explanations and replies in clear, natural English, roughly "80% of the way to ASD-STE100."

Treat me as an experienced software engineer.

- Start with the answer, result, or recommendation.
- Prefer short, complete sentences with concrete subjects and verbs. Name who acts. Avoid jargon, long noun phrases, and compressed status-note shorthand.
- Use consistent names. When introducing an unfamiliar component, explain its role before relying on its name.
- Explain the connections between facts, especially cause and effect. Use a small example or diagram when that would make them clearer.
- Preserve technical precision, conditions, and uncertainty. Remove repetition, not explanations needed to understand the answer.
- Use paragraphs for reasoning and lists for distinct items or steps. Avoid unnecessary preambles, decorative formatting, and repeated summaries.

Before replying, check whether I must decode shorthand or infer a missing connection. Rewrite those parts.

## Comments, commit messages, and PR descriptions

Write these for reviewers and future maintainers who saw none of the session that produced the change. Test: would someone with only the final code and this text find it useful?

- **Default to no comment.** Comment only a non-obvious *why*: a workaround, constraint, subtle invariant, or surprising edge case. Do not restate what code does, annotate obvious lines or standard idioms, or add section-divider or step-narration comments. When in doubt, leave it out; when asked to trim, cut aggressively.
- **Describe the current state, not its history.** Omit "previously…", "changed from…", and "used to…"; Git carries history.
- **Include only the change and its rationale.** Omit development process such as rebases, conflict resolution, review feedback, and abandoned approaches.
- **Omit session context.** What "we discussed", planning or tracking notes, session or task IDs, and tool or agent names mean nothing to readers.
- **Be concise.** One clear line beats a paragraph.
