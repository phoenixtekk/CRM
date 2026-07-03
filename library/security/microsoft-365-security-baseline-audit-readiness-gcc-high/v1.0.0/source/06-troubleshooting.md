# Troubleshooting — Microsoft 365 Security Baseline & Audit Readiness (Government / GCC High)

GCC-High-specific failures and how to fix them. Most problems on the sovereign cloud trace back to one
root cause: **something is pointed at the Commercial cloud instead of the `*.us` sovereign endpoints.**
Check that first, every time.

> Before deep-diving any issue, run environment sanity checks E1–E4 in `05-testing.md`. If
> `(Get-MgContext).Environment` is not `USGov`, stop — that alone explains most "weird" results.

---

## A. Sign-in, portal, and "wrong cloud" issues

### A1. A `*.us` portal won't load, or shows a tenant that isn't yours
- **Likely cause:** you signed in with a Commercial account, or the browser cached a Commercial
  session.
- **Fix:** sign out fully; sign in with your **GCC High** account against **`login.microsoftonline.us`**
  at the specific `*.us` portal (`security.microsoft.us`, `compliance.microsoft.us`,
  `entra.microsoft.us`). Use a fresh/incognito window to avoid cached Commercial tokens.

### A2. `security.microsoft.com` / `compliance.microsoft.com` opens but Secure Score / Compliance Manager data is missing
- **Likely cause:** you're on the **Commercial** portal, not the sovereign one.
- **Fix:** switch to **`security.microsoft.us`** (Secure Score) and **`compliance.microsoft.us`**
  (Compliance Manager). GCC High data never appears in the `*.com` portals.

### A3. `Connect-MgGraph` redirect / "wrong tenant" / "wrong version number" error
- **Likely cause:** you connected **without** `-Environment USGov`, so the SDK tried the Commercial
  authority for a GCC High account.
- **Fix:**
  ```
  Disconnect-MgGraph
  Connect-MgGraph -Environment USGov -Scopes "SecurityEvents.Read.All"
  (Get-MgContext).Environment   # must return USGov
  ```
  Confirm the env exists: `Get-MgEnvironment` should list `USGov` with Graph endpoint
  `https://graph.microsoft.us`.

### A4. Script output looks plausible but numbers don't match the portal
- **Likely cause:** the script connected to Commercial (wrong cloud) and returned data from the wrong
  place — or from an empty/foreign context.
- **Fix:** every script in this solution guards on `(Get-MgContext).Environment -eq 'USGov'`. If you
  adapted a community script, add the same guard and re-point `graph.microsoft.com` →
  `graph.microsoft.us`. Re-run.

---

## B. Microsoft Graph / PowerShell issues

### B1. `Get-MgEnvironment` doesn't list `USGov`
- **Likely cause:** outdated Microsoft Graph SDK.
- **Fix:** update the module: `Update-Module Microsoft.Graph` (or reinstall
  `Install-Module Microsoft.Graph -Scope CurrentUser`). Restart PowerShell and re-check.

### B2. `Install-Module Microsoft.Graph` fails (can't reach the Gallery)
- **Likely cause:** proxy/firewall blocks the PowerShell Gallery.
- **Fix:** allow the Gallery, or install from an offline package on an admin workstation that has
  access. Then confirm R8 network reachability to the **`*.us`** endpoints (not just Commercial).

### B3. Consent / scope errors on first connect
- **Likely cause:** required delegated scopes aren't consented in the GCC High tenant.
- **Fix:** have a Global Administrator (or Privileged Role Administrator) approve the consent prompt, or
  pre-consent in **`entra.microsoft.us`** → Enterprise applications. Grant **only** the scopes the task
  needs (read for Discovery/Validation/Report; write only for Remediation).

### B4. Remediation script "changed nothing"
- **This is expected.** `M365SECG-Remediation.ps1` and `M365SECG-Set-ScopeTargeting.ps1` **default to
  `-WhatIf`** — they only preview. Review the preview, confirm it matches your approved ticket, then
  re-run with **`-Execute`**.

---

## C. Secure Score issues

### C1. An improvement action you expected isn't in the list
- **Likely cause:** **feature parity** — some Secure Score recommendations **are not available in GCC
  High** (cited in `gcc-high-parity-notes.md`).
- **Fix:** confirm against the parity notes. If it's a known GCC High gap, record it as **"N/A — GCC
  High parity"** in your backlog; it is not a defect. Do **not** try to force an action that depends on
  **Microsoft Threat Experts** or **enterprise IoT** — those are absent in GCC High.

### C2. Score didn't move after applying an action
- **Likely cause:** refresh lag, or the action was scoped to pilot only and Secure Score reflects
  tenant-wide state.
- **Fix:** allow ~24–48 hours and re-check **Secure Score → History** (**verify for GCC High** — Gov
  refresh cadence may differ). Confirm the control is actually in the state the action requires; some
  actions only credit at broader coverage.

### C3. Defender API calls fail (if you script against the Defender API directly)
- **Likely cause:** using the Commercial API base URI.
- **Fix:** for **GCC High**, use **`https://api-gov.securitycenter.microsoft.us`** with sign-in
  authority **`https://login.microsoftonline.us`** (cited in parity notes). GCC uses
  `https://api-gcc.securitycenter.microsoft.us`.

---

## D. Compliance Manager issues

### D1. Can't assign Compliance Manager roles in the portal
- **Likely cause:** in **GCC High and DoD**, Compliance Manager **permissions/roles are set in
  Microsoft Entra ID**, not in the portal's own role UI.
- **Fix:** assign the Compliance role in **`entra.microsoft.us`** → Roles and administrators (cited in
  parity notes).

### D2. A Compliance Manager feature described in Commercial docs is missing
- **Likely cause:** it's **in development / rolling out** for GCC High (e.g. **alerts and
  notifications**, **recommended engine for bulk assessment creation**, **continuous compliance
  assessments**).
- **Fix:** confirm status in `gcc-high-parity-notes.md`. Don't build a process that depends on a
  feature that isn't live yet in GCC High.

### D3. CMMC templates not available
- **Likely cause:** licensing. **CMMC Levels 1–5** templates are **included with G5 (Gov)**.
- **Fix:** confirm a **G5 Gov** license (R2). The **Microsoft Data Protection Baseline** is included for
  everyone and works without G5 — start there if you're on G3.

---

## E. Rollout / lockout issues

### E1. A pilot user is locked out after an auth-impacting change
- **Action:** **execute the rollback** from your change ticket immediately (disable/undo the named CA
  policy in `entra.microsoft.us`). Then diagnose in a controlled way before re-piloting. In GCC High
  there is **no Commercial fallback**, so treat any lockout as a stop-the-line event.

### E2. Change worked in pilot but broke a broader wave
- **Likely cause:** the wider cohort includes a user/device type your pilot didn't represent.
- **Fix:** roll the wave back to the last-good scope, add the missing persona to `SEC-Baseline-Pilot`,
  re-pilot, re-validate, then expand again.

---

## F. First things to check (fast triage)

1. **Are you on `*.us`?** Portal host and `(Get-MgContext).Environment = USGov`.
2. **Right account?** Signed in against `login.microsoftonline.us` with a GCC High account.
3. **Right license?** Gov SKU present (R2); G5 Gov if using CMMC.
4. **Role in Entra?** Least-privilege role assigned in `entra.microsoft.us` (and CM roles set in Entra).
5. **Is it parity, not a bug?** Cross-check `gcc-high-parity-notes.md` before filing a "missing feature."
