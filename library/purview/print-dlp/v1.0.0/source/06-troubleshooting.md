# 6. Troubleshooting Guide — Print DLP (Microsoft Purview)

Symptom → likely root cause → fix. Use **`DLPPRINT-Discovery.ps1`** (posture),
**`DLPPRINT-EndpointReadiness.ps1`** (onboarding/licensing), **`DLPPRINT-Validation.ps1`** (policy shape),
and **`DLPPRINT-Report.ps1`** (activity) to confirm before and after each fix. Where print behaviour is
**OS-/tenant-dependent (e.g. macOS) or evolving, verify against current Microsoft guidance / your tenant**
rather than assuming.

## A. Availability / setup

### The "Print" activity isn't selectable when authoring a rule
- **Licensing insufficient.** Endpoint DLP activity restrictions are plan-gated (typically E5 / E5
  Compliance). **Fix:** confirm the subscription in the M365 admin center; run
  **`DLPPRINT-EndpointReadiness.ps1`**. Assign the required licensing (Req 2.1).
- **Devices location not enabled / no onboarded devices.** The Print activity only appears with the Devices
  location available. **Fix:** confirm **Settings → Device onboarding** shows onboarded devices; onboard
  targets (Req 2.3).

### "Devices" location can't be selected on the policy
- **Onboarding incomplete.** A Devices-location policy is inert until devices are onboarded (shared with
  Defender for Endpoint onboarding). **Fix:** onboard via the Purview package / Intune / Group Policy;
  re-check with `DLPPRINT-EndpointReadiness.ps1`.

## B. Nothing is detected (false negatives)

### A sensitive print isn't flagged even in simulation
- **Device not onboarded or not reporting.** No onboarded, reporting device = no endpoint signal. **Fix:**
  `DLPPRINT-EndpointReadiness.ps1`; confirm the device is onboarded and checked in; confirm the minimum OS
  build for the Print activity.
- **Detector too strict.** Confidence too high or instance count too large, so real content doesn't match.
  **Fix:** lower confidence/instance count, or switch to a **sensitivity-label condition**; re-simulate.
- **Content not classifiable at print time.** The agent couldn't classify the document (e.g. image-only PDF,
  unsupported format). **Fix:** verify the format is supported; consider a label condition for such content.
- **Policy scoped away from the user/device.** The user/device is excluded or outside the included group.
  **Fix:** `DLPPRINT-Validation.ps1` shows the scoped identities; correct the include/exclude.

### macOS prints aren't restricted like Windows
- **OS-specific support differs.** Windows print restriction is the most complete; **macOS print support and
  specific behaviours evolve**. **Fix:** **verify against current Microsoft guidance / your tenant** for
  macOS print support; deliver Windows print first and revisit macOS when the capability is confirmed.

## C. Too much is detected (false positives)

### Ordinary documents are flagged as would-be blocks
- **Detector too broad.** A low-confidence SIT matches incidental patterns. **Fix:** raise confidence /
  instance count, add supporting keywords/proximity, or prefer a **label condition**; re-simulate and
  re-measure with `DLPPRINT-Report.ps1`.
- **Pattern SIT over-matches structured data.** **Fix:** introduce **Exact Data Match (EDM)** for
  customer/account numbers; refresh EDM data on cadence.

### Legitimate corporate printing is being caught
- **Corporate printers not in the allowed group.** The `Printers – Corporate – Allowed` group is missing
  printers or the rule doesn't treat it distinctly. **Fix:** **Endpoint DLP settings → Printer groups** —
  add the sanctioned printers (name/IP/USB IDs); keep that group at *allow/audit* while restricting
  network/local/universal. Re-run `DLPPRINT-Validation.ps1`.
- **Printer moved / changed IP.** A stale printer group no longer matches the moved corporate printer.
  **Fix:** refresh the printer group whenever the print estate changes.

## D. Printer groups

### Print-to-PDF/XPS (print to file) isn't being restricted
- **Universal / print-to-file class not covered.** Physical-printer rules don't automatically cover
  print-to-file. **Fix:** ensure the **universal / print-to-file** class is in scope of the restriction (not
  just physical printers) — this is a common quiet exfiltration gap.

### A printer lands in the wrong group
- **Ambiguous match (name vs IP vs USB ID).** Overlapping group definitions. **Fix:** tighten the group
  membership criteria so each printer resolves to exactly one group; validate with
  `DLPPRINT-Validation.ps1`.

## E. Enforcement / user experience

### Users see no policy tip or override prompt
- **Still in simulation.** Tips/overrides only appear once the policy is **enforced** (unless "simulation
  with policy tips" is selected). **Fix:** confirm mode with `DLPPRINT-Discovery.ps1` (`Test*` = simulation,
  `Enable` = enforce); move the ring to enforce when ready.
- **Policy-tip / override not configured.** **Fix:** set `DLP Notice – Print – Standard` text and enable
  allow-override-with-justification in the rule's user-experience settings.

### Enforcement leaked outside the pilot ring
- **Scope not limited to the ring.** **Fix:** `DLPPRINT-Validation.ps1` shows the scoped identities; set the
  included scope to `DLP Pilot Ring – Stage1` only (config helper `-SetScope`), all others excluded.

### A hard block is stopping essential printing
- **Escalated too fast / wrong printer group.** **Fix:** immediate rollback — set the policy back to
  **simulation** (single setting, no data change), or relax the affected **printer group** to *block with
  override* / *audit*; re-tune before re-escalating.

## F. Alerts / operations

### Restricted prints don't raise alerts (or no one sees them)
- **Alert not enabled / no triage owner.** **Fix:** confirm the rule's **alert** is on and severity set;
  assign the `DLP Alerts – Print – Operations` owner/queue (Req 2.7). A restricted print with no triage is
  not a control.
- **SIEM forwarding not wired.** **Fix:** confirm the Office 365 Management Activity API / Defender
  connector to Sentinel is configured if forwarding is required.

### Reports show rising overrides
- **Detector or printer groups mis-calibrated, or users bypassing.** **Fix:** review override justifications
  in `DLPPRINT-Report.ps1`; if legitimate, calibration is fine; if routine bypass, tighten the detector or
  printer groups, or escalate the action per compliance.

---
## Escalation checklist
1. `DLPPRINT-EndpointReadiness.ps1` — licensed, devices onboarded/reporting, Print activity available?
2. `DLPPRINT-Discovery.ps1` — policy exists, Devices-only, correct mode (Test* vs Enable), Print restriction set?
3. `DLPPRINT-Validation.ps1` — printer groups resolve, corporate group distinct, scope = intended identities?
4. `DLPPRINT-Report.ps1` — matches, false-positive rate, overrides, restricted printers as expected?
5. Still stuck → capture the print symptom and **verify the current Microsoft guidance** for Endpoint DLP
   Print behaviour (especially macOS / printer-group syntax) in your tenant before a fleet-wide change.
