# Diagnostic Playbook

This is the symptom-driven decision tree for a compliance failure. Work it **top to
bottom** — each step narrows the cause before you touch anything. The golden rule runs
through every branch: **read the exact per-setting failure first, understand timing and
grace, measure the Conditional Access blast radius, then remediate the smallest thing.
Never disable or loosen a compliance policy fleet-wide to unblock one device.**

Run the scripts alongside the clicks — the console tells you *what*, the scripts give you
the raw reason string and the fleet/CA context so you are never guessing.

---

## Step 0 — Frame the symptom

Before diagnosing, write down what the user actually experiences. Pick the entry symptom:

- **A. A specific device is non-compliant** → start at Step 1.
- **B. "It worked yesterday, blocked today," no change made** → likely **grace expiry**;
  jump to Step 4 after confirming the setting in Step 1–2.
- **C. Many devices failed the same setting at once** → likely a **policy/setting change or
  a service-side shift**; do Step 1–3 on one device, then use the fleet view (Step 6).
- **D. User is blocked but device shows compliant** → this is a **Conditional Access /
  timing** problem, not a setting failure; jump to Step 5.

---

## Step 1 — Which setting failed? (read per-setting state)

**Never trust "non-compliant" alone.** Find the exact failing setting.

1. Intune → **Devices → All devices → <device>**.
2. Open **Device compliance**. Each assigned compliance policy is listed with its state.
3. **Expand the failing policy.** You now see the **per-setting** state: each setting shows
   **Compliant / Not compliant / Error / Not applicable**, plus a **failure reason** on the
   ones that failed.
4. Record the exact policy name (for example `Win-Baseline-Compliance`), the exact failing
   **setting name**, its **state**, and the **reason string** verbatim.

Run in parallel: `INTCOMPDX-Validation.ps1 -DeviceName "<device>"` returns the same
per-device, per-setting failure with the raw reason from Graph — copy that string; it is the
authoritative text.

**Branch on the state:**

- State **Not compliant** with a reason → a real setting failure → **Step 2**.
- State **Error** → the setting could not be evaluated (agent/script/permission problem),
  not necessarily a real failure → **Step 3B**.
- State **Not applicable** on a setting you expected to enforce → targeting/OS mismatch →
  **Step 3A**.
- No failing setting visible but device still non-compliant → **timing** → **Step 5**.

---

## Step 2 — Is it timing, or a real failure?

A device can *report* a failure that is already fixed but not yet re-evaluated.

1. Note the **Last check-in** / **Last compliance report** time on the device blade.
2. If the reported failure is older than the last on-device change, force a re-evaluation:
   device **Settings → Accounts → Access work or school → <account> → Info → Sync**, or
   Intune **device → … → Sync**.
3. Wait for the next check-in (minutes, not instant — see Overview timing), then re-read
   Step 1.

- Failure **clears** after sync → it was **stale reporting**; done, confirm CA in Step 5.
- Failure **persists** after a fresh check-in → it is a **real setting failure** →
  continue.

Now split by rule type:

- The failing setting is a **built-in** setting (BitLocker, Secure Boot, Minimum OS
  version, Firewall, Antivirus, Defender signatures, password/PIN) → **Step 3A**.
- The failing setting is a **Custom compliance** result (a policy that references a
  **Custom compliance script** + JSON) → **Step 3B**.

---

## Step 3A — Built-in setting failed

Confirm the real state **on the device**, because a built-in setting reflects an actual OS
condition:

- **BitLocker / Encryption:** on the device run `manage-bde -status` (or check **Settings →
  Privacy & security → Device encryption**). If the OS drive is **not** fully encrypted /
  protection is **off**, the failure is genuine — the fix is to encrypt, not to remove the
  setting.
- **Secure Boot / TPM:** `msinfo32` → **Secure Boot State = On**, **TPM** present and ready.
  Hardware/firmware condition — fix in UEFI/enable TPM.
- **Minimum OS version:** the device build is below the policy's floor. Fix = **patch/update
  the device** (Update rings), not lower the floor.
- **Firewall / Antivirus / Defender signatures:** confirm the service is running and
  signatures are current (`Get-MpComputerStatus`). Restart the service / update signatures.
- **Password / PIN complexity:** the device's local policy does not meet the rule; fix the
  device-side setting.

Read the exact policy floor and setting definition with
`INTCOMPDX-Discovery.ps1 -PolicyName "<policy>"` so you compare the device's real value
against the **exact** configured requirement.

Now check grace before deciding urgency → **Step 4**. Safe fixes for the common built-in
failures are in `INTCOMPDX-Remediation.ps1` (default **-WhatIf**).

---

## Step 3B — Custom compliance rule, or an "Error" state

**Custom compliance** = a compliance policy that runs a **Custom compliance script**
(PowerShell) whose output is matched against a **JSON rule file** (the discovered settings,
operators, and remediation strings you authored). It fails differently from built-ins:

1. In the failing policy, confirm it is a **Custom compliance** policy and note the
   referenced **script** name and the **JSON** rule that failed (the per-setting reason
   shows the rule's *SettingName* and often your authored **RemediationString**).
2. On the device, run the same **detection** the script performs to see the real returned
   value; compare it to the **operator + value** in the JSON rule.
3. Decide which is wrong:
   - The **device value** genuinely fails the rule → real failure, fix the device.
   - The **rule/JSON** is wrong (bad operator, wrong data type, typo in *SettingName*) →
     the *policy* is faulty; fix the JSON/script and re-upload (stage via **Step 7**, do
     **not** delete the policy fleet-wide).
   - State is **Error** (not "Not compliant") → the script did not return valid JSON, timed
     out, or the agent could not run it. This is an **evaluation** failure, not a
     compliance verdict: check the script's exit/output on the device, script signing, and
     the Intune management extension health. Fix the script/agent; the setting cannot be
     "compliant" until it evaluates cleanly.

`INTCOMPDX-Validation.ps1` flags Custom vs built-in and surfaces the Error state so you do
not mistake an evaluation error for a real failure.

---

## Step 4 — Has the grace period expired?

Grace decides whether a *failed* setting is actually *enforced* yet.

1. Intune → **Devices → Compliance → <policy> → Properties → Actions for noncompliance**.
2. Read the **Mark device noncompliant** schedule: **Immediately (0 days)** = no grace;
   `N days` = a grace window.
3. Compare **when the setting first failed** (from the device's compliance history) against
   the grace window:
   - Still **within grace** → the device is failing a setting but is **reported compliant**
     to CA; the user is **not** blocked yet. You have `N days` to fix the real setting
     (Step 3). Do **not** extend grace to hide it.
   - Grace **expired** → the device is now **Not compliant** and CA will act. Fix the real
     setting (Step 3) and let it re-evaluate; only consider a *temporary, pilot-scoped*
     grace extension if the fix legitimately needs more time (Step 7).

Symptom B ("worked yesterday, blocked today," no change) is almost always a **grace expiry
of a setting that had been failing quietly** — Step 1 will show the setting, Step 4 confirms
the clock ran out.

`INTCOMPDX-Discovery.ps1` reports each policy's grace configuration so you can see at a
glance which policies enforce immediately versus with a window.

---

## Step 5 — What does Conditional Access do about it? (blast radius)

Now measure impact — *who* is blocked and *by which* policy.

1. Entra → **Protection → Conditional Access → Policies**. Identify every **enabled** policy
   with the grant control **Require device to be marked as compliant** (or a device-filter
   requiring compliance). Note each policy's **Users/groups**, **Target resources**
   (cloud apps), and **conditions**.
2. Determine whether the affected user/device is **in scope** of one of those policies — if
   not, a non-compliant device may not actually be blocked (the block is coming from
   somewhere else).
3. Entra → **Monitoring & health → Sign-in logs** → filter by the user. Open a failed
   sign-in → **Conditional Access** tab → find the policy whose result is **Failure** and
   confirm the failing control is **Require compliant device**. This proves CA is the block
   and names the exact policy.
4. If the device **reports compliant** but CA still blocks → it is **timing**: CA read a
   stale state or the user's token predates the fix. Have the user **sign out and back in**
   (or wait for token refresh) after the device reports compliant.

`INTCOMPDX-Report.ps1` produces the fleet compliance summary **plus** the CA-impact view
(which compliance-requiring CA policies exist and how many affected devices they touch), so
you can state the blast radius precisely before remediating.

---

## Step 6 — Fleet pattern (many devices, same setting)

If the failure is widespread (Symptom C):

1. Intune → **Devices → Compliance → <policy> → Per-setting status** to see which single
   setting is failing across many devices.
2. Ask what changed: a **policy edit** (new/tightened setting), a **service-side** shift
   (updated Defender platform, new OS floor), or a **broken Custom compliance script/JSON**
   pushed to everyone.
3. Fix the **cause**, staged to the pilot group first (Step 7) — do not mass-exempt devices
   or disable the policy.

`INTCOMPDX-Report.ps1` ranks settings by failure count so you spot the one setting driving
the fleet number.

---

## Step 7 — Remediate safely (never fleet-wide-disable)

Choose the **smallest** action that fixes the **cause**:

- **Real device failure** (BitLocker off, firewall stopped, out-of-date signatures, low OS
  build): fix on the device / push the enabling policy; let it re-evaluate.
  `INTCOMPDX-Remediation.ps1` performs the safe common fixes and defaults to **-WhatIf** —
  review the planned action, then re-run with `-WhatIf:$false` to commit.
- **Faulty rule/JSON or script** (Custom compliance): correct the rule/script and stage the
  updated policy to the **pilot group** first.
- **Grace genuinely too short** for a legitimate fleet-wide fix: adjust grace on a
  **pilot-scoped** assignment, validate, then expand — never blanket-extend to mask a real
  failure.
- **Targeting change** (a device should not have been in scope): use
  `INTCOMPDX-Set-ScopeTargeting.ps1` to move the affected device(s) to the correct pilot/
  target group. It defaults to **-WhatIf** and shows the assignment change before applying.

After any change, **confirm the loop closes** (Step 5): device re-evaluates → reports
compliant → CA re-reads → user regains access. Re-run the report to prove the fleet number
moved in the right direction. Verification gates are in `05-testing.md`.
