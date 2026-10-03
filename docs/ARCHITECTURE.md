# FocusFlow implementation notes

The original purple/green Material 3 screens and animated tree/chart painters remain. Cubits remain application-scoped and feature-first. Settings and achievements use routes; the five navigation destinations remain Home, Tasks, Focus, Garden and Stats.

## Architecture inherited from the earlier implementation

The following describes the existing design supplied in the September 26 upload. It is not a list of new changes in this review; see PRODUCTION_REVIEW.md for that distinction.

- XP was awarded by mounted widgets. Task flags, XP and session summaries were persisted independently. A shutdown between writes could lose rewards; a restored session could not award them reliably.
- The timer decremented on periodic callbacks and discarded active state on launch. The new timer uses a durable session ID, scheduled finish timestamp and paused remaining seconds. An injected clock makes elapsed-time tests deterministic. A late completion is dated at its scheduled finish, not the time the user reopened the app.
- Sample tasks populated new accounts. New installations now start empty. Old tests explicitly seed their own fixtures; existing user tasks are migrated.
- A single versioned JSON document (`focus_flow_v2`) stores tasks, event receipts, XP, history, settings, achievements and active session state. `AppRepository` serializes mutations and publishes successful writes. Rewards and their events share one preference write. Old preference keys are read once for migration; legacy rewards are marked as already applied without adding XP again.
- Event IDs are random, not dependent on the wall clock remaining monotonic. Task/session receipts survive individual resets. Claiming a completed task is an explicit user action; toggling it never grants XP. Undoing completion withdraws unclaimed reward availability. Deletion never retracts earned XP or lifetime task milestones.
- Focus rewards are centralized at **2 XP per completed minute**. Level progression retains the original 1,000 XP per level. Failed writes retain the previous published state and show a retryable error.
- History determines session totals, focus minutes, calendar-day streaks, weekly charts and garden stages. Day ordinals use UTC representations of local date components to avoid 23/25-hour DST-day arithmetic. Current streak accepts yesterday; best streak uses distinct consecutive dates.
- Achievements persist their first unlock date; normal transactions never unlock them twice. Lifetime task milestones count distinct task IDs ever completed. Current-task completion percentage uses the current list, while the statistics overview reports lifetime task completions.
- Reused entrance animations use `CurveTween` rather than allocating subscribed `CurvedAnimation` instances on each build. Add-task dialog and garden/stats painters were extracted. Hidden navigation pages have disabled tickers and separate repaint boundaries. Reduced-motion entrance content stays visible.

## Reset semantics

| Action | Clears | Keeps |
| --- | --- | --- |
| Tasks | Current tasks | Earned XP, task milestones, receipts, badges |
| Focus history | Session history and active timer | Earned XP, receipts, badges |
| XP/progress | XP and level | Tasks, history, receipts, badges |
| All data | All application state, reminders and legacy preference keys | Nothing from the previous account |

Individual resets deliberately do not make old rewards claimable again. Full reset intentionally shows onboarding again.

## Reminders

Android and iOS use small native MethodChannel implementations, avoiding a new plugin dependency. Permission is requested only when a reminder is enabled. Android uses inexact alarms, rescheduling against the local calendar after delivery/reboot/time-zone/time changes. No exact-alarm permission is requested. iOS uses calendar notification requests. The daily reminder repeats; the streak reminder is scheduled for the day after the latest completed focus date and replaced when activity changes. Unsupported desktop/web platforms show an explanation and disabled reminder switches.

A completion sound/haptic is in-app feedback. This implementation does not promise a timer-completion notification while the OS has suspended/terminated the app. The completed session and its reward are reconciled when execution resumes. Reminder delivery timing is subject to OS power and notification settings.

## Persistence limits

The single-document approach prevents partial reward/event writes and serializes mutations within the app's one repository instance. SharedPreferences is device-local storage, not an ACID database or a cloud backup; abrupt power loss and platform write failures cannot be eliminated. Unreadable documents are not silently replaced. This is a single-user, single-app-process architecture; multi-process/multi-tab synchronization is outside its scope.
