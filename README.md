# Focuslog — quiet time tracking for reflection

Focuslog is a small, privacy-first time tracker that helps you notice patterns without pressure. It’s built for people who want clearer, kinder insight into their days — no scores, no nudges, just facts and gentle context.

Why I made this

I wanted a calm place to capture what happened during my day and later look back without feeling judged. Focuslog aims to support honest reflection: light, optional, and kind.

What you'll find

- Simple manual time tracking (activity name, category, start/end)
- Custom categories so the app fits how you actually spend time
- Optional tags: Energy (Low / Neutral / High) and Intent (Intentional / Unintentional)
- Today and Weekly views with a quiet baseline comparison when there’s enough history
- Small, rule-based insights that only appear when data is meaningful
- Local-first: export JSON/CSV and clear data after a calm confirmation

How this stays calm and neutral

- Observational language only: we describe patterns ("slightly more time", "about the same") and avoid score-like language.
- No colors or icons that imply achievement — comparisons are subdued, skimmable, and optional.
- The app avoids goal-setting and gamification on purpose: this keeps your data honest and reduces pressure.

Run locally

Requirements: Flutter SDK (https://docs.flutter.dev/get-started/install)

From the project root:

```bash
flutter pub get
flutter run
```

Development notes

- Components are small and modular.
- Logic is commented where rules are non-obvious (weekly aggregation, exports, insight rules).

Validation & overlaps

- If the end time is earlier than the start time, the app asks whether the activity crossed midnight; if confirmed, the activity is split into two entries (before and after midnight) so daily and weekly summaries reflect actual minutes per day. Weekly summaries also compute per-day overlaps (including parts of entries stored under adjacent dates) so totals remain accurate.
- Zero-length entries (end time equal to start time) are not allowed and the app asks you to correct them.
- If a new or edited entry overlaps existing entries for the same date, the app warns you and shows the conflicting entries; you may then choose to save anyway or review times. Overlaps are allowed but surfaced clearly so you can resolve them.

License

MIT

Weekly overview

A dedicated Week view shows how time was spent across the last 7 days.

Time is grouped by category to make patterns easy to notice.

The focus is readability, not flashy charts.

Baseline comparison

The Week view includes an option to compare the current week with the previous week (baseline period).

When enabled, category breakdowns show both current and baseline time allocations side by side.

This provides context for weekly patterns without targets or judgments.

Reflection

Each day has a small reflection section.

Prompts like:

“What helped me today?”

“What drained me today?”

These notes stay tied to the specific day.

Data control

Export all data as JSON or CSV.

Clear data only after a calm confirmation step.

Everything is stored locally on the device.

Design philosophy

Focuslog is built around a few simple rules:

Calm, neutral language

Minimal UI

No productivity scores or gamification

No notifications or reminders

Clarity over aesthetics

If something feels stressful or noisy, it doesn’t belong here.

Language philosophy

All text in the app uses optional, neutral language to avoid judgment or pressure. Instead of directives like "Fix this" or evaluative terms like "unproductive," the app suggests possibilities (e.g., "You may want to review") and states facts (e.g., "Time recorded"). This creates a calm, reflective space focused on observation rather than evaluation.

## How comparisons work (and what they are not)

- Comparisons are intentionally quiet and optional. They are meant to provide gentle context, not judgments or scores. The UI uses subdued text and spacing (no bright colors or icons) so comparisons are skimmable and non-evaluative.
- Thresholds and sufficiency: To avoid noisy or misleading signals, comparisons are shown only when there's a reasonably complete baseline (data from at least **4 of the previous 7 days**). Energy timing comparisons use a duration-weighted average start time and conservative thresholds (>= 1.0 hour = notable shift, >= 0.4 hour = small shift). Intent comparisons (unintentional time) compare today's total minutes against the 7-day average; extremely small baselines are treated as absent.
- Language safety: All comparison text is neutral (e.g., "slightly more time", "about the same", "not enough recent data to compare"). We avoid framing that implies success/failure such as achievement-oriented "increase/decrease" language and avoid using colored signals or arrows that may feel evaluative.
- Why no goals/scores: Focuslog intentionally avoids goals, scoring, or productivity nudges because those features change how people record and interpret their time (they can introduce pressure and reduce honest reflection). Comparisons are purely observational to support reflection, not to prescribe actions.



How data is stored

Data is stored locally, grouped by date.

Examples:

time_entries_YYYY_M_D

daily_reflection_YYYY_M_D

This makes it easy to reason about daily and weekly patterns without a backend.

Running the project locally

Focuslog is built with Flutter.

Requirements

Flutter SDK installed
https://docs.flutter.dev/get-started/install

Run

From the project directory:

flutter pub get
flutter run


No additional setup is required.

Main dependencies

shared_preferences – local data storage

intl – date handling and formatting

path_provider – temporary files for export

share_plus – sharing exported files

Development notes

UI components are kept small and modular.

Logic is commented where it’s not obvious (weekly aggregation, exports, date helpers, and insight rules).

Version 3 — Energy & Intent (stable)

Version 3 adds two optional, neutral tags to entries:

- Energy: one of Low energy, Neutral, or High energy. This field is optional and skippable.
- Intent: one of Intentional or Unintentional. This field is optional and skippable.

These tags are intentionally minimal and non-judgmental. They are stored per entry and included in exports (JSON/CSV). Older data (from earlier versions) remains compatible because both fields are nullable and safely ignored when absent.

Simple, rule-based insights (non-AI) were added to the Today view. Examples:

- “Most of your focused time happened when energy was high.”
- “A large portion of unintentional time happened in the evening.”

Insights are produced by explicit, transparent rules (no scoring or AI) and are optional to view.

Features are added slowly to avoid complexity creep.

This project is intentionally evolving over time rather than aiming for a “final” version.

License

MIT

Why this version works better

Sounds like a real person, not a spec sheet

Shows intent and understanding

Honest about scope and limits

Exactly what Hack Club likes to see

Next time you commit, use a message like:

rewrite README in personal voice and clarify project intent.

## Data handling notes

- Cross-midnight entries: If an entry's `endTime` is earlier than its `startTime`
	the app treats it as crossing midnight when the user confirms. The entry is
	split into two normalized `TimeEntry` objects (one ending at midnight and one
	starting at midnight) so per-day and per-week aggregates report minutes on the
	correct calendar day.
- Normalization on load/save: When reading stored entries the app defensively
	parses each item, skips unrecoverable/malformed entries, and persists a
	normalized representation back to storage. `saveEntries` also writes a
	normalized JSON representation. This makes migrations from earlier versions
	safe and keeps on-disk data consistent.
- Optional fields: `energy` and `intent` are nullable. Missing or invalid
	values are treated as `null` rather than being coerced to defaults. This
	preserves historical data and avoids introducing misleading tags.
- Migration safety: malformed entries or unexpected shapes in stored JSON are
	skipped during load to prevent crashes; the cleaned list is written back so
	future loads are stable. Exports include the normalized fields for clarity.

These decisions prioritize robustness and clear per-day accounting over
heuristic repairs or opaque defaults.



