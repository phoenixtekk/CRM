# 5. Testing & Validation Guide — Office & PDF Rights Protection (RMS/IRM)

Run these tests after the Implementation Guide, **in order**. Each has an explicit **pass/fail** signal
and a rollback. Do not expand from the pilot ring to the broad policy until the relevant tests pass —
because label encryption has **no simulation mode**, these pilot tests **are** your safety gate. Checks
use the Purview portal, Security & Compliance PowerShell, and the AIPService module; the provided
scripts automate the read-only ones.

> **Reminder:** you are validating that protection *behaves as designed* (right people open with the
> right rights, wrong people are denied, PDF is covered, recovery works) — not deciding *who* should have
> access or how encrypted content is handled for legal/records; those are governance/legal
> determinations from §2.

## Test 1 — RMS service is activated and recoverable
- **How:** `IPRMS-Readiness.ps1` (or `Get-AipServiceConfiguration` / `Get-AipServiceSuperUserGroup`).
- **Pass:** the Rights Management service is **Activated**, the super-user feature is enabled, and
  `grp-rms-superusers@contoso.com` is set as the super-user group.
- **Fail:** service not activated → `Enable-AipService`; no super-user → enable and set the group
  (Step 2) **before** any broad publish.

## Test 2 — Each label's effective encryption matches the design
- **How:** `IPRMS-Validation.ps1 -LabelName "Confidential\All Employees"` (repeat for each label).
- **Pass:** `EncryptionEnabled = True`; protection type is **Template** (assigned) or **UserDefined** as
  designed; the rights definition, offline days, and expiry match §1.
- **Fail:** a setting is missing/wrong → re-run the relevant `IPRMS-LabelProtection.ps1` mode with
  `-Commit` and re-validate.

## Test 3 — A template label protects an Office document for the right audience
- **How:** as a pilot user, apply `Confidential \ All Employees` to a Word/Excel/PowerPoint file; have an
  **in-scope** org user open it.
- **Pass:** the file is encrypted (protection banner shown) and the in-scope user opens it with the
  intended rights (view/edit/print/copy for Co-Author).
- **Fail:** file not encrypted (allow client sync; confirm the label's encryption is on) or wrong rights
  → re-check Step 5.

## Test 4 — The wrong recipient is denied
- **How:** share the same protected file with an **out-of-scope** account (e.g. an external address not
  in any grant).
- **Pass:** the out-of-scope user is **denied** — they cannot obtain a use license / cannot open the
  content.
- **Fail:** an out-of-scope user opens it → the grant is too broad (e.g. AuthenticatedUsers where a named
  group was intended) → correct the rights definition (Step 5/7) and re-test. This is the most important
  protection test.

## Test 5 — Usage rights actually restrict (view-only means no print/copy)
- **How:** as a member of `grp-rms-named-recipients@contoso.com`, open a file labeled `Highly
  Confidential \ Named Recipients`.
- **Pass:** the user can **view** but the app blocks **print, copy, and edit** (Viewer rights only).
- **Fail:** the user can print/copy → the rights definition granted more than VIEW → correct it
  (Step 7) and re-test.

## Test 6 — Do Not Forward / Encrypt-Only works in Outlook
- **How:** as a pilot user, apply `Confidential \ Recipients Only` to an email and send to a recipient;
  the recipient attempts to **forward**.
- **Pass:** the recipient can read but **cannot forward** (Do Not Forward); for Encrypt-Only files, the
  content is encrypted to the chosen recipients.
- **Fail:** forwarding succeeds → confirm Exchange **IRM** is enabled (Req 2.6) and the label is
  user-defined with DNF (Step 6).

## Test 7 — A protected PDF opens for the right people in a supported reader
- **How:** export/label a **PDF** as `Confidential \ All Employees`; open it in a supported reader
  (e.g. Microsoft Edge) as an in-scope user, then attempt as an out-of-scope user.
- **Pass:** the in-scope user opens the protected PDF with the intended rights; the out-of-scope user is
  denied; the reader honors the protection.
- **Fail:** the PDF opens unprotected, or a supported reader can't open it → confirm PDF protection/
  handling is enabled (Req 2.6) and the reader supports Microsoft Information Protection — **verify your
  PDF-reader/tenant support**.

## Test 8 — Super-user recovery works
- **How:** as a member of `grp-rms-superusers@contoso.com`, open a file protected with a label whose
  grant does **not** include you.
- **Pass:** the super-user can open/decrypt the content for recovery — the records/legal recovery path
  exists.
- **Fail:** super-user cannot open → confirm the super-user feature is enabled and the group is set
  (Step 2); allow propagation.

## Test 9 — Content expiry / offline access behave as configured
- **How:** review a label with a content-expiry or short offline-access value and confirm the
  configuration (`IPRMS-Validation.ps1`); where an expiry date is set, confirm access lapses per design.
- **Pass:** offline-access days and content-expiry match §1; expired content is no longer openable by
  standard users (super-user recovery still works).
- **Fail:** values differ from the design → re-apply via `IPRMS-LabelProtection.ps1` and re-validate.

## Test 10 — Broad-policy publish matches the accepted pilot, and posture evidence is complete
- **How:** after Step 10, `IPRMS-Validation.ps1` on a sample against the broad policy and
  `IPRMS-Report.ps1 -CsvFolder <path>`.
- **Pass:** the labels published to `RMSPolicy – Broad – AllUsers` carry the **accepted** pilot encryption
  settings; the posture report lists every label's encryption/type/rights/offline/expiry plus RMS
  activation and super-user state — matching the signed-off design.
- **Fail:** a gap or mismatch → reconcile and re-export; confirm no protection label was left only in the
  pilot policy.

---
### Exit criteria (all must be true before broad enforcement)
`RMS activated + super-user recovery works · each label's encryption matches design · right audience opens
with right rights · wrong recipient denied · view-only restricts print/copy · DNF/Encrypt-Only works ·
protected PDF honored in a supported reader · content-expiry/offline as configured · broad == accepted
pilot · posture evidence complete · rollback (remove protection/unpublish) documented per label`
