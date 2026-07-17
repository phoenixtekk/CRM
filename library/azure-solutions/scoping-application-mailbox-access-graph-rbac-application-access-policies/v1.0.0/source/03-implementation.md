# 3. Implementation Guide — Scoping Application-Permission Mailbox Access

Follow these steps **in order**. Steps run in **Exchange Online PowerShell** (`Connect-ExchangeOnline`) and **Microsoft Graph PowerShell** (`Connect-MgGraph`), with portal confirmations in the **Exchange admin center** (`https://admin.exchange.microsoft.com`) and **Microsoft Entra admin center** (`https://entra.microsoft.com`). Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **Verify-with-Microsoft note (applies to every cmdlet, role name, permission name, and model name below):** exact cmdlet names, parameters, Exchange role names, Graph permission names, scope-object types, and **which of the two models Microsoft currently recommends** are version- and cloud-dependent. **Confirm each against current Microsoft documentation before running it.** The names below are a faithful starting point, not an assertion of current fact.

## Naming (set once, reuse verbatim)
| Object | Name | Notes |
|---|---|---|
| Pilot application (the identity being scoped) | `Mailbox Reporting App` | `AppId` `11111111-1111-1111-1111-111111111111` (example — substitute yours) |
| In-scope mailbox (allowed) | `reports@contoso.com` | the app **may** read this |
| Second in-scope mailbox (allowed) | `shared-invoices@contoso.com` | optional; also allowed |
| Out-of-scope mailbox (must be denied) | `ceo@contoso.com` | the app **must not** read this |
| Mail-enabled security group (Model A) | `App Mailbox Scope – Reporting – Prod` | SMTP `app-mailbox-scope-reporting@contoso.com` |
| Application Access Policy (Model A) | `App Mailbox Scope – Reporting – Prod – Policy` | the policy description |
| Scope object (Model B) | `App Mailbox Scope – Reporting – RBAC Scope` | management scope / admin unit |
| RBAC role assignment (Model B) | `App Mailbox Scope – Reporting – RBAC Assignment` | the scoped role assignment |

## Decision path — choose the model FIRST
Decide before you configure (then confirm against current Microsoft guidance — see the note above):

1. **App already holds a broad Graph mail permission and you just need to fence it to a set of mailboxes, and/or your estate already uses Application Access Policies** → do **Model A (Application Access Policy)** — Steps 2–4.
2. **You want the app to hold only a narrow, specific Exchange right scoped to specific mailboxes (no tenant-wide grant at all) — the tightest least privilege** → do **Model B (Graph RBAC for Exchange Online)** — Steps 5–6, *if it is available and supported for your scenario and cloud*.
3. **Unsure, or in a government cloud** → pilot **Model A** first (more broadly available and audit-recognized); verify **Model B** availability before adopting it as target state.
4. **Either way**, always finish with **Step 7 (validate)** and the **Testing Guide** (prove the boundary).

## Step 1 — Discover and confirm the starting state
1. Open PowerShell and connect: `Connect-ExchangeOnline` and `Connect-MgGraph -Scopes "Application.Read.All","Directory.Read.All","Mail.Read"` (*verify the exact scopes required against current Microsoft documentation*).
2. Run `MBXRBAC-Discovery.ps1` — it lists every app / managed identity holding a mail-capable **application** permission (`Mail.Read`, `Mail.ReadWrite`, `Mail.Send`, `MailboxSettings.*`, etc.) and whether each is **scoped** (has an access policy / RBAC assignment) or **tenant-wide**.
3. Confirm `Mailbox Reporting App` (`AppId` `11111111-1111-1111-1111-111111111111`) appears as **tenant-wide** — this is the exposure you are closing.
4. Run `MBXRBAC-Report.ps1` to capture the pre-change state as your rollback baseline.

---

## Model A — Application Access Policy

### Step 2 — Create the mail-enabled security group
1. In **Exchange Online PowerShell**, create the mail-enabled security group and name it exactly `App Mailbox Scope – Reporting – Prod`:
   ```powershell
   New-DistributionGroup -Name "App Mailbox Scope – Reporting – Prod" `
     -Type Security `
     -PrimarySmtpAddress "app-mailbox-scope-reporting@contoso.com"
   ```
   *(Verify `New-DistributionGroup -Type Security` is the current way to create a mail-enabled security group against current Microsoft documentation.)*
2. Add **only** the allowed mailbox(es) as members:
   ```powershell
   Add-DistributionGroupMember -Identity "App Mailbox Scope – Reporting – Prod" -Member "reports@contoso.com"
   ```
   Add `shared-invoices@contoso.com` too if it is in scope. **Do not** add `ceo@contoso.com`.
3. Confirm membership in Exchange admin center → **Recipients → Groups** → `App Mailbox Scope – Reporting – Prod`.

### Step 3 — Create the Application Access Policy binding the app to the group
1. Create the policy that restricts `Mailbox Reporting App` to the group:
   ```powershell
   New-ApplicationAccessPolicy `
     -AppId "11111111-1111-1111-1111-111111111111" `
     -PolicyScopeGroupId "app-mailbox-scope-reporting@contoso.com" `
     -AccessRight RestrictAccess `
     -Description "App Mailbox Scope – Reporting – Prod – Policy"
   ```
   *(Verify the exact cmdlet name `New-ApplicationAccessPolicy`, the `-AccessRight` values — e.g. `RestrictAccess` vs `DenyAccess` — and all parameters against current Microsoft documentation. `RestrictAccess` limits the app to the group; `DenyAccess` blocks the app from the group.)*
2. Note the `-Description` value **is** the policy's name for later reference: `App Mailbox Scope – Reporting – Prod – Policy`.

### Step 4 — Verify the policy took effect (allow propagation)
1. **Wait for propagation** before testing — new access policies are not instant (commonly cited up to ~30 minutes; *verify current guidance with Microsoft*).
2. Test the boundary with Microsoft's built-in test (*verify the exact cmdlet name against current Microsoft documentation*):
   ```powershell
   Test-ApplicationAccessPolicy -Identity "reports@contoso.com" -AppId "11111111-1111-1111-1111-111111111111"   # expect: Granted
   Test-ApplicationAccessPolicy -Identity "ceo@contoso.com"     -AppId "11111111-1111-1111-1111-111111111111"   # expect: Denied
   ```
3. Run `MBXRBAC-Validate.ps1` (PASS/FAIL: the app is scoped, not tenant-wide) and proceed to **Step 7** then the **Testing Guide**.

---

## Model B — Graph RBAC for Exchange Online (resource-scoped)

> Do this model **instead of** Model A when you want the app to hold only a narrow, specific Exchange right scoped to specific mailboxes. **Verify every cmdlet, role name, and scope-object type below against current Microsoft documentation — this model is newer and its exact syntax and availability (especially in government clouds) are version-dependent.**

### Step 5 — Create the resource scope
1. Register the application's **service principal** in Exchange (if the RBAC model requires an Exchange-side service principal object) — *verify the exact cmdlet (e.g. `New-ServicePrincipal`) and whether it is required against current Microsoft documentation*:
   ```powershell
   New-ServicePrincipal -AppId "11111111-1111-1111-1111-111111111111" -ObjectId "<SP object id>" -DisplayName "Mailbox Reporting App"
   ```
2. Create the **resource scope** that bounds access to the allowed mailbox(es), and name it `App Mailbox Scope – Reporting – RBAC Scope` — *verify the exact scope-object type and cmdlet (management scope vs administrative unit vs group filter) against current Microsoft documentation*:
   ```powershell
   New-ManagementScope -Name "App Mailbox Scope – Reporting – RBAC Scope" `
     -RecipientRestrictionFilter "MemberOfGroup -eq '<DN of App Mailbox Scope – Reporting – Prod>'"
   ```

### Step 6 — Assign the scoped Exchange application role
1. Assign the specific Exchange **application role** (e.g. an "Application Mail.Read"-style role — *verify the exact role name against current Microsoft documentation*) to the app's service principal, scoped to the resource scope, and name the assignment `App Mailbox Scope – Reporting – RBAC Assignment`:
   ```powershell
   New-ManagementRoleAssignment -Name "App Mailbox Scope – Reporting – RBAC Assignment" `
     -App "11111111-1111-1111-1111-111111111111" `
     -Role "Application Mail.Read" `
     -CustomResourceScope "App Mailbox Scope – Reporting – RBAC Scope"
   ```
   *(Verify the exact cmdlet `New-ManagementRoleAssignment`, the `-App` / `-Role` / scope parameters, and the exact role name against current Microsoft documentation.)*
2. **Wait for propagation**, then run `MBXRBAC-Validate.ps1` and proceed to **Step 7** and the **Testing Guide**.

---

## Step 7 — Validate the boundary (both models)
1. Run `MBXRBAC-Validate.ps1` → confirms `Mailbox Reporting App` is **scoped** (an Application Access Policy or an RBAC assignment covers it) and **not** tenant-wide.
2. Run `MBXRBAC-Test-Boundary.ps1` → proves the app can read the **in-scope** mailbox (`reports@contoso.com` — **PASS**) and is **denied** the **out-of-scope** mailbox (`ceo@contoso.com` — **DENIED**).
3. Run `MBXRBAC-Report.ps1` → captures the post-change scoping evidence for auditors. Complete the **Testing Guide** before declaring the app scoped.

## Step 8 — Expand to the next app
1. Repeat the chosen model for the next application / managed identity, giving each its **own** mail-enabled security group / scope object and its own policy / assignment — never reuse one app's scope for another.
2. Re-run `MBXRBAC-Report.ps1` across the tenant each cycle; the goal is **zero** mail-capable application permissions left tenant-wide.

## Rollback (for every change)
- **Model A:** `Remove-ApplicationAccessPolicy` for `App Mailbox Scope – Reporting – Prod – Policy` (*verify cmdlet*) — the app returns to its prior (tenant-wide) state; existing mail is unaffected.
- **Model B:** `Remove-ManagementRoleAssignment "App Mailbox Scope – Reporting – RBAC Assignment"` (*verify cmdlet*).
- If in-scope reads start failing after scoping, check group membership / scope filter and propagation before removing the policy (see the Troubleshooting Guide).

---
### Order of operations
`Discover (is the app tenant-wide?) → choose model → [Model A: group → policy → verify] OR [Model B: scope → role assignment → verify] → validate scoped → prove boundary (in PASS / out DENIED) → expand`
