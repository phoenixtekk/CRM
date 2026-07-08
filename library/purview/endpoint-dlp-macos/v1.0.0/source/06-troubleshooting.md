# 6. Troubleshooting Guide — Endpoint DLP for macOS (Microsoft Purview)

Symptom → likely root cause → fix. Use **`DLPMac-Discovery.ps1`** (policy scope + Mode + egress
restrictions), **`DLPMac-Validation.ps1`** (pass/fail on scope + mode + channels),
**`DLPMac-Report.ps1`** (Activity Explorer evidence), and **`DLPMac-Onboarding-Check.ps1`**
(Intune-side onboarding/extension health) to confirm before and after each fix. Where a control's
availability on macOS is **version- or plan-dependent, verify against current Microsoft guidance / your
licensing / tenant** rather than assuming.

## A. Onboarding

### A Mac never shows any DLP activity (policy "does nothing")
- **Mac not onboarded.** Endpoint DLP only affects **onboarded** devices. **Fix:** confirm the Mac in
  Purview → **Settings → Device onboarding → Devices**; run **`DLPMac-Onboarding-Check.ps1`** to confirm
  the onboarding profile is deployed in Intune; onboard it (Implementation Phase 1) if absent.
- **System / network extension not approved.** Without the approved extension the agent can't inspect
  egress. **Fix:** deploy the **System Extensions** allow + **network/content-filter** profile via MDM;
  on the Mac, **System Settings → Privacy & Security** should show the extension allowed.
- **Full Disk Access not granted.** The agent can't see file activity without it. **Fix:** deploy the
  **PPPC/TCC (Full Disk Access)** profile via Intune/Jamf; verify it is granted on the Mac. These must
  be **pushed by MDM**, not clicked per device, for a silent rollout.

### Onboarding package deployed but the Mac still isn't "active"
- **Profiles not assigned / not yet applied.** **Fix:** confirm all four payloads (onboarding, system
  extension, network extension, Full Disk Access) are **assigned to the pilot Mac group** and have
  applied; force an MDM sync; re-check `DLPMac-Onboarding-Check.ps1`.
- **Unsupported macOS version.** Support is the **three latest major** releases. **Fix:** update macOS;
  the onboarding check flags clearly old majors (verify the current supported list).
- **MDE pipeline conflict / duplication.** macOS DLP shares onboarding with Defender for Endpoint.
  **Fix:** if MDE is already present, don't double-deploy conflicting extensions — **verify the shared
  configuration against current Microsoft guidance for your tenant.**

## B. Policy scope / mode

### The policy exists but nothing is audited on Macs
- **Policy not scoped to Devices.** A policy on Exchange/SharePoint/etc. won't touch endpoints. **Fix:**
  `DLPMac-Validation.ps1` FAILs if the **Devices (Endpoint)** location is missing — add it (or recreate
  with `-EndpointDlpLocation All` via `DLPMac-Set-Policy.ps1`).
- **Policy Disabled.** **Fix:** `DLPMac-Discovery.ps1` reports `Enabled`; enable the policy.
- **No rule / rule has no endpoint restrictions.** **Fix:** confirm `macOS Egress - Sensitive Content`
  exists with endpoint restrictions (`DLPMac-Discovery.ps1` lists them); add the channels at **Audit**.

### The policy is unexpectedly blocking users
- **Policy is in Enable (enforcing) prematurely.** **Fix (immediate rollback):**
  `Set-DlpCompliancePolicy -Identity 'Endpoint DLP - macOS - Pilot' -Mode TestWithoutNotifications` —
  reverts to silent simulation on next sync. `DLPMac-Validation.ps1` FAILs when a pilot policy is
  enforcing unexpectedly.
- **A channel was set to Block instead of Audit.** **Fix:** set the channel's action back to **Audit**
  in the rule; only Block after the simulation gate passes and compliance signs off.

## C. Channel coverage

### Cloud/browser upload isn't caught
- **Non-Edge browser without the Purview extension.** Service-domain controls on **Chrome/Firefox**
  need the **Microsoft Purview browser extension**; Edge is native. **Fix:** force-install the extension
  (Requirement 2.8), or test cloud egress from Edge for the initial pilot.
- **Sensitive service domains / browser restrictions not set.** These live in **Endpoint DLP settings**.
  **Fix:** configure **Sensitive service domains** and **Browser and domain restrictions** (Step 4).

### A specific channel (clipboard / print / network share) produces no events
- **Channel not supported on that macOS version, or not enabled in the rule.** macOS supports a
  **subset** of Windows channels and it **evolves**. **Fix:** confirm the channel is in the rule
  (`DLPMac-Validation.ps1` WARNs if an expected channel is missing) and **verify current macOS support**
  before concluding it's broken.

### Restricted-app control does nothing
- **`macOS - Restricted Apps` group missing or empty.** The rule's app control acts on the group in
  **Endpoint DLP settings**. **Fix:** create/populate the group (by bundle ID/name); `DLPMac-Validation.ps1`
  notes the dependency.

## D. Reporting / evidence

### `DLPMac-Report.ps1` returns no events
- **No activity driven / not yet propagated.** Endpoint events can lag. **Fix:** drive a test action
  with SIT-matching **test** content, wait, and re-run; widen with `-Days 30`.
- **Role lacks Activity Explorer export.** **Fix:** ensure the operator has the compliance role that
  permits `Export-ActivityExplorerData`.
- **Filter field names drifted.** The script retries without the workload filter; if still empty,
  **verify current Activity Explorer field names** against Microsoft guidance and review in the portal.

### Events show but none are tagged macOS
- **Platform field absent/normalised differently.** **Fix:** the report notes this; confirm the device
  platform in **Activity Explorer** directly (filter by device) rather than relying on the platform tag.

## E. Determinations (not a technical fix)
- **"Should this be blocked / is this regulated?"** These are **compliance, records, privacy, and
  legal** determinations, not endpoint-configuration questions. **Fix:** route to the relevant
  governance function; this solution configures and evidences the control once they decide.

---
## Escalation checklist
1. `DLPMac-Onboarding-Check.ps1` — Macs managed, supported macOS, onboarding/extension/PPPC profiles present?
2. Purview portal → **Device onboarding** — do the Macs show **onboarded/active**? (No cmdlet for this.)
3. `DLPMac-Discovery.ps1` — policy Devices-scoped, Mode = a **test** mode, rule egress restrictions listed?
4. `DLPMac-Validation.ps1` — PASS on scope + mode + intended channels + restricted-app group present?
5. `DLPMac-Report.ps1` — driven test activity appears as audited events attributed to the policy/rule?
6. Still stuck → capture the symptom and **verify current Microsoft guidance** for macOS Endpoint DLP
   support (version + channel + licensing) in your tenant before any fleet-wide change; keep enforcement
   in **TestWithoutNotifications** until resolved.
