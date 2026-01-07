Focuslog

Focuslog is a calm, minimal web app I’m building to understand how my time actually goes each day.
It’s intentionally simple and judgment-free — no scores, no streaks, no pressure — just clarity.

The goal is not to “optimize productivity”, but to notice patterns and reflect honestly.

Current state

This repository represents the current stable version of Focuslog.
I’m building it iteratively and expanding it step by step.

Right now, Focuslog focuses on:

manual time tracking

clear daily and weekly views

simple reflections

Everything runs locally and stays private.

What Focuslog can do (current version)
Daily time tracking

Log activities manually with:

activity name

category (study, work, rest, scroll, other)

start and end time

View the day as a chronological timeline of time blocks.

Multi-day navigation

Switch between Today, Yesterday, or any past date.

Each day’s data is stored separately so patterns don’t get mixed up.

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

Clear all data only after a clear confirmation step.

Everything is stored locally on the device.

Design philosophy

Focuslog is built around a few simple rules:

Calm, neutral language

Minimal UI

No productivity scores or gamification

No notifications or reminders

Clarity over aesthetics

If something feels stressful or noisy, it doesn’t belong here.

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

Logic is commented where it’s not obvious (weekly aggregation, exports, date helpers).

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

rewrite README in personal voice and clarify project intent