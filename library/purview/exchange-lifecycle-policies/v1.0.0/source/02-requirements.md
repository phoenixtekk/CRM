# Requirements — Exchange Lifecycle Policies in Microsoft Purview

Confirm every prerequisite below **before** you configure anything. Category-level prerequisites
(tenant, licensing model, least-privilege roles, S&C PowerShell / Graph toolchain, in-scope data
sources, compliance/records/privacy/legal stakeholders, pilot scope + change control) are in
`global-requirements-purview.md` — reference them; they are **not** repeated here. The items below are
the ones **specific to Exchange lifecycle policies** and their two engines: **Purview Data Lifecycle
Management retention** and **Exchange (MRM) messaging records management**.

Each requirement is written as **Description · Why · Verify · Implement if missing.**

> The retention **schedule** (how long mail is kept, when it may be deleted) and any **legal hold**
> are **records/legal determinations**, not technical defaults — see `global-requirements-purview.md`
> §5. Several requirements below are hard gates because retention **delete** is destructive and, past
> the recovery window, **irreversible**.

---

## R1. Licensing for Exchange retention + MRM + archive

**Description:** Microsoft 365 / Exchange Online plans that unlock the pieces you use: **Purview
retention policies** for Exchange (available with **Exchange Online Plan 2**, included in **Microsoft
365 E3/E5** and equivalents); the **online archive mailbox** (Plan 2 / E3+) and **auto-expanding
archiving** (E3/E5 or Exchange Online archiving add-on) if you use MoveToArchive cleanup; and
**adaptive scopes** (require **E5 / E5 Compliance**) if you scope the retention policy dynamically.
**Why:** Retention, archive, and adaptive scoping are plan-gated; the control will not be available
without the right plan, and in-scope mailboxes must be licensed.
**Verify:** Microsoft 365 admin center → **Billing → Licenses**; in the Purview portal, **Data
Lifecycle Management → Retention Policies** is present and **Exchange** is a selectable location;
archive availability shows per mailbox. Cross-check advanced features against the *Microsoft Purview
service description* — **verify against your licensing/tenant.**
**Implement if missing:** Acquire/assign the required SKUs/add-ons before configuring. If you lack E5,
use **static scoping** (a mailbox list / group) instead of adaptive scopes.

## R2. Least-privilege roles — retention (Purview) and MRM (Exchange)

**Description:** The least-privilege roles for each engine, mapped to **named** people:
- **Retention Management** or **Compliance Administrator / Compliance Data Administrator** in the
  Purview portal to author **retention policies and rules**.
- **Retention Management** role (Exchange Online RBAC) to create **MRM retention tags/policies** and
  assign them to mailboxes; **Recipient Management** where you also change mailbox settings/archive.
- **Global Administrator** only where genuinely required (e.g. first-time Purview role assignment).
**Why:** Purview retention and Exchange MRM use **separate** role models; configuring both requires the
matching least-privilege role on each surface, without over-granting.
**Verify:** Purview → **Roles & scopes / Permissions** (retention roles); Exchange admin center →
**Roles → Admin roles** (Retention/Recipient Management). `DLCEXO-Discovery.ps1` reports the role
signals it can read.
**Implement if missing:** Assign the least-privilege role on each surface under change control.

## R3. Exchange Online PowerShell + Security & Compliance PowerShell toolchain

**Description:** A workstation with the **ExchangeOnlineManagement** module, able to run both
**`Connect-IPPSSession`** (Security & Compliance — for Purview retention policies/rules) and
**`Connect-ExchangeOnline`** (Exchange Online — for MRM tags/policies, mailbox assignment, and the
Managed Folder Assistant), with a modern-auth / MFA-capable admin account.
**Why:** The two engines are configured through **two different connections** in the same module; the
provided scripts use both. Graph is used only for read-only mailbox/scope signals.
**Verify:** `Connect-IPPSSession` and `Connect-ExchangeOnline` both succeed; `Get-RetentionCompliancePolicy`
and `Get-RetentionPolicy` each return without error.
**Implement if missing:** `Install-Module ExchangeOnlineManagement`; confirm modern-auth sign-in for
both connections before running steps.

## R4. The retention schedule (records determination) — retain, delete, or keep-then-delete

**Description:** A **documented retention schedule for mail**, approved by records/legal: the
**retain period** (e.g. retain 7 years), whether mail is **deleted at end-of-life** (`KeepAndDelete`),
**retained only** (`Retain`), or **deleted by age** with no retain guarantee (`Delete`), and whether
the period runs from **created** or **last-modified** date.
**Why:** This determines exactly what the retention rule does to real mail; a delete action is
destructive. It is a **records/legal determination**, not a technical choice.
**Verify:** Confirm the approved schedule **in writing**, including the disposition action and duration,
before you author the rule.
**Implement if missing:** **Stop** and obtain it from records/legal. Do not enable a delete action on a
schedule you cannot cite. (See `global-requirements-purview.md` §5.)

## R5. Legal-hold / eDiscovery status of the in-scope mailboxes

**Description:** Knowledge of which in-scope mailboxes are under a **litigation hold**, **eDiscovery
hold**, or an existing **retention policy/label** that preserves content — and confirmation that the
new cleanup/delete behavior will not conflict with an active hold.
**Why:** A hold **overrides** delete (held content is preserved regardless), which is correct — but you
must know it, because it changes what "cleanup" actually removes and can mask a mis-scoped rule.
Removing or shortening retention on held data is a legal matter.
**Verify:** Purview → **Data Lifecycle Management / eDiscovery** and Exchange **litigation hold**
status per mailbox; `DLCEXO-Discovery.ps1` reports litigation-hold and existing-policy signals it can
read.
**Implement if missing:** Reconcile holds with records/legal **before** enabling delete/cleanup;
exclude or defer any mailbox whose hold status is unresolved.

## R6. Cleanup design — MRM tags and the archive tier

**Description:** The **MRM cleanup design**, agreed with the business: which default folders are aged
out (e.g. **Deleted Items** and **Junk Email** → permanently delete after 30 days), whether a **Default
Policy Tag** moves old mail to the **archive** (e.g. move to archive after 2 years), and whether users
get **Personal Tags**. Plus whether the **online archive** (and **auto-expanding archive**) is enabled
where MoveToArchive is used.
**Why:** MRM is the hygiene engine; its tags act on real folders and (for delete tags) permanently
remove mail. MoveToArchive needs an archive mailbox to move to.
**Verify:** Exchange → **Compliance management → Retention tags/policies**; archive enabled per mailbox
(`Get-Mailbox -Archive`); `DLCEXO-Discovery.ps1` reports existing MRM tags/policies and archive status.
**Implement if missing:** Define the tag set and (if used) enable archive mailboxes before assigning the
MRM policy.

## R7. Pilot scope and change control (limited ring / retain-first)

**Description:** A **named pilot ring** — a small mailbox list or mail-enabled group **`SG-DLCEXO-Pilot`**
— and agreement to deploy the Purview retention policy and MRM policy to that ring **first**, under
**change control**, before any tenant-wide or delete-enabled expansion. Because retention has **no
simulation mode**, the pilot is the safety mechanism; optionally start the retention rule **retain-only**
and add delete after validation.
**Why:** Retention delete and MRM delete are high-impact and largely irreversible; the pilot ring proves
the policies keep/move/clean the right mail **without** touching anyone else, and lets you tune before
enforcing broadly.
**Verify:** Confirm the pilot group exists and its membership, that a retain-first option was
considered, and a change window/approval path. `DLCEXO-Set-Scope.ps1` (read-only) records the pilot
scope manifest; `DLCEXO-Configure.ps1` defaults to `-WhatIf`.
**Implement if missing:** Create the pilot group, deploy to it first, and agree change control before
expanding scope or enabling delete.

## R8. Managed Folder Assistant / processing expectations

**Description:** Awareness that MRM tags are applied by the **Managed Folder Assistant (MFA)**, which
runs on its own **work cycle** (roughly once per day, best-effort) — cleanup/archive is **not
instantaneous** — and that you can trigger a processing pass for a pilot mailbox with
`Start-ManagedFolderAssistant`.
**Why:** Test expectations must match reality: if you assign a tag and check a minute later, nothing
will have changed. Validation must allow for the MFA cycle (or a manual trigger on the pilot mailbox).
**Verify:** `Start-ManagedFolderAssistant -Identity <pilotMailbox>` succeeds on a pilot mailbox;
`Get-MailboxFolderStatistics` / message age reflects processing after the pass.
**Implement if missing:** Plan validation around the MFA cycle; trigger it manually on pilot mailboxes
to observe results within a test window.
