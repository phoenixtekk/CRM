# 5. Testing Guide — Vault ↔ Purview Coexistence: eDiscovery, Legal Hold & Retention

Run after the pilot matter/case and parallel holds are configured (Implementation Step 8), and re-run
after each expansion wave. The most important tests are the **coexistence probes** — proving a
custodian is held on **both** ecosystems and that discovery returns the right data from each. Each
check below is a **validation gate**.

> **Not legal advice.** These tests confirm the *technical* state (hold effective, retention applied,
> discovery returns). Whether the preserved scope satisfies the legal obligation is a legal/records-
> counsel determination.

## Test 1 — Vault hold effective on the matter
**Do:** Run `GWVAULT-Validation.ps1` for the pilot scope. In **Vault → Matters →** *(matter)* **→ Holds**, confirm the hold covers each in-scope service and custodian.
**Expected:** A Vault hold exists in the matter across the in-scope services (Gmail, Drive, Chat, etc.); held data is preserved indefinitely, taking precedence over retention rules.

## Test 2 — Purview parallel hold effective (same custodians)
**Do:** In **Purview → eDiscovery → Cases →** *(matched case)* **→ Hold policies →** *(policy)* **→ Details**, confirm each location shows **on hold** (allow up to 24h after apply).
**Expected:** The same custodians are held in Purview across their M365 workloads (Exchange, SharePoint/OneDrive, Teams-associated mailbox+site) — held on **both** ecosystems, under the matched matter name.

## Test 3 — Matter/case names match across platforms
**Do:** Compare the Vault matter name and the Purview case name for the pilot matter.
**Expected:** Identical names (`<Purpose> – <Scope> – <Stage>`), so the two holds are unmistakably the same legal matter.

## Test 4 — Vault retention applied to the approved schedule
**Do:** In **Vault → Retention**, confirm default and custom rules match the counsel-approved schedule for each in-scope service/OU. Run `GWVAULT-Validation.ps1`.
**Expected:** Vault retention matches the approved schedule; where a class also lives in M365, the Vault period is the **longer** of the two.

## Test 5 — Purview retention aligned (longer-of-two)
**Do:** In **Purview → Data Lifecycle / Records management → Retention policies (and labels)**, confirm the M365 retention matches the approved schedule and is aligned to the longer period for shared classes.
**Expected:** Purview retention matches the schedule and is aligned with Vault; most-restrictive-preservation-wins holds for any content also under a hold.

## Test 6 — Coexistence coverage: no custodian held on only one side
**Do:** Run `GWVAULT-Report.ps1`; review the coverage/gap output for the pilot custodians, cross-checking Vault matters against Purview cases.
**Expected:** Every pilot custodian who has data on both sides is held on **both**; no custodian is held on only one ecosystem.

## Test 7 — Discovery probe: matched search returns on both sides
**Do:** For a known pilot item, run the matched search in **Vault → Matters →** *(matter)* **→ Search** and in **Purview → eDiscovery → Cases →** *(case)*, and export from each.
**Expected:** The item is found and exportable from the correct side(s); the two export sets reconcile into a single production with no coexistence-gap item missed.

## Test 8 — Retention does not purge held content
**Do:** Confirm (with counsel) that a held record whose retention period has lapsed is still preserved by the hold on each platform.
**Expected:** The hold preserves the content regardless of retention (Vault hold precedence; Purview most-restrictive-wins) — nothing under a hold is purged.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–3 and 6–7 pass — the same custodians are held on both ecosystems under a matched matter name, and the matched search returns/exports from both |
| **Expand pass** | Tests 1–2, 4–6 pass for each newly held custodian wave before proceeding to the next |
