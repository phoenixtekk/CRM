# 5. Testing & Validation Guide — Mandatory vs Recommended Labeling Policy Design

Run these tests after the Implementation Guide, **in order**. Each has an explicit **pass/fail** signal
and a rollback. Do not expand from the pilot ring to the broad policy until the relevant tests pass —
because label-policy settings have **no simulation mode**, these pilot tests **are** your safety gate.
All checks use the Purview portal and Security & Compliance PowerShell — the provided scripts automate
the read-only ones.

> **Reminder:** you are validating that the configuration *behaves as designed* (mandatory/default/
> downgrade/recommend), not deciding which populations should be mandated — that is the governance
> determination from §2.

## Test 1 — Effective policy settings match the design
- **How:** `IPMANREC-Validation.ps1 -PolicyName "LabelPolicy – Pilot – Ring1"`, or `Get-LabelPolicy "LabelPolicy – Pilot – Ring1" | Select-Object -ExpandProperty Settings`.
- **Pass:** the policy shows the intended default label (`General`), `Mandatory = true`, downgrade justification on, and `DisableMandatoryInOutlook` set if Outlook was relaxed.
- **Fail:** a setting is missing or wrong → re-run the relevant `IPMANREC-PolicyConfig.ps1` mode with `-Commit` and re-validate.

## Test 2 — Default label applies to new content (pilot)
- **How:** as a **pilot** user, create a new document in Word/Excel/PowerPoint and a new email in Outlook.
- **Pass:** the new document/email is pre-set to `General` (the default label) rather than "no label"; the default is a **non-encrypting** label.
- **Fail:** no default applied (allow client sync time) or an encrypting label defaulted (wrong default — fix in Step 4) → re-check the policy default setting.

## Test 3 — Mandatory labeling prompts on documents
- **How:** as a pilot user, create a document, remove any label, and attempt to **save**.
- **Pass:** the user is **required** to choose a label before the save completes (mandatory is enforcing on documents).
- **Fail:** save completes with no label → confirm `Mandatory = true` on the pilot policy and allow client sync; confirm the user is in the pilot group.

## Test 4 — Outlook friction matches the per-app decision
- **How:** as a pilot user, compose and **send** an email with no label.
- **Pass (relaxed):** if `-RelaxOutlook` was used, send is **not** blocked (mandatory does not apply in Outlook). **Pass (strict):** if Outlook was intentionally kept mandatory, send is blocked until a label is chosen.
- **Fail:** behaviour is the opposite of the design → re-check `DisableMandatoryInOutlook` on the policy (Step 5); this is the most common adoption complaint, so confirm it matches the signed-off decision.

## Test 5 — Downgrade requires a justification and records it
- **How:** as a pilot user, take a document labelled `Confidential \ All Employees` and change it to `General` (or remove the label).
- **Pass:** the user is prompted to type a **justification**; the downgrade only completes after one is supplied.
- **Fail:** downgrade completes silently → confirm the downgrade-justification setting on the policy (Step 6); **verify the advanced-setting key in your tenant** if the portal toggle and PowerShell disagree.

## Test 6 — Downgrade justification appears in audit (evidence)
- **How:** after Test 5, in Purview → **Audit** (or `Search-UnifiedAuditLog`), search for the label-change / justification activity for the test document.
- **Pass:** the downgrade event (old label → new label, with the justification) is discoverable in the audit log — the intended evidence trail exists.
- **Fail:** no audit event → confirm auditing is enabled for the tenant and allow audit-ingestion latency; **verify audit availability for your licensing/tenant.**

## Test 7 — Recommended prompt suggests (does not force) the label
- **How:** as a pilot user, create content that matches `Confidential \ All Employees` conditions (e.g. the configured sensitive info type).
- **Pass:** a **recommend** prompt appears with the configured message ("This content looks sensitive — apply Confidential to protect it."); the user can **accept** (label applied) **or dismiss** (no label forced).
- **Fail (forces the label):** the label is auto-applied without a choice → the label's Office-app auto-labeling is set to **Automatic**, not **Recommend** — fix in Step 7. **Fail (no prompt):** conditions not matching or feature not licensed → verify the condition and **your licensing/tenant.**

## Test 8 — No conflicting settings across overlapping policies
- **How:** `IPMANREC-Health.ps1` (read-only).
- **Pass:** no user is covered by two policies that set **different** mandatory/default values; policy priority/order resolves predictably; the pilot policy targets only the pilot ring.
- **Fail:** a conflict is flagged (e.g. two policies with different default labels hitting the same users) → resolve the overlap (priority or scope) before expanding.

## Test 9 — Broad-policy settings match the accepted pilot design
- **How:** after Step 9, `IPMANREC-Validation.ps1 -PolicyName "LabelPolicy – Broad – AllUsers"`.
- **Pass:** the broad policy's effective settings equal the **accepted** pilot settings (mandatory scope, default label, downgrade, Outlook relaxation).
- **Fail:** divergence between pilot and broad → re-apply the signed-off settings to the broad policy and re-validate before relying on it.

## Test 10 — Posture evidence is complete
- **How:** `IPMANREC-Reporting.ps1 -CsvFolder <path>`; review the exported matrix.
- **Pass:** the report lists every policy's mandatory state, default label, downgrade state, and every label's recommend/automatic mode — matching the signed-off design matrix.
- **Fail:** a gap or mismatch → reconcile the configuration with the matrix and re-export.

---
### Exit criteria (all must be true before broad enforcement)
`Effective settings match design · default label applies · mandatory prompts on documents · Outlook friction matches decision · downgrade requires + records justification · recommend suggests (never forces) · no policy conflicts · broad == accepted pilot · posture evidence complete · rollback documented per setting`
