# Troubleshooting — Hybrid Identity (Government / GCC High)

GCC-High-specific symptoms and fixes. Most GCC High incidents trace back to **wrong cloud / wrong
endpoint**, not a broken feature. Work top-down; the first few cover the vast majority of cases.

## 1. "I configured it in the portal but nothing changed"
**Cause:** You are in a **Commercial portal** (`entra.microsoft.com`, `portal.azure.com`,
`admin.microsoft.com`) which points at the wrong (or an empty) tenant.
**Fix:** Use the **`*.us`** portals only: `entra.microsoft.us`, `portal.azure.us`,
`portal.office365.us`. Confirm the tenant shown is your GCC High tenant with your verified Gov
domain.

## 2. Entra Connect sign-in fails at "Connect to Microsoft Entra ID"
**Cause:** Cloud selection did not take — Connect is trying Commercial endpoints.
**Fix:** Confirm the prompt routes through **`login.microsoftonline.us`**. If not, revisit
Implementation Step 2.3: either open **`*.windows.net`** for auto-detection, or pause the wizard at
the EULA and set `HKLM\SOFTWARE\Microsoft\Azure AD Connect\AzureInstance` = **`4`**, then use the
**Custom** install path
([Sync service instances](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/reference-connect-instances#microsoft-azure-government)).

## 3. Sync engine cannot reach the service / stalls
**Cause:** Gov sync endpoints are not open on the proxy/firewall.
**Fix:** Open `*.microsoftonline.us`, `*.gov.us.microsoftonline.com`, `*.windows.net`,
`graph.microsoft.us`, `*.auth.microsoft.us`, and CRLs (R8). Reconcile against the live
[GCC High endpoints web service](https://endpoints.office.com/endpoints/USGOVGCCHigh). Test 443
reachability from `SVR-ENTRACONNECT01`.

## 4. `Connect-MgGraph` returns the wrong tenant or an auth error
**Cause:** The Graph SDK defaulted to Commercial `graph.microsoft.com`.
**Fix:** Always pass **`-Environment USGov`** (or `USGovDoD` for DoD/L5). All scripts in this
solution do this; if you run Graph manually, add the flag. Confirm you can reach
`graph.microsoft.us`.

## 5. Users appear as cloud-only or with `onmicrosoft.us` UPNs
**Cause:** UPN/domain hygiene — the public domain is not verified **in the GCC High tenant**, or AD
UPN suffixes don't match.
**Fix:** In `entra.microsoft.us` → `Identity → Settings → Domain names`, verify the public domain
**in the Gov tenant**; add the matching UPN suffix in AD; update user UPNs; re-run sync (R7).

## 6. Pilot users not syncing (or too many syncing)
**Cause:** OU/group filtering scope is wrong.
**Fix:** Confirm only `OU=HybridPilot` / `sg-HybridIdentity-Pilot` is in scope. Use
`HYBIDG-Set-ScopeTargeting.ps1` (default `-WhatIf`) to preview, then apply.

## 7. Pass-through Authentication or Seamless SSO fails
**Cause:** The auth agent registered to the wrong cloud, or Gov agent endpoints are blocked.
**Fix:** Confirm the PTA/SSO agent registered against the **US Gov** instance and the
`*.microsoftonline.us` / `*.gov.us.microsoftonline.com` allow-list is open. For Seamless SSO verify
the `AZUREADSSOACC` computer object and Kerberos config. **Verify for GCC High** with your specific
agent version. PTA/PHS/Federation are all supported in Azure for US Government
([feature availability](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability)).

## 8. SSPR resets in cloud but on-prem password unchanged
**Cause:** Password writeback misconfigured or service-account permissions missing.
**Fix:** Confirm password writeback is enabled in Connect and the sync service account has the
required AD permissions. SSPR with on-premises writeback is available in Azure for US Government
(same source).

## 9. A feature you expect is "missing" in GCC High
**Cause:** It may be a genuine parity gap, not a misconfiguration.
**Fix:** Check `gcc-high-parity-notes.md`. Known gaps: **My Staff**, **Entra threat intelligence**
risk detection, **Enterprise State Roaming** shared-device sign-out (all ❌); **HR-driven
provisioning** is partial ([feature availability](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability)).
Do not spend hours "fixing" an unavailable feature.

## 10. Unexpected mass deletion staged on export
**Cause:** A scope/filtering change removed many objects; the deletion threshold caught it.
**Fix:** **Do not confirm the export.** Investigate the filtering change. Only lift/confirm the
threshold once you have confirmed the deletions are intended (T6).

## 11. Break-glass account is locked out
**Cause:** A Conditional Access / MFA policy is not excluding the break-glass accounts.
**Fix:** In `entra.microsoft.us`, exclude `bg-admin1@<yourtenant>.onmicrosoft.us` and
`bg-admin2@<yourtenant>.onmicrosoft.us` from all broad CA/MFA policies. Test per T8. These accounts
are your only recovery path if an auth change locks everyone out.

## 12. Connect Health shows no data
**Cause:** Health agent not installed or cannot reach Gov endpoints.
**Fix:** Confirm the Connect Health agent is installed and the Gov endpoints (R8) are reachable.
Connect Health is available in Azure for US Government (same source).

---
The deployment model (all solutions): Assess → Configure → Pilot → Validate → Expand.
