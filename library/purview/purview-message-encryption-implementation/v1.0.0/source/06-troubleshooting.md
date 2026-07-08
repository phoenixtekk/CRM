# 6. Troubleshooting — Purview Message Encryption (OME) in Microsoft Purview

The failure modes you'll hit configuring and operating OME. Each: **symptom → likely cause → fix.**
Most "encryption isn't working" reports are actually RMS not enabled, a rule still in `Audit` mode, a
condition that doesn't match, or a recipient-experience issue — this guide separates those from real
faults. OME is administered in **Exchange Online PowerShell** (`Connect-ExchangeOnline`); label-driven
encryption also uses **S&C PowerShell** (`Connect-IPPSSession`).

## `Test-IRMConfiguration` fails, or `AzureRMSLicensingEnabled` is False
- **Cause A — RMS not enabled.** Azure RMS/IRM is the foundation; without it nothing encrypts. **Fix:**
  `Set-IRMConfiguration -AzureRMSLicensingEnabled $true`, activate Azure RMS in the portal, then
  re-run `OME-ScopeHealth.ps1 -Sender <pilot> -Recipient <external>` (Gate 2).
- **Cause B — licensing.** The sender lacks an AIP/Azure RMS entitlement. **Fix:** confirm licensing
  (Requirement R1); **verify your licensing/tenant** — plan names evolve.
- **Cause C — propagation.** RMS was just enabled. **Fix:** allow propagation, then re-test.

## `Get-RMSTemplate` returns no `Encrypt` / `Do Not Forward` template
- **Cause:** RMS isn't active yet, or templates haven't propagated. **Fix:** confirm Gate 2 passes,
  allow time, re-run `OME-Discovery.ps1`. **Verify template availability in your tenant** — do not
  invent template names.

## A message that should encrypt isn't being encrypted
- **Cause A — rule in Audit mode (expected during pilot).** In `Audit` the rule **matches and logs but
  does not encrypt** — this is by design until you enforce. **Fix:** confirm with `OME-Validate.ps1`;
  encryption begins only when the rule is deliberately flipped to `Enforce` (Phase 5, after the gates).
- **Cause B — condition mismatch.** The subject keyword (`[encrypt]`), recipient scope
  (`NotInOrganization`), or label header/GUID doesn't match the test message. **Fix:** re-check the
  rule conditions against the test (`OME-Configure.ps1 -Action MailFlowRules -WhatIf` reprints the
  plan); confirm the sender is in `SG-OME-Pilot`.
- **Cause C — sender out of scope.** The sender isn't a member of `SG-OME-Pilot`. **Fix:** confirm
  membership with `OME-ScopeHealth.ps1`.

## The label-driven Do-Not-Forward rule doesn't fire
- **Cause:** the `msip_labels` header pattern doesn't match your actual label GUID, or the message
  never carried the label. **Fix:** capture the real header from a labeled test message and confirm the
  **Highly Confidential** label GUID (**verify the header name and your label GUID in your tenant**);
  alternatively key on the agreed keyword/classification per the Phase-1 design. *Which* mail warrants
  DNF is a compliance/privacy determination — configure to their mapping.

## External recipient can't open the encrypted message
- **Cause A — recipient experience.** External recipients read via **one-time passcode / OME portal**
  (Requirement R7); a mail/social account mismatch or a blocked portal breaks the flow. **Fix:** have
  them use the OTP path; confirm the OME portal is reachable from their side.
- **Cause B — branding renders as untrusted.** Missing/broken branding looks like phishing. **Fix:**
  re-run `Set-OMEConfiguration` (Phase 2), verify with `OME-Validate.ps1` and a test send (Gate 4);
  **verify current logo size/format limits.**

## Branding doesn't appear, or the logo is broken
- **Cause A — wrong identity.** You set branding on a custom template but the rule uses the default
  configuration (or vice-versa). **Fix:** confirm which configuration the rule applies; align them.
- **Cause B — logo format/size.** The image exceeds current limits or is an unsupported format.
  **Fix:** resize/reformat; **verify current limits in your tenant.**
- **Cause C — Advanced feature without licensing.** Custom branding templates need **Advanced Message
  Encryption (E5 / E5 Compliance)**. **Fix:** confirm licensing (R1) or fall back to default branding.

## `Set-OMEConfiguration` / `New-TransportRule` — "term is not recognized"
- **Cause:** wrong endpoint. `*-OMEConfiguration`, `*-IRMConfiguration`, `*-TransportRule`,
  `Test-IRMConfiguration`, `Get-RMSTemplate` are **Exchange Online PowerShell**
  (`Connect-ExchangeOnline`). **Fix:** connect Exchange Online; both endpoints ship in
  `ExchangeOnlineManagement`.

## A rule is encrypting more mail than intended after enforcement
- **Cause:** the condition is too broad (e.g. all external recipients) or the scope was widened too
  fast. **Fix (immediate):** `Set-TransportRule -Mode Audit` (or `Disable-TransportRule`) — encryption
  stops at once; tune the condition and re-pilot. Widen scope **group-by-group** with
  `OME-ScopeHealth.ps1`, re-running the gates each time.

## `OME-Report.ps1` counts don't match message trace
- **Cause:** message trace is authoritative; the report is a scoped rollup and message trace does not
  label every path as "encrypted." **Fix:** reconcile against message trace and, for Advanced external
  mail, `Get-OMEMessageStatus` (Gate 9). Message-trace retention is tenant-dependent — **verify.**

## Revocation / expiration options aren't available
- **Cause:** message revocation and expiration are **Advanced Message Encryption** features and apply to
  OME-portal (external) mail. **Fix:** confirm E5 / E5 Compliance licensing (R1); confirm
  `Get-OMEMessageStatus` / `Set-OMEMessageRevocation` and the expiration property in your tenant
  (**verify property/licensing**).

## When to escalate beyond this solution
- **What must be encrypted, what triggers Do Not Forward, and how long external mail stays readable** →
  **compliance / privacy / legal** (this solution configures and evidences the method; the mapping is
  their determination — deferred).
- **Records-retention or legal-hold interaction with encrypted mail** → **records / legal.**
- **Feature genuinely absent despite correct licensing** → verify against current Microsoft
  documentation and open a Microsoft support case; OME/Advanced Message Encryption capabilities evolve.
