# Testing Guide

Testing an egress allow-list has two layers: **(1) reachability** — each required destination is
allowed through the filter on its required port(s); and **(2) real-workflow success** — the things
that were failing (enrollment, sync, update) now work end to end. An allow-list can pass reachability
and still miss a workflow if a needed endpoint was mis-scoped, so **both layers must pass** before you
expand.

Every gate below is **pass/fail**. Run the reachability tests from a device that sits **behind the
same filter** as the managed fleet — testing from an unfiltered admin box proves nothing.

---

## Gate T1 — Required-set derived correctly

**Test:** Open `egress-required-set.json` (from `EGRESS-Discovery.ps1`).
**Pass:** It contains the M365 endpoints for the **correct instance**, all entries marked
**required = true** and all **Optimize/Allow** categories are present, and the Intune / Autopilot /
Defender section is present.
**Fail:** Wrong instance, missing required/Optimize/Allow entries, or missing the Intune/Defender
section → re-run Discovery with the correct `-Instance` and re-check.

---

## Gate T2 — Per-endpoint reachability (the core reachability gate)

**Test:** From a pilot device, run `EGRESS-Validation.ps1` against `egress-required-set.json`.
**Pass:** **Every** required endpoint returns **reachable** on its required port(s) (TCP connect / TLS
handshake / HTTP response succeeds). Result file shows zero failures in the required set.
**Fail:** Any required endpoint is unreachable → that endpoint is not allowed (or is being decrypted
when it must be bypassed). Note the failing URL/IP+port, fix the allow-list (Implementation Phase 2),
and re-test.

---

## Gate T3 — Coverage / gap report clean

**Test:** Run `EGRESS-Report.ps1`; open `egress-coverage-report.html`.
**Pass:** **Zero gaps** in the required + Optimize + Allow set (every required endpoint is both present
in the allow-list and reachable).
**Fail:** Any required-set gap listed → add the missing entry and re-run T2/T3.

---

## Gate T4 — Enrollment / Autopilot succeeds

**Test:** Enroll (or run Autopilot provisioning on) a pilot device that reaches the internet **only**
through the filtered egress path.
**Pass:** The device completes Entra device registration and Intune enrollment (or Autopilot completes
to the desktop) with no network-caused stalls or timeouts.
**Fail:** Enrollment stalls or errors → use the Troubleshooting Guide to map the stall to the missing
endpoint (device-registration / enrollment / identity), add it, and re-test.

---

## Gate T5 — Policy / compliance sync succeeds

**Test:** On the enrolled pilot device, force an Intune sync (Company Portal / Settings sync, or
`Sync` from the Intune admin center) and confirm assigned configuration/compliance/app policies land.
**Pass:** The device check-in completes and assigned policies apply; Intune shows the device syncing
and reporting status (not stuck "pending").
**Fail:** Sync never completes or policies stay pending → the device-management check-in endpoint is
likely blocked; add it and re-test.

---

## Gate T6 — Update / app delivery succeeds

**Test:** Trigger a Windows Update check and an Intune app install on the pilot device.
**Pass:** Update detection/download and the app install both complete (content downloads succeed).
**Fail:** Update or content download hangs/fails → a content/update endpoint is blocked; add it and
re-test.

---

## Gate T7 — Defender cloud protection reachable (if in scope)

**Test:** On the pilot device, confirm Defender cloud-delivered protection is active/connected.
**Pass:** Defender reports cloud protection connected and reachable.
**Fail:** Defender cloud protection cannot reach its service → add the Defender endpoints and re-test.

---

## Gate T8 — Drift check operates

**Test:** Run the keep-current Discovery with `-BaselineVersionPath` (Implementation Phase 6).
**Pass:** The version comparison runs, correctly reports "no change" or produces a delta, and the
delta (if any) can be previewed via `EGRESS-Remediation.ps1`.
**Fail:** The drift check errors or does not detect a known change → fix the scheduled job / baseline
path before relying on it.

---

## Overall exit criteria (before Expand)

All of the following on the pilot, behind the real filter:

- **T1–T3** pass: required set correct, every required endpoint reachable, zero coverage gaps.
- **T4–T6** pass: enrollment/Autopilot, policy sync, and update/app delivery all succeed.
- **T7** passes if Defender is in scope.
- **T8** passes: the drift check is working.

Only when all applicable gates pass do you proceed to fleet **Expand** (Implementation Phase 5).
