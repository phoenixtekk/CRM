# 6. Troubleshooting — HIPAA & HITRUST Endpoint Compliance & Vulnerability Remediation (Intune + Defender) — Government (GCC High)

Common failure modes across the six phases, with likely cause and fix — tuned for a **GCC High** tenant.
**Run `HIPAACOMPG-Discovery.ps1` first when in doubt** — it confirms you are on the **USGov** cloud and
surfaces most readiness gaps. All diagnostic actions are read-only; remediate through the named objects,
not by hand. **Section F (wrong-cloud / endpoints) is unique to the Government edition — check it first
when a portal is empty or a script returns nothing.**

> These fix the **technical controls** on a sovereign tenant. They are not a substitute for the
> organizational elements of a HIPAA/HITRUST program.

---

## F. GCC High wrong-cloud and endpoint issues (check this first)

**A portal shows no tenant / no devices, or "you don't have access"**
- *Cause:* You are on a **Commercial (`.com`) portal**, not the GCC High (`.us`) one.
- *Fix:* Use the **`.us`** portals: `intune.microsoft.us`, `entra.microsoft.us`, `security.microsoft.us`,
  `compliance.microsoft.us`, `portal.office365.us`, `portal.azure.us`. Sign in via
  `login.microsoftonline.us`. Delete `.com` bookmarks. Cited: `gcc-high-parity-notes.md` §1.

**A script returns nothing / an authority error / connects to the wrong tenant**
- *Cause:* The Graph session reached the **Commercial** cloud because `-Environment USGov` was missing.
- *Fix:* Every included script connects with `-Environment USGov`. Confirm the banner shows
  **Environment: USGov**. If not, `Disconnect-MgGraph` and re-run. Do not remove `-Environment USGov`.
  Cited: `gcc-high-parity-notes.md` §2.

**Device onboarded to Defender but reports no data / stays "not onboarded"**
- *Cause:* The device is reaching the **Commercial** MDE endpoints, or the **Gov/GCC/DoD** connectivity
  URLs are blocked, or (downlevel/MMA) the wrong Azure Cloud was selected.
- *Fix:* Allow the **Gov/GCC/DoD** URL lists through the proxy/firewall (use the **streamlined** list
  where supported — *Preview, verify for GCC High*). For downlevel/MMA choose **Azure US Government** (or
  `OPINSIGHTS_WORKSPACE_AZURE_CLOUD_TYPE=1`) and deploy the required KB **before** onboarding. Confirm in
  `security.microsoft.us` > Assets > Devices. Cited: Microsoft — Required connectivity settings
  (Gov/GCC/DoD); `gcc-high-parity-notes.md` §4.

**Custom tooling calling the Defender API fails auth**
- *Cause:* Using the public `api.securitycenter.microsoft.com`.
- *Fix:* Use **`https://api-gov.securitycenter.microsoft.us`** (GCC High & DoD) and sign in at
  `login.microsoftonline.us`. Cited: `gcc-high-parity-notes.md` §2.

**A feature/report/dashboard from Commercial docs is missing**
- *Cause:* A **Gov parity gap** — the capability is not yet available in GCC High, or Secure Score omits
  the recommendation.
- *Fix:* Check `gcc-high-parity-notes.md` §5–§7. Notably: **Windows Update *policies*** (feature/quality/
  expedite/driver, Autopatch) and **classic Autopilot** are **not available** on GCC High; use **Update
  rings** for patching. **DVM Report inaccuracy** and **Request CVE support** are **not available** — use
  your own change record. Treat anything unconfirmed in your `.us` tenant as absent.

## Compliance evaluation

**Devices show "Not evaluated" or no compliance state**
- *Cause:* Device hasn't synced, isn't enrolled, or the policy isn't assigned to `HIPAA – Clinical
  Endpoints` — **or** you are viewing the Commercial portal (see F).
- *Fix:* Confirm enrollment in `intune.microsoft.us` > Devices > device; force sync (Settings > Accounts
  > Access work or school > Sync); confirm **`HIPAA Compliance – Clinical Endpoints – Policy`** assignment
  includes the group and the device is a member. Allow an evaluation cycle.

**Device unexpectedly Noncompliant**
- *Cause:* A measured safeguard isn't enforced (e.g. the compliance policy requires BitLocker but
  `Encryption – Clinical Endpoints – Baseline` didn't apply), or a setting genuinely fails.
- *Fix:* Open the policy > **Device status** > device > **Per-setting status** to find the failing
  setting. Verify the matching baseline is assigned and applied. Run **`HIPAACOMPG-Validation.ps1`** to
  pinpoint the safeguard.

**Compliance and configuration disagree**
- *Cause:* Policy measures a setting no baseline enforces.
- *Fix:* Add/repair the enforcing baseline (implementation Steps 4–8); every measured setting needs a
  matching baseline.

## BitLocker / encryption

**BitLocker not encrypting; device fails the encryption check**
- *Cause:* No usable TPM, Secure Boot disabled, or the device waiting on user action.
- *Fix:* `manage-bde -status` and check TPM (`tpm.msc`); enable/clear TPM and Secure Boot in firmware
  (R6). Confirm `Encryption – Clinical Endpoints – Baseline` is assigned. Replace hardware without a TPM.

**Recovery keys not escrowed**
- *Cause:* Baseline not set to save recovery info before enabling, or keys expected in the Commercial
  directory.
- *Fix:* In `Encryption – Clinical Endpoints – Baseline`, set *Save BitLocker recovery information to
  Microsoft Entra ID* = **Yes** and *Store recovery information before enabling* = **Yes**; re-sync.
  Verify under `intune.microsoft.us` > Devices > device > **Recovery keys** (escrowed to the **Gov**
  directory).

## Automatic lock / antivirus / firewall

**Screen doesn't lock on timeout**
- *Cause:* `Lock – Clinical Endpoints – Baseline` not applied or overridden.
- *Fix:* Confirm the settings-catalog policy is assigned/applied; check per-setting status for a conflict;
  verify *Maximum Inactivity Time Lock Screen* / machine inactivity limit.

**Defender AV reported unhealthy / signatures stale**
- *Cause:* Cloud/real-time protection off, signature update blocked at the **US Gov** endpoints, or a
  third-party AV present.
- *Fix:* `Get-MpComputerStatus`; ensure `Antivirus – Clinical Endpoints – Baseline` enables real-time +
  cloud protection and a short signature interval. Confirm the **Gov** update endpoints are reachable
  (Section F / GR5). Remove/disable conflicting third-party AV (Defender goes passive when another AV is
  active).

**Firewall check fails**
- *Cause:* A profile disabled or overridden by GPO/third-party.
- *Fix:* `Get-NetFirewallProfile`; confirm `Firewall – Clinical Endpoints – Baseline` enables all three
  profiles; resolve GPO/third-party conflicts.

## Conditional Access (the gate)

**Compliant users still blocked**
- *Cause:* Device not Entra-registered/compliant at token time, or policy scoped too broadly.
- *Fix:* Confirm the device is compliant **and** Entra-joined/registered on the **Gov** tenant; review
  `entra.microsoft.us` > Sign-in logs > Conditional Access for the failing control. Re-check the device
  platform condition and grant control.

**Admins locked out / risk of lockout**
- *Cause:* No break-glass exclusion, or gate enabled before report-only validation.
- *Fix:* Use the excluded break-glass account (R8) to regain access; set the gate to **Report-only**,
  validate, then enable. Always keep break-glass excluded.

**Non-compliant device NOT blocked**
- *Cause:* Gate still in Report-only, or device/user outside scope.
- *Fix:* Confirm `Require Compliance – Clinical Endpoints – Gate` is **On** in `entra.microsoft.us`, the
  user is in the included population, and the device platform/target resource match.

## Defender Vulnerability Management

**No exposure data / devices missing from TVM**
- *Cause:* Devices not onboarded to Defender for GCC High, sensor inactive, or reaching the wrong cloud
  (Section F).
- *Fix:* `security.microsoft.us` > Assets > Devices — confirm Onboarded + Active sensor (R3). Re-deploy
  onboarding via the Intune connector; confirm **Gov** connectivity URLs (Section F).

**Remediation task created but exposure unchanged**
- *Cause:* Patch/config not actually deployed, or the recommendation needs the baseline/Update ring.
- *Fix:* Close patch findings via `Patch – Clinical Endpoints – Baseline` (**Update ring** — the update
  *policies* are not available on GCC High); close config findings via the matching baseline. Manual
  fixes drift back — enforce via policy.

**A recommendation looks wrong, or a CVE isn't covered — no portal button to report it**
- *Cause:* **Report inaccuracy** and **Request CVE support** are **not available** in GCC High/DoD.
- *Fix:* Record the concern in your **own** change record (R12) and escalate through your Microsoft
  support channel; do not expect the portal action. Cited: `gcc-high-parity-notes.md` §5.

**Recommendation can't be remediated (medical/vendor device)**
- *Cause:* Embedded/unpatchable clinical device.
- *Fix:* Create a Defender **exception** with justification, owner approval (R10), and expiry; record in
  the evidence store (R12); compensate with network segmentation.

## Patch / updates (GCC High specifics)

**"Feature updates / Quality updates / Expedite / Driver update" policy option is missing**
- *Cause:* Those update **policies** (and Autopatch/Delivery Optimization) are **planned but not yet
  available** on GCC High.
- *Fix:* Use an **Update ring for Windows 10 and later** (`Patch – Clinical Endpoints – Baseline`) plus
  the compliance policy **Minimum OS version**. *Re-verify Gov availability periodically.* Cited:
  Microsoft — Intune Government Service overview; `gcc-high-parity-notes.md` §6.

## Evidence / reporting

**Report script returns nothing or errors on auth**
- *Cause:* Wrong cloud (Section F), missing Graph scopes/modules, or insufficient role.
- *Fix:* Confirm the session is **USGov**; ensure the Microsoft Graph PowerShell SDK is installed and the
  operator has read access to Intune/Defender data on the Gov tenant; the script header lists the read
  scopes. Re-run.

**Evidence missing for a past period**
- *Cause:* Reports not scheduled/retained.
- *Fix:* Schedule `HIPAACOMPG-Report.ps1` / `HIPAACOMPG-Validation.ps1` on a cadence; write to the
  retained, access-controlled **sovereign** repository (R11). You cannot reconstruct past-period evidence
  after the fact.

**Concern: ePHI in evidence**
- *Cause:* Report scope too broad.
- *Fix:* Confirm outputs are device/compliance/exposure metadata only (GR6); redact incidental sensitive
  values; restrict the repository.

## Discovery / drift

**Discovery flags a missing named object**
- *Cause:* Object deleted, renamed off-convention, or unassigned.
- *Fix:* Recreate/rename to the exact `<Purpose> – <Scope> – <Stage>` name and reassign to `HIPAA –
  Clinical Endpoints` (use **`HIPAACOMPG-Remediation.ps1`** to fix assignments); update the control
  mapping under change control (R12).
