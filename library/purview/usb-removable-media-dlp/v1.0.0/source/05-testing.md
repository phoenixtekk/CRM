# Testing & Validation — USB & Removable-Media DLP

This is the pass/fail gate set. Run it in two passes: **once in simulation/audit** (Phase 5 — the
activity is *seen* and the controls *would* act, nothing is blocked) and **again after enforce**
(Phase 6 — the block/warn/read-only actions *actually* apply). Every test uses **benign test
content** deliberately marked to match your policy conditions (e.g. a document carrying your
*Confidential* sensitivity label and/or seeded with a matching sensitive information type) and a
**non-corporate test USB** — **never** real regulated data.

> **Determination boundary.** These tests prove the **controls work as configured**. Whether a given
> real-world action is a *violation*, and any consequence, is a **compliance / security / HR-legal**
> determination — not a test outcome (see `global-requirements-purview.md` §5).

Run `.\DLPUSB-Validate.ps1` for the configuration gates and `.\DLPUSB-Report.ps1` for the
activity/telemetry rollup between passes.

---

## A. Configuration gates (automated — `DLPUSB-Validate.ps1`, read-only)

| # | Check | PASS signal |
|---|---|---|
| A1 | DLP policy exists | `EDLP-USB-Pilot` is present. |
| A2 | Devices location | The policy covers the **Devices** location. |
| A3 | Simulation first | In the pilot pass, the policy **Mode** is a **Test/simulation** mode (not `Enable`). |
| A4 | Pilot scope | The policy is scoped to `DG-USB-Pilot` / `SG-USB-Pilot`, **not** all devices. |
| A5 | Removable-media rule present | `EDLP-Rule-USB` exists and is enabled. |
| A6 | Sensitive-content condition | The rule carries a sensitivity-label and/or sensitive-info-type condition (not "all content"). |
| A7 | Allow-list group referenced | The rule references `USBG-Corporate` as the approved-media exception. |

**Gate A:** All applicable rows PASS. Any FAIL → fix in `03-implementation.md` before behavioural
testing.

> Device-control policy configuration is **not** readable via Security & Compliance PowerShell —
> confirm `DC-RemovableStorage-Pilot` and its posture in your **management tooling** (Intune / GPO /
> OMA-URI) as a manual gate.

---

## B. Behavioural tests — both layers (manual, on a pilot device)

Perform each action with the stated media/content and record the result. In the **simulation/audit
pass** the expected result is *"activity recorded; no block."* In the **enforce pass** the expected
result is the **R8** action.

| # | Layer | Test action (on a pilot device) | Simulation/audit PASS | Enforce PASS (per R8) |
|---|---|---|---|---|
| B1 | **Endpoint DLP (content)** | Copy the **matching test file** to a **non-corporate** USB stick | Activity recorded in Activity explorer; no block | Blocked/Warned as designed |
| B2 | **Endpoint DLP (exception)** | Copy the same file to a **`USBG-Corporate`** device | Activity recorded; no block | **Allowed** (approved media exempt) |
| B3 | **Device control (device)** | Plug in an **unapproved** USB and attempt read/write | Audit event recorded; access allowed | **Read-only / blocked** per R8 |
| B4 | **Device control (exception)** | Plug in a **`USBG-Corporate`** device and read/write | Audit event recorded; access allowed | **Allowed** (approved media exempt) |

**Gate B (simulation/audit pass):** B1–B4 all recorded the activity. A test that records **nothing**
is a coverage failure — do not enforce it; diagnose per `06-troubleshooting.md` (onboarding, latency,
condition match, device-group membership).

**Gate B (enforce pass):** The enforced content block/warn (B1) and device-control read-only/block
(B3) act as designed **and** the `USBG-Corporate` exceptions (B2, B4) are **not** blocked. Any
deviation → roll back to simulation/audit and tune.

---

## C. Negative / false-positive tests (both passes)

| # | Check | PASS signal |
|---|---|---|
| C1 | Non-matching content | Copying a file that carries **no** matching label/SIT to a non-corporate USB triggers **no** Endpoint DLP content match. |
| C2 | Allow-listed media | The corporate USB (`USBG-Corporate`) is **not** blocked by either layer in the enforce pass. |
| C3 | Out-of-scope device | A device **not** in `DG-USB-Pilot` shows **no** enforcement from this policy or the device-control assignment. |
| C4 | Override/justification | Where **Warn/override** or **business justification** is configured on the DLP rule, the prompt appears and the override is **logged**. |

**Gate C:** All applicable rows PASS. A false positive (C1/C2 fails) must be tuned **before** wider
enforcement — false positives erode user trust and drive shadow workarounds.

---

## D. Evidence to capture (for the defensibility pack)

Capture and retain, for each pass:

- `DLPUSB-Validate.ps1` output (configuration gate results).
- `DLPUSB-Report.ps1` output (policy modes + Activity-explorer export of removable-media activity,
  where available).
- Screenshots of **Purview → Activity explorer (Devices)** showing the removable-media activity, the
  device-control **audit/enforce** events in your management tool, and the **policy tip / block
  dialog** in the enforce pass.
- A completed **B-layer matrix** signed off by the change owner, the **R8 action decision**, the
  **device-group (`USBG-Corporate`) membership**, and the **onboarding confirmation** (pilot devices
  listed in **Purview → Devices**).

> This evidence set is what makes the control **defensible** — it shows *what* was configured across
> both layers, *that* each was validated in simulation/audit before enforcement, and *that*
> enforcement behaves as designed. Store it with the change record.
