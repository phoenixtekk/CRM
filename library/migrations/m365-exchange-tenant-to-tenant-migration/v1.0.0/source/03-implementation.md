# 3. Implementation — Microsoft 365 Exchange Online Tenant-to-Tenant Migration (1:1 Domains)

This is the ordered runbook for the full migration. Execute the phases in order: **Assess → Plan → Prepare → Pilot → Migrate → Cutover → Validate → Decommission**. Do not advance a phase until its exit gate (see `05-testing.md`) passes. Every object you create is named with the convention `<Purpose> – <Scope> – <Stage>`; reuse the exact names verbatim in later steps, testing, troubleshooting, and the scripts.

**Conventions used below**
- Source vanity domain: `contoso.com` · Source default: `source.onmicrosoft.com`
- Target default / routing domain: `target.onmicrosoft.com`
- Migration service accounts: `svc-quest-migration@source.onmicrosoft.com`, `svc-quest-migration@target.onmicrosoft.com`
- Quest On Demand project: **`EXO T2T – Contoso – Migration Project`**
- Pilot wave: **`EXO T2T – Pilot Wave`** · Bulk waves: **`EXO T2T – Wave 1`**, **`EXO T2T – Wave 2`**, … 
- Coexistence connectors: **`Coexistence – Source→Target Connector`**, **`Coexistence – Target→Source Connector`**
- Mail-enabled security group for pilot: **`EXO T2T – Pilot Members`**

> Replace `contoso.com` / `*.onmicrosoft.com` and the wave list with your real values, but keep the naming **pattern** identical so downstream steps and scripts line up.

---

## Phase 1 — Assess

### 1.1 Confirm access to both tenants
1. Sign in to the **source** Exchange admin center (https://admin.exchange.microsoft.com) and the **source** Microsoft 365 admin center (https://admin.microsoft.com); confirm Global Admin (R2).
2. Repeat for the **target** tenant.

### 1.2 Run source discovery
1. On an operator workstation, install the Exchange Online PowerShell module: `Install-Module ExchangeOnlineManagement`.
2. Run **`scripts\EXOMIG-Discovery.ps1`** against the source tenant. It exports CSVs of: all mailboxes (user/shared/room/equipment), sizes, item counts, aliases, accepted domains, distribution groups, Microsoft 365 groups, and mailbox permissions/delegation.
3. Save the exports as the **assessment baseline** (also serves G6 backup posture).

### 1.3 Build the source→target mapping (R11) and permission inventory (R12)
1. From the discovery CSVs, build the mapping file `mapping.csv` with columns: `SourceUPN, SourcePrimarySMTP, MailboxType, TargetUPN, TargetRoutingAddress, FinalPrimarySMTP, Wave`.
2. Build `permissions.csv` from the permissions export: `TargetMailbox, Trustee, AccessRight` (FullAccess / SendAs / SendOnBehalf).
3. Reconcile shared mailboxes, room/equipment mailboxes, distribution groups, and forwarding rules explicitly.

**Exit gate:** complete inventory; every source object has a target mapping row. (Test T1.)

---

## Phase 2 — Plan

### 2.1 Decide waves
1. Group users into waves by department/dependency so people who collaborate move together. Assign each row in `mapping.csv` a `Wave` value: `EXO T2T – Pilot Wave`, `EXO T2T – Wave 1`, etc.
2. Keep the pilot wave small (5–15 representative mailboxes, including at least one shared and one resource mailbox).

### 2.2 Decide routing domain and coexistence model
1. Choose the routing domain (R9): default `target.onmicrosoft.com` or a dedicated routing domain.
2. Decide whether to enable GAL sync + free/busy coexistence (recommended for multi-week projects).

### 2.3 Plan the cutover and rollback
1. Choose the cutover window (low-mail-volume hours) and lower DNS TTLs in advance (see `07-best-practices.md`).
2. Capture current DNS (MX, Autodiscover CNAME, SPF, DKIM, DMARC) and write the rollback plan (G6).

**Exit gate:** approved plan, wave list, routing decision, cutover window, rollback plan. (Test T2.)

---

## Phase 3 — Prepare

### 3.1 Prepare the target tenant and licensing
1. In the **target** Microsoft 365 admin center → **Billing → Licenses**, confirm Exchange Online licensing for all migrated users (R1).
2. Assign licenses to target users (per-user under **Users → Active users → (user) → Licenses and apps**, or group-based via **Microsoft Entra admin center → Identity → Groups**).

### 3.2 Add the routing/coexistence domain (if using a dedicated one)
1. In the **target** Microsoft 365 admin center → **Settings → Domains → Add domain**, add the routing domain and complete TXT verification; or simply use the built-in `target.onmicrosoft.com`.
2. In the **target** Exchange admin center → **Mail flow → Accepted domains**, confirm it is present (or add it with `EXOMIG-Set-Coexistence.ps1 -AddRoutingDomain`).

### 3.3 Create the migration service accounts (R3)
1. In the **source** Microsoft 365 admin center → **Users → Active users → Add a user**, create **`svc-quest-migration@source.onmicrosoft.com`**.
2. In the **target** Microsoft 365 admin center → **Users → Active users → Add a user**, create **`svc-quest-migration@target.onmicrosoft.com`**.
3. Grant each the minimum roles the engine requires (Quest uses app consent; native MRS needs the **Migration**/**Mail Recipients** roles and application access).

### 3.4 Exclude the service accounts from MFA / Conditional Access (R8)
1. In each **Microsoft Entra admin center** → **Protection → Conditional Access → Policies**, edit each blocking policy → **Users → Exclude** → add `svc-quest-migration`. Do **not** disable policies tenant-wide.
2. Record the exclusion in change-control and add a reversal task to Decommission.

### 3.5 Connect both tenants in Quest On Demand and create the project
1. In the **Quest On Demand portal** (https://login.quest-on-demand.com) → **Tenants → Add Tenant**, run the consent flow for the **source** tenant (source Global Admin signs in and accepts), then repeat for the **target** tenant. Confirm both show **Connected** (R4).
2. In **Migration → Exchange → New Project**, create **`EXO T2T – Contoso – Migration Project`**, selecting source and target tenants.
3. Inside the project, create the pilot wave object **`EXO T2T – Pilot Wave`** (and, later, `EXO T2T – Wave 1`, etc.).

### 3.6 Configure coexistence mail-flow connectors
1. Create the source→target relay: in the **source** Exchange admin center → **Mail flow → Connectors → Add a connector** (From: Office 365 → To: Partner organization), name it **`Coexistence – Source→Target Connector`**, routing mail for migrated users to the target routing domain.
2. Create the reverse: in the **target** Exchange admin center → **Mail flow → Connectors**, name it **`Coexistence – Target→Source Connector`**.
3. Alternatively run **`scripts\EXOMIG-Set-Coexistence.ps1`** (use `-WhatIf` first) to create both connectors and the accepted domain.
4. (Optional) In Quest On Demand, enable **GAL synchronization** and **free/busy coexistence** for the project.

**Exit gate:** target licensed; routing domain present; service accounts created and CA-excluded; both tenants connected in Quest; project + pilot wave created; coexistence connectors created. (Test T3.)

---

## Phase 4 — Pilot

### 4.1 Provision and map pilot targets
1. Ensure the pilot users' target mailboxes exist (R10) carrying a routing address (`user@target.onmicrosoft.com`). Let Quest auto-provision or pre-create them.
2. In the project, add the pilot users to **`EXO T2T – Pilot Wave`** using `mapping.csv` (filter `Wave = EXO T2T – Pilot Wave`).
3. Add pilot members to the mail-enabled security group **`EXO T2T – Pilot Members`** for comms/testing.

### 4.2 Pre-flight validation
1. Run **`scripts\EXOMIG-Validation.ps1`** in pre-flight mode against the pilot mappings: confirms target licensing, accepted/verified domains, and provisioned mailboxes.

### 4.3 Migrate the pilot wave
1. In Quest On Demand → project → **`EXO T2T – Pilot Wave`**, start the **migration (copy)** task.
2. When the initial copy completes, run a **delta pass** to catch changes.

### 4.4 Validate the pilot
1. Run **`scripts\EXOMIG-Validation.ps1`** in post-migration mode for a sample of pilot users: item-count parity (source vs target) for mail/calendar/contacts.
2. Manually verify in the target: a pilot user can open Outlook on the web (https://outlook.office.com) and see migrated mail, calendar, and contacts.
3. Verify coexistence mail flow both directions using `EXO T2T – Pilot Members` (send source→pilot and pilot→source).

**Exit gate:** pilot content parity, coexistence mail flow both ways, free/busy (if enabled). No data loss. (Test T4.)

---

## Phase 5 — Migrate (bulk, in waves)

### 5.1 Pre-stage each wave
1. For each wave (`EXO T2T – Wave 1`, `EXO T2T – Wave 2`, …), add its mapped users in Quest On Demand and start the **initial copy** well ahead of cutover. Pre-staging copies the bulk of data while users keep working in the source.

### 5.2 Run delta passes
1. On a schedule (e.g. nightly), run **delta passes** for each pre-staged wave so the target stays current with source changes.
2. Track progress with **`scripts\EXOMIG-Report.ps1`** (per-wave counts, completed/failed, GB moved).

### 5.3 Re-apply permissions and delegation
1. After each wave's mailboxes are migrated, re-apply FullAccess/SendAs/SendOnBehalf in the target using **`scripts\EXOMIG-Remediation.ps1`** driven by `permissions.csv` (run with default `-WhatIf`, then `-Apply`).

**Exit gate:** all waves pre-staged; delta passes current (small, fast deltas); permissions re-applied; report shows near-100% complete, zero unresolved failures. (Test T5.)

---

## Phase 6 — Cutover (the 1:1 domain move)

> This is the irreversible moment. Perform in the change window, after a final delta. Lower DNS TTLs at least 24–48h in advance (best practices).

### 6.1 Final delta pass
1. Run a **final delta** for all waves so the target is fully caught up immediately before the domain moves.

### 6.2 Clear references and remove the domain from the source tenant (R6)
1. In the **source** tenant, re-stamp every object that uses `@contoso.com` onto `source.onmicrosoft.com`:
   - User UPNs and primary SMTP → `source.onmicrosoft.com`; remove `@contoso.com` proxy addresses.
   - Distribution groups, shared/resource mailboxes → remove `@contoso.com` addresses.
   - Review/remove any source connectors, transport rules, or app references using the domain.
2. In the **source** Microsoft 365 admin center → **Settings → Domains → contoso.com → Remove domain**. Microsoft will block removal if any reference remains — resolve each blocker it lists, then retry.

### 6.3 Add and verify the domain in the target tenant
1. In the **target** Microsoft 365 admin center → **Settings → Domains → Add domain**, enter `contoso.com`.
2. Add the provided **TXT verification record** at the DNS host (R5), wait for propagation, and click **Verify**. (Domain verification can only succeed once the source has released the domain — step 6.2 must complete first.)

### 6.4 Stamp primary SMTP addresses in the target
1. With `contoso.com` now verified in the target, stamp each migrated mailbox's **primary SMTP** to its final `@contoso.com` address using **`scripts\EXOMIG-Remediation.ps1 -Apply`** driven by `mapping.csv` (`FinalPrimarySMTP`).
2. Confirm `@contoso.com` is the **primary** and the routing address remains as a secondary alias.

### 6.5 Cut over MX and Autodiscover DNS
1. At the DNS host for `contoso.com`:
   - Repoint the **MX** record to the target tenant's Exchange Online endpoint (`contoso-com.mail.protection.outlook.com`).
   - Repoint **Autodiscover** CNAME to `autodiscover.outlook.com`.
   - Update **SPF** to the target's `include:spf.protection.outlook.com`, publish target **DKIM** CNAMEs (enable DKIM in the target Defender/Exchange portal), and review **DMARC**.
2. In the target Exchange admin center → **Settings → Domains**, follow the recommended DNS records for the now-verified `contoso.com`.

### 6.6 Tidy coexistence
1. Once mail is flowing directly to the target, disable/remove the coexistence connectors **`Coexistence – Source→Target Connector`** and **`Coexistence – Target→Source Connector`** when no longer needed.

**Exit gate:** domain removed from source, verified in target; primary SMTP stamped; MX/Autodiscover/SPF/DKIM repointed; mail delivering to target. (Test T6.)

---

## Phase 7 — Validate

1. Confirm inbound external mail to `user@contoso.com` lands in the **target** mailbox.
2. Confirm outbound mail from the target shows `@contoso.com` as the sender and passes SPF/DKIM/DMARC at external recipients.
3. Confirm Outlook (desktop and mobile) reconnects via Autodiscord to the target mailbox; reprofile any clients that don't auto-reconnect.
4. Run **`scripts\EXOMIG-Validation.ps1`** post-migration for a broad sample: item-count parity, addresses correct, permissions present.
5. Confirm free/busy and delegation work within the target tenant.

**Exit gate:** all acceptance tests in `05-testing.md` PASS. (Test T7, acceptance gate.)

---

## Phase 8 — Decommission

1. **Convert/remove source mailboxes** — once validation is signed off and a retention/grace period has passed, convert source user mailboxes to shared (for short-term reference) or remove them; offboard source licenses.
2. **Remove coexistence objects** — delete the coexistence connectors and any routing-domain artifacts no longer needed.
3. **Reverse the MFA / Conditional Access exclusions (R8)** — remove `svc-quest-migration` from the CA exclude lists in both tenants.
4. **Disable/remove the migration service accounts** — `svc-quest-migration` in both tenants, after final reporting.
5. **Disconnect tenants in Quest On Demand** if the project is closed; revoke the consented enterprise application if not needed.
6. **Archive evidence** — keep the discovery, validation, and report CSVs as the project record.

**Exit gate:** source footprint retired, temporary exclusions reversed, service accounts removed, evidence archived. (Test T8.)

---

## Object name register (reuse verbatim)

| Object | Name |
|--------|------|
| Quest On Demand project | `EXO T2T – Contoso – Migration Project` |
| Pilot wave | `EXO T2T – Pilot Wave` |
| Bulk waves | `EXO T2T – Wave 1`, `EXO T2T – Wave 2`, … |
| Source service account | `svc-quest-migration@source.onmicrosoft.com` |
| Target service account | `svc-quest-migration@target.onmicrosoft.com` |
| Source→target connector | `Coexistence – Source→Target Connector` |
| Target→source connector | `Coexistence – Target→Source Connector` |
| Pilot mail-enabled security group | `EXO T2T – Pilot Members` |
