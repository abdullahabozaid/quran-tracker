# Quran Tracker — Tafsir, Weekly Report & Delete Students

Date: 2026-06-06

Four changes to the single-file vanilla-JS Quran Tracker. All work applies to **both** `index.html` and `quran-tracker.html` (currently byte-identical; kept in sync by copying `index.html` → `quran-tracker.html` after edits). All new UI is fully localized EN/AR with RTL support.

## 1. Tafsir (تفسير) — new tracked count + quick-action button

Tafsir behaves exactly like the existing `videos` and `wird` metrics.

- **Data model:** each day-log entry gains an optional `tafsir` number → `{date, text, videos, wird, tafsir}`. No DB schema change — `log` is stored as one JSON blob and already syncs via `save_student`.
- **Composer:** a third stepper row ("Tafsir this day") with `−` / count / `+` (ids `tfMinus`/`tfCount`/`tfPlus`), saved with the day.
- **Quick actions:** new built-in `kind: 'tafsir'` button (`+1 تفسير`), added to `defaultQuickActions()`. Custom buttons gain an "also +1 tafsir" checkbox alongside the existing video/wird ones.
- **Display:** third number in the hero tile; included in history list/cards pills, calendar badges/extras, the "copy as text" export, and the teacher's per-student detail chips.
- `weekChart` stays videos-only (unchanged) to keep the bar chart simple.

## 2. Weekly report — student & teacher

Shared core: `summarizeWeek(log, weekStartDate)` → `{ws, we, days, videos, wird, tafsir}` for a Mon–Sun week, plus `weekLabel(ws)` and `reportText(...)`.

- **Student side:** a new toggleable tile (`data-tile="report"`, added to `TILE_DEFS`) titled "This week's report" with the week's stats, a `‹ range ›` week stepper, and a **Copy report** button (plain text for sending to the teacher). Tasks done/total comes from the student's own weekly tasks.
- **Teacher side:** a "Weekly report" section inside each student's detail page, same stats + week stepper + copy, built from `s.log`. Teacher-side tasks-done is the count of checked items in `s.weekly` for that week (total unknown teacher-side, so count only).

## 3. Delete students (teacher) — per-student + delete all

- **New Supabase RPCs** in `supabase-setup.sql`, passcode-gated (same passcode as the other teacher RPCs):
  - `delete_student(pass text, p_id text)`
  - `delete_all_students(pass text)`
  - ⚠️ The teacher must re-run the SQL in Supabase for delete to work — flagged in `TEACHER-SETUP.md`.
- **Per-student:** a destructive "Delete student" button in the student detail view → single confirm → removes from cloud + local `ADMIN` list → back to list.
- **Delete all:** a "Delete all students" danger button above the student list → two confirms → wipes all. To keep one student, the teacher deletes the others individually.
- Both call the new RPCs (synced) and update the in-memory `ADMIN` array + re-render stats/list.

## 4. Sync & i18n

- Tafsir syncs automatically via the existing `log` blob; deletes sync via the new RPCs.
- Every new string added to the `STR` dictionary with both `en` and `ar`.

## Out of scope (YAGNI)

- No per-metric chart changes beyond videos.
- No multi-select delete (per-student + delete-all covers the "keep one" need).
- No new DB columns.
