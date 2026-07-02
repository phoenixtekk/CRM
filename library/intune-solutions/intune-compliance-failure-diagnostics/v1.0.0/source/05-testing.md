# Testing & Validation

A compliance diagnosis is only "done" when three gates all pass, in order:
**the failing setting now passes → the device is reported compliant → Conditional Access
allows the user.** Test each gate explicitly; do not stop at the first green.

Run the checks from the same surfaces you diagnosed from, and confirm with the scripts so
the result is not just a stale console.

---

## Gate 1 — The failing setting passes

**Goal:** the specific setting that failed now reports **Compliant** (not just the device
overall).

**Steps:**
1. Force a re-evaluation on the device (Sync), then wait for the next check-in and report.
2. Intune → **Devices → All devices → <device> → Device compliance** → expand the policy →
   confirm the previously failing **setting** now shows **Compliant** (state, not just
   absence of an error).
3. Script check: `INTCOMPDX-Validation.ps1 -DeviceName "<device>"` returns **no** failing
   settings for that device (empty failure set for the policy).

| Result | Meaning |
|--------|---------|
| **PASS** | The named setting reports **Compliant**; validation returns no failures. |
| **FAIL** | The setting still shows **Not compliant** or **Error** → return to Diagnostic Playbook Step 3 (real failure) or Step 3B (evaluation error). |

---

## Gate 2 — The device is compliant

**Goal:** the **device-level** compliance state is **Compliant**, and grace is not masking a
still-failing setting.

**Steps:**
1. Intune → **Devices → All devices → <device>** → the device state shows **Compliant**.
2. Confirm this is a *real* pass, not a *grace* pass: re-check **Actions for noncompliance**
   (Playbook Step 4) — the device should be compliant because the setting passed, not
   because it is still inside a grace window.
3. Script check: `INTCOMPDX-Discovery.ps1 -DeviceName "<device>"` shows the device
   **Compliant** with no settings in a failing/grace state.

| Result | Meaning |
|--------|---------|
| **PASS** | Device state is **Compliant** on its own merits (no failing setting hiding under grace). |
| **FAIL** | Device still **Not compliant**, or compliant only because grace has not expired → the underlying setting is not fixed; return to Step 3. |

---

## Gate 3 — Conditional Access allows the user

**Goal:** the user can actually sign in to the protected resource — the block is gone.

**Steps:**
1. Have the user **sign out and sign back in** (or wait for token refresh) so CA re-reads
   the fresh compliant state.
2. Entra → **Monitoring & health → Sign-in logs** → filter by the user → open the latest
   sign-in → **Conditional Access** tab → the **Require compliant device** control now shows
   **Success** for the relevant policy.
3. Confirm the user reaches the resource that was previously blocked.
4. Script check: `INTCOMPDX-Report.ps1` shows the device no longer counted against the
   compliance-requiring CA policies (blast radius reduced by one).

| Result | Meaning |
|--------|---------|
| **PASS** | Sign-in log shows the compliance control **Success**; user reaches the resource. |
| **FAIL** | CA control still **Failure** → if the device is compliant, it is **timing** (stale token/read): re-sign-in and re-test; if it persists, re-check which CA policy is in scope (Playbook Step 5). |

---

## Regression / safety checks

Because the cardinal rule is **do not loosen policy fleet-wide**, verify you did not widen
exposure while fixing one device:

- **No fleet-wide disable:** the compliance policy is still **assigned and enabled** for its
  original groups (you fixed the cause, not the policy). `INTCOMPDX-Discovery.ps1` should
  show the policy unchanged in scope.
- **Staged change stayed staged:** any grace/targeting change went only to the **pilot
  group** first. `INTCOMPDX-Set-ScopeTargeting.ps1 -WhatIf` re-run shows the intended
  assignment and no unexpected broader targeting.
- **Fleet trend moved the right way:** re-run `INTCOMPDX-Report.ps1` — the non-compliant
  count for the fixed setting decreased; no *new* setting started failing as a side effect.

---

## Overall pass criteria

The diagnosis is complete when **all three gates PASS and the regression checks hold**:
the exact setting passes, the device is genuinely compliant, Conditional Access grants
access, and no policy was disabled or loosened for the fleet to get there.
