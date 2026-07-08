# 5. Testing Guide — Container Labeling (Teams, Groups & Sites)

Run after each configuration step. Every test is safe (read-only or a `-WhatIf` preview) except where it
asks you to observe real behavior in a labeled container. Validate on the
`Container Labels – Pilot Ring – Stage1` before treating the tenant as production-ready.

## Test 1 — Prerequisites and enablement are in place
**Do:** Run `IPCONT-Check-Prereqs.ps1`.
**Expected:** `EnableMIPLabels` reports `True`; container-scoped labels exist; the SharePoint tenant
`SharingCapability`/`ConditionalAccessPolicy` baseline is reported and is compatible with the taxonomy;
the required modules/connections are healthy. Any gap (e.g. P1 missing → device-access deferred) is
recorded, not guessed.

## Test 2 — Discovery inventory is complete and accurate
**Do:** Run `IPCONT-Discover-Containers.ps1`; spot-check a few containers in the Teams/SharePoint admin
centers.
**Expected:** Every M365 Group/Team and site is listed with its current privacy, guest-allowed, external
sharing, and assigned label; unlabeled containers are flagged. The spot-checks match.

## Test 3 — Enablement dry-run makes no changes
**Do:** Run `IPCONT-Set-ContainerLabels.ps1 -EnablePrerequisites -WhatIf`.
**Expected:** It states it *would* set `EnableMIPLabels = True` and run `Execute-AzureAdLabelSync` — and
changes nothing. Re-reading the `Group.Unified` setting shows it unchanged until `-Commit`.

## Test 4 — Labels exist with Groups & sites scope and are published
**Do:** Run `Get-Label | Where-Object {$_.ContentType -match 'Site' -or $_.DisplayName -like 'Container*'}`
and `Get-LabelPolicy`; as a pilot user, start creating a new Team/site.
**Expected:** The three container labels exist with the Groups & sites scope; `Container Labels – Groups &
Sites – Policy` is published to the pilot users; the labels appear in the container-creation UI for a
policy member and **not** for a non-member.

## Test 5 — Apply dry-run makes no changes and prints reverse commands
**Do:** Run `IPCONT-Set-ContainerLabels.ps1 -TargetsPath .\PilotTargets.csv -WhatIf`; afterward re-run
`IPCONT-Discover-Containers.ps1` on a target.
**Expected:** The dry-run lists the label it *would* apply per container plus the exact reverse command;
the target's assigned label is unchanged — `-WhatIf` truly changed nothing.

## Test 6 — Labels apply and the container posture matches the tier
**Do:** After `-Commit` on the pilot ring, run `IPCONT-Validate-ContainerLabels.ps1 -TargetsPath
.\PilotTargets.csv`.
**Expected:** Each target carries the intended label, and privacy, guest access, and external sharing
match the tier definition (e.g. `Highly Confidential` → Private, guests not allowed, org-only sharing).

## Test 7 — Guest access is governed by the label
**Do:** As an owner of a `Container – Highly Confidential` Team/Group, attempt to add an external guest.
**Expected:** The invite is blocked (guests not allowed by the label). On a `Container – General`
container the same action succeeds — the label, not the tenant default, is deciding.

## Test 8 — Unmanaged-device access is enforced (where Entra ID P1 applies)
**Do:** From a device that is **not** compliant/domain-joined, open a `Container – Confidential` site,
then a `Container – Highly Confidential` site.
**Expected:** `Confidential` opens **web-only** (no download/print/sync); `Highly Confidential` is
**blocked**. `General` opens with full access. (If P1/Conditional Access is not licensed, this test is
recorded as deferred, not failed.)

## Test 9 — Coverage report reflects reality
**Do:** Run `IPCONT-Report-ContainerLabeling.ps1`; review `Container Inventory – Report`.
**Expected:** The report shows the coverage percentage of in-scope containers and, per container, the
assigned tier and actual privacy/guest/sharing/device posture — matching what Tests 6–8 observed.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–9 pass on `Container Labels – Pilot Ring – Stage1`: prerequisites/enablement confirmed, inventory accurate, labels published, apply is safe + reversible, applied posture matches each tier, guest + device controls enforced (device where P1 applies) |
| **Expand pass** | Tests 5–6 and 9 pass again after each expansion wave, with coverage of in-scope containers meeting the agreed target and no container's posture drifting from its assigned tier |
