# 6. Troubleshooting Guide — Application Packaging & Deployment Standards

Use `APPSTD-Invoke-PackageStandardAudit.ps1` for naming/metadata violations,
`APPSTD-Test-DetectionRuleQuality.ps1` for detection findings,
`APPSTD-Get-AssignmentHygieneReport.ps1` for assignment problems,
`APPSTD-Get-PackageMetadataCompleteness.ps1` for metadata scores, and
`APPSTD-Set-AppMetadataStandard.ps1` (preview by default) to normalise mechanical gaps. The worked
example throughout is `Acme Software Ltd. Acme Invoice Client – Win32 – v7.3.1`.

## A. The scripts won't connect or return nothing

| Symptom | Cause | Remediation |
|---|---|---|
| `Connect-MgGraph` fails or prompts endlessly | SDK missing or scopes not consented | Install the SDK (Requirement 2.4); run once interactively as an Intune Administrator to accept the consent prompt (Requirement 2.5) |
| Script runs but reports "No matching Windows apps found" | Tenant genuinely has no Win32/Store/MSIX apps, or a filter excluded them | Confirm apps exist in Intune → **Apps → All apps**; remove `-CreatedSinceDays` if you set it |
| `Insufficient privileges` on the remediation `-Apply` | Only read scope consented | Re-run and consent to `DeviceManagementApps.ReadWrite.All`; the account needs the **Intune Administrator** role |
| Consent blocked by the tenant | User-consent is disabled | Have a Global Administrator grant admin consent for the Microsoft Graph PowerShell app for the listed scopes |

## B. An app fails the naming/standard audit but "looks fine"

| Symptom | Cause | Remediation |
|---|---|---|
| `name-convention` FAIL on a correct-looking name | The separator is a plain hyphen without surrounding spaces, or the format token isn't exactly `Win32`/`MSIX`/`Store` | Rename to `<Publisher> <Product> – <Format> – v<Version>` with ` – ` (space-dash-space); a new version is a new app object, never an in-place rename of a live one |
| `version-stamp` FAIL | No `vX.Y` token in the name | Add the vendor version, prefixed `v`, to the name and confirm the detection rule asserts the same version |
| `banned-word` FAIL for `New`/`Copy` | A real word in the product name coincides with a banned token | This is a false positive on a legitimate name; record it as an accepted exception in the register rather than renaming the product |
| `description-standard` FAIL | Description lacks the three mandatory lines | Use `APPSTD-Set-AppMetadataStandard.ps1` with `BusinessPurpose`/`BusinessOwner`/`PackageRecord` values (preview, then `-Apply`) |

## C. Detection quality checker flags a rule

| Finding | Meaning | Remediation |
|---|---|---|
| `B1(file-exists-no-version)` | A versionable app is detected by mere existence | Change the file rule's method to **Version** with operator **≥**, or use the MSI product code with a version check |
| `B2(folder-only)` | Detection points at a folder, not a file | Point at a specific versioned file the installer writes; uninstallers leave folders behind |
| `B5(shared-runtime)` | Detection targets a shared DLL/runtime | Re-target the app's own uniquely-named binary or its MSI product code |
| `B6(per-user-path-system-context)` | An `HKCU`/`%AppData%` rule on a System-context install | Move detection to an `HKLM` key or a `Program Files` file; SYSTEM cannot see the user hive |
| `B7(multiple-rule-types)` | More than one rule type combined | Reduce to one authoritative rule, or document the reason and countersign |
| `B8`/`B9`/`B10` on a script rule | The detection script acts, uses `Write-Host`/no exit, or calls `Win32_Product` | Rewrite the script to only observe: emit STDOUT + exit `0` on detect, no output + exit `0` on not-detected; never `Win32_Product` |
| `NO-RULE(missing detection)` | The Win32 app has no detection rule | Add one before any assignment; without detection Intune cannot report state |

## D. Assignment hygiene report shows violations

| Finding | Meaning | Remediation |
|---|---|---|
| `H1(all-devices/all-users)` | App targets a virtual all-fleet group | Remove it; assign to `APP – Ring 1/2` or a purpose-named `APP – ` group instead |
| `H2(required+uninstall)` | Same app is both Required and Uninstall for overlapping groups | The device installs and uninstalls on alternating cycles; remove one intent and let supersedence handle replacement |
| `H3(duplicate-intent-target)` | Two Required (or two Available) assignments to the same group | Delete the duplicate; one assignment per intent per group |
| `H4(missing-standard-exclusion)` | A Required assignment lacks `APP – Exclusions – Do Not Deploy` | Add the exclusion group under **Excluded** on the assignment |
| `H5(unassigned-orphan)` | App has no assignments | Assign it, or delete it — a Ring 0-only app older than 30 days is debris |

## E. Metadata remediation didn't change anything

- **By design, it previews by default.** Nothing is written until you pass `-Apply`. Run once to
  review the diff, then re-run with `-Apply`.
- **A category name "not found in tenant"** means the exact category string isn't in **Apps →
  Categories**. Create it first (Implementation Step 2e); the script matches on the exact display name.
- **The description overwrote free text.** The script preserves only text placed **below** the
  `<!-- free-text below this line is preserved -->` marker. Put any narrative below that marker.

## F. The standard is "adopted" but nobody follows it

This is the most common failure, and it is not technical.

- **Symptom:** new apps still arrive non-compliant. **Cause:** the acceptance checklist and sign-off
  are being skipped because there is no consequence. **Remediation:** enforce the packager RBAC scope
  (Requirement 2.6) so packagers physically cannot self-release to Ring 2, and run the monthly new-app
  audit (Implementation Step 10c) with the Packaging Standard Owner reviewing the results.
- **Symptom:** the exceptions register is full of permanent, never-reviewed waivers. **Cause:**
  exceptions were logged without expiry dates. **Remediation:** add a review date to every exception;
  close or renew each at the annual review (Step 10f).
- **Symptom:** the baseline never improves quarter over quarter. **Cause:** findings are reported but
  not assigned to anyone. **Remediation:** each quarterly finding gets a decision — fix now, fix at
  next version, or accepted exception — with an owner and a date.

## G. Government-cloud specifics

- **Portal host differs.** Government tenants use hosts such as `intune.microsoft.us` / `portal.azure.us`
  rather than `.com`. Confirm the exact host for your cloud in Microsoft's US-sovereign-cloud
  documentation before following any portal path.
- **The Microsoft Store (new) branch may be unavailable.** If Requirement 2.9 established the Store
  type is absent in your cloud, an app the matrix would route to Store must fall through to Win32.
  Strike Question 1 from your local decision tree and reflect the extra Win32 workload in capacity
  planning. **Verify for GCC High** against Microsoft's documentation; do not assume the Commercial
  answer, and do not invent Government specifics.

## H. When to escalate

If the naming, detection, metadata, and assignment audits all report clean, the acceptance checklist
passed, sign-off is filed, the pilot reports Installed — but Intune still reports Failed for an app
across the fleet after a policy cycle — the problem is in the per-app package mechanics (install
command, dependency, or the installer itself), not in the standard. Collect the device's
`C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log` and the
installer's own verbose log (`C:\ProgramData\PackageLogs\`) and treat it as a per-app packaging fault
(see the companion Win32 packaging solution) or open a Microsoft support case.
