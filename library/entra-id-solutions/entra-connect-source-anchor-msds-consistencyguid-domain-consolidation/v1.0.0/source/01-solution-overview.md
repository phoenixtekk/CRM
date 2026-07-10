# 1. Solution Overview — Migrating the Microsoft Entra Connect Source Anchor to mS-DS-ConsistencyGuid for AD Domain Consolidation & Cross-Forest Migration

## The scenario this solves
You are consolidating Active Directory — remapping accounts into a target domain or forest and up
into Microsoft Entra ID — and you are moving the objects with the Quest On Demand Migration (ODM)
Active Directory tooling. But your existing Microsoft Entra Connect Sync deployment uses **objectGUID**
as its source anchor (the older default). That single design choice will break every migrated
identity's link to the cloud unless you change it first. This solution changes the source anchor to
**mS-DS-ConsistencyGuid** safely, on a live deployment, without re-syncing your users or creating
duplicates — so the domain consolidation does not orphan your Entra identities.

## Why objectGUID breaks on migration (the why lives here)
The source anchor (also called the immutableId) is the value Entra Connect uses to say "this on-prem
object *is* that cloud object." objectGUID is stamped by Active Directory and is unique to an object
**within a single domain**. When Quest ODM migrates (or you otherwise re-create) an account into a
different domain or forest, the target domain issues the object a **brand-new objectGUID**. With
objectGUID as the anchor, Entra Connect then sees the migrated object as a **completely new identity**:
it can no longer match it to the existing Entra user. The result is a duplicate or orphaned cloud
account — and the user loses their mailbox, licenses, Teams, and everything else tied to the original
Entra object. On a domain consolidation, objectGUID is a landmine.

## Why mS-DS-ConsistencyGuid is the fix
mS-DS-ConsistencyGuid is a writable AD attribute whose value is **preserved across a migration**
when the migration tool carries it forward. Quest ODM **stamps (copies) the mS-DS-ConsistencyGuid
value onto the target object** as part of the move. Because the anchor value survives the move,
Entra Connect can **hard-match** the migrated AD object to the *existing* Entra user — same identity,
same mailbox, same licenses. The on-prem ↔ Entra link survives the consolidation. This is exactly why
Microsoft recommends mS-DS-ConsistencyGuid as the source anchor for any environment that will migrate
or restructure AD.

## What the switch actually does (and why it is seamless)
Switching the anchor on a live objectGUID deployment is a supported wizard operation. When you select
mS-DS-ConsistencyGuid in the Microsoft Entra Connect wizard, for **each in-scope object whose
mS-DS-ConsistencyGuid is currently empty**, Connect **writes that object's own objectGUID value into
its mS-DS-ConsistencyGuid attribute** (a write-back into AD). Because the value it seeds is the *same*
objectGUID the anchor already used, the computed immutableId does **not change** for your existing
users. So there is **no re-sync, no duplicate accounts, and no user impact** at cutover — the anchor
simply moves from a domain-scoped attribute to a migration-safe one, carrying the same value.

## The precondition that makes it safe
The wizard will only seed mS-DS-ConsistencyGuid where it is **empty**. It analyzes all in-scope objects
first, and **if any in-scope object already has a value in mS-DS-ConsistencyGuid, the wizard refuses
by default** — because a pre-existing value could mean the object was matched by something else, and
overwriting it would break the link. That refusal is a safety feature, not a bug: it forces you to
find and understand what populated the attribute before you proceed. Confirming the attribute is empty
across scope is therefore the central go/no-go check of this solution.

## What you can control
- The **source anchor** itself — objectGUID today, mS-DS-ConsistencyGuid after this change.
- The **AD scope** the change applies to — the `Source Anchor – In-Scope OUs` that Connect syncs.
- The **AD DS connector (sync) account's** write permission to mS-DS-ConsistencyGuid (required to seed it).
- The **backup** taken before the change — the exported Connect configuration in your
  `Source Anchor – Change & Backup Record`.
- The **pilot proof** — a `PILOT – Source Anchor – Validation Users` set migrated through Quest ODM to
  prove the hard-match survives before you run production waves.

## The standard deployment model
> Assess the current anchor, version, permissions, and whether mS-DS-ConsistencyGuid is empty ->
> Configure the switch in the Entra Connect wizard -> Pilot one migrated user through Quest ODM and
> confirm a hard-match -> Validate no duplicates/orphans and unchanged immutableId -> Expand into the
> full Quest ODM migration waves. The repeatable way: Assess -> Configure -> Pilot -> Validate -> Expand.

## Limitations (be honest with buyers)
- The anchor switch is effectively **permanent and one-way**. Once objects are seeded and migrations
  begin, you do **not** revert to objectGUID mid-migration — the safety net is the pre-change backup
  and the empty-attribute precondition, not a rollback.
- It requires a **current Microsoft Entra Connect Sync** build (mS-DS-ConsistencyGuid has been the
  default source anchor since Azure AD Connect 1.1.524; an old build may not offer the operation).
- mS-DS-ConsistencyGuid is a **single-forest linking attribute**; a genuine multi-forest topology
  needs additional matching planning (called out where relevant).
- The **actual attribute-carry across the migration is Quest ODM's job** — this solution states the
  coordination point (Quest must stamp/copy mS-DS-ConsistencyGuid onto the target object) and consumes
  it; the Quest ODM console configuration itself is documented by Quest.

## Scope of this solution (what it is and is not)
This is the **source-anchor migration** for a domain consolidation — the specific, high-risk switch
from objectGUID to mS-DS-ConsistencyGuid on an existing deployment, plus the precondition, permission,
backup, pilot, and validation work around it. It does **not** re-teach general Microsoft Entra Connect
or hybrid-identity setup (installing Connect, choosing PHS/PTA/federation, hybrid join) — that is the
companion Hybrid Identity solution. Start here when Connect is already running on objectGUID and a
migration is coming.
