# Repo Agent Instructions

1. At the start of every conversation in this repository, read `AGENT_NOTES.md` before proposing or writing changes.
2. Use `AGENT_NOTES.md` as preference memory for communication style, delivery format, and reporting conventions.
3. When a new stable preference appears, append it to `AGENT_NOTES.md` with a date and short rationale.
4. Keep notes concise and behavioral; do not store secrets, passwords, API tokens, or personal data.
5. If a note conflicts with an explicit user request in the current conversation, follow the current explicit request and then update notes accordingly.
6. If multiple tasks are provided, prioritize the oldest requested task first and then newer tasks; if the user explicitly marks a task as urgent, complete that urgent task first and then automatically continue the remaining tasks in original order.
7. When repo-level notes are insufficient, consult `/Users/khizar/Documents/GitHub/AGENT_NOTES_GLOBAL.md`.
8. Do not copy global notes into local notes unless explicitly requested; reference them instead.
9. When instructions or notes change, update all setup docs in this repo (`setup_instructions.md`, `setup_instructions_win.md`, `setup_instructions_ubuntu.md`) and push `main` in the same turn when feasible.
