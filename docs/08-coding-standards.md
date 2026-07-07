# Coding Standards

## 1. Required Skill

Use the `karpathy-guidelines` skill for all non-trivial coding, refactoring, debugging, and code review work in this project.

Reference repository reviewed:

- `https://github.com/multica-ai/andrej-karpathy-skills`

Local status:

- The `karpathy-guidelines` skill is already installed locally at `~/.codex/skills/karpathy-guidelines/SKILL.md`.
- The installed skill defines the same practical rules needed by this project: think before coding, prefer simplicity, make surgical changes, and define verifiable success criteria.

## 2. Core Rules

## 2.1 Think Before Coding

- Do not assume missing requirements.
- State meaningful assumptions before implementation.
- Ask when ambiguity would create risky or irreversible work.
- Surface tradeoffs instead of silently choosing complex paths.

## 2.2 Simplicity First

- Implement the smallest solution that satisfies the requirement.
- Do not add speculative features.
- Do not introduce abstractions for one-off use.
- Avoid configurability unless it is required by product or operations.
- Prefer boring, maintainable code over clever code.

## 2.3 Surgical Changes

- Touch only files required by the task.
- Do not refactor unrelated code.
- Do not reformat unrelated files.
- Preserve existing style unless changing style is the explicit task.
- Remove only unused code introduced by the current change.

## 2.4 Goal-Driven Execution

- Define success criteria before meaningful implementation work.
- Prefer tests or repeatable checks for every behavior change.
- For bug fixes, reproduce the bug first where practical.
- For refactors, verify behavior before and after.
- Keep looping until the stated checks pass or the blocker is explicit.

## 3. Project-Specific Rules

- Do not expose Fansgurus API keys to frontend code.
- Do not write real API keys into repository files.
- Keep Fansgurus adapter code isolated from UI code.
- Use decimal arithmetic for money and rates.
- Keep Dujiao-Next upstream code external unless explicitly approved.
- Prefer mature existing framework or skill solutions according to `docs/07-implementation-policy.md`.
- Make all SEO and language-routing changes verifiable with URL-level tests.
- Treat payment, order forwarding, and upstream fulfillment as high-risk paths requiring idempotency checks.

## 4. Required Checks Before Completion

For implementation work, the final response must report:

- What changed.
- What was verified.
- What was not verified, if anything.
- Any remaining risk or follow-up that materially affects launch.

For code review work, findings must come first and be ordered by severity.

## 5. When Full Rigor Can Be Relaxed

For trivial changes such as typo fixes, documentation-only wording edits, or obvious one-line corrections, use judgment. The default is still to avoid unrelated changes and verify the edited file when practical.
