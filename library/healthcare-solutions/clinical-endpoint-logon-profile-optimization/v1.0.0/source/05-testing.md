# 5. Testing — Clinical Endpoint Logon & Profile Performance Optimization (FSLogix)

This document is the validation plan. Run it against the pilot endpoints (group `Clinical – Logon Optimization – Pilot`) in the **Validate (measure)** phase, and on a sample of each wave during **Expand**. Each test has a **procedure**, an **expected result**, and a **PASS/FAIL** record. The **acceptance gate** at the end must be fully met before fleet expansion. Run all tests with **test accounts and test data only** — never use real PHI.

> Names referenced below are the exact objects from `03-implementation.md`: the Win32 app `FSLogix Agent – Clinical Endpoints – Deploy`, the device group `Clinical – Logon Optimization` (pilot subset `Clinical – Logon Optimization – Pilot`), the settings profiles `FSLogix Profile – Clinical Endpoints – Container` and `Fast Logon – Clinical Endpoints – Tuning`, and the profile share `Clinical Profiles – FSLogix – Share`.

---

## T1 — Logon time reduced vs. baseline by the target

- **Procedure:** On a pilot endpoint, sign in as a test clinician and measure usable-desktop logon time and profile load time using the same method as the Phase 1 baseline (run `CLINLOGON-Set-FSLogixBaseline.ps1` or `CLINLOGON-Report.ps1`). Compare against the recorded baseline.
- **Expected result:** Logon time is reduced versus the baseline by **at least the target reduction agreed in Phase 1** (e.g., ≥ 50% / under N seconds). The improvement is consistent across repeated sign-ins (not just a warm-cache one-off).
- **Result:** ☐ PASS ☐ FAIL — notes: baseline ___s → measured ___s (___% reduction) ______________________

## T2 — Agent installed and configuration applied

- **Procedure:** In `Apps > All apps > FSLogix Agent – Clinical Endpoints – Deploy > Monitor`, confirm the pilot device shows **Installed**. In `Devices > Configuration`, confirm `FSLogix Profile – Clinical Endpoints – Container` and `Fast Logon – Clinical Endpoints – Tuning` both show **Succeeded** for the device. On the device, confirm the FSLogix registry settings (`HKLM\SOFTWARE\FSLogix\Profiles`) reflect the configured values.
- **Expected result:** Agent reports **Installed**, both profiles report **Succeeded**, and the on-device settings match `03-implementation.md`.
- **Result:** ☐ PASS ☐ FAIL — notes: ______________________

## T3 — Profile container created and attaches

- **Procedure:** Sign in as a test clinician. On the profile share `Clinical Profiles – FSLogix – Share`, confirm a per-user container folder (e.g., `%username%_%sid%`) was created and contains a `.VHDX`. On the endpoint, confirm the container is **attached** (a mounted profile disk) and that no "signed in with a temporary profile" message appeared.
- **Expected result:** The per-user VHD(X) exists on the share, attaches at sign-in, and the clinician gets their real (not temporary) profile.
- **Result:** ☐ PASS ☐ FAIL — notes: ______________________

## T4 — Profile roams across shared endpoints

- **Procedure:** As the same test clinician, make a visible profile change (e.g., a desktop/setting change), sign out, then sign in on a **different** pilot endpoint (or AVD host).
- **Expected result:** The same FSLogix container attaches on the second endpoint and the change is present — one roaming profile follows the clinician across shared devices.
- **Result:** ☐ PASS ☐ FAIL — notes: ______________________

## T5 — No profile corruption; container size controlled

- **Procedure:** Over the pilot period, repeatedly sign in/out as test clinicians across endpoints. Inspect the container for corruption symptoms (failed attach, ESENT/Profile Service errors, runaway size). Check the VHD(X) size against the agreed R7 per-container target and confirm the redirections/exclusions are keeping volatile/cache data out.
- **Expected result:** No profile corruption or temporary-profile fallback across the pilot; container size stays within the agreed target because excluded caches are not stored in the VHD(X).
- **Result:** ☐ PASS ☐ FAIL — notes: container size ___ MB (target ___ MB) ______________________

## T6 — Session stable

- **Procedure:** During a normal clinical workflow on a pilot endpoint, run the EHR/clinical web apps and Office through a representative session; sign out cleanly and confirm the container **detaches**.
- **Expected result:** The session is stable for the workflow duration with no profile-related crashes or hangs, and the container detaches cleanly on sign-out (no orphaned/locked VHD(X) left on the share).
- **Result:** ☐ PASS ☐ FAIL — notes: ______________________

## T7 — Fast user switch / tap-and-go works (where Imprivata is present)

- **Procedure:** On an endpoint that also runs Imprivata tap-and-go, sign in test clinician A (tap in), then have test clinician B tap in per the agreed session model (R9). Repeat the A→B→A cycle a few times in quick succession.
- **Expected result:** On tap-out/switch, clinician A's container detaches cleanly and clinician B's container attaches without a locked-VHD or temporary-profile error; rapid switching does not orphan a container. (On endpoints without Imprivata, validate the equivalent fast Windows switch/sign-out behavior.)
- **Result:** ☐ PASS ☐ FAIL — notes: ______________________

## T8 — Negative / failure handling

- **Procedure:** (a) On a test endpoint, temporarily simulate the profile share being unreachable (with storage-team coordination) and attempt sign-in. (b) Sign in a user **not** granted by the share permissions (R2/R8) and observe.
- **Expected result:** (a) The endpoint degrades predictably — either a clear failure/retry rather than a silent corrupt profile — and recovers when the share returns. (b) The ungranted user does not silently corrupt or attach another user's container; the failure is clear and attributable.
- **Result:** ☐ PASS ☐ FAIL — notes: ______________________

---

## Acceptance gate

The deployment is accepted for fleet expansion **only when all of the following are true**:

- **T1** Logon time reduced vs. baseline by the agreed target — PASS
- **T2** Agent installed and both configuration profiles applied — PASS
- **T3** Profile container created and attaches (no temporary profile) — PASS
- **T4** Profile roams across shared endpoints — PASS
- **T5** No profile corruption; container size within target — PASS
- **T6** Session stable; container detaches cleanly — PASS
- **T7** Fast user switch / tap-and-go works (where Imprivata is present) — PASS
- **T8** Negative / failure handling behaves safely — PASS
- **Change control / compliance sign-off (R10)** recorded for the profile-storage and sign-on changes.

Record the gate decision, date, tester, approver, and the measured baseline→after logon figures. Any FAIL blocks expansion until remediated (see `06-troubleshooting.md`) and re-tested.
