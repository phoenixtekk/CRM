# 6. Troubleshooting Guide — Office & PDF Rights Protection (RMS/IRM), Microsoft Purview

Symptom → likely root cause → fix. Use **`IPRMS-Discovery.ps1`** (RMS state / encryption posture),
**`IPRMS-Readiness.ps1`** (activation / super-user / IRM / licensing / pilot sanity),
**`IPRMS-Validation.ps1`** (a label's effective encryption), and **`IPRMS-Report.ps1`** (posture matrix)
to confirm before and after each fix. Label encryption has **no simulation mode**, so most issues surface
on the **pilot ring first** — that is by design. Cmdlet/parameter names and PDF-reader support are
**tenant-/version-dependent**; where flagged, **verify against current Microsoft guidance / your tenant**.

## A. Service availability / setup

### Applying an encryption label fails (content won't protect)
- **RMS not activated.** Label encryption depends on the Rights Management service being **Activated**.
  **Fix:** `IPRMS-Readiness.ps1` (or `Get-AipServiceConfiguration`); if not activated, `Enable-AipService`
  under change control (Req 2.5), then retry.
- **Wrong role.** Label encryption edits need **Information Protection Admin**; activation/super-user need
  RMS/Global Admin. **Fix:** confirm the roles (Req 2.3).

### The Encryption page/settings aren't available on the label
- **Licensing insufficient.** Label encryption requires an AIP/MIP-enabled plan. **Fix:**
  `IPRMS-Readiness.ps1` licensing signal; confirm the plan in the M365 admin center — **verify your
  licensing/tenant** (Req 2.2).

### `Set-Label -Encryption*` parameter is rejected
- **Cmdlet/param drift.** Encryption parameter names can vary by module version. **Fix:** confirm the
  ExchangeOnlineManagement module is current; **verify the exact parameter against current Microsoft
  documentation**; the script flags encryption params.

## B. Protection doesn't apply (false negatives)

### A file labeled with a protection label isn't encrypted
- **Client hasn't synced / label not published to the user.** **Fix:** confirm the label is published in
  the policy scoping the user (`IPRMS-Discovery.ps1`); allow client sync (restart Office); confirm the
  user is in `grp-rms-pilot@contoso.com` during pilot.
- **Encryption not actually enabled on the label.** **Fix:** `IPRMS-Validation.ps1 -LabelName …`; if
  `EncryptionEnabled` is false, re-run `IPRMS-LabelProtection.ps1 -SetTemplate/-SetUserDefined -Commit`.

### Do Not Forward / Encrypt-Only doesn't work in Outlook
- **Exchange IRM not enabled.** **Fix:** `IPRMS-Readiness.ps1` IRM check (or `Get-IRMConfiguration`);
  enable IRM for Exchange Online (Req 2.6); confirm the label is **user-defined** with DNF (Step 6).

## C. Protection is wrong / too broad (the critical failures)

### The wrong recipient can open protected content
- **Grant too broad.** Most common cause: the rights definition grants **AuthenticatedUsers** where a
  **named group** was intended. **Fix:** `IPRMS-Validation.ps1 -LabelName … -ExpectIdentity
  "grp-rms-named-recipients@contoso.com"` flags an over-broad grant; re-run `IPRMS-LabelProtection.ps1
  -SetTemplate -RightsIdentity "<named group>" -Rights "VIEW,VIEWRIGHTSDATA" -Commit`. Re-test with
  Test 4 — proving the wrong recipient is **denied** is the point of the control.

### A view-only recipient can still print or copy
- **Rights definition too permissive.** VIEW alone should not allow print/extract. **Fix:** confirm the
  rights string is exactly the intended set (e.g. `VIEW,VIEWRIGHTSDATA` — no `PRINT`/`EXTRACT`/`DOCEDIT`);
  re-apply (Step 7) and re-test (Test 5). RMS usage-right keywords — **verify the exact set against
  current Microsoft documentation**.

### A default/auto grant encrypted content nobody intended to protect
- **Encryption on a label that's applied too widely.** **Fix:** encryption should be on deliberate
  protection labels, not a broad default. Remove protection from the over-applied label
  (`IPRMS-LabelProtection.ps1 -RemoveProtection -Commit`) and re-scope which label carries encryption.

## D. External recipients

### An external partner can't open a file they should be able to
- **No identity / external sharing not configured.** External recipients must authenticate to get a use
  license. **Fix:** confirm the grant includes the external address/domain; **verify the current
  external-sharing / one-time-passcode options for your tenant**; have the recipient sign in with a
  supported identity.

## E. PDF specifics

### A protected PDF opens unprotected, or a valid reader can't open it
- **PDF protection/handling not enabled, or reader unsupported.** **Fix:** confirm labeled/protected
  **PDF** handling is enabled for the tenant/workload (Req 2.6); open in a reader that supports Microsoft
  Information Protection (e.g. Microsoft Edge); **verify your PDF-reader/tenant support** — older/third-
  party readers may not honor protection. Where support is uncertain, standardize on a supported reader.

## F. Recovery / continuity

### Encrypted content can't be recovered (departed user / mis-scoped grant)
- **No super-user configured.** Without a super-user, encrypted content locked to an unavailable identity
  is unrecoverable. **Fix:** enable the super-user feature and set `grp-rms-superusers@contoso.com`
  (Step 2); confirm with Test 8. **Do this before broad publish.**

### The super-user still can't open a protected file
- **Feature/group not propagated, or membership wrong.** **Fix:** `Get-AipServiceSuperUserGroup` returns
  the group; confirm the tester is a member; allow propagation; re-test.

## G. Rollout / drift

### A protection label is stranded in the pilot policy after expansion
- **Not published to the broad policy (or configured but never published).** **Fix:** `IPRMS-Readiness.ps1`
  flags encrypting labels published only to a pilot-named policy or not published at all; publish the
  accepted labels to `RMSPolicy – Broad – AllUsers` (Step 10).

### RMS/IRM/super-user silently changed
- **Config drift.** **Fix:** run `IPRMS-Discovery.ps1` / `IPRMS-Report.ps1` on a cadence; reconcile any
  change to RMS activation, the super-user group, IRM, or a label's protection against the signed-off design.

---
## Escalation checklist
1. `IPRMS-Readiness.ps1` — RMS Activated? super-user set? IRM enabled? licensing signal? pilot sanity?
2. `IPRMS-Discovery.ps1` — which labels encrypt, with what type/rights/offline/expiry?
3. `IPRMS-Validation.ps1 -LabelName … -ExpectType … -ExpectIdentity …` — does the grant match the design,
   and is it **not** over-broad (no AuthenticatedUsers where a named group was intended)?
4. Live test — right recipient opens with the right rights (Test 3/5), **wrong recipient denied** (Test 4),
   PDF honored (Test 7), super-user recovers (Test 8).
5. Still stuck → capture the exact behaviour and **verify the current Microsoft guidance / your tenant**
   for RMS usage rights, encryption parameters, and PDF-reader support before a tenant-wide change. *Who*
   may access what and how encrypted content is handled for legal/records remain governance/legal
   determinations — this guide fixes the *technical protection*, not the *access decision*.
