# Sub-issue for [#15](https://github.com/fessykhan699-cmyk/garage-mv0/issues/15): Keep Copilot instructions in sync

## Objective
Document a follow-up task to ensure the repository’s Copilot-facing instructions stay aligned with the locked scope files (AGENT_PROMPT.md, UI_FLOW.md, FIRESTORE_SCHEMA.md, TASKS.md).

## Scope
- No feature work; documentation alignment only.
- Apply to the existing instruction files and the public `.github/copilot-instructions.md`.

## Tasks
- [ ] Cross-check that the four locked scope files (AGENT_PROMPT.md, UI_FLOW.md, FIRESTORE_SCHEMA.md, TASKS.md) match the content in `.github/copilot-instructions.md`.
- [ ] Add any missing constraints or gating rules from the locked files into `.github/copilot-instructions.md`.
- [ ] Keep command references for lint, test, and build consistent across README.md and `.github/copilot-instructions.md`.

## Acceptance Criteria
- Checklist above is completed.
- Copilot instruction file reflects the latest locked-scope documents without introducing new scope.
- No code changes beyond documentation alignment.
