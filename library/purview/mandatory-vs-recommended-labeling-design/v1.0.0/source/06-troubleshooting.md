# 6. Troubleshooting Guide — Mandatory vs Recommended Labeling Policy Design (Microsoft Purview)

Symptom → likely root cause → fix. Use **`IPMANREC-Discovery.ps1`** (current posture),
**`IPMANREC-Validation.ps1`** (a policy's effective settings), **`IPMANREC-Health.ps1`** (conflicts /
pilot sanity), and **`IPMANREC-Reporting.ps1`** (posture matrix) to confirm before and after each fix.
Label-policy behaviour settings have **no simulation mode**, so most issues surface on the **pilot ring
first** — that is by design. Advanced-setting **key names differ by tenant/version**; where a key is
flagged, **verify it in your tenant** (portal toggle vs PowerShell) before a broad change.

## A. Availability / setup

### A setting or toggle isn't present when configuring the policy
- **Licensing insufficient.** Mandatory labeling and default labels work broadly, but **recommended /
  automatic labeling for Office apps** (client-side conditions) is plan-gated (typically E5 / E5
  Compliance). **Fix:** confirm the subscription in the M365 admin center; the recommend prompt (Step 7)
  needs the advanced classification licensing — **verify your licensing/tenant** (Req 2.1).
- **Wrong role.** Label/policy edits require **Information Protection Admin** (or a role that includes it).
  **Fix:** confirm the role under Purview → Roles & scopes (Req 2.2).

### Portal toggle and PowerShell advanced-setting disagree
- **Key name drift.** The exact advanced-setting key (e.g. downgrade justification) can differ by
  tenant/version. **Fix:** set the behaviour once in the **portal Policy-settings wizard**, then read it
  back with `IPMANREC-Validation.ps1` to learn the resolved key your tenant uses; align the script value
  to that key. The scripts flag these keys as "verify in your tenant".

## B. Behaviour doesn't apply (false negatives)

### The default label doesn't apply to new content
- **Client hasn't synced.** Policy changes take time to reach Office clients. **Fix:** wait for client
  sync (sign out/in or restart Office); re-test with a pilot user.
- **User not in the policy scope.** The pilot user isn't in the published group. **Fix:**
  `IPMANREC-Discovery.ps1` shows the policy's scope; confirm the user is in `grp-labeling-pilot@contoso.com`.
- **Default set on the wrong policy or as "None".** **Fix:** `IPMANREC-Validation.ps1 -PolicyName …`;
  confirm `DefaultLabelId` resolves to the intended **non-encrypting** label (Step 4).

### Mandatory labeling doesn't prompt on save
- **`Mandatory` not effective / client not synced.** **Fix:** confirm `Mandatory = true` on the pilot
  policy with `IPMANREC-Validation.ps1`; allow client sync; confirm the user is in the pilot group.

### The recommend prompt never appears
- **Conditions don't match.** The label's Office-app auto-labeling conditions (e.g. the sensitive info
  type) aren't met by the test content. **Fix:** test with content that clearly matches; lower confidence
  if too strict.
- **Feature not licensed.** Client-side recommend conditions are licensing-gated. **Fix:** **verify your
  licensing/tenant** (Req 2.1).

## C. Behaviour is too aggressive (false positives / adoption pain)

### Outlook blocks email send and users complain
- **Outlook kept strict when it should be relaxed.** This is the single most common adoption complaint.
  **Fix:** confirm the per-app decision (§2.7). If email should not be blocked, run
  `IPMANREC-PolicyConfig.ps1 -SetMandatory -RelaxOutlook -Commit` (`DisableMandatoryInOutlook = true`);
  re-test send. If email *should* be mandatory, this is working as designed — confirm the signed-off decision.

### The recommend label force-applies instead of suggesting
- **Label set to Automatic, not Recommend.** **Fix:** `IPMANREC-Validation.ps1 -RecommendLabel …` shows
  the mode; re-run `IPMANREC-PolicyConfig.ps1 -SetRecommend -LabelName …` so auto-labeling is **Recommend**
  (a prompt the user can dismiss), not Automatic (Step 7).

### A default label unexpectedly encrypts new content
- **Encrypting label chosen as the default.** A default that applies encryption causes surprise
  encryption and breaks sharing. **Fix:** set the default to a **non-encrypting** label (e.g. `General`);
  rollback is `DefaultLabelId = None`. Confirm with `IPMANREC-Discovery.ps1`.

## D. Downgrade justification

### Downgrade completes silently (no justification prompt)
- **Setting off or wrong key.** **Fix:** re-run `IPMANREC-PolicyConfig.ps1 -SetDowngradeJustification
  -Commit`; if it still doesn't prompt, **verify the advanced-setting key in your tenant** (portal toggle
  "Users must provide justification…") and align the script to the resolved key.

### The justification isn't discoverable as evidence
- **Auditing off or latency.** **Fix:** confirm unified audit is enabled for the tenant; allow audit
  ingestion latency, then re-search (Test 6). **Verify audit availability for your licensing/tenant.**

## E. Conflicting / overlapping policies

### Users get unpredictable mandatory/default behaviour
- **Overlapping policies with different values.** Priority resolves opaquely. **Fix:** `IPMANREC-Health.ps1`
  flags policies with different mandatory/default values hitting overlapping populations; reconcile via
  **one coherent policy per population** or an explicit, documented priority (§7).

### A pilot policy is still mandating after the ring dissolved
- **Stale pilot.** **Fix:** `IPMANREC-Health.ps1` flags pilot-named policies still mandating; confirm the
  design expanded to the broad policy, then retire the pilot policy.

## F. Expansion / evidence

### Broad policy behaves differently from the accepted pilot
- **Settings not re-applied identically.** **Fix:** re-run each `IPMANREC-PolicyConfig.ps1` mode against
  `LabelPolicy – Broad – AllUsers`, then `IPMANREC-Validation.ps1` on the broad policy to confirm it equals
  the accepted pilot design (Step 9).

### The posture matrix has gaps or mismatches
- **Configuration drifted from the design matrix.** **Fix:** `IPMANREC-Reporting.ps1 -CsvFolder <path>`;
  reconcile any policy/label that doesn't match the signed-off matrix and re-export.

---
## Escalation checklist
1. `IPMANREC-Discovery.ps1` — do the pilot/broad policies exist with the intended scope?
2. `IPMANREC-Validation.ps1 -PolicyName …` — do effective settings (mandatory / default / downgrade /
   Outlook / recommend) match the design on the policy in question?
3. `IPMANREC-Health.ps1` — any conflicting/overlapping policies or a stale pilot still mandating?
4. `IPMANREC-Reporting.ps1 -CsvFolder …` — does the posture matrix match the signed-off design?
5. Still stuck → capture the exact behaviour, compare the **portal toggle** to the **resolved advanced
   setting**, and **verify the current Microsoft guidance / your tenant** for the setting's key before a
   tenant-wide change. Regulatory/records determinations (which populations to mandate) remain with the
   governance owner — this guide fixes the *technical behaviour*, not the *policy decision*.
