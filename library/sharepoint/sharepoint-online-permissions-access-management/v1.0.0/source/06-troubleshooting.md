# 6. Troubleshooting

Common failure modes and how to resolve them. Symptoms reference the artifacts and scripts from the other
sections. Work read-only first; never `-Commit` while diagnosing.

---

## Connection & permission problems

### `Connect-PnPOnline -Interactive` fails or prompts for an app
- **Cause:** PnP.PowerShell v2+ requires an **Entra app registration** for interactive sign-in; without
  one, the connection is rejected.
- **Fix:** Register access once (`Register-PnPManagementShellAccess`) or use your org's PnP app, and
  consent the delegated SharePoint permissions (Requirement 2). Re-run `SPOPERM-Scope.ps1` to confirm.

### Scripts connect but can't read groups / role assignments ("access denied")
- **Cause:** The account is not **Site Collection Admin** on the target site (SharePoint Admin alone does
  not grant per-site object access until it's SCA).
- **Fix:** Add the account as SCA (SharePoint admin center → *Sites → Active sites → <site> → Membership*,
  or `Set-SPOUser -Site <url> -LoginName <upn> -IsSiteCollectionAdmin $true`). `SPOPERM-Scope.ps1` reports
  this as the "group-read (SCA proxy)" check.

### Government cloud: URLs/cmdlets don't resolve
- **Cause:** Commercial URLs/endpoints were used on **GCC High / DoD**.
- **Fix:** Use your cloud's admin/site URLs (`*.sharepoint.us`) and connect Graph with the right
  environment (`Connect-MgGraph -Environment USGov` / `USGovDoD`). **Verify the exact paths in your
  tenant** — do not assume the commercial ones.

---

## Audit / discovery problems

### `SPOPERM-Discovery.ps1` reports "no unique permissions" but you know sharing happened
- **Cause 1:** The unique permissions are at **item/folder** level, and you ran without `-IncludeItems`
  (which only scans the web + lists by default for performance).
- **Fix 1:** Re-run with `-IncludeItems` on the suspect library. Expect it to be slower.
- **Cause 2:** Access came via a **sharing link** (which grants through a system group) rather than a
  classic unique role assignment — that is **external/link sharing**, a different product's scope (see
  Overview → Scope). This solution governs the internal permission model, not link sharing.

### The audit shows a broad principal (e.g. "Everyone except external users") — is that always bad?
- **Cause:** Broad principals are only a problem at **high levels** (Edit/Full Control) or on sensitive
  content. Broad **Read** on genuinely all-hands content may be intentional.
- **Fix:** Treat `OverShare = True` rows (broad principal **and** a high level) as findings for the owner;
  confirm broad Read is intentional before removing it.

---

## Remediation problems

### `SPOPERM-Remediate-GroupAccess.ps1 -ConvertDirectGrants` skips a user ("no standard group maps")
- **Cause:** The user's direct grant is a **custom or unusual level** (e.g. only `Perm Level – Read No
  Download – Prod`, or a bespoke level) that doesn't map to Owners/Members/Visitors automatically.
- **Fix:** The **information owner decides** the correct group (or that access should be removed). Add the
  user to that group manually, then remove the direct grant — this is exactly the owner-decision the
  script defers rather than guessing.

### `SPOPERM-Reset-Inheritance.ps1` won't reset a scope / reset "succeeds" but it's still unique
- **Cause 1:** The scope is in the **`-ExcludeList`** of documented exceptions (by design — check the
  `KEEP` lines).
- **Cause 2:** A **child** scope below it still has its own unique permissions; resetting the parent does
  not touch independently-broken children.
- **Fix:** Confirm the scope isn't an intended exception; if a child is still unique, reset it too
  (run with `-IncludeItems` to reach item/folder scopes). Re-run `SPOPERM-Discovery.ps1` to confirm.

### After a reset, someone lost access they actually needed
- **Cause:** A unique grant was **load-bearing but undocumented** — exactly the risk the pilot/`-WhatIf`
  flow exists to catch.
- **Fix (rollback):** Using the `Permission Audit – SPO – Discovery` baseline as the record of prior
  state, re-grant the access **as a group** at the minimum necessary scope (preferred), or restore the
  documented unique grant. Then add the scope to the design's exception list so future runs keep it.

---

## Limited Access & inheritance quirks

### "Limited Access" won't go away when I try to remove it
- **Cause:** **Limited Access is system-managed** — you cannot assign or delete it directly. It exists
  because a **child** list/folder/item still has a unique grant for that principal.
- **Fix:** Find the underlying sub-scope still granting that principal (audit with `-IncludeItems`) and
  reset **it** to inherit; Limited Access at the parent disappears once its cause is gone.

### Broken-inheritance count didn't drop as much as expected
- **Cause:** Item/folder-level scopes weren't included in the reset run.
- **Fix:** Re-run `SPOPERM-Reset-Inheritance.ps1 -IncludeItems` on the affected library (still `-WhatIf`
  first). Very large libraries take time; scope deliberately.

---

## Ongoing model / drift problems

### Direct user grants keep reappearing after remediation
- **Cause:** Someone is "just adding a user" to resolve urgent access requests — the classic regression.
- **Fix:** Enforce the group-only rule (Best Practices), and run the recurring `Access Report – SPO –
  Report` / `SPOPERM-AccessReview.ps1 -Report` — its **"direct-grant leftovers"** count surfaces new
  direct grants so they're converted quickly. Coach owners to add people to the group, not the site.

### Can't create an Entra ID Access Review / no Data Access Governance reports in the admin center
- **Cause:** **Access Reviews require Entra ID P2**; **DAG reports / site access review require SharePoint
  Advanced Management (SAM)**. If unlicensed, the features simply don't appear.
- **Fix:** Either license the add-on under change control, **or** use the included
  `SPOPERM-AccessReview.ps1 -Report` on a schedule for the same attestation evidence. **Verify licensing
  in your tenant** — availability is plan-dependent and changes over time.

### The access report is missing members of a group
- **Cause:** The group is a **nested Entra/M365 group** and the report ran without `-ExpandEntraGroups`,
  or the Graph read scopes weren't consented.
- **Fix:** Re-run `SPOPERM-AccessReview.ps1 -Report -ExpandEntraGroups` and ensure delegated
  `Group.Read.All` / `Directory.Read.All` are consented (Requirement 6).

### A custom `Perm Level – Read No Download – Prod` isn't actually blocking downloads
- **Cause:** Permission-level mechanics are nuanced — removing certain permissions doesn't always prevent
  every copy/download path (and Office Online "View Only" behaves differently from a custom Read level).
- **Fix:** **Verify the effective behavior in your tenant** before relying on it; for hard
  download-prevention consider the appropriate protection control rather than a permission level alone.
  Never edit the **built-in** Read level to achieve this.
