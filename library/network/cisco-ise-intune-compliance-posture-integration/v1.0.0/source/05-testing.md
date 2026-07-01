# Testing

Validate the integration with explicit **pass/fail gates** before you expand beyond the pilot.
The core principle of this solution: **compliant → access granted; non-compliant → access
denied.** Both directions must be proven.

Run these tests against `PILOT – ISE Posture Devices` only. Record the result of each gate.

---

## Gate 1 — Connector readiness

**Goal:** ISE can authenticate to Entra and read Intune device state.

**Steps:**
1. Run `ISEPOST-Discovery.ps1`. Confirm the app registration
   `ISE-Intune-Compliance-Connector` exists, has a valid (unexpired) secret, and shows the
   Graph permissions `DeviceManagementManagedDevices.Read.All` and
   `DeviceManagementConfiguration.Read.All` **admin-consented**.
2. In the ISE console, run **Test Connection** on the External MDM (Intune) server (per Cisco's
   documentation).

**Pass:** Discovery reports the app, valid secret, and consented permissions; ISE Test
Connection succeeds.
**Fail:** Missing/expired secret, un-consented permission, or ISE Test Connection error → see
Troubleshooting.

---

## Gate 2 — Compliance policies present and evaluating

**Goal:** The named baseline policies exist, are assigned to the pilot, and Intune is producing
a compliance verdict per device.

**Steps:**
1. Run `ISEPOST-Discovery.ps1` and confirm the baseline policies
   (`Compliance – Windows – Baseline`, `Compliance – iOS – Baseline`,
   `Compliance – Android – Baseline`, `Compliance – macOS – Baseline`) are present and assigned
   to `PILOT – ISE Posture Devices`.
2. Intune → **Devices → Compliance** and confirm pilot devices show a computed compliance
   state (compliant / non-compliant / in grace), not "not evaluated."

**Pass:** All target-platform baseline policies exist, assigned to pilot, with devices
evaluating.
**Fail:** A policy missing/unassigned, or devices stuck "not evaluated" → see Troubleshooting.

---

## Gate 3 — Compliant device is GRANTED access (the positive path)

**Goal:** A healthy, enrolled pilot device gets full network / VPN access.

**Steps:**
1. Pick a pilot device that is **enrolled** and **compliant**. Confirm with
   `ISEPOST-Validation.ps1` on that device (it reports enrollment + compliance as ISE reads it).
2. Have the device connect through an ISE-mediated path (VPN, wired 802.1X, or wireless).
3. Confirm in ISE **Live Logs** that the authorization result is the **permit / full-access**
   profile and the device reaches the network.

**Pass:** Enrolled + compliant device → **access granted**, permit profile in Live Logs.
**Fail:** A compliant device is denied → see Troubleshooting ("compliant device denied").

---

## Gate 4 — Non-compliant device is DENIED access (the critical path)

**Goal:** Prove the gate actually enforces. This is the gate that justifies the whole solution.

**Steps:**
1. Take a pilot device and deliberately make it non-compliant against its baseline policy — for
   example **turn off disk encryption** (BitLocker / FileVault) or let it fall below the OS
   floor.
2. Force an Intune sync and confirm Intune now marks it **non-compliant**. Confirm with
   `ISEPOST-Validation.ps1` that the device reads as non-compliant.
3. Have the device connect through the ISE-mediated path.
4. Confirm in ISE **Live Logs** that the authorization result is the **deny / quarantine /
   remediation** profile and the device does **not** get full access.

**Pass:** Non-compliant device → **access denied or quarantined**. **This gate must pass.**
**Fail:** A non-compliant device still gets full access → **stop the rollout** and see
Troubleshooting ("non-compliant device allowed").

---

## Gate 5 — Unmanaged device is DENIED / redirected

**Goal:** A device that is not enrolled in Intune is treated as unmanaged.

**Steps:**
1. Attempt to connect with a device that is **not enrolled** in Intune.
2. Confirm in ISE Live Logs the authorization result is **deny** or **enrollment redirect**,
   not full access.

**Pass:** Unmanaged device → denied or redirected to enrollment.
**Fail:** Unmanaged device granted full access → see Troubleshooting.

---

## Gate 6 — Fleet coverage snapshot

**Goal:** Understand compliance coverage and the conceptual access decision across the pilot
before expanding.

**Steps:**
1. Run `ISEPOST-Report.ps1` and review the compliance-coverage + conceptual access-decision
   report (how many devices would be granted vs denied).

**Pass:** Coverage is understood; the granted/denied split matches expectations.
**Fail:** Unexpected large denial population → investigate compliance policy scope / grace
before expanding.

---

## Exit criteria to expand

Proceed to **Expand** only when **Gates 1–5 all pass** — in particular **Gate 3 (compliant →
granted)** and **Gate 4 (non-compliant → denied)** — and the Gate 6 coverage report looks sane.
Keep the rollback (R7) available through expansion.
