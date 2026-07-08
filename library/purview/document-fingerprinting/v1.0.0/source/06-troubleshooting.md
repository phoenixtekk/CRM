# 6. Troubleshooting — Document Fingerprinting (Microsoft Purview)

Symptom-first fixes for the failures you actually hit fingerprinting standard forms and running them in
DLP. Most problems are one of: a fingerprint that won't build, a form that isn't detected, a fingerprint
that over-matches, no alert on a match, or detection drifting as a form is revised.

---

## Creating the fingerprint / SIT

**`New-DlpFingerprint` fails or produces a weak fingerprint.**
- Confirm the source is **text-based with selectable boilerplate**, not a flattened image or scan — a
  fingerprint is built from extractable text, so an image-only file yields nothing usable. OCR the file
  to extractable text first, or source a text-based template.
- Confirm the file is a **supported type** and **within the size limit** (`.docx`, `.dotx`, `.pdf`,
  `.txt`, and similar; **verify current supported types/limits for your tenant**). Password-protected
  files can't be read.
- On **PowerShell 7**, `Get-Content -Encoding Byte` is not valid — use `-AsByteStream`. The delivered
  `CLSFINGER-CreateFingerprint.ps1` handles both PS 5.1 and PS 7 automatically.

**`New-DlpSensitiveInformationType` fails or the SIT doesn't appear.**
- Confirm your account holds **Compliance Administrator / Compliance Data Administrator** — a missing
  role surfaces as "cmdlet not recognized" or access denied.
- **Propagation:** a newly created SIT can take time to appear in the portal (**Data classification →
  Classifiers → Sensitive info types**) and to become selectable in a DLP rule. Wait and re-check with
  `Get-DlpSensitiveInformationType`.

## Detection (form not matched)

**A filled copy of a fingerprinted form isn't detected.**
- Confirm the SIT is actually **referenced by a DLP policy** and the policy is in a **mode that
  evaluates** — an *unreferenced* SIT is inert; a *disabled* policy does nothing; a **simulation**
  policy evaluates and logs but does not block. Check with `CLSFINGER-Validation.ps1` and
  `CLSFINGER-Discovery.ps1`.
- **Policy propagation takes time** — new/changed DLP policies can take **up to ~1 hour (longer for some
  locations)** to take effect. Wait before concluding it's broken.
- Confirm the **location scope** includes where you're testing and the test identity isn't in an
  **exclusion** (`CLSFINGER-Set-Scope.ps1` reports the Exchange include/exclude scope).
- The live form may have **drifted from the fingerprinted template** — if the boilerplate was
  substantially revised, re-fingerprint the current template (Req 2.5 / Impl. Phase 5 refresh) and add it
  to the SIT.
- The moved document may carry **only a fragment** of the form's text — fingerprinting needs substantial
  form structure to match; that a fragment isn't caught is expected behavior.

**Matches appear in simulation but nothing is blocked.**
- That is **correct** — simulation logs what *would* happen without enforcing. To block, move the policy
  to **enforce** for the pilot ring (Impl. Phase 5). If you expected blocking, you're still in simulation.

## Over-matching (false positives)

**Unrelated documents are matching the fingerprint.**
- The most common cause is **shared boilerplate** — the fingerprinted template's distinctive text is
  mostly a **common letterhead/header** that also appears on unrelated documents. **Re-source** a copy
  with more form-specific boilerplate (trim the generic chrome) and re-fingerprint.
- If **one SIT groups several forms** and it over-fires, **split** it so each form is detected on its own
  distinctive text.
- Add a targeted **exception** (specific sender/site) where justified — narrowly, with a documented
  reason. Re-simulate after each change and re-measure with `CLSFINGER-Report.ps1`; don't stack changes
  blind.

## Alerts / incident handling

**Form matches occur but no alert appears / no one is notified.**
- Confirm **alerts are configured** on the rule and check **Purview → Data loss prevention → Alerts**.
  Some low-severity matches aggregate rather than alert per event.
- Confirm **audit logging is enabled** in the tenant — the report script and Activity Explorer rely on it.
- Confirm the **triage owner/queue** (`Fingerprint Alerts – Triage – Operations`) exists and, if
  forwarding to SIEM/Sentinel, that the connector is healthy (Req 2.7).

**The report script returns no matches.**
- **Get-DlpDetectionsReport** may not be available in a pure S&C session — the script falls back to
  `Search-UnifiedAuditLog`; connect **Exchange Online** and confirm the **View-Only DLP / Audit** role.
- **Audit latency / dwell time:** DLP events take time to surface and a fresh policy may simply have no
  matches yet. Widen `-Days` and re-run.

## Refresh / drift

**Detection was working, now it's missing the current form.**
- The form was likely **revised** — the fingerprint reflects the template *as fingerprinted*. Obtain the
  new template, run `CLSFINGER-CreateFingerprint.ps1 -Commit` to **add** its fingerprint to the same SIT
  (a SIT can hold multiple fingerprints), and retire the old template's fingerprint where appropriate.

## Connectivity / tooling

**`Connect-IPPSSession` or a fingerprint/DLP cmdlet fails.**
- Ensure the **ExchangeOnlineManagement** module is installed/updated and you're using a **modern-auth /
  MFA-capable** admin.
- Confirm the account holds the required **DLP role** (Compliance Administrator / Compliance Data
  Administrator / DLP Compliance Management).

**A script made an unexpected change.**
- The delivered scripts are **read-only or `-WhatIf` by default**; writes require `-Commit`.
  `CLSFINGER-CreateFingerprint.ps1` only ever creates/updates a SIT (never a policy), and
  `CLSFINGER-Set-Scope.ps1` **never changes a policy's enforce/simulation mode**. The safe recovery for
  enforcement is always to set the policy back to **simulation** in the portal (one setting, no data
  change).

---

### Fast triage table

| Symptom | First check |
|---|---|
| Fingerprint won't build | Text-based/selectable? supported type/size? PS7 → `-AsByteStream` |
| SIT won't create/appear | Role (Compliance Admin), propagation delay |
| Form not detected | SIT referenced? policy mode (disabled/sim)? propagation? scope/exclusion? template drift? |
| Nothing blocked | Still in **simulation** — expected; enforce the ring to block |
| Unrelated docs matching | Shared letterhead — re-source form-specific template; split SIT; add exception |
| No alert on match | Alert config on rule, audit logging on, triage owner, SIEM connector |
| Report returns nothing | Exchange Online connected? audit role/latency, widen `-Days` |
| Was detecting, now misses | Form revised — re-fingerprint current template into the SIT |
| Cmdlet/connect fails | Module updated, modern auth, correct DLP role |
