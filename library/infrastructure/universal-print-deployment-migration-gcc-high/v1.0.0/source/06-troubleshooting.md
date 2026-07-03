# Troubleshooting — Universal Print on GCC High

GCC-High-specific symptoms and fixes. Most Universal Print problems on a Government tenant trace
back to one of four root causes: **wrong cloud (`.com` instead of `.us`)**, **missing
`-Environment USGov`**, **missing US Gov registry keys on older clients**, or **blocked
`*.print.azure.us` endpoints**. Work the table for your symptom; each fix references the relevant
implementation step.

> Re-run **`UPRTG-Discovery.ps1` → `UPRTG-Validation.ps1`** after any fix to confirm resolution.

---

## T1. Sign-in fails / "account doesn't exist" / redirect error when connecting Graph

- **Likely cause:** Connecting against the **Commercial** identity endpoint. A GCC High account
  does not exist at `login.microsoftonline.com`.
- **Fix:** Always connect with **`Connect-MgGraph -Environment USGov`** (all bundled scripts do
  this). Confirm the sign-in page shows **`login.microsoftonline.us`**. If you scripted
  `Connect-MgGraph` yourself, add `-Environment USGov`.
- **Verify:** `UPRTG-Discovery.ps1` completes sign-in and reports UP reachable.

## T2. Universal Print blade shows "not available" or licensing banner in the portal

- **Likely cause A — wrong cloud:** You opened **`portal.azure.com`**. GCC High uses
  **`portal.azure.us`**.
- **Likely cause B — licensing:** The admin account has **no eligible UP license**, or licensing
  hasn't propagated yet.
- **Fix:** Open **`portal.azure.us`**. In `portal.office365.us` confirm the admin holds a GCC
  High SKU (`SPE_E3_USGOV_GCCHIGH` / `SPE_E5_USGOV_GCCHIGH` / `Universal_Print_for_GCCHIGH_USGOV_GCCHIGH`).
  **Wait up to 24 hours** after assigning a license.
- **Reference:** `02-requirements.md` R2/R4; `03-implementation.md` Steps 1, 3.

## T3. Printer discovery fails on Windows 10 / older Windows 11 clients (works on Win 11 22H2+)

- **Likely cause:** Pre-22H2 clients are not natively supported in GCC High and are trying
  **Commercial** print endpoints because the **three US Gov registry keys** are missing.
- **Fix:** Deploy to the **user** context (via Intune or user-context script), then have the user
  sign out/in:
  ```
  reg add "HKCU\SOFTWARE\Microsoft\Print\MPS" /t REG_SZ /v "OAuthAuthority"    /d "https://login.microsoftonline.us/common" /f
  reg add "HKCU\SOFTWARE\Microsoft\Print\MPS" /t REG_SZ /v "MSGraphBaseUrl"    /d "https://graph.microsoft.us/v1.0" /f
  reg add "HKCU\SOFTWARE\Microsoft\Print\MPS" /t REG_SZ /v "MSGraphResourceId" /d "https://graph.microsoft.us" /f
  ```
- **Best fix:** Upgrade the device to **Windows 11 22H2+**, which works natively with no keys.
- **Reference:** `03-implementation.md` Step 8; `gcc-high-parity-notes.md` §4.

## T4. Connector won't register or drops offline

- **Likely cause A — endpoints blocked:** Proxy/firewall does not allow the GCC High
  **`*.print.azure.us`** endpoints and `login.microsoftonline.us` / `graph.microsoft.us`.
- **Likely cause B — proxy in user context only:** The connector runs as a **service
  (LocalSystem)**; a user-context proxy setting doesn't apply.
- **Likely cause C — cloned host:** A cloned connector host runs in parallel and blocks printing.
- **Fix:** Allow the endpoints in `02-requirements.md` R6. Set the proxy for **LocalSystem** with
  `bitsadmin`. If cloned, turn off the clone (or remove the connector from the clone **without**
  unregistering printers).
- **Reference:** `03-implementation.md` Steps 4–5.

## T5. Endpoints unreachable / intermittent print failures

- **Likely cause:** Firewall allows Commercial UP URLs (`*.print.microsoft.com`) but **not** the
  GCC High `*.print.azure.us` set.
- **Fix:** Explicitly allow, on both connector host and clients, outbound 443 to:
  `print.print.azure.us`, `register.print.azure.us`, `discovery.print.azure.us`,
  `notification.print.azure.us`, `graph.print.azure.us`, `login.microsoftonline.us`,
  `graph.microsoft.us`.
- **Verify:** `UPRTG-Discovery.ps1` endpoint check passes.
- **Reference:** `gcc-high-parity-notes.md` §3.

## T6. Printer registered but users can't see it

- **Likely cause:** The printer is registered but **not Shared**, or the user's **targeting
  group** isn't granted on the share, or the user isn't in the group.
- **Fix:** In `portal.azure.us` → Universal Print → Printers → Share the printer (`UP-Pilot-Printer-01`)
  and grant **`UP-Pilot-Users`**. Confirm the user is a member (`entra.microsoft.us` → Groups).
  Re-run targeting with `UPRTG-Set-ScopeTargeting.ps1 -WhatIf` then apply.
- **Reference:** `03-implementation.md` Steps 6–7, 9.

## T7. Delegated (scoped) admin not working in GCC High

- **Likely cause:** **Delegated Administration** was **not yet available in GCC High** at
  authoring ("coming soon").
- **Fix:** Manage centrally with **Printer Administrator** / **Printer Technician** roles for now.
  **Verify current GCC High availability** before designing a scoped-admin model.
- **Reference:** `gcc-high-parity-notes.md` §6.

## T8. macOS users can't print

- **Likely cause:** **macOS client printing was not yet available in GCC High** at authoring.
- **Fix:** Do not rely on Universal Print for Mac users on GCC High yet, and do not retire a
  server that is their only print path. **Verify current GCC High availability.**
- **Reference:** `gcc-high-parity-notes.md` §6.

## T9. Print jobs succeed but don't appear in reporting / job pool concerns

- **Likely cause:** Report refresh lag, or misunderstanding of job counting.
- **Fix:** Check **`portal.azure.us` → Universal Print → Usage and Reports**. Remember a **single
  document = one job** regardless of pages/copies/color/duplex; a job counts only when completed.
  If the pool is near exhaustion, buy 500/10,000-job add-ons.
- **Reference:** `07-best-practices.md` §2.

## T10. "It worked in the lab (Commercial) but not in production (GCC High)"

- **Likely cause:** The lab used Commercial portals/endpoints/Graph; production is GCC High.
- **Fix:** Re-check every URL ends in `.us`, every script uses `-Environment USGov`, endpoints are
  `*.print.azure.us`, and licensing is the GCC High SKU. This is the single most common
  cross-cloud mistake — the **Commercial vs GCC High** table in `01-solution-overview.md` is your
  checklist.

## T11. DoD tenant — nothing works

- **Likely cause:** **Universal Print is not available in DoD.** This is expected, not a
  misconfiguration.
- **Fix:** There is no supported Universal Print deployment in DoD at authoring. Track the
  Microsoft 365 roadmap. **Verify for DoD** before assuming a change.
- **Reference:** `gcc-high-parity-notes.md` §1.

---

## Escalation checklist (before opening a Microsoft support case)

1. `UPRTG-Discovery.ps1` output (US Gov Graph reachable? endpoints reachable?).
2. `UPRTG-Report.ps1` current-state report (printers, shares, connector, targeting).
3. Confirm cloud: all portals `.us`, all scripts `-Environment USGov`.
4. Confirm licensing propagated (≥24 h) for the affected users **and** the admin.
5. Client `winver` + registry-key presence for any pre-22H2 device.
6. Endpoint allow-list includes the full `*.print.azure.us` set.
7. Note whether the blocked capability is a known **GCC High parity gap** (Delegated Admin,
   macOS) rather than a fault.
