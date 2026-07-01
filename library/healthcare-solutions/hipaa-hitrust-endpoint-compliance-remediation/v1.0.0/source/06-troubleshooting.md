# 6. Troubleshooting — HIPAA & HITRUST Endpoint Compliance & Vulnerability Remediation (Intune + Defender)

Common failure modes across the six phases, with likely cause and fix. Run **`HIPAACOMP-Discovery.ps1`** first when in doubt — it surfaces most readiness gaps. All diagnostic actions are read-only; remediate through the named objects, not by hand.

> These fix the **technical controls**. They are not a substitute for the organizational elements of a HIPAA/HITRUST program.

---

## Compliance evaluation

**Devices show "Not evaluated" or no compliance state**
- *Cause:* Device hasn't synced, isn't enrolled, or the policy isn't assigned to `HIPAA – Clinical Endpoints`.
- *Fix:* Confirm enrollment (**Devices** > device > overview); force sync (Settings > Accounts > Access work or school > Sync); confirm **`HIPAA Compliance – Clinical Endpoints – Policy`** assignment includes the group and the device is a group member. Allow an evaluation cycle.

**Device unexpectedly Noncompliant**
- *Cause:* A measured safeguard isn't enforced (e.g. compliance policy requires BitLocker but the `Encryption – Clinical Endpoints – Baseline` didn't apply), or a setting genuinely fails.
- *Fix:* Open the policy > **Device status** > device > **Per-setting status** to see the failing setting. Verify the matching configuration baseline is assigned and applied (**Endpoint security** / **Configuration** > policy > device status). Run **`HIPAACOMP-Validation.ps1`** to pinpoint the safeguard.

**Compliance and configuration disagree**
- *Cause:* Policy measures a setting no baseline enforces.
- *Fix:* Add/repair the enforcing baseline (implementation Steps 4–8); every measured setting needs a matching baseline.

## BitLocker / encryption

**BitLocker not encrypting; device fails the encryption check**
- *Cause:* No usable TPM, Secure Boot disabled, or the device waiting on user action.
- *Fix:* `manage-bde -status` and check TPM (`tpm.msc`); enable/clear TPM and Secure Boot in firmware (R6). Confirm `Encryption – Clinical Endpoints – Baseline` is assigned. For hardware without a TPM, replace it — the control can't be enforced otherwise.

**Recovery keys not escrowed**
- *Cause:* Baseline not set to save recovery info to Entra ID before enabling.
- *Fix:* In `Encryption – Clinical Endpoints – Baseline`, set *Save BitLocker recovery information to Azure AD* = **Yes** and *Store recovery information before enabling* = **Yes**; re-sync. Verify under **Devices** > device > **Recovery keys**.

## Automatic lock / antivirus / firewall

**Screen doesn't lock on timeout**
- *Cause:* `Lock – Clinical Endpoints – Baseline` not applied or overridden.
- *Fix:* Confirm the settings-catalog policy is assigned/applied; check for a conflicting policy in per-setting status; verify *Maximum Inactivity Time Lock Screen* / machine inactivity limit values.

**Defender AV reported unhealthy / signatures stale**
- *Cause:* Cloud/real-time protection off, signature update blocked, or a third-party AV present.
- *Fix:* `Get-MpComputerStatus`; ensure `Antivirus – Clinical Endpoints – Baseline` enables real-time + cloud protection and a short signature interval. Remove/disable conflicting third-party AV (Defender goes passive when another AV is active). Confirm connectivity to update endpoints (GR5).

**Firewall check fails**
- *Cause:* A profile disabled or overridden by GPO/third-party.
- *Fix:* `Get-NetFirewallProfile`; confirm `Firewall – Clinical Endpoints – Baseline` enables all three profiles; resolve GPO/third-party conflicts.

## Conditional Access (the gate)

**Compliant users still blocked**
- *Cause:* Device not Entra-registered/compliant at token time, or policy scoped too broadly.
- *Fix:* Confirm the device is compliant **and** Entra-joined/registered; review **Sign-in logs** > **Conditional Access** for which control failed. Re-check the policy's device platform condition and grant control.

**Admins locked out / risk of lockout**
- *Cause:* No break-glass exclusion, or gate enabled before report-only validation.
- *Fix:* Use the excluded break-glass account (R8) to regain access; set the gate to **Report-only**, validate impact, then enable. Always keep break-glass excluded.

**Non-compliant device NOT blocked**
- *Cause:* Gate still in Report-only, or device/user outside scope.
- *Fix:* Confirm `Require Compliance – Clinical Endpoints – Gate` is **On**, the user is in the included population, and the device platform/target resource match.

## Defender Vulnerability Management

**No exposure data / devices missing from TVM**
- *Cause:* Devices not onboarded to Defender for Endpoint, or sensor inactive.
- *Fix:* **Defender portal** > **Assets** > **Devices** — confirm Onboarded + Active sensor (R4). Re-deploy onboarding via the Intune connector; confirm connectivity (GR5).

**Remediation task created but exposure unchanged**
- *Cause:* Patch/config not actually deployed, or recommendation needs the baseline/Update ring.
- *Fix:* Close patch findings via `Patch – Clinical Endpoints – Baseline` (Update ring); close config findings via the matching baseline. Manual fixes drift back — enforce via policy.

**Recommendation can't be remediated (medical/vendor device)**
- *Cause:* Embedded/unpatchable clinical device.
- *Fix:* Create a Defender **exception** with justification, owner approval (R10), and expiry; record in the evidence store (R12); compensate with network segmentation.

## Evidence / reporting

**Report script returns nothing or errors on auth**
- *Cause:* Missing Microsoft Graph scopes/modules or insufficient role.
- *Fix:* Ensure the Microsoft Graph PowerShell SDK is installed and the operator has read access to Intune/Defender data; connect with the required read scopes (the script header lists them). Re-run.

**Evidence missing for a past period**
- *Cause:* Reports not scheduled/retained.
- *Fix:* Schedule `HIPAACOMP-Report.ps1` / `HIPAACOMP-Validation.ps1` on a cadence; write to the retained, access-controlled repository (R11) with retention applied. You cannot reconstruct past-period evidence after the fact.

**Concern: ePHI in evidence**
- *Cause:* Report scope too broad.
- *Fix:* Confirm outputs are device/compliance/exposure metadata only (GR6); redact any incidental sensitive values; restrict the repository.

## Discovery / drift

**Discovery flags a missing named object**
- *Cause:* Object deleted, renamed off-convention, or unassigned.
- *Fix:* Recreate/rename to the exact `<Purpose> – <Scope> – <Stage>` name and reassign to `HIPAA – Clinical Endpoints`; update the control mapping under change control (R12).
