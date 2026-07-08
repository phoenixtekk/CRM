# Testing & Validation — Endpoint DLP for Windows

This is the pass/fail gate set. Run it in two passes: **once in simulation** (Phase 4 — the channel
is *seen* and the policy *would* act, nothing is blocked) and **again after enforce** (Phase 5 — the
block/warn channels *actually* act). Every test uses **benign test content** deliberately marked to
match your policy conditions (e.g. a document carrying your *Confidential* sensitivity label and/or
seeded with a matching sensitive information type) — **never** real regulated data.

> **Determination boundary.** These tests prove the **control works as configured**. Whether a given
> real-world action is a *violation*, and any consequence, is a **compliance / security / HR-legal**
> determination — not a test outcome (see `global-requirements-purview.md` §5).

Run `.\DLPWIN-Validate.ps1` for the configuration gates and `.\DLPWIN-Report.ps1` for the
activity/telemetry rollup between passes.

---

## A. Configuration gates (automated — `DLPWIN-Validate.ps1`, read-only)

| # | Check | PASS signal |
|---|---|---|
| A1 | Policy exists | `EDLP-Windows-Pilot` is present. |
| A2 | Devices location | The policy covers the **Devices** location. |
| A3 | Simulation first | In the pilot pass, the policy **Mode** is a **Test/simulation** mode (not `Enable`). |
| A4 | Pilot scope | The policy is scoped to `DG-EDLP-Pilot` / `SG-EDLP-Pilot`, **not** all devices. |
| A5 | Five rules present | `EDLP-Rule-USB`, `-Print`, `-Clipboard`, `-NetworkShare`, `-CloudEgress` all exist and are enabled. |
| A6 | Sensitive-content condition | Each rule carries a sensitivity-label and/or sensitive-info-type condition (not "all content"). |
| A7 | Allow-list groups referenced | USB/print/network rules reference `USBG-Corporate` / `PRNG-Corporate` / `NSG-Corporate` as designed. |

**Gate A:** All applicable rows PASS. Any FAIL → fix in `03-implementation.md` before behavioural
testing.

---

## B. Behavioural tests — per channel (manual, on a pilot device)

For each channel, perform the action with a **matching** test file and record the result. In the
**simulation pass** the expected result is *"activity recorded in Activity explorer / simulation
results; no block."* In the **enforce pass** the expected result is the **R8** action for that
channel.

| # | Channel | Test action (on a pilot device, with a matching test file) | Simulation PASS | Enforce PASS (per R8) |
|---|---|---|---|---|
| B1 | **USB** | Copy the test file to a **non-corporate** USB stick | Activity recorded; no block | Blocked/Warned as designed; copy to a `USBG-Corporate` device is **allowed** |
| B2 | **Print** | Print the test file to a **non-sanctioned** printer | Activity recorded; no block | Blocked/Warned; printing to `PRNG-Corporate` is **allowed** |
| B3 | **Clipboard** | Copy content from the test file and paste into a browser/other app | Activity recorded; no block | Blocked/Warned as designed |
| B4 | **Network share** | Copy the test file to an **out-of-scope / unmanaged** network share | Activity recorded; no block | Blocked/Warned; copy to an in-scope share is handled as designed |
| B5 | **Cloud egress — Edge** | Upload the test file to a **personal/non-sanctioned** cloud domain in **Edge** | Activity recorded; no block | Blocked/Warned; upload to a sanctioned service domain is **allowed** |
| B6 | **Cloud egress — Chrome/Firefox** | Repeat B5 in **Chrome** and **Firefox** (extension deployed) | Activity recorded; no block | Blocked/Warned as in Edge — confirms extension coverage |

**Gate B (simulation pass):** Every in-scope channel **B1–B6** recorded the activity. A channel that
records **nothing** is a coverage failure — do not enforce it; diagnose per `06-troubleshooting.md`
(onboarding, extension, latency, condition match).

**Gate B (enforce pass):** Every **block/warn** channel enforces as designed **and** every
**allow-listed** exception (corporate USB, sanctioned printer, sanctioned domain) is **not** blocked.
Any deviation → roll the policy back to simulation and tune.

---

## C. Negative / false-positive tests (both passes)

| # | Check | PASS signal |
|---|---|---|
| C1 | Non-matching content | Copying/printing/uploading a file that carries **no** matching label/SIT triggers **no** endpoint match. |
| C2 | Allow-listed paths | The corporate USB (`USBG-Corporate`), sanctioned printer (`PRNG-Corporate`), and sanctioned service domains are **not** blocked in the enforce pass. |
| C3 | Out-of-scope device | A device **not** in `DG-EDLP-Pilot` shows **no** endpoint enforcement from this policy. |
| C4 | Override/justification | Where **Warn/override** or **business justification** is configured, the prompt appears and the override is **logged**. |

**Gate C:** All applicable rows PASS. A false positive (C1/C2 fails) must be tuned **before** wider
enforcement — false positives erode user trust and drive shadow workarounds.

---

## D. Evidence to capture (for the defensibility pack)

Capture and retain, for each pass:

- `DLPWIN-Validate.ps1` output (configuration gate results).
- `DLPWIN-Report.ps1` output (policy modes + Activity-explorer export of endpoint activities, where
  available).
- Screenshots of **Purview → Activity explorer (Devices)** showing each channel's recorded activity,
  and of the **policy tip / block dialog** in the enforce pass.
- A completed **B-channel matrix** signed off by the change owner, plus the **R8 action decision**
  and the **onboarding confirmation** (pilot devices listed in **Purview → Devices**).

> This evidence set is what makes the control **defensible** — it shows *what* was configured, *that*
> each channel was validated in simulation before enforcement, and *that* enforcement behaves as
> designed. Store it with the change record.
