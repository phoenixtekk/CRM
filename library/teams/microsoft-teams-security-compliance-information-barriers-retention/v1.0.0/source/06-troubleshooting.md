# 6. Troubleshooting

Common failure modes for the Teams-specific compliance controls and how to resolve them. Artifact
names match the Implementation Guide.

---

## A. Information barriers

### A1. IB cmdlets not found / access denied
- **Symptom:** `New-OrganizationSegment` / `New-InformationBarrierPolicy` are unrecognized, or return an
  access-denied error.
- **Likely cause:** Not connected to **Security & Compliance PowerShell** (used `Connect-ExchangeOnline`
  or `Connect-MicrosoftTeams` by mistake), missing the **Information Barriers** role group, or the plan
  does not entitle IB.
- **Resolve:** Connect with `Connect-IPPSSession`; confirm membership in the Information Barriers role
  group (Requirements item 2); verify the compliance entitlement (item 1). Government cloud: use the
  cloud-specific connection URI (verify in your tenant).

### A2. IB application stuck or failed
- **Symptom:** `Get-InformationBarrierPoliciesApplicationStatus` shows `In progress` for a long time or
  `Failed`.
- **Likely cause:** A prior application run has not finished (only one runs at a time), a segment
  attribute is missing/inconsistent, or a conflicting address book policy exists.
- **Resolve:** Wait for the current run to finish before starting another; confirm the segment
  attribute is populated for the affected users (use `TEAMSCOMP-ScopeHelper.ps1`); clear conflicting
  ABPs (Requirements item 6). Re-run `Start-InformationBarrierPoliciesApplication`.

### A3. Barrier not enforced in Teams (users can still chat)
- **Symptom:** A GroupA user can still chat with, find, or add a GroupB user after application.
- **Likely cause:** Policy left `Inactive`, application not completed, **scoped directory search** not
  enabled, users carry no segment attribute, or replication has not propagated yet.
- **Resolve:** Confirm the policy `State = Active` and application `Completed` (Tests 1–2); enable
  scoped directory search (Requirements item 5); verify recipient status
  (`Get-InformationBarrierRecipientStatus`); allow time for propagation across the tenant.

### A4. A user is blocked from everyone / unexpectedly
- **Symptom:** A user cannot communicate with anyone, or an unexpected pair is blocked.
- **Likely cause:** The user matches more than one segment, or the block/allow direction is inverted in
  the policy definition.
- **Resolve:** Check the user's resolved segments with `Get-InformationBarrierRecipientStatus`; a user
  should map to exactly one segment. Confirm the block vs allow model with compliance and correct the
  policy (`-SegmentsBlocked` vs `-SegmentsAllowed`), then re-apply. **Rollback:** set the policy
  `Inactive` and re-apply to lift the barrier while you fix it.

## B. Teams retention

### B1. "Teams locations cannot be combined" error
- **Symptom:** `New-RetentionCompliancePolicy` errors when Teams locations are added alongside
  Exchange/SharePoint locations.
- **Likely cause:** Teams locations must live in a retention policy of their **own**.
- **Resolve:** Create a separate policy (`Retention Policy – Teams Chat+Channel – Pilot`) that contains
  only the Teams locations.

### B2. Retention not applying to Teams messages
- **Symptom:** Messages are not being retained/deleted per the schedule.
- **Likely cause:** Policy `Enabled = False`, wrong scope (chat vs channel vs private/shared channel),
  or content is under an eDiscovery/Litigation hold that supersedes deletion.
- **Resolve:** Confirm `Enabled = True` and the correct Teams location scope (Test 4); remember holds
  preserve content regardless of a delete action — coordinate with the eDiscovery/legal owner. Note
  Teams retention can take time to take effect after enabling.

### B3. Private/shared channel messages not covered
- **Symptom:** Standard-channel messages are retained but private/shared channel messages are not.
- **Likely cause:** The policy did not include `-TeamsPrivateChannelLocation` /
  `-TeamsSharedChannelLocation`, or those parameters are not available on your tenant's version.
- **Resolve:** Add the channel-type locations your determination requires; **verify parameter
  availability in your tenant** — channel-type coverage is version-dependent.

## C. Teams DLP

### C1. DLP policy not matching anything in Teams
- **Symptom:** No events appear in Activity explorer / DLP alerts when test content is sent.
- **Likely cause:** The `-TeamsLocation` scope does not include the test chat, the referenced
  sensitive-information type does not actually match the test value, or the policy is `Disable`d.
- **Resolve:** Confirm the Teams location scope covers the pilot chat; use a **synthetic** value that
  genuinely matches the SIT (Microsoft's SIT test data); confirm the policy is in a Test/Enable mode
  (Tests 5–6).

### C2. DLP blocking legitimate messages (false positives)
- **Symptom:** Users report legitimate Teams messages being blocked.
- **Likely cause:** The policy was moved to enforce/block before the audit gate cleared false positives.
- **Resolve:** Return the policy to `-Mode TestWithoutNotifications` (impact stops immediately), tune
  the rule (confidence level, count thresholds, exceptions), re-run the audit gate, then re-enforce.

### C3. Cannot reference a sensitive-information type or label
- **Symptom:** `New-DlpComplianceRule` fails on the `-ContentContainsSensitiveInformation` value.
- **Likely cause:** The SIT/label name is misspelled or not present in the tenant.
- **Resolve:** Reuse the org's **approved** SITs/labels from the Purview program (Requirements item 7);
  confirm the exact name exists before referencing it.

## D. Cross-cutting

### D1. Connected to the wrong endpoint
- **Symptom:** Compliance cmdlets missing though Teams cmdlets work (or vice versa).
- **Resolve:** IB/retention/DLP need **`Connect-IPPSSession`** (Security & Compliance PowerShell);
  Teams client settings need **`Connect-MicrosoftTeams`**; ABP checks need
  **`Connect-ExchangeOnline`**. They are separate endpoints.

### D2. Government cloud path differences
- **Symptom:** Connection or portal URLs from Commercial docs do not work.
- **Resolve:** Government clouds use different endpoints (for example `*.office365.us`) and portal URLs;
  use your cloud's connection URI and **verify in your tenant** rather than assuming the Commercial path.

### D3. Change appears not to take effect immediately
- **Symptom:** A newly enabled policy or barrier is not visible right away.
- **Resolve:** Purview policy propagation and IB application are asynchronous and tenant-wide; allow
  time to propagate, then re-validate with `TEAMSCOMP-Validation.ps1` before concluding it failed.
