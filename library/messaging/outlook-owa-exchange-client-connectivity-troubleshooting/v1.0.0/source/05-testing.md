# Testing & Validation

Validate the toolkit against these gates. Each test states the **procedure** and the
**expected pass/fail signal**. Run them against the **`ConnTest`** baseline first (everything
should PASS), then against an affected user during a real ticket. These same gates are the
pilot exit criteria in the deployment model.

> Run diagnostics read-only. Only after a change is approved and applied (change control) do
> you re-run the relevant gate to confirm the fix.

---

## Gate 1 — Autodiscover resolves (Discovery layer)

- **Procedure:** Remote Connectivity Analyzer → **Outlook Autodiscover** test for `ConnTest`
  and the affected user. Also `Resolve-DnsName autodiscover.<domain> -Type CNAME` and the
  `Test-AutodiscoverEndpoints.ps1` script.
- **PASS:** RCA reports **Autodiscover succeeded**; DNS returns the expected host
  (`autodiscover.outlook.com` for Commercial cloud-only — verify sovereign host); the script
  returns a healthy JSON/endpoint response.
- **FAIL:** RCA cannot complete Autodiscover, or DNS returns a wrong/absent record → root cause
  is the Discovery layer (playbook **D1**).

## Gate 2 — Each required protocol connects (Protocol layer)

- **Procedure:** `Get-CASMailbox <user>` (enablement) → `Test-OutlookConnectivity -MailboxId
  <user>` and `Test-OutlookWebServices -Identity <user>` → RCA **Outlook Connectivity**, **EWS**,
  **ActiveSync** tests. `Get-ClientConnectivityAssessment.ps1` summarizes enablement.
- **PASS:** Required protocols show **`True`** in `Get-CASMailbox`; the `Test-*` cmdlets return
  **Success**; RCA protocol tests pass. `ConnTest` connects in Outlook and OWA.
- **FAIL:** A required protocol is `False`, or a `Test-*` cmdlet / RCA test fails → Protocol
  layer (playbook **D2**).

## Gate 3 — Authentication succeeds (Auth layer)

- **Procedure:** Sign in as the user in Outlook desktop **and** OWA; inspect Entra **sign-in
  logs** (client app + Conditional Access result); `Test-ModernAuthConditionalAccess.ps1`.
- **PASS:** Sign-in logs show **Success** for the client app; Conditional Access shows
  **Success / Not applied** (no blocking Failure); no repeating credential prompt.
- **FAIL:** Repeating prompt / auth loop; sign-in log shows a **Conditional Access Failure** or
  MFA registration required → Auth layer (playbook **D3**).

## Gate 4 — Free/busy returns (hybrid) 

- **Procedure (hybrid only):** In Outlook/OWA, open the scheduling assistant for a cross-org
  attendee; on-prem EMS `Test-OrganizationRelationship -Identity <rel> -UserIdentity <user>`;
  RCA **Free/Busy** test.
- **PASS:** Availability shows real busy/free (not hash marks); `Test-OrganizationRelationship`
  and RCA free/busy **PASS**.
- **FAIL:** Hash marks (`/////`); relationship/free-busy test fails → playbook **D5**.
- **N/A:** Cloud-only tenants skip this gate.

## Gate 5 — Mobile syncs

- **Procedure:** Set up the affected user in **Outlook mobile** (Graph) and, if EAS is in use,
  a native mail app; `Get-CASMailbox <user> | Select ActiveSyncEnabled`; `Get-MobileDevice
  -Mailbox <user>`; RCA **Exchange ActiveSync** test.
- **PASS:** Outlook mobile syncs; EAS device is not quarantined/blocked; RCA ActiveSync passes
  (if EAS in scope).
- **FAIL:** Won't set up / device quarantined / EAS disabled → playbook **D6**.

## Gate 6 — Substitution isolation is conclusive (Client layer)

- **Procedure:** Confirm `ConnTest` on the affected client and the affected user on a known-good
  client / in OWA (playbook **D4.1**).
- **PASS:** The substitution cleanly localizes the fault to **server-side** (affected user fails
  everywhere) or **client-side** (only this client/profile fails) — you can state which.
- **FAIL:** Result is ambiguous → re-scope at **D0**; you have not yet isolated the layer.

---

## Regression / re-test after any remediation

After a change (Autodiscover DNS, protocol re-enable, SCP fix, relationship fix), re-run the
**specific gate** for that change plus a full `ConnTest` pass:

- `ConnTest` sets up cleanly in Outlook **and** OWA.
- The affected user now passes the gate that previously failed.
- No previously-passing gate has regressed (run Gates 1–3 as a smoke test).

**Pilot exit criterion:** the playbook resolves the target first-contact-resolution rate on the
pilot ticket batch, with every closed ticket carrying a named root-cause node (D1–D6) — before
expanding to the whole service desk.
