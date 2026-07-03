# Troubleshooting — Intune Custom Compliance & Configuration Items (Scripted), Government (GCC High) Edition

Failure modes and fixes, ordered by how often they bite on a **GCC High** tenant. Almost every GCC High problem is one of three things: **you're in the wrong cloud**, **TLS is being broken on the device endpoints**, or **the script output doesn't match the JSON**. Each item below is symptom → cause → fix.

---

## 1. Device shows "not evaluated" / no custom-compliance result (the #1 GCC High issue)

**Symptom:** In `https://intune.microsoft.us/` → policy → **Device status**, the device is `unknown` / `not applicable`; `CUSTCOMPG-Report.ps1` flags it as NotEvaluated. No error — just silence.
**Most likely cause:** a proxy is performing **SSL inspection on `*.manage.microsoft.us`**. Microsoft does not support TLS interception on these endpoints, so discovery-script delivery and result return fail silently ([Intune US Gov endpoints](https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints)).
**Fix:** Exempt `*.manage.microsoft.us` (and `*.dm.microsoft.us` for EPM/Defender) from SSL inspection. Confirm the certificate the device sees for `*.manage.microsoft.us` is Microsoft's, not your proxy's. Re-sync and re-check.
**Other causes to rule out:** device not licensed for Intune (R2), not enrolled/targeted (R8), or the policy not yet assigned to the device's group.

## 2. Sign-in works but scripts/portal "see nothing" — wrong cloud

**Symptom:** The portal or a script returns an empty tenant, or `Connect-MgGraph` succeeds but returns no GCC High data.
**Cause:** You're pointed at the **Commercial** cloud (`.com` / Global) instead of GCC High.
**Fix:**
- Portals: use `intune.microsoft.us`, `entra.microsoft.us`, `portal.azure.us`, `portal.office365.us` — never the `.com` equivalents.
- Scripts: reconnect with `Connect-MgGraph -Environment USGov` and confirm `(Get-MgContext).Environment` returns **`USGov`** ([Connect-MgGraph](https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/connect-mggraph)). All five scripts in this solution check this automatically and stop if it isn't `USGov`.

## 3. Discovery script runs but device never grades Compliant/NonCompliant

**Symptom:** Script works locally, but the policy never reflects a result.
**Causes and fixes:**
- **Output not single-line.** The last line must be `return $hash | ConvertTo-Json -Compress`. Multi-line output isn't graded ([Create discovery scripts](https://learn.microsoft.com/en-us/intune/intune-service/protect/compliance-custom-script)).
- **Over a limit.** Script > 1 MB, output > 1 MB, or runtime > 10 minutes (Windows). Trim what you discover.
- **Wrong host bitness.** A 64-bit-only cmdlet/path under the default 32-bit host returns nothing — set **Run script in 64-bit PowerShell Host = Yes**.
- **User-context mismatch.** If the check needs the logged-on user but runs as System (or vice-versa), it returns empty — align the "Run using logged-on credentials" toggle.

## 4. Device grades wrong (false compliant / false non-compliant)

**Symptom:** A device that should fail passes, or vice-versa.
**Cause:** Mismatch between discovery output and the JSON rules.
**Fix:** Run `CUSTCOMPG-Validation.ps1`. Check:
- **Case-sensitive key match** — `SettingName` must match the returned key **exactly**. `TPMChipPresent` ≠ `TpmChipPresent`.
- **Correct `DataType`/`Operator`** — use `Version` (not `String`) for version comparisons so `GreaterEquals` works; `Boolean` for true/false; `Int64` for counts.
- **`Operand`** is the intended compliant value.

## 5. Can't create or edit the discovery script (Scripts → Add blocked)

**Symptom:** The **Endpoint security → Device compliance → Scripts → Add** workflow won't proceed, or you can't see existing scripts.
**Cause:** The discovery-script workflow **does not support scope tags**, and you must hold the **Default** scope tag to create/edit/view these scripts ([Create discovery scripts](https://learn.microsoft.com/en-us/intune/intune-service/protect/compliance-custom-script)).
**Fix:** In `intune.microsoft.us` → **Tenant administration → Roles**, ensure your admin's role assignment includes the **Default** scope tag (Requirement R3). Apply the `CUSTCOMPG` scope tag to the **policy**, not the script.

## 6. Graph Explorer won't connect to the government tenant

**Symptom:** Browser-based Graph Explorer returns nothing / errors for `graph.microsoft.us`.
**Cause:** **Graph Explorer is not supported** for the US Gov Graph endpoint ([Graph national clouds](https://learn.microsoft.com/en-us/graph/deployments)).
**Fix:** Use the Microsoft Graph PowerShell SDK with `-Environment USGov` for all API recon — `CUSTCOMPG-Discovery.ps1` does exactly this.

## 7. `Connect-MgGraph -Environment USGov` fails or scopes are missing

**Symptom:** Connection error, or `(Get-MgContext).Scopes` lacks a needed permission.
**Fixes:**
- **SDK missing:** `Install-Module Microsoft.Graph -Scope CurrentUser`; confirm `Get-MgEnvironment` lists `USGov`.
- **Missing scopes:** reconnect requesting them — read-only work needs `DeviceManagementConfiguration.Read.All`, `DeviceManagementManagedDevices.Read.All`, `Group.Read.All`; writes need `DeviceManagementConfiguration.ReadWrite.All`, `Group.ReadWrite.All`.
- **Admin consent:** approve the consent prompt in `entra.microsoft.us`.

## 8. A capability from commercial docs doesn't exist in your tenant

**Symptom:** A custom-compliance, Linux, or Conditional Access option in commercial documentation isn't present in GCC High.
**Cause:** National clouds may lack some global-service features, and government clouds can lag commercial ([Graph national clouds](https://learn.microsoft.com/en-us/graph/deployments)).
**Fix:** Treat commercial docs as **"verify for GCC High"** (see `gcc-high-parity-notes.md`). Confirm the capability is live in your tenant on the pilot before depending on it; if absent, plan around it or check availability with your Microsoft government account team.

## 9. Users see the wrong / unreachable remediation link

**Symptom:** In Company Portal (`portal.manage.microsoft.us`), the "more info" link doesn't resolve for government users.
**Cause:** `MoreInfoUrl` in the JSON points at a commercial or externally-hosted page the government environment can't reach.
**Fix:** Set `MoreInfoUrl` (and any operator help links) to an internal/US-Gov-appropriate resource, and write actionable `RemediationStrings` that route users to the government service desk.

## 10. Conditional Access lockout after enforcement

**Symptom:** After requiring "compliant device" in Conditional Access, users are blocked.
**Cause:** CA enforced before validation was clean, or before compliance results were reliably returning (see #1).
**Fix:** Roll back the CA rule in `entra.microsoft.us`. Confirm devices are genuinely grading Compliant (clean `CUSTCOMPG-Report.ps1`), then re-enable CA gradually with a pilot account and a break-glass exclusion. Only wire CA in after a clean validation window (Implementation Phase 4).

---

**When in doubt, in this order:** confirm you're in **USGov** (portals and `Get-MgContext`), confirm **`*.manage.microsoft.us` isn't SSL-inspected**, then run **`CUSTCOMPG-Validation.ps1`** to confirm script output matches the JSON. Those three cover the large majority of GCC High custom-compliance failures.
