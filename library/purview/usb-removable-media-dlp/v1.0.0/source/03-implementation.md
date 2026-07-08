# Implementation Guide — USB & Removable-Media DLP in Microsoft Purview

This is the ordered, do-it-in-this-sequence guide. It follows the standard model —
**Assess → Design → Configure → Pilot (simulation/audit) → Validate → Expand (enforce)** — with every
object **named**, an explicit **pass/fail gate** at each phase, and a **rollback** for each change.
Do **not** skip the simulation/audit phase; removable-media block and read-only actions are
high-impact.

**The two control layers you are delivering:**

| Layer | Keys on | Controls | Built where |
|---|---|---|---|
| **Endpoint DLP — removable media** | **Content** (label / SIT) | *Copy a matching file to removable/USB storage* — Audit / Warn / Block, except the corporate device group | **Purview → Data Loss Prevention** (Devices location, removable-media restriction) |
| **Device control — removable-storage access** | **Device** (device group) | **Read / Write / Execute** on removable storage — Allow / Audit / Block by device group | **Management tooling** (Intune / GPO / OMA-URI) — **verify surface for your tenant** |

**Named objects used throughout (rename to your convention, but be consistent):**

| Object | Name used here |
|---|---|
| Endpoint DLP policy | `EDLP-USB-Pilot` |
| Removable-media rule | `EDLP-Rule-USB` |
| Device-control policy (management tool) | `DC-RemovableStorage-Pilot` |
| Corporate removable-media device group | `USBG-Corporate` |
| Pilot device group | `DG-USB-Pilot` |
| Pilot user group | `SG-USB-Pilot` |

> **Tooling note.** Endpoint **device onboarding** and the **removable-storage device groups** are
> configured in the **Purview portal** — there is no supported Security & Compliance PowerShell cmdlet
> to *onboard* a device or to *deploy* a device-control policy. The DLP **policy and rule** can be
> authored in the portal **or** with `New-/Set-DlpCompliancePolicy` and `New-/Set-DlpComplianceRule`;
> the provided `DLPUSB-Configure.ps1` builds them in **simulation** with `-WhatIf` by default. The
> **device-control policy** is deployed through your management tooling — the scripts *report* on
> it, they do not push it. **Verify every portal path and cmdlet parameter against your tenant** — the
> portal and the removable-media restriction parameter names evolve.

---

## Phase 0 — Assess (confirm you are ready)

1. **Confirm requirements.** Walk `02-requirements.md` R1–R9. Do **not** proceed until licensing,
   roles, supported devices, an onboarding method, in-scope sensitive content, the removable-storage
   device group plan, the device-control surface, the per-layer action decision, and a pilot group
   are all confirmed.
2. **Run Discovery.** `Connect-IPPSSession`, then `.\DLPUSB-Discovery.ps1` to inventory existing DLP
   policies/rules, the **Devices** coverage, sensitivity labels, and SITs. Keep the CSV as your
   baseline.
3. **Confirm onboarding readiness.** `.\DLPUSB-ScopeHealth.ps1` reports managed-device signals
   (Graph) and prompts you to confirm, **in Purview → Settings → Device onboarding**, that the pilot
   devices are onboarded.

**Gate 0 (pass/fail):** All of R1–R9 satisfied, Discovery baseline captured, pilot devices onboarded
and visible in **Purview → Devices**. **Fail → stop** and close the gap; do not configure.

---

## Phase 1 — Onboard the pilot devices

1. In **Purview portal → Settings → Device onboarding** (verify path), review the supported
   onboarding methods and download the package for your chosen method (Intune / Group Policy / local
   script / Configuration Manager).
   - *Local script* is fine for a **handful of pilot machines**; use **Intune or GPO** for scale.
   - If devices are already **onboarded to Microsoft Defender for Endpoint**, they may already be
     onboarded here — confirm they appear under **Devices**.
2. Onboard **only the pilot devices** (`DG-USB-Pilot`) first.

**Gate 1:** Pilot devices show as **onboarded** in **Purview → Devices**; a test activity (copy a
benign file to a USB stick) appears in **Activity explorer** (Devices) within the expected latency.
**Fail → rollback:** offboard the device via your onboarding tool's offboarding package; re-check the
device prerequisites (R3) before retrying. **No policy is configured yet, so there is nothing to
enforce-rollback at this stage.**

---

## Phase 2 — Define the removable-storage device group(s)

In **Purview → Data Loss Prevention → Endpoint DLP settings → Removable storage device groups**
(verify path), create `USBG-Corporate` listing the corporate-issued/approved USB devices (by device
ID / vendor ID / serial number, as your standard allows). This is the allow-list both layers use to
**block everything except** approved media. Define any **file-path exclusions** here too.

**Gate 2:** `USBG-Corporate` exists and is populated; `DLPUSB-Discovery.ps1` re-run reports it as
readable (or you have confirmed it in-portal where a setting is not exposed to PowerShell).
**Fail → rollback:** remove/blank the group; groups are inert until a rule or device-control policy
references them, so there is no user impact yet.

---

## Phase 3 — Author the Endpoint DLP policy + removable-media rule in SIMULATION

Create **one** DLP policy, `EDLP-USB-Pilot`, scoped to the **Devices** location and the **pilot scope
only**, in **simulation/test mode** (nothing is blocked), with a single removable-media rule. Author
in the portal or run `.\DLPUSB-Configure.ps1 -WhatIf` first, then `.\DLPUSB-Configure.ps1 -Commit`
(still simulation) to create the objects.

1. **Create the policy** (simulation, Devices location, pilot scope):
   - Location: **Devices** only, scoped to `DG-USB-Pilot` / `SG-USB-Pilot`.
   - Mode: **simulation/test** (portal: *"Run the policy in simulation mode"*; PowerShell: a **Test**
     mode — `TestWithoutNotifications` for a silent pilot, or `TestWithNotifications` to also show
     policy tips). **Verify the exact mode value in your tenant.**
2. **Add the removable-media rule** `EDLP-Rule-USB`:
   - **Condition** on your sensitive content (a sensitivity-label condition such as *Confidential*,
     and/or a sensitive-info-type condition) — **not** "all content".
   - **Endpoint restriction:** the *copy to a removable USB/removable-storage device* activity, set to
     **Audit** while in simulation, **except** `USBG-Corporate` (approved media is exempt).
   - The endpoint restriction is set on the rule (portal → **Devices** activities, or PowerShell via
     the rule's endpoint-restriction parameter). **Verify the exact restriction Setting name and
     permitted values (`Audit` / `Warn` / `Block` / `Ignore`) against `Get-Help New-DlpComplianceRule
     -Full` in your tenant** before scripting them.
3. **Save.** The policy is now evaluating on the pilot devices **without blocking anyone.**

**Gate 3:** `EDLP-USB-Pilot` exists, is in **simulation/test**, scoped to **Devices + pilot only**,
with `EDLP-Rule-USB` present, conditioned on sensitive content, and referencing `USBG-Corporate`.
`DLPUSB-Validate.ps1` reports **PASS** for policy-exists, Devices-location, mode-is-simulation,
scope-is-pilot, and rule-present.
**Fail → rollback:** `Set-DlpCompliancePolicy -Identity EDLP-USB-Pilot -Mode Disable` (or delete with
`Remove-DlpCompliancePolicy`); simulation blocks nothing, so impact is limited to telemetry.

---

## Phase 4 — Deploy the device-control policy in AUDIT-first

In your **management tooling** (Intune / GPO / OMA-URI — verify surface, R7), create
`DC-RemovableStorage-Pilot` targeting `DG-USB-Pilot`:

1. Set the posture for **unapproved** removable storage to **Audit** first (allow + audit), with
   **`USBG-Corporate`** as the approved exception.
2. Do **not** set Block/read-only yet — audit-first proves the control is seen without disrupting
   work.

**Gate 4a:** `DC-RemovableStorage-Pilot` is deployed to the pilot devices in **audit** posture;
device-control audit events appear for a test USB action. **Fail → rollback:** remove the assignment
in your management tool; nothing is blocked in audit posture.

---

## Phase 5 — Pilot & validate (simulation + audit)

1. Let both layers run on `DG-USB-Pilot` for the agreed observation window.
2. Perform the **sanctioned test actions** in `05-testing.md` on a pilot device (copy a test-labeled
   file to a non-corporate USB; copy to a `USBG-Corporate` device; plug in an unapproved USB).
3. Review **Activity explorer** (Devices), the DLP policy's **simulation results**, and the
   device-control **audit** events; run `.\DLPUSB-Report.ps1` to roll up configuration and (where
   available) activity.
4. **Tune:** adjust the DLP condition/allow-list to remove false positives (e.g. add a legitimate
   corporate USB to `USBG-Corporate`) and confirm both layers **see** the activity.

**Gate 5 (pass/fail):** The Endpoint DLP rule recorded the *copy sensitive content to USB* action in
simulation (would act), the device-control policy recorded the unapproved-media action in audit, the
`USBG-Corporate` exception is respected, false positives triaged, and the **R8 action decision**
confirmed **in writing**. **Fail → do not enforce**; keep tuning in simulation/audit.

---

## Phase 6 — Enforce, then expand

**Only after Gate 5 passes.**

1. **Endpoint DLP:** update `EDLP-Rule-USB` to its **R8** action — **Warn (override)** or **Block** —
   then move the policy out of simulation to **enforce** (portal: turn the policy **On**; PowerShell:
   `Set-DlpCompliancePolicy -Identity EDLP-USB-Pilot -Mode Enable`), still scoped to the pilot first.
2. **Device control:** update `DC-RemovableStorage-Pilot` from **audit** to the **R8** posture —
   **read-only** or **Block** for unapproved removable storage — in your management tool, still
   targeting the pilot.
3. **Re-run the sanctioned tests** (`05-testing.md`) and confirm the enforced behaviour: sensitive
   content is blocked/warned on non-corporate USB, unapproved media is read-only/blocked, and
   `USBG-Corporate` remains allowed.
4. **Expand scope in rings.** Widen the **Devices** scope and the device-control assignment (add the
   next device group), re-validate, and repeat. Consider renaming/cloning to production policies
   (`EDLP-USB` / `DC-RemovableStorage`) as you exit pilot.

**Gate 6:** On the pilot, the enforced content block/warn and the device-control read-only/block act
as designed and `USBG-Corporate` is not blocked; expansion rings each pass the same gate before
widening.
**Fail → rollback:** immediately return the DLP policy to **simulation/test**
(`Set-DlpCompliancePolicy -Mode TestWithoutNotifications`) or **Disable** it, and set the
device-control policy back to **audit** in your management tool — this stops enforcement at once —
then diagnose per `06-troubleshooting.md` before re-enforcing.

---

## Rollback summary (fast reference)

| Situation | Action |
|---|---|
| The DLP rule blocks legitimate work | Set `EDLP-Rule-USB` action back to **Audit**, or set the policy to **simulation/test**, then tune the allow-list/conditions. |
| Device control blocks a legitimate USB | Add the device to `USBG-Corporate`, or set the device-control posture back to **audit/read-only** in your management tool. |
| The whole DLP policy misbehaves | `Set-DlpCompliancePolicy -Identity EDLP-USB-Pilot -Mode Disable` (stops all enforcement) or `-Mode TestWithoutNotifications` (back to simulation). |
| A device should not be in scope | Remove it from the scoped device/user group and the device-control assignment, or **offboard** it via your onboarding tool. |
| Start over cleanly | `Remove-DlpComplianceRule -Identity EDLP-Rule-USB`, then `Remove-DlpCompliancePolicy -Identity EDLP-USB-Pilot`; remove the device-control assignment in your management tool. |

> Enforcement changes are **high-impact** — make them under change control, keep the pilot ring
> small, and never move both layers to hard **Block** at once without validating each in
> simulation/audit first.
