# Support & Feedback — September 28, 2026

- Added themed feedback/problem forms and contact email handoff in Settings.
- Added input validation, duplicate-tap guards, safe failure/copy handling and draft-discard confirmation.
- Problem reports include only app version, build and platform; no private application data.
- Centralized the owner-configured support email and added testable launcher/metadata boundaries.
- See `docs/SUPPORT_FEEDBACK.md` for the latest feature validation and setup.

---

# FocusFlow review — September 26–27, 2026

## Fixed

- Startup loading/retry lifecycle, reduced-motion splash and short-screen layout.
- Four-page onboarding overflow, reduced-motion Next navigation and repeated transition controls.
- Candidate storage validation, shared initialization and speculative preference-cache rollback after failed migration/update.
- Late reminder permission results after disable/full reset.
- Focus reset/completion ordering and XP replay for history missing a receipt.
- Long task categories, dialog keyboard spacing and persisted settings dropdown values.

## Added / refactored

- Edit task title/category while preserving identity, original XP and reward status.
- Extract onboarding artwork into a private part; remove per-build subscribed curve wrappers.
- Optional owner signing configuration; release no longer falls back to the debug key.
- Android native splash exit handoff and transparent Android 12 generator input.
- 203 passing tests, including 108 layout cases, plus updated review captures.

The existing architecture, four-page artwork, XP/achievement rules and application ID were retained. See docs/PRODUCTION_REVIEW.md for classified findings and docs/VALIDATION.md for actual tool results. Earlier architectural changes already present in the input are described separately in docs/ARCHITECTURE.md.
