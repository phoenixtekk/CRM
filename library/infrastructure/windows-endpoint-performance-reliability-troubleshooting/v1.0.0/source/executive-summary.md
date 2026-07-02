# Executive Summary

## The business problem

"My computer is slow." "It keeps crashing." These are the most common — and most expensive — end-user
tickets, precisely because no one can quantify them. They get closed with a reboot or a costly
reimage, the user loses productive hours, and the problem returns. Multiply that across a fleet and
unmeasured performance and reliability issues become a steady, invisible drain on both IT time and
workforce productivity.

## The solution

A **measure-first root-cause method** for Windows endpoint performance and reliability in an
enterprise, Intune-managed fleet. Instead of guessing, you follow a repeatable loop — **measure it,
isolate it, fix it, re-measure it** — that turns a vague complaint into a specific, measured cause and
a targeted fix.

The method covers the full endpoint lifecycle where slowness and instability actually live:

- **Slow boot** — measured boot timing and the exact slow driver/service behind it.
- **Slow sign-in / profile** — measured sign-in duration, profile size, and startup-app load.
- **High CPU / RAM / disk** — steady-state resource pressure with the named process responsible.
- **Crashes / bugchecks** — system Stop codes and repeat-offending applications, from the event record.
- **Storage / SSD health** — failing, worn, or full drives caught before they take a machine down.

## What is included

- A **Solution Overview** defining the performance/reliability model, the signals to measure, and the
  root-cause tree.
- A **Requirements Guide** with a verify step for every prerequisite.
- A **Diagnostic Playbook** — the symptom tree with exact measurements and pass/fail gates per branch.
- **Five PowerShell scripts** — signal discovery, per-device measurement validation, a fleet report,
  safe remediation of the common causes (startup, temp, profile), and a scoped-targeting builder.
  Discovery/Validation/Report are read-only; Remediation and targeting default to a safe preview.
- **Testing** (measured pass/fail gates), **Troubleshooting**, and **Best Practices** for baselining
  and repeatable triage.

## The outcome

A slow or crashing endpoint becomes a **measured cause and a targeted fix** — with a repeatable,
evidence-based method and scripts the team keeps and reuses. Tickets close on facts, not guesses;
hardware is replaced only when the numbers prove it; and a rising fleet trend is caught before users
complain. Self-guided and tested, at a fraction of the cost of an outside engagement.
