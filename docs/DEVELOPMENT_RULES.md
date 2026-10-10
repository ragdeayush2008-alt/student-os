# Student OS — Development Rules

These rules govern all changes to the Student OS project. Every contributor and every automated change must follow them.

## Change Discipline

1. **Never modify unrelated files.** Only touch files relevant to the task at hand.
2. **Always inspect existing code before changing it.** Understand the current implementation and conventions before editing.
3. **Before major changes, explain what will change.** Describe intent and impact before implementing significant work.
4. **After changes, report files created/modified.** Provide a concise report of what was added or changed.

## Modularity & Quality

5. **Keep features modular.** Isolate feature areas; avoid coupling unrelated modules.
6. **Avoid unnecessary dependencies.** Add a dependency only when it clearly solves a real problem.
7. **Prefer free/open-source solutions initially.** Favor free-tier and open-source services and packages.
8. **Keep code clean, maintainable and scalable.** Write clear, well-structured, extensible code.

## Security & Preservation

9. **Never expose API keys or secrets.** Store credentials in secure environment configuration only. Never commit secrets or keys to the repository.
10. **Do not remove existing functionality without permission.** Never delete or degrade working features unless explicitly authorized.

## Reporting Standard

After any change, the modification report must list:

- Files **created**
- Files **modified**
- Any dependencies added (with justification)

This keeps the project transparent and auditable.
