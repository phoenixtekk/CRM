# 3. Implementation Guide

This guide stands up the Drive & Shared Drives architecture following the house model — **Assess →
Design → Configure → Pilot → Validate → Expand** — with every artifact **named** on a consistent
convention and reused in later steps, testing, and the scripts. Production sharing changes are
**pilot-first**, **gated**, and **rollback-ready**.

**Naming conventions used throughout (agree once, reuse exactly):**
- Shared Drive: `Shared Drive – <Domain> – <Team/Function> – <Purpose>` (e.g. `Shared Drive – Finance – AP Records`)
- Membership group: `grp-<function>-<purpose>@<domain>` (e.g. `grp-finance-ap@corp.example`)
- Manager (owner) group per Drive: `grp-<function>-drive-owners@<domain>`
- Target audience: `Audience – <Scope> – <Purpose>` (e.g. `Audience – Internal – All Staff`, `Audience – Partner – AcmeLegal`)
- Trust rule: `Trust Rule – <Direction> – <Partner> – <Mode>` (e.g. `Trust Rule – Outbound – AcmeLegal – Allow`)
- Sharing setting profile (per OU): `Sharing Profile – <OU> – <Posture>` (e.g. `Sharing Profile – Finance – Restricted`)
- DLP rule: `DLP – <Detector> – <Action>` (e.g. `DLP – NationalID – Block-External`)
- Pilot scope: `Pilot OU – Drive – Finance`
- Reviews: `Access Review – <Drive> – <Quarter>`, `Orphaned-Owner Sweep – <Scope> – <Date>`

---

## 3.1 Assess — inventory the current Drive exposure (read-only)

Establish the Stage-0 baseline before changing anything.

1. Run the sharing-exposure assessment against the pilot scope:
   ```
   python drive_sharing_exposure_assessment.py --domain corp.example \
       --ou "/Finance" --json > baseline-finance.json
   ```
   It reports (read-only): files shared **externally**, files with **"Anyone with the link"**,
   **orphaned-owner** files (owner is a suspended/deleted user), and content held in **My Drive** that
   should be in a Shared Drive.
2. Record the baseline counts. These are the numbers the Validation step must improve on.
3. Review current Admin-console sharing state: **Admin console → Apps → Google Workspace → Drive and
   Docs → Sharing settings** — note the current external-sharing, link-sharing, and Shared Drive
   creation settings per OU (so the rollback baseline is documented).

> **Gate G0 (Assess complete):** a baseline JSON exists for the pilot scope and the current
> Admin-console sharing settings are documented. Do not proceed without a recorded rollback baseline.

## 3.2 Design — agree the taxonomy, roles, sharing policy, DLP alignment, governance

Produce the signed-off design (Requirement 2.5). Decide and document:
1. **Taxonomy & naming** — the top-level domains (Corporate Functions / Business Units / Projects /
   Cross-Org Collaboration) and the `Shared Drive – <Domain> – <Team> – <Purpose>` standard.
2. **Role model** — the default role per member group and the named **Manager group per Drive**
   (`grp-<function>-drive-owners@…`). Least-privilege default: most groups **Contributor** or
   **Viewer**; **Manager** only for the owner group.
3. **External-sharing policy** — the posture per OU (`Sharing Profile – <OU> – Restricted` by default),
   the allow-listed partner domains, and which **target audiences** and **trust rules** implement them.
4. **DLP alignment** — which classification levels (2.3) map to which `DLP – <Detector> – <Action>`
   rules on external sharing.
5. **Lifecycle governance** — the review cadence (`Access Review – <Drive> – <Quarter>`), the
   orphaned-owner and stale-Drive sweep schedule, and the provisioning standard.

Validate the naming/role model with the config helper (no tenant change):
```
python drive_governance_config_helper.py --catalog drive-catalog.csv \
    --new-drive "Finance – AP Records" --domain Finance --owner-group grp-finance-drive-owners@corp.example \
    --member-group grp-finance-ap@corp.example --member-role contributor
```

> **Gate G1 (Design signed off):** the taxonomy, naming, role model, external-sharing policy, DLP
> mapping, and governance cadence are approved by the Drive service owner and GR-6 stakeholders.

## 3.3 Configure — apply sharing settings, audiences, trust rules, DLP (pilot OU first)

Apply configuration to the **pilot OU** (`Pilot OU – Drive – Finance`) only.

1. **Sharing settings (per OU)** — **Admin console → Apps → Google Workspace → Drive and Docs →
   Sharing settings**, scoped to the pilot OU. Apply `Sharing Profile – Finance – Restricted`:
   - **Sharing outside <domain>:** set to **OFF** or **allow-listed domains only** per the design.
   - **"When sharing outside … users will see a warning":** **ON**.
   - **Access checker / link sharing default:** set link-sharing default to **restricted** ("Only
     added people"), not "Anyone with the link".
   - **Shared Drive creation:** restrict who can create Shared Drives (default to admins/service owners
     so provisioning stays governed), and set defaults for members outside the org, download/copy, and
     non-member access per the design.
2. **Target audiences** (edition-gated) — **Admin console → Directory → Target audiences**. Create
   `Audience – Internal – All Staff` (and any partner audiences), so the sharing dialog's default
   suggested audience is the governed one, not "Anyone with the link."
3. **Trust rules** (edition-gated) — **Admin console → Apps → Google Workspace → Drive and Docs →
   Trust rules**. Create `Trust Rule – Outbound – <Partner> – Allow` for each allow-listed partner
   domain and a default-restrict rule; scope to the pilot OU first. *Verify the exact page layout in
   your tenant — this surface is edition-gated and evolving.*
4. **DLP for Drive** (edition-gated) — **Admin console → Security → Data protection → Manage rules**.
   Author `DLP – <Detector> – Block-External` / `DLP – <Detector> – Warn-External` rules mapping the
   2.3 detectors to **block** or **warn** actions on **external** sharing; scope to the pilot OU.
5. **Provision the pilot Shared Drives** to the naming model — either in **Admin console → Apps →
   Google Workspace → Drive and Docs → Manage Shared Drives**, or with the provisioner in dry-run then
   `--apply`:
   ```
   python shared_drive_provisioner.py --catalog drive-catalog.csv --dry-run
   python shared_drive_provisioner.py --catalog drive-catalog.csv --apply   # after review
   ```
   The provisioner creates each `Shared Drive – …` and adds the **member group** at the designed role
   and the **owner group** as **Manager** — never individual users.

## 3.4 Pilot — run the design against the pilot scope

1. Relocate the pilot team's business content from My Drive into the provisioned Shared Drives (owner
   transfer / move), so no business content remains individually owned.
2. Have the pilot team collaborate normally for the agreed pilot window (internal shares, one
   allow-listed partner share, one blocked-by-DLP attempt).
3. Monitor for broken collaborations and DLP false-positives; adjust rules within the pilot only.

> **Gate G2 (Pilot pass/fail):** PASS requires — no business content left in pilot users' My Drive;
> external sharing limited to the allow-listed audience(s); a genuine sensitive-content external share
> is **blocked/warned** by DLP; the pilot team can still do its legitimate work. **FAIL** on any
> broken legitimate workflow or any un-scoped external leak → **rollback** (§3.6) and revise the design.

## 3.5 Validate & Expand

1. Re-run the assessment and the validation report against the pilot scope:
   ```
   python drive_sharing_exposure_assessment.py --domain corp.example --ou "/Finance" --json > post-finance.json
   python drive_governance_report.py --catalog drive-catalog.csv --exposure post-finance.json --out finance-governance.html
   ```
   Confirm exposure counts dropped to policy (no orphaned owners, no un-scoped external shares).
2. Run the policy/health check as the go/no-go gate:
   ```
   python external_sharing_policy_validator.py --domain corp.example --ou "/Finance" --catalog drive-catalog.csv
   ```
   Exit **0** = pilot conforms to policy; non-zero = a violation remains.
3. **Expand** domain by domain, repeating Configure → Pilot → Validate per OU, keeping the provisioning
   standard and the review cadence as steady-state governance (`Access Review – <Drive> – <Quarter>`,
   scheduled `Orphaned-Owner Sweep – <Scope> – <Date>`).

## 3.6 Rollback (documented, per production sharing change)

If a Gate fails or a production change breaks collaboration:
1. **Sharing settings:** in **Drive and Docs → Sharing settings** for the affected OU, restore the
   documented G0 baseline values (this is why §3.1 recorded them).
2. **Trust rules / target audiences:** disable or delete the `Trust Rule – …` / `Audience – …`
   created for the change (audiences/rules are additive; removing them reverts behavior).
3. **DLP rules:** set the offending `DLP – <Detector> – …` rule action to **audit only** (non-blocking)
   or deactivate it, so no legitimate work is blocked while the rule is revised.
4. **Provisioned Shared Drives:** membership changes are reversible via the provisioner's recorded
   before-state; a wrongly-created Shared Drive is emptied and hidden/deleted through **Manage Shared
   Drives** by a Manager.
Rollback restores the pre-change posture; re-enter Design with the lesson recorded.
