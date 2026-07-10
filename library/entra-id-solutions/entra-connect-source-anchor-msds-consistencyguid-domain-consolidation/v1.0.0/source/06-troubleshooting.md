# 6. Troubleshooting Guide — Migrating the Microsoft Entra Connect Source Anchor to mS-DS-ConsistencyGuid

Use `SRCANCHOR-Assess.ps1` and `SRCANCHOR-Test-Preconditions.ps1` for the pre-change state,
`SRCANCHOR-Check-Permissions.ps1` for the connector-account permission, and `SRCANCHOR-Validate.ps1` /
`SRCANCHOR-Report.ps1` for the post-change state. The anchor switch is effectively permanent — work
these issues before and immediately after the wizard, not after production waves.

## A. Wizard won't offer / won't allow mS-DS-ConsistencyGuid
| Symptom | Cause | Remediation |
|---|---|---|
| Wizard says mS-DS-ConsistencyGuid is "not empty" and refuses | One or more in-scope objects already have a value in mS-DS-ConsistencyGuid (prior Connect install, earlier migration, or manual stamp) | Run `SRCANCHOR-Test-Preconditions.ps1 -IncludeOU "<OU DN>"` to list them; investigate what populated the attribute, then either clear it after confirming it is safe, or exclude those objects from scope, until the count is zero — then retry the wizard |
| `Configure Source Anchor` is not offered at all | Microsoft Entra Connect Sync build too old to support the mS-DS-ConsistencyGuid operation | Confirm the version with `SRCANCHOR-Assess.ps1`; upgrade Entra Connect Sync to the current release (mS-DS-ConsistencyGuid is the default since Azure AD Connect 1.1.524), then retry |

## B. "Access denied" writing mS-DS-ConsistencyGuid (seed fails)
| Symptom | Cause | Remediation |
|---|---|---|
| Wizard/sync errors with access-denied when seeding the attribute | The AD DS connector (sync) account lacks Write permission to mS-DS-ConsistencyGuid on an in-scope OU | Run `SRCANCHOR-Check-Permissions.ps1 -ConnectorAccount "<DOMAIN\account>" -IncludeOU "<OU DN>"`; delegate Write mS-DS-ConsistencyGuid on the failing OU (Implementation Step 4 — ADUC Delegation of Control or `dsacls ... /G "<DOMAIN\account>:WP;mS-DS-ConsistencyGuid;user"`); re-run the check until every OU is PASS, then re-run the wizard |

## C. Duplicate or orphaned Entra objects after a migration
| Symptom | Cause | Remediation |
|---|---|---|
| A migrated user appears as a NEW/duplicate Entra account; the original is orphaned | Quest ODM did not stamp mS-DS-ConsistencyGuid onto the target object, or stamped a mismatched value | Confirm the mS-DS-ConsistencyGuid carry in Quest ODM (per Quest's docs, Requirement 2.6); for the affected user, align mS-DS-ConsistencyGuid on the target to the original immutableId, let a delta sync run, then hard-match/soft-match remediate the duplicate in Entra |
| Duplicates appeared for users migrated BEFORE the switch | Objects were migrated while the anchor was still objectGUID — their new objectGUID broke the match | Set mS-DS-ConsistencyGuid on the migrated (target) object to the original object's objectGUID Base64 value, re-sync, and remediate the resulting duplicate (hard-match by immutableId); migrate no further waves until the anchor switch and pilot pass |
| Cloud account separate from on-prem after migration | Soft-match failed (attribute mismatch) | Verify the migrated object's mS-DS-ConsistencyGuid equals the existing Entra user's onPremisesImmutableId; correct the attribute, re-sync, and hard-match by immutableId |

## D. AD FS sign-in breaks after the change
- If sign-in uses AD FS, changing the source anchor updates the issuance/claim rules against the
  **primary AD FS server**. If that update did not complete, federated sign-in can fail.
- Confirm direct network connections on **TCP 80, 443, and 5985** from the Connect server to the
  primary AD FS server (Requirement 2.7), then re-run the wizard's source-anchor/claim-rule step.
- If sign-in is PHS, PTA, or cloud authentication, this section does not apply — the claim-rule update
  is not performed.

## E. Version too old
- `SRCANCHOR-Assess.ps1` reports a Microsoft Entra Connect Sync build that predates mS-DS-ConsistencyGuid
  support (older than Azure AD Connect 1.1.524). Upgrade Entra Connect Sync to the current release, then
  re-run `SRCANCHOR-Assess.ps1` and proceed.

## F. Multi-forest conflicts
- mS-DS-ConsistencyGuid is a **single-forest** linking attribute. In a genuine multi-forest topology,
  the same anchor value could collide or fail to match across forests. Plan the multi-forest matching
  (which forest is authoritative, how objects are joined) before relying on mS-DS-ConsistencyGuid, and
  treat that planning as out of scope for this single-forest switch.

## G. Diagnostics quick reference
```powershell
Get-ADSyncGlobalSettings | Select-Object -ExpandProperty Parameters   # current source anchor
Start-ADSyncSyncCycle -PolicyType Delta                                # trigger a delta sync
Get-ADObject -LDAPFilter "(mS-DS-ConsistencyGuid=*)" -SearchBase "<OU DN>"  # objects already stamped
Get-ADSyncRunProfileResult -NumberRequested 10                         # recent run results/errors
```
Connector and run-profile detail is in the Synchronization Service Manager (`miisclient.exe`) on the
Connect host.

## H. When to escalate
If the version supports the operation, the precondition count is zero, the connector account has Write
mS-DS-ConsistencyGuid, and the wizard still refuses or the seed still fails, capture the
`SRCANCHOR-Assess.ps1` and `SRCANCHOR-Validate.ps1` output and the wizard/connector error, and open a
Microsoft support case before migrating any further objects.
