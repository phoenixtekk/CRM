# Troubleshooting — Purview DLP, Labels & Retention (Government / GCC High)

Work top-down. The first section covers the failures that are **unique to GCC High** — check these
before generic Purview troubleshooting, because in GCC High "it's not there" is often a **parity
gap**, not a misconfiguration.

---

## A. GCC-High-specific gotchas

### A1. A menu/option/feature simply isn't there
**Symptom:** A step in a Commercial guide references a menu, toggle, SIT, or classifier that does not
exist in your portal.
**Likely cause:** It is a **GCC High parity gap** — the feature is *in development* or *on the
engineering backlog*, i.e. **not available** in GCC High.
**Check / fix:** Open `gcc-high-parity-notes.md` and confirm the feature's status. Common ones:
**named-entity SITs** (not available), **Office *mobile* auto-labeling** (not available),
**default label on SharePoint upload / on documents being edited** (not available),
**auto-apply records with trainable classifiers** (not available), **retention label action at end
of period** (not available), **records Power Automate / Graph APIs** (not available), **Microsoft
Priva** (not available). Use the GA alternative documented in `03-implementation.md`. Do **not** file
a support case for a backlog feature.

### A2. Wrong cloud — portal or script hit a `.com` host
**Symptom:** Sign-in loops, "tenant not found", empty portal, or a script authenticates but sees no
Purview objects.
**Likely cause:** You reached the **Commercial** cloud (`compliance.microsoft.com`,
`login.microsoftonline.com`, or `Connect-MgGraph -Environment Global`) instead of GCC High.
**Fix:** Use the `.us` hosts only — `login.microsoftonline.us`, `compliance.microsoft.us`
(→ `purview.microsoft.us`), `security.microsoft.us`, `entra.microsoft.us`, `portal.office365.us`. In
scripts, connect with **`Connect-MgGraph -Environment USGov`** (DoD: `USGovDoD`). Verify with
`(Get-MgContext).Environment` = `USGov`. Run `PURVIEWG-Discovery.ps1`, which reports the environment.

### A3. Endpoint blocked by filtering
**Symptom:** Portal will not load, or the labeling client / endpoint DLP / scripts cannot reach the
service, on-network only.
**Likely cause:** Proxy/firewall allows the **Commercial** Office 365 endpoint list but not the
**Office 365 U.S. Government GCC High** list (the `.us` sovereign hosts are a separate published set).
**Fix:** Allow the GCC High URL/IP ranges (portals, `graph.microsoft.us`,
`login.microsoftonline.us`, the Security & Compliance PowerShell Gov URI, endpoint-DLP and labeling
client endpoints). Re-test R6 reachability from an on-network workstation.

### A4. Security & Compliance PowerShell won't connect
**Symptom:** `Connect-IPPSSession` fails or connects to the wrong org.
**Fix:** Use the GCC High connection: `Connect-IPPSSession -ConnectionUri
https://ps.compliance.protection.office365.us/powershell-liveid/ -ExchangeEnvironmentName
O365USGovGCCHigh` (per Microsoft "Connect to Security & Compliance PowerShell"). The Graph-SDK
scripts in this solution use `-Environment USGov`; cmdlet-based label/DLP work uses the URI above.

### A5. Trainable classifier not selectable
**Symptom:** A pre-trained classifier you expected is missing when authoring an auto-label/retention
condition.
**Likely cause:** In GCC High, trainable classifiers are **Available for client-side sensitivity
auto-labeling** but **not** for auto-applying **records** labels (*in development*); individual
classifier availability can also lag.
**Fix:** For records auto-apply, use **condition-based** (keyword/SIT/EDM) or **event-based** rules.
For sensitivity auto-labeling, confirm the specific classifier is listed before designing on it —
**verify for GCC High** if unsure.

### A6. Adaptive Protection options missing
**Symptom:** Risk-based DLP (Insider Risk levels as a DLP condition) not available.
**Likely cause:** Adaptive Protection is **rolling out to Gov clouds** (GCC/GCC High/DoD) — it may
not yet be enabled in your tenant.
**Fix:** Verify presence in `compliance.microsoft.us` (Insider Risk Management → Adaptive
Protection); if absent, do not design DLP on it yet. Ship standard DLP and add Adaptive Protection
when it lands.

---

## B. Labels not appearing for users

- **Cause:** `LP-Purview-Pilot` not assigned to `SG-Purview-Pilot`, or replication delay.
- **Fix:** `compliance.microsoft.us → Information Protection → Label policies` — confirm the policy
  targets `SG-Purview-Pilot` and includes all four labels. Allow up to a few hours; have the user
  restart the Office app / sign out and in. Confirm the user has a G3/G5 license (R2).

## C. Mandatory labeling / justification not enforced

- **Cause:** Policy toggles off, or the client is older than the setting supports.
- **Fix:** In `LP-Purview-Pilot`, confirm **Require users to apply a label** and **Require
  justification to remove/lower** are on. Ensure supported, current Office builds (G6).

## D. Auto-labeling not matching (or over-matching)

- **Cause:** Conditions use a non-GA SIT (named-entity — not available), or thresholds too
  broad/narrow; policy still in simulation.
- **Fix:** Rebuild conditions from **built-in SITs / EDM / keyword / regex**. Re-run **simulation**
  on `AL-CUI-ServiceSide`; review matches; tune; only then turn On. Remember mobile-client
  auto-labeling is not available in GCC High.

## E. DLP not detecting

- **Cause:** Wrong locations, policy scoped away from the pilot, non-GA SIT, or (for devices)
  unonboarded endpoints.
- **Fix:** Confirm `DLP-CUI-Baseline` locations (EXO/SPO/OneDrive/Teams/Devices) and that
  `DLP-CUI-Baseline-Rule1` conditions are GA SITs/EDM/keywords or the `Confidential \ CUI` label.
  For Endpoint DLP, confirm devices are onboarded (`Settings → Device onboarding`, R7). Check **DLP →
  Alerts** and **Activity Explorer**.

## F. DLP blocking legitimate work

- **Cause:** Enforcement enabled before audit tuning, or conditions too broad.
- **Fix:** Set `DLP-CUI-Baseline` back to **test/audit**, retune to cut false positives, get
  change-control approval, then re-enable Block/Restrict with user override/justification.

## G. Retention not applying / wrong end-of-life behavior

- **Cause:** Auto-apply conditions non-GA (classifier-based for records — not available), scope
  mismatch, or an attempt to use "apply label action at end of period" (not available in GCC High).
- **Fix:** Use condition/event-based auto-apply for `RP-CUI-7yr-Auto`; set a **supported**
  end-of-period behavior (retain-then-delete or disposition review). Confirm `RP-Baseline-Retain`
  locations.

## H. Records / disposition not working

- **Cause:** Records management not licensed (needs G5), "Mark as record" not set, or reliance on a
  *rolling-out* feature (multi-stage disposition review) or an unavailable one (records Power
  Automate / Graph).
- **Fix:** Confirm G5; enable **Mark items as a record** on `Ret-CUI-7yr`; verify multi-stage review
  presence before relying on it; do not automate records via Power Automate/Graph in GCC High yet.

## I. Scripts fail or report nothing

- **Cause:** Connected to Commercial Graph, missing scopes, or insufficient role.
- **Fix:** Reconnect with `Connect-MgGraph -Environment USGov` and the scopes listed in each
  script's **HOW TO RUN** header; confirm the operator's Purview roles (R3). Run
  `PURVIEWG-Discovery.ps1` first to confirm the environment and connectivity.

---

**When in doubt about a GCC High specific:** re-open the Microsoft *Plan for Microsoft Purview — GCC
High deployments* page and the Microsoft 365 Roadmap filtered to **GCC High**, and re-confirm the
feature status before troubleshooting further. Never assume Commercial behavior carries over.

**The deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**
