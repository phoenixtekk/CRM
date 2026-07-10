# Executive Summary — Migrating the Microsoft Entra Connect Source Anchor to mS-DS-ConsistencyGuid for AD Domain Consolidation & Cross-Forest Migration

Entra ID Solutions

You are consolidating Active Directory — remapping accounts into a target domain or forest and up into
Microsoft Entra ID — and moving the objects with the Quest On Demand Migration (ODM) tooling. But your
existing Microsoft Entra Connect Sync deployment still uses **objectGUID** as its source anchor. That
older default is a landmine: objectGUID is regenerated when an object moves to a new domain or forest,
so every migrated account looks like a brand-new identity to Entra — producing duplicate or orphaned
cloud accounts and users who lose their mailbox, licenses, and Teams. This solution changes the source
anchor to **mS-DS-ConsistencyGuid** safely, on a live deployment, without re-syncing users or creating
duplicates — so the consolidation does not orphan your Entra identities.

This is a complete, do-it-safely package for the specific, high-risk switch from objectGUID to
mS-DS-ConsistencyGuid, written for an administrator with no prior experience of the operation — and it
treats the identity link as the near-irreversible surface it is.

## What you get
- A plain-language Solution Overview of why objectGUID breaks on migration, why mS-DS-ConsistencyGuid
  survives (and how Quest ODM stamps it onto the target), what the wizard switch actually does, and why
  it is seamless for existing users.
- A Requirements Guide with verify / implement-if-missing for every prerequisite — a current Connect
  build, the current anchor, the empty-attribute precondition, the connector-account write permission,
  a configuration backup, the Quest ODM stamp, AD FS ports (if federated), roles, and the tenant.
- An Implementation Guide of precise, click-to-implement steps in five phases with explicit Gates A-E.
- Five read-only PowerShell scripts for assessment, precondition testing, permission checking,
  post-change validation, and coverage reporting. (The anchor change itself is done in the wizard, by
  design — never scripted.)
- Testing and Troubleshooting guides, including the decisive Quest ODM hard-match test.

## What this delivers
The source anchor migrated from objectGUID to mS-DS-ConsistencyGuid: Connect seeds each in-scope
object's existing objectGUID value into mS-DS-ConsistencyGuid, so the immutableId does not change,
there is no re-sync, and no duplicates appear. Quest ODM then carries that attribute across each move,
letting Entra Connect hard-match every migrated object to its existing Entra user.

## The deployment model
Assess -> Configure -> Pilot -> Validate -> Expand — with an explicit gate between phases and a
pre-change configuration backup taken before the wizard runs.

## Outcome
A migration-safe identity link: the same user, mailbox, and licenses survive the domain consolidation,
proven by a Quest ODM hard-match on a pilot before the production waves — deployable by a single
administrator, without orphaning a single Entra identity.
