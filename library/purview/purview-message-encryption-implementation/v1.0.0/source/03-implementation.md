# Implementation — Purview Message Encryption (OME) in Microsoft Purview

This is the ordered, do-this-then-that guide. It follows the standard model
(**Assess → Design → Configure → Pilot (Audit mode / pilot group) → Validate → Expand (Enforce)**) and
— because a mis-scoped encryption rule changes how mail is delivered — it enables the **RMS foundation
first**, sets **branding**, then builds the mail flow rules in **`Audit` mode scoped to a pilot group**
before anything encrypts in production. Every object is named verbatim so the scripts, testing, and
troubleshooting line up. Replace the `contoso.com` / sample names with your own.

> **Toolchain note.** OME is administered in **Exchange Online** — these steps use **Exchange Online
> PowerShell** (`Connect-ExchangeOnline`): `Set-IRMConfiguration`, `*-OMEConfiguration`,
> `*-TransportRule`, `Test-IRMConfiguration`. Label-driven encryption additionally uses **S&C
> PowerShell** (`Connect-IPPSSession`). Some settings (Azure RMS activation, and the branding preview)
> are surfaced in the Microsoft Purview / Exchange admin portals — where a path or parameter may differ
> by tenant/licence, **verify against your licensing/tenant.**

> **Hard gate before you enforce.** Do **not** flip any mail flow rule from `Audit` to `Enforce` until
> compliance/privacy have confirmed **what** should be encrypted and to which template (R5), and the
> Testing gates pass. *What is sensitive* is a business determination (`global-requirements-purview.md`
> §5), not a technical default.

---

## Phase 0 — Assess (confirm you can build safely)

1. **Confirm licensing (R1).** Verify the AIP/Azure RMS entitlement for the pilot senders (Basic OME);
   confirm E5/E5 Compliance if you need **custom branding / revocation / expiration** (Advanced).
2. **Confirm the RMS foundation (R2).** Connect Exchange Online PowerShell and run
   **`OME-Discovery.ps1`** (read-only). Confirm `AzureRMSLicensingEnabled : True` and that
   `Test-IRMConfiguration` passes.
   - **Gate 0a:** RMS is enabled and `Test-IRMConfiguration` passes → continue. Otherwise run
     `Set-IRMConfiguration -AzureRMSLicensingEnabled $true` (and activate Azure RMS in the portal),
     then re-test.
3. **Confirm roles (R3).** The connected account holds Exchange **Organization Management** (or the
   least-privilege transport-rules + IRM role group).
4. **Confirm the toolchain** (`global-requirements-purview.md` §3): `Connect-ExchangeOnline` succeeds
   (and `Connect-IPPSSession` if you will use label-driven encryption).

## Phase 1 — Design (agree it with compliance/privacy, then name everything)

Decide and **record with compliance/privacy**:

- **Branding (R4):** the default OME configuration's logo, background/accent colour, portal text,
  disclaimer, and email text; and whether any **custom** template (`OME-Branding-Corp`, Advanced only)
  is needed.
- **Trigger conditions → template (R5):**
  - **`OME-Encrypt-Outbound-Pilot`** — condition: sender ∈ **`SG-OME-Pilot`** **AND** (subject
    contains **`[encrypt]`** **OR** recipient is **external**) → template **`Encrypt`**.
  - **`OME-DoNotForward-Confidential`** — condition: message carries the **`Highly Confidential`**
    sensitivity label (or the agreed classification/header) → template **`Do Not Forward`**.
- **Pilot scope:** a named group, **`SG-OME-Pilot`**, holding a small set of sanctioned pilot senders.
- **Manual controls:** confirm the Outlook **Encrypt** / **Do Not Forward** options are enabled for
  users who need to protect one-off messages deliberately.

## Phase 2 — Configure the RMS foundation and branding

In **Exchange Online PowerShell**:

1. **Enable RMS (if not already, R2).** `Set-IRMConfiguration -AzureRMSLicensingEnabled $true`, then
   `Test-IRMConfiguration -Sender pilot@contoso.com -Recipient external@example.com` — confirm all
   checks **PASS**.
2. **Set the default branding.** Use **`OME-Configure.ps1 -Action Branding -WhatIf`** to preview, then
   `-Commit` to apply, or run `Set-OMEConfiguration` directly against the default configuration
   (identity **"OME Configuration"**) — logo, `BackgroundColor`, `EmailText`, `PortalText`,
   `DisclaimerText`, `ReadButtonText` (**verify current property names in your tenant**).
3. **(Advanced only) Create a custom branding template.** If licensed, `New-OMEConfiguration -Identity
   "OME-Branding-Corp"` then `Set-OMEConfiguration -Identity "OME-Branding-Corp" ...` for a per-flow
   look.
- **Pass/fail:** `Get-OMEConfiguration` returns the branding you set; a test send renders it (Phase 4 /
  Testing Gate 4). **Rollback:** re-run `Set-OMEConfiguration` to restore prior values (record the
  originals first with `OME-Discovery.ps1`).

## Phase 3 — Build the mail flow rules in AUDIT mode, scoped to the pilot

In **Exchange Online PowerShell**, create the rules with **`OME-Configure.ps1 -Action MailFlowRules
-WhatIf`** (prints the exact plan), then **`-Commit`** (creates them in **`Audit` mode**). The
equivalent direct commands:

1. **`OME-Encrypt-Outbound-Pilot`** (template `Encrypt`, Audit first):
   ```powershell
   New-TransportRule -Name "OME-Encrypt-Outbound-Pilot" `
     -FromMemberOf "SG-OME-Pilot@contoso.com" `
     -SentToScope NotInOrganization `
     -SubjectContainsWords "[encrypt]" `
     -ApplyRightsProtectionTemplate "Encrypt" `
     -Mode Audit
   ```
   (Combine/loosen the `-SubjectContainsWords` / `-SentToScope` conditions to match your Phase-1
   design; to apply a custom branding template add `-ApplyRightsProtectionCustomizationTemplate
   "OME-Branding-Corp"` — **verify the exact parameter name in your tenant**.)
2. **`OME-DoNotForward-Confidential`** (template `Do Not Forward`, Audit first):
   ```powershell
   New-TransportRule -Name "OME-DoNotForward-Confidential" `
     -FromMemberOf "SG-OME-Pilot@contoso.com" `
     -HeaderMatchesMessageHeader "msip_labels" `
     -HeaderMatchesPatterns "<Highly Confidential label GUID>" `
     -ApplyRightsProtectionTemplate "Do Not Forward" `
     -Mode Audit
   ```
   (The `msip_labels` header carries the applied sensitivity-label GUID — **verify the header name and
   your label GUID**; alternatively key on a keyword/classification per Phase 1.)
- **Pilot rule:** every rule is created with **`-Mode Audit`** and scoped to **`SG-OME-Pilot`**. In
  `Audit` mode the rule **matches and logs but does not encrypt** — so nothing changes for real mail
  yet.
- **Pass/fail:** `Get-TransportRule` shows both rules **enabled, `Mode = Audit`**, scoped to the pilot
  group. `OME-Validate.ps1` confirms mode/scope. **Rollback:** `Disable-TransportRule` (or
  `Remove-TransportRule`); Audit mode changes nothing for users, so pilot rollback is trivial.

## Phase 4 — Pilot and validate (run the gates)

Work the gates in `05-testing.md`. In summary, from a **sanctioned pilot sender** in `SG-OME-Pilot`:

- Send a test message that matches `OME-Encrypt-Outbound-Pilot` (subject `[encrypt]`, external
  recipient). In **`Audit` mode**, confirm via **message trace** / rule Audit logs that the rule
  **matched** — without the message actually being encrypted yet.
- Temporarily flip **only the one pilot rule** to `Enforce` for a controlled test window (or use a
  dedicated test rule) and confirm a real test send is **encrypted, branded, and readable** by an
  internal and an external test recipient (OTP/portal for external — R7).
- Confirm **`Do Not Forward`** actually **prevents forwarding/printing/copying** for the recipient.
- Confirm reporting (`OME-Report.ps1`) reconciles with **message trace**.
- **Do not enforce broadly** until every gate passes **and** compliance/privacy confirm the
  condition→template mapping (R5).

## Phase 5 — Expand (enforce, then widen — only after the gate passes)

1. **Flip rules to Enforce.** Change each rule's mode: `Set-TransportRule -Identity
   "OME-Encrypt-Outbound-Pilot" -Mode Enforce` (and the DNF rule). Watch the first cohort closely via
   message trace and help-desk signal.
2. **Widen scope deliberately** — add members to `SG-OME-Pilot` (or broaden the rule's `-FromMemberOf`
   / `-SentToScope`) **group-by-group**, not tenant-wide in one move, using `OME-ScopeHealth.ps1`
   (read-only preview) to stage the expansion. **Re-run the gates** after each expansion.
3. **(Advanced) Enable revocation/expiration if licensed.** For external OME-portal mail, confirm
   `Get-OMEMessageStatus` and `Set-OMEMessageRevocation` are available, and set expiration on the OME
   configuration (`ExternalMailExpiryInDays` — **verify property/licensing**).

---

### Rollback summary

| Change | Rollback |
| --- | --- |
| Branding wrong / broken logo | Re-run `Set-OMEConfiguration` to restore the prior values (captured by `OME-Discovery.ps1` before you changed them). |
| Encryption rule too broad / breaking a flow | `Set-TransportRule -Mode Audit` (or `Disable-TransportRule`) — encryption stops immediately; tune conditions and re-pilot. |
| DNF too restrictive for a flow | Change that rule's template to `Encrypt`, or narrow its condition; DNF only where forwarding must be blocked. |
| Rule scoped too far | Remove members from `SG-OME-Pilot` (`OME-ScopeHealth.ps1` preview first), or tighten `-FromMemberOf`; the rule follows the scope. |
| RMS/IRM change caused mail issues | Re-run `Test-IRMConfiguration` to isolate; `Set-IRMConfiguration` to correct; RMS enablement is tenant-wide, so change it under change control. |

> **Never** treat OME as a substitute for the business decision about **what is sensitive**. The
> conditions and templates here **enforce** a policy; deciding *which mail* must be encrypted, and for
> how long it may be readable, is a **compliance/privacy/legal determination** (§5). This solution
> provides the method and the evidence, not the determination.
