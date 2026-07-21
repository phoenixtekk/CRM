# 7. Best Practices — Proactive Remediations at Scale (Detection & Remediation Script Packs for Microsoft Intune)

Field-proven guidance for running auto-remediation at fleet scale **without** turning it into an
auto-outage.

## Authoring the pair
- **Detection observes; remediation acts — never blur them.** A detection script must be **read-only
  and idempotent**, reaching the same verdict every run and reporting **only** through its exit code
  (`exit 0` healthy / `exit 1` issue). A detection that "fixes while it checks" hides what the
  remediation did and breaks the model.
- **Make remediation minimal.** Change the **smallest possible thing** that resolves exactly the
  detected condition, then stop. No opportunistic extras — every extra action is extra blast radius.
- **Preview before you act — always.** Prove a new remediation in **dry-run/preview** (it logs what
  it *would* change without changing it) and read the log before you ever let it act. The included
  remediation template **defaults to preview** for exactly this reason.
- **Honor the exit-code contract.** `exit 0` = success/healthy; `exit 1` = issue/failed. Don't invent
  other codes to signal state — the console interprets non-zero detection as "run remediation" and
  reads remediation exit codes as success/fail.
- **Match the run context to the target.** Machine/HKLM/service pairs run as **system**; user-hive/
  HKCU/profile pairs run in the **logged-on user's** context. The wrong context runs but changes
  nothing.
- **Log on-device.** Write a timestamped line to a predictable path (e.g.
  `C:\ProgramData\Remediations\`) so every action has local evidence, independent of console
  reporting delays and truncation.

## Deploy & scope
- **Pilot ring first, every time.** Assign new/edited pairs to `PILOT – Remediations – Devices` and
  prove them before production — no exceptions.
- **Seed a test issue.** Deliberately break the target condition on one pilot device so you can prove
  detection catches it and remediation fixes it, and keep a healthy device as the negative test.
- **Widen in waves.** Fill `Remediations – Windows – Production` gradually; never point a new or
  changed remediation at the entire fleet at once.
- **Keep the schedule conservative.** Start Daily; only tighten cadence when the trend is clean.
  Faster is not better if a bad fix runs more often.

## Operate safely
- **Watch for loops.** If the same devices report *Issue remediated* every cycle, the fix isn't
  holding or detection is over-firing — **pause the assignment** and investigate before it churns the
  fleet.
- **Re-detect to prove, don't assume.** Treat the post-remediation *Without issue* result as your
  evidence; if it doesn't hold, the pair isn't done.
- **Keep an off switch and a reverse.** You can **unassign** a package to stop it instantly; for
  impactful changes, author a paired **revert** remediation before deploying the forward one.
- **Report on the trend.** Export detection/remediation success-fail regularly with
  `PROREM-Report.ps1`; a downward "with issue" trend is proof the practice is working.

## Govern the library
- **Name everything by intent.** Use `PROREM – <Area> – <Target> – <Stage>` across the library, the
  console package, assignments, testing, and troubleshooting so packs are identifiable and auditable.
- **Version and changelog every pack.** Know exactly which version is live and what changed.
- **Require a second-admin review + approval to act.** A remediation reaches production only after
  another admin reviews the source and confirms it was proven in preview + pilot.
- **Reuse proven packs.** Start the next recurring issue from an existing proven pack — the governed
  library is how the practice compounds instead of restarting each time.
- **Retire deliberately.** When an issue is designed out or a pack is superseded, unassign and
  archive it (with a note) rather than leaving stale automation running.
