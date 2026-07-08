# 3. Implementation Guide — Azure RMS / AIP → Built-in Unified Labeling Migration

Follow these steps **in order**. Work is done in the **Microsoft Purview portal**
(purview.microsoft.com), **Security & Compliance PowerShell** (`Connect-IPPSSession`, label cmdlets), the
**AIPService** module (`Connect-AipService`, the Azure Rights Management protection service), **Microsoft
Graph**, and Office **client policy** (Group Policy ADMX or the Microsoft 365 Apps admin center / Cloud
Policy). Label-policy changes are previewed with `-WhatIf` before `-Commit`. Artifact names follow the
`<Purpose> – Purview – <Stage>` convention from the Overview and are reused verbatim.

> **Model:** Assess the estate → design the parity map + target client policy → configure label-policy
> settings and stage the client policy → **cut the pilot ring over** → validate parity → expand
> tenant-wide and decommission the add-in. Pattern: **Assess → Design → Configure → Pilot → Validate →
> Expand.**
>
> **The AIP add-in's retirement state, the Office ADMX/Cloud-Policy setting names, and any registry
> values evolve — verify each against Microsoft's current guidance and your Office channel.** Encryption
> and parity features are licensing-/build-gated — verify against your plan and Office build (Requirements
> 2.1, 2.5). Cut over the pilot ring only; do not flip the tenant until the ring passes validation.

## Step 1 — Inventory the current estate (Assess)
1. Run `IPRMSMIG-Assess-Migration.ps1 -CsvPath .\AipRmsInventory.csv`. Read-only, it captures: the
   sensitivity-labeling SKUs present (Graph), all **sensitivity labels** (`Get-Label` — name, GUID,
   whether the label applies **encryption**), all **label policies** (`Get-LabelPolicy` — name, scope,
   and key advanced settings), and the **Azure RMS / protection templates** (`Get-AipServiceTemplate`)
   with the RMS `FunctionalState`. It writes `AIP/RMS Inventory – Migration – Assess`.
2. In the Purview portal, open **Information Protection → Sensitivity labels** and **Label policies**
   (verify path) and confirm the on-screen estate matches the inventory.
3. **Pass/fail:** you have a complete, dated inventory of every label, every label policy (with its
   advanced settings), and every RMS/protection template — the parity baseline.

## Step 2 — Build the parity map (Design)
1. From the inventory, build `Built-in Labeling Parity – Design` — a row per item mapping the **current
   experience** to its **built-in-labeling target**:
   - **Labels & order** → same labels from the Purview label policy (confirm each is in the unified store,
     Requirement 2.7).
   - **AIP add-in feature** (default label, mandatory labeling, custom permissions, Do-Not-Forward,
     protected-PDF, tracking/revocation) → the **built-in equivalent** (label-policy setting, label
     encryption setting, or advanced setting) **and the minimum Office build it needs**. Flag any feature
     with **no direct equivalent** as an explicit decision for the label owner.
   - **Departmental RMS template** → a **sensitivity label with matching encryption** (permissions,
     offline access, expiry). There is no auto-convert cmdlet — record the target label and its
     encryption settings.
2. Record the **target Office client policy** (use built-in labeling; disable the AIP add-in) and the
   **label-policy advanced settings** needed for behavioural parity (e.g. a default Outlook label,
   mandatory-labeling posture, custom-permissions availability — **verify each key name against current
   documentation**).
3. **Pass/fail:** every label, feature, and template has a target and a parity decision; gaps are named,
   owned, and licensing/build requirements are recorded.

## Step 3 — Configure label-policy settings for parity (Configure, preview-first)
1. Dry-run first: `IPRMSMIG-Set-LabelPolicy.ps1 -PolicyName '<policy>' -SettingsPath .\parity.json -WhatIf`.
   With `-WhatIf` (the default) it makes **no changes** — it prints exactly which advanced settings would
   be applied to which label policy (`Set-LabelPolicy -AdvancedSettings`) and prints the reverse for each.
2. Read every line against `Built-in Labeling Parity – Design`. Confirm the settings reproduce the add-in
   behaviour and nothing broadens scope unexpectedly. The `settings` file holds **only** the advanced
   settings you decided in Step 2 — do not invent keys.
3. Apply to the **pilot policy first**: `IPRMSMIG-Set-LabelPolicy.ps1 -PolicyName '<pilot policy>'
   -SettingsPath .\parity.json -Commit`, scoped to the label policy that targets
   `AIP Migration Pilot Ring – Stage1`. Writes/updates `Label Policy Config – Configure`.
4. **Pass/fail + rollback:** `Get-LabelPolicy -Identity '<policy>'` shows the intended advanced settings.
   Rollback re-applies the previous settings (the script prints each prior value) or removes a key.

## Step 4 — Confirm labels and protection in the unified store (Configure)
1. Confirm every add-in label is present in the unified store and scoped to the pilot users:
   `IPRMSMIG-Test-Parity.ps1 -UserUpn <pilot user> -OfficeBuild '<build>'` resolves the effective label
   set and flags any label missing for that user.
2. For each **departmental RMS template** in the parity map, confirm the **target sensitivity label**
   reproduces its encryption (permissions, offline access, expiry) — recreate the protection on the label
   in the portal where it is not yet present. Then run `IPRMSMIG-Scope-Health.ps1 -Commit` to
   `Execute-AzureADLabelSync` so the protection service picks up label changes.
3. **Pass/fail:** every pilot label resolves for a pilot user; each departmental template has a matching,
   published protecting label; the label sync has run.

## Step 5 — Stage and cut over the pilot ring (Pilot)
1. Stage the **Office client policy** for `AIP Migration Pilot Ring – Stage1` **only** — via Group Policy
   (Office ADMX: *use the Sensitivity feature in Office to apply and view sensitivity labels*, and disable
   the **Azure Information Protection** COM add-in) or the **Microsoft 365 Apps admin center** (Cloud
   Policy). **Verify the exact setting names / any registry values against the current Office ADMX** — the
   policy that turns on built-in labeling is commonly delivered as `UseOfficeForLabelling` (verify) plus a
   managed-add-in setting to disable the add-in.
2. In a **change window**, apply the policy to the ring, have users restart Office, and confirm the add-in
   is gone and built-in labeling is active (the Sensitivity button appears in the Office ribbon).
3. Keep everyone outside the ring on the current experience. **Pass/fail:** ring devices show built-in
   labeling, the AIP add-in disabled, and the expected labels in the ribbon.

## Step 6 — Validate parity on the ring (Pilot → Validate)
1. Work through the **Testing Guide** on the ring: every label appears and applies; encryption/custom
   permissions behave as before; the default/mandatory-labeling posture matches; departmental-template
   protection is reproduced by the mapped label; protected content created on the add-in still opens.
2. Run `IPRMSMIG-Report-Migration.ps1 -CsvPath .\MigrationStatus.csv` to produce
   `Migration Validation – Report` — the parity matrix with a pass/fail per item.
3. **Pass/fail:** every parity row passes on the ring, or an open gap has a recorded owner decision. Do
   **not** expand with an unresolved protection/encryption gap.

## Step 7 — Expand tenant-wide (Expand)
1. With the ring validated, broaden the Office client policy from the ring to the next rings and then the
   full population (repeat the change-window + validate pattern per ring). Apply the parity label-policy
   advanced settings to the broad label policies (`-WhatIf` then `-Commit`).
2. Monitor: re-run `IPRMSMIG-Report-Migration.ps1` after each wave; watch for labels not resolving or
   protection failures, and keep RMS super-user recovery available.
3. **Decommission the add-in:** once a population is fully on built-in labeling and validated, retire the
   AIP add-in for it (managed-add-in policy). Record the completion in `Migration Validation – Report`.
4. **Pass/fail:** the full population is on built-in labeling with parity, the add-in is disabled, and the
   validation report shows no open protection/encryption gap.

---
### Order of operations
`Inventory labels/policies/RMS templates → design parity map + target client policy → dry-run (-WhatIf)
label-policy settings → apply to pilot policy → confirm labels + template protection in unified store +
sync → stage + cut the pilot ring over → validate parity on the ring → expand ring-by-ring + decommission
the add-in`
