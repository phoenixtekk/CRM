# 3. Implementation

Follow these steps in order. They implement the reference design from Section 1 using the house model
— **Assess → Design → Configure → Pilot → Validate → Expand** — with explicit **pass/fail gates** and a
**documented rollback** for every high-impact change (posting/access-settings tightening, external-member
removal, retirement). **Every artifact is named** with `<Type> – <Scope> – <Purpose>` (or the
convention for that object) and the **exact name is reused** in later steps, testing, troubleshooting,
and the scripts. Navigation is written for the current Google Admin console; where a page is evolving it
is flagged **"verify in your tenant."**

Throughout, `corp.example` stands in for the organization's primary domain.

---

## Stage 0 — Assess (read-only baseline)

**Step 0.1 — Inventory the Groups estate and its risk posture.**
Run the read-only assessment to get a baseline before changing anything:
```
python groups_inventory_hygiene_assessment.py --domain corp.example --json > baseline-groups.json
```
It enumerates every group and flags **ORPHANED** (no live owner), **STALE** (empty / no recent
activity), **EXTERNAL-EXPOSED** (external members or public settings), **OVER-PERMISSIONED**
(access-granting group with open settings), and **NAMING-NONCONFORMANT** (name/prefix off-standard).
Save the output as artifact **`Baseline – Groups Estate – Assess`**.

**Step 0.2 — Record the current Admin-console Groups baseline.** In **admin.google.com → Directory →
Groups → Settings** (org-wide **sharing/settings** for groups) and **Apps → Google Workspace → Groups
for Business**, note the current values for: **who can create groups**, **default access level**,
**allow external members**, **who can post to groups from outside the organization**. This is your
**rollback reference** — capture it before any change.

> **Gate 0 (baseline captured):** you have `Baseline – Groups Estate – Assess` and the recorded
> Admin-console settings. **Pass** → proceed to Design. Do not change settings until the baseline exists.

---

## Stage 1 — Design (agree the model)

**Step 1.1 — Finalise the type catalogue and per-type policy.** Confirm the five types and lock the
**default settings per type** (see table). This table is the policy the validators and helpers enforce.

| Type (prefix) | whoCanJoin | whoCanPostMessage | whoCanViewGroup | whoCanViewMembership | External members | Security label |
| --- | --- | --- | --- | --- | --- | --- |
| Distribution (`dl-`) | `INVITED_CAN_JOIN` | `ALL_IN_DOMAIN_CAN_POST` | `ALL_IN_DOMAIN_CAN_VIEW` | `ALL_MANAGERS_CAN_VIEW` | No | Optional |
| Security/Access (`sec-`) | `INVITED_CAN_JOIN` | `NONE_CAN_POST` | `ALL_MANAGERS_CAN_VIEW` | `ALL_MANAGERS_CAN_VIEW` | No | **Required** |
| Collaboration (`collab-`) | `CAN_REQUEST_TO_JOIN` | `ALL_MEMBERS_CAN_POST` | `ALL_MEMBERS_CAN_VIEW` | `ALL_MEMBERS_CAN_VIEW` | No | Optional |
| Dynamic (`dyn-`) | membership computed (CEL) | per underlying type | `ALL_IN_DOMAIN_CAN_VIEW` | `ALL_MANAGERS_CAN_VIEW` | No | Optional |
| External (`ext-`) | `INVITED_CAN_JOIN` | `ALL_MEMBERS_CAN_POST` | `ALL_MEMBERS_CAN_VIEW` | `ALL_MEMBERS_CAN_VIEW` | **Yes (allow-listed)** | Optional |

> Setting names/values above are Groups Settings API fields; confirm the exact enum values against the
> Groups Settings API reference for your tenant version — **verify in your tenant** where a value is
> deprecated or renamed.

**Step 1.2 — Finalise the naming convention.** Lock `<Type> – <Scope> – <Purpose>` display names and the
email prefixes. Example canonical artifacts used through the rest of this guide:
- `Distribution – Finance – All Staff` → `dl-finance-all@corp.example`
- `Security – Finance – AP Drive Access` → `sec-finance-ap@corp.example`
- `Collaboration – Finance – AP Team Inbox` → `collab-finance-ap@corp.example`
- `Dynamic – Sales – All Sales` → `dyn-sales-all@corp.example`
- `External – ProjectX – Partner Collab` → `ext-projectx-partner@corp.example`
- Owner group (never individuals): `Security – Groups – Owners` → `sec-groups-owners@corp.example`

**Step 1.3 — Design the ownership model.** Standard: **≥2 owners per group**, and prefer an **owner
*group*** as the `OWNER` rather than named individuals, so ownership survives departures. Nominate
`sec-groups-owners@corp.example` (from Step 1.2) as the default owner group for governed/security groups.

**Step 1.4 — Design the lifecycle.** Document **request → approve → review → retire**: the intake
form/queue (from Requirement 2.5), the approval rule (must specify type, scope, purpose, owner group,
external? and be approved to the type catalogue), the **review cadence** (owner-attested, e.g.
quarterly for `sec-`/`ext-`, annually for `dl-`/`collab-`), and the **staged retirement** procedure
(Stage 5).

**Step 1.5 — Choose the pilot scope.** Select one scope to pilot on and name it **`Pilot OU – Groups –
Finance`** — the Finance function's groups (or an equivalent). All Stage-3/4 changes are made here first.

> **Gate 1 (design signed off):** type catalogue, naming convention, ownership model, lifecycle, and
> named pilot scope are documented and approved by the Groups/security owners. **Pass** → Configure.

---

## Stage 2 — Configure the org-wide baseline

Make these **once**, tenant-wide, before touching individual groups. Each has a rollback (revert to the
values recorded in Step 0.2).

**Step 2.1 — Restrict who can create groups.** In **admin.google.com → Directory → Groups → Settings**
(org sharing settings), set group creation to **admins/allow-listed only** (or route all creation through
the lifecycle intake). This stops uncontrolled sprawl at the source.
*Rollback:* re-open creation to the previous value.

**Step 2.2 — Set the restrictive default access baseline.** In the same settings, set the **default
access level** to the internal-only / restricted option and **disable "allow external members"** at the
org default (external is enabled per-group only on `ext-*` groups in Stage 3).
*Rollback:* restore the previous default access + external-members value.

**Step 2.3 — Lock inbound external posting default.** In **Apps → Google Workspace → Groups for
Business** settings, ensure the default for **who can post from outside the organization** is
**restricted** (owners approve; not "anyone on the internet").
*Rollback:* restore the recorded inbound-posting default.

**Step 2.4 — Create the default owner group.** Create `Security – Groups – Owners`
(`sec-groups-owners@corp.example`) as a **Cloud Identity security group** and add the lifecycle owners
as members. This group becomes the `OWNER` of governed groups.

> **Gate 2 (baseline configured):** creation restricted, default access restrictive, external members
> off by default, inbound external posting restricted, owner group created. Verify with
> `groups_settings_policy_helper.py check-baseline --domain corp.example`. **Pass** → Pilot.

---

## Stage 3 — Pilot (apply the model to the pilot scope)

Do everything below **only for groups in `Pilot OU – Groups – Finance`** first. Every helper runs
**dry-run by default**; add `--apply` only inside the change window.

**Step 3.1 — Re-type and re-name pilot groups.** For each pilot group, decide its **type** and bring
its **name/email prefix** to standard. Preview then apply:
```
python groups_naming_type_validator.py --domain corp.example --scope finance --json    # report drift
```
Rename to the convention in the console (or via the config helper) so every pilot group is, e.g.,
`Distribution – Finance – All Staff` / `dl-finance-all@corp.example`.

**Step 3.2 — Apply per-type settings.** For each pilot group, set its **Groups settings** to the
type's row from Step 1.1. Dry-run first, then apply:
```
python groups_settings_policy_helper.py --group dl-finance-all@corp.example --type distribution --dry-run
python groups_settings_policy_helper.py --group dl-finance-all@corp.example --type distribution --apply
```
Repeat per pilot group and type. The helper only writes the fields defined for that type and prints a
before/after diff.

**Step 3.3 — Convert access-granting groups to security groups.** Any pilot group used to grant access
(e.g. `sec-finance-ap@corp.example`) must carry the **security label**. Create/label it as a **Cloud
Identity security group** and re-point the access grants (Shared Drive membership, IAM) at it.
*Rollback:* the prior group/label is retained until the re-point is validated (Stage 4), then removed.

**Step 3.4 — Convert eligible groups to dynamic.** For a pilot group whose membership maps to a
directory attribute (e.g. all Finance users), create the **dynamic group** `Dynamic – Finance – All
Finance` (`dyn-finance-all@corp.example`) with the CEL query (e.g. `user.organizations.exists(o,
o.department == 'Finance')` — **verify the exact CEL syntax in your tenant**) and validate its computed
membership **before** retiring the equivalent static group.

**Step 3.5 — Fix ownership.** Ensure every pilot group has the owner group `sec-groups-owners@corp.example`
as an `OWNER` and **≥2 owners total**; remove single-owner and orphaned states:
```
python groups_settings_policy_helper.py --group <group> --set-owner sec-groups-owners@corp.example --dry-run
```

**Step 3.6 — Scope external membership.** Remove external members from any non-`ext-` pilot group. For a
legitimately external pilot group, rename it `External – ProjectX – Partner Collab`
(`ext-projectx-partner@corp.example`), allow-list the partner domain, and confirm its settings match the
External row. **This is high-impact** (removing external members can break a live collaboration) — do it
in the change window with owners notified.
*Rollback:* re-add the removed external member(s) from the assessment record if a break is reported.

> **Gate 3 (pilot pass/fail):** for `Pilot OU – Groups – Finance`, `groups_naming_type_validator.py`
> reports **zero** naming/type drift, `groups_membership_external_policy_checker.py` reports **zero**
> out-of-policy external members and no over-permissioned security groups, every group has ≥2 owners,
> and dynamic membership matches expected. **Any FAIL → fix or rollback that change; do not expand.**

---

## Stage 4 — Validate the pilot

**Step 4.1 — Naming/type conformance.** `python groups_naming_type_validator.py --domain corp.example
--scope finance` → expect **PASS** (no drift).

**Step 4.2 — Membership & external policy.** `python groups_membership_external_policy_checker.py
--domain corp.example --scope finance` → expect **zero** external members outside `ext-*`, no public
settings, no over-permissioned `sec-*` groups.

**Step 4.3 — Ownership & hygiene.** Re-run `groups_inventory_hygiene_assessment.py --domain corp.example`
filtered to Finance → expect **zero ORPHANED**, **zero STALE** in the pilot scope (or each stale group
ticketed for retirement).

**Step 4.4 — Access re-point verification.** Confirm that access previously granted via a repurposed
group now flows through the security group from Step 3.3 (a Shared Drive/IAM check) before removing the
old grant.

**Step 4.5 — Generate the pilot review report.** `python groups_lifecycle_review_report.py --domain
corp.example --scope finance --out pilot-review.html` → produces the owner-attestation review artifact
**`Review Report – Finance – Pilot`**.

> **Gate 4 (validation):** all Step 4 checks PASS and the review report is signed off by the pilot owners.
> **Pass** → Expand. **Fail** → remediate within the pilot; do not roll out.

---

## Stage 5 — Expand & operationalise

**Step 5.1 — Roll out scope by scope.** Repeat Stages 3–4 for each remaining scope (function/BU), one at
a time, each with its own `Pilot OU – Groups – <Scope>`-style change window and gate. Never big-bang the
whole estate.

**Step 5.2 — Operationalise the lifecycle.** Route all new-group requests through the intake; approvals
enforce type/naming/owner/external at creation. Schedule the **hygiene sweeps**
(`groups_inventory_hygiene_assessment.py`) and the **owner-attested reviews**
(`groups_lifecycle_review_report.py`) on the cadence from Step 1.4.

**Step 5.3 — Staged retirement (the documented rollback for a group's life).** To retire a group:
1. **Suspend** — set posting to `NONE_CAN_POST` and remove it from any active access grant (keep the
   group + membership recorded).
2. **Hold** — leave suspended for the rollback window (e.g. 30 days); if mail/access breaks are reported,
   **re-enable** (rollback).
3. **Delete** — after the hold with no breaks, delete the group.
Never delete a group that still routes mail or grants access in a single step.

> **Estate gate (steady state):** across all in-scope groups, naming/type validator and external/policy
> checker report PASS, the hygiene assessment shows no orphaned groups and all stale groups ticketed,
> and every group has an owner group and a review date. This is the ongoing definition of "governed."
