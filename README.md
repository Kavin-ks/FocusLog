# Focuslog

A small, calm tool for keeping a simple record of how you spend your time each day. It runs locally and is private — no accounts, no scores, no streaks.

Why I built this

I wanted a quiet, pressure-free way to notice patterns in my days. The goal is clarity: to help reflection without nudges or scoring.

What’s in this version (v3)

- Manual time tracking: activity name, category, start and end times
- Custom categories: Add your own categories alongside built-in ones (Study, Work, Rest, Scroll, Other) to make time tracking more personal
- Date navigation (Today, Yesterday, or pick a date)
- Daily timeline and a Week view that summarizes the last 7 days
- Optional tags per entry: Energy (Low / Neutral / High) and Intent (Intentional / Unintentional)
- Simple, rule-based insights on the Today page (optional to view)
- Export data (JSON/CSV) and a calm confirmation before removing saved data

Energy & Intent

- Energy and Intent tags are small, optional fields you can add when logging an entry.
- They are intentionally neutral and skippable. Older entries without these tags remain compatible.

Custom categories

Focuslog includes built-in categories (Study, Work, Rest, Scroll, Other) but you can add your own to make time tracking more personal. Custom categories appear alongside built-in ones in entry forms and summaries. This helps reflect your unique activities without making the app more complex.

How insights are generated

Insights on the Today page are simple, rule-based observations derived from your entries. They appear only when there's sufficient data (at least 3 entries and 60+ minutes total).

- **Dominant category energy pattern**: Finds your most-used category for the day (excluding Scroll) and checks if 60% or more of time in that category was logged when energy was "High", showing "Most time in [category] was recorded when energy was high."
- **Unintentional timing pattern**: If 50% or more of unintentional time occurred in a single time-of-day period (morning/afternoon/evening/night), shows which period.

Thresholds are conservative to highlight clear patterns. Insights are optional to view and prioritize observation over judgment.

Data & storage

Data is stored locally and grouped by date (e.g., `time_entries_YYYY_M_D`, `daily_reflection_YYYY_M_D`).
Exports include the optional tags when present.

Design principles

- Calm, neutral language
- Minimal UI
- No productivity scoring or gamification

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

