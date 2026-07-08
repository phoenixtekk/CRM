# 3. Implementation Guide — Sensitivity Label Taxonomy Design

Follow these steps **in order**. Configuration is done in the **Microsoft Purview portal**
(`https://purview.microsoft.com`) and **Security & Compliance PowerShell** (`Connect-IPPSSession`).
Every write is previewed with `-WhatIf` first, every encrypting label is **piloted in a small ring**
before broad publish, and label names follow the naming convention from the Overview and are reused
verbatim. Portal paths are current at authoring — **verify in your tenant**, as the portal is evolving.

> **Model:** Assess the current posture → **design** the taxonomy (tiers, sublabels, naming, protection/
> marking mapping) → build the labels (`-WhatIf` → `-Commit`) → publish to a **pilot ring** → validate
> structure + protection → **expand** to broad publish.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**
>
> **Deferral:** tier count, final names, which tiers encrypt, and the rights model are **security/
> compliance/records determinations** — confirm the design sheet (§2.7) before building.

## Step 1 — Assess the current label posture (Assess)
1. Run `IPTAX-Discovery.ps1` (read-only). It inventories existing **sensitivity labels** (`Get-Label`),
   their **parent/sublabel structure and order** (Priority / ParentId), **protection/marking** per label
   (encryption, header/footer/watermark), and existing **label policies** (`Get-LabelPolicy`) — plus a
   **naming-convention conformance** view and any **name collisions** with the taxonomy you plan to build.
2. Review the output: what labels already exist, whether there is label sprawl or inconsistent naming,
   and whether any internal `Name` you plan to use is already taken. This is your baseline.
3. **Gate:** you have a written baseline of every existing label/policy and have confirmed **no internal
   `Name` collisions** with the taxonomy in the design sheet.

## Step 2 — Design the taxonomy and protection mapping (Design)
1. With your security/compliance/records owners, finalize the design using the Overview's sample as a
   starting point to react to. Record, for **each label**:
   - **display name**, **internal `Name`** (per the `SL-<Tier>[-<Audience>]` convention), **tooltip**,
     and **order**;
   - the **parent/sublabel structure** (parents group only, never protect, never selectable);
   - the **protection/marking mapping** — encryption yes/no, the rights group + usage-rights level, and
     the header/footer/watermark text.
2. Confirm the pilot ring (the group backing `SL Policy - Pilot - Ring1`) and the rights groups named in
   the mapping exist (§2.6).
3. **Gate:** a **signed-off taxonomy + protection-mapping sheet** exists — names, order, structure,
   protection, and rights — before any label is created (§2.7). Internal names are unique and final.

## Step 3 — Build the parent tiers and top-level labels (Configure, -WhatIf first)
1. Run `IPTAX-TaxonomyConfig.ps1 -WhatIf` (the default). It prints exactly which labels it would create
   with `New-Label`, **in order** — the non-protecting tiers (`SL-Public`, `SL-Internal`) and the
   **parent grouping labels** (`SL-Confidential`, `SL-HighlyConf`, created with **no protection** and as
   non-selectable groupings) — **without making changes**.
2. Review every line against the design sheet: display names, internal names, tooltips, order, and that
   parents carry no protection.
3. Re-run `IPTAX-TaxonomyConfig.ps1 -Commit` to create these labels. They exist but are **not published**
   yet — labels only appear to users once a policy publishes them (Step 5).
4. **Gate:** `Get-Label` shows `SL-Public`, `SL-Internal`, `SL-Confidential`, `SL-HighlyConf` in the
   correct order; the two parents carry no encryption/marking.

## Step 4 — Build the protected sublabels per the mapping (Configure, -WhatIf first)
1. Run `IPTAX-TaxonomyConfig.ps1 -Sublabels -WhatIf`. It prints the `New-Label` calls for each sublabel
   with its **parent link**, **content marking**, and **encryption/rights** exactly as the mapping
   specifies — `SL-Conf-AllEmp`, `SL-Conf-Trusted`, `SL-HighlyConf-AllEmp`, `SL-HighlyConf-Specified` —
   **without making changes**.
2. Review every line: confirm each encrypting sublabel's rights definition targets the correct
   **mail-enabled security group** (§2.6) and usage-rights level, and that the footer/watermark text
   matches the mapping.
3. Re-run `IPTAX-TaxonomyConfig.ps1 -Sublabels -Commit` to create the sublabels. Encryption and marking
   are set on the labels but **not yet visible to anyone** — nothing is published.
4. **Gate:** `Get-Label` shows every sublabel under its correct parent with the intended protection; the
   full ordered taxonomy matches the design sheet. Run `IPTAX-Validation.ps1` to confirm structure/order/
   protection == design.

## Step 5 — Publish the taxonomy to the pilot ring (Pilot)
1. Run `IPTAX-TaxonomyConfig.ps1 -PublishPolicy -PolicyName "SL Policy - Pilot - Ring1" -PilotGroup "grp-purview-pilot@contoso.com" -WhatIf`.
   It shows the `New-LabelPolicy` it would run — publishing the **ordered, selectable** label set
   (parents excluded from selection) to the pilot group only.
2. Re-run with `-Commit` to create `SL Policy - Pilot - Ring1`.
3. In the Purview portal (**Information Protection → Label policies**) confirm the policy is published to
   the pilot group and the labels appear in Office for a pilot user (allow time for client sync).
4. **Gate:** pilot users see the full ordered taxonomy in Word/Excel/PowerPoint/Outlook; parents are not
   individually selectable; a **non-pilot** user sees nothing. Rollback: `Remove-LabelPolicy "SL Policy -
   Pilot - Ring1"` unpublishes without deleting the labels.

## Step 6 — Validate structure, marking, and protection (Validate)
1. Run `IPTAX-Validation.ps1 -Full`. It re-checks the built taxonomy against the design: order, parent/
   sublabel structure, per-label protection/marking, naming-convention conformance, and that the pilot
   policy is published to the intended scope.
2. As a pilot user, apply a **marking-only** label (`Internal`) and confirm the footer appears; apply an
   **encrypting** sublabel (`Confidential \ Trusted People` or `Highly Confidential \ Specified People`)
   and confirm protection enforces (Testing Guide §5, Test 4 — open as an unauthorized user → denied).
3. Complete the **Testing Guide (§5)**.
4. **Gate:** all §5 tests pass — structure as designed, marking visible, encryption enforces, scope
   correct.

## Step 7 — Expand to broad publish (Expand)
1. Only after every §5 gate passes, publish the taxonomy broadly:
   `IPTAX-TaxonomyConfig.ps1 -PublishPolicy -PolicyName "SL Policy - Broad - AllUsers" -PilotGroup "<all-users-or-broad-scope>" -WhatIf`,
   review, then `-Commit`. This publishes the same designed taxonomy to the broad scope.
2. Communicate to users what the labels mean and what changes (marking/encryption they'll see) **before**
   the broad publish reaches them — the ticket flood comes from surprise, not from labels.
3. Re-run `IPTAX-Validation.ps1 -Full` and confirm the broad policy is published to the intended scope.
4. **Gate:** broad publish confirmed to the correct scope; a rollback path
   (`Remove-LabelPolicy "SL Policy - Broad - AllUsers"`) is documented; the taxonomy design sheet, the
   built labels, and the published policy all agree.

---
### Order of operations
`Assess posture → Design taxonomy + protection mapping (signed off) → Build parents/top-level (-WhatIf → commit) → Build protected sublabels (-WhatIf → commit) → Publish to pilot ring → Validate structure + marking + protection → Expand to broad publish`
