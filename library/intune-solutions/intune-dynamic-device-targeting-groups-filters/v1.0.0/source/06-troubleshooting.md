# 6. Troubleshooting Guide — Dynamic Device Targeting in Intune

Use `DYNTGT-Discovery.ps1` for the group/filter inventory, `DYNTGT-Validation.ps1` for a device's
membership and effective targeting, `DYNTGT-Report.ps1` for fleet coverage and drift, and
`DYNTGT-Remediation.ps1` (default `-WhatIf`) for safe fixes to mis-scoped assignments.

## A. Device not in the expected dynamic group
| Symptom | Cause | Remediation |
|---|---|---|
| New device missing from a dynamic group | Membership rule not yet evaluated, or attribute not populated | Wait for evaluation; confirm the attribute (ownership, category, `enrollmentProfileName`) is set; run `DYNTGT-Discovery.ps1` |
| Device should match but does not | Rule syntax or attribute value mismatch | Re-check the rule against the device's actual attribute value; correct the rule or the attribute |
| Device stays after it should leave | Attribute still set, or evaluation lag | Update the attribute; allow re-evaluation |

## B. Policy/app reaching the wrong devices
| Symptom | Cause | Remediation |
|---|---|---|
| Devices outside intent receive the assignment | Group too broad and no filter applied | Attach an include filter (for example `OS Version – Windows 11 – Include`) to the assignment |
| BYOD receiving a corporate assignment | No ownership exclusion | Attach `Ownership – Personal – Exclude` in Exclude mode |
| Include filter drops everyone | Filter rule matches nothing on this platform | Validate the filter rule and platform; run `DYNTGT-Validation.ps1` |

## C. Effective targeting not what was intended
- Remember precedence: group membership, then filter include/exclude on the assignment, then any
  exclude-assignment beating an include-assignment. Validate the effective result with
  `DYNTGT-Validation.ps1` rather than assuming from intent.
- Overlapping filters or an exclude group can silently remove devices; check for a competing exclude
  assignment on the same policy/app.

## D. Filter cannot be applied to an assignment
- Confirm the filter's platform matches the assignment's platform; a mismatched-platform filter will
  not be selectable. Recreate the filter for the correct platform if needed.

## E. Coverage gaps / drift
- Devices matched by no targeting group appear in `DYNTGT-Report.ps1` drift output; add or broaden a
  dynamic group rule to cover them, or correct their attributes so an existing rule matches.

## F. Diagnostics quick reference
```powershell
Connect-MgGraph -Scopes 'Group.Read.All','DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All'
# Dynamic groups with their membership rules
Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=groupTypes/any(c:c eq 'DynamicMembership')&`$select=displayName,membershipRule"
# Assignment filters
Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/assignmentFilters"
```

## G. When to escalate
If the membership rule and device attributes are correct, the filter validates on the right platform,
no competing exclude assignment exists, and effective targeting is still wrong after re-evaluation,
capture `DYNTGT-Report.ps1` and `DYNTGT-Validation.ps1` output and open a Microsoft support case.
