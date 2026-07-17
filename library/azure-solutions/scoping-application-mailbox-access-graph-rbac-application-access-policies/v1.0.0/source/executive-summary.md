# Executive Summary — Scoping Application-Permission Mailbox Access (Graph RBAC & Application Access Policies)

**White-label · Azure Solutions**

Granting an application — an app registration or the managed identity of a Logic App or Function — an **application** Graph permission over mail (`Mail.Read`, `Mail.Send`, `Mail.ReadWrite`, `MailboxSettings.*`) is **tenant-wide by default**: it can read, write, or send as **every mailbox in the organization**, not just the one it was built to service. That is almost never intended, and it is a classic security-review finding — the blast radius of a leaked secret or a compromised managed identity is the entire organization's mail.

This solution implements **least-privilege mailbox access** for apps and managed identities: it scopes the identity to a specific mailbox or a mail-enabled security group of allowed mailboxes, and then **proves** the boundary. It is written for an administrator with no prior experience of Exchange application access policies or Exchange RBAC, and it is the standalone reference that the sibling automation solutions (Logic Apps mailbox automation, managed-identity authentication to Microsoft 365) point to for scoping.

## What you get
- A plain-language **Solution Overview** of the exposure and the **two scoping models** — Application Access Policy and Graph RBAC for Exchange Online — with a clear decision path for which fits.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite.
- An **Implementation Guide** covering **both** models end to end — create the mail-enabled security group and bind the app (Model A), or create the resource scope and assign a scoped Exchange role (Model B) — every object named and reused, every cmdlet flagged to verify against current Microsoft documentation.
- Five **PowerShell scripts** for discovery, scoping validation, a tenant-wide audit report, the in-scope/out-of-scope boundary proof, and a `-WhatIf`-gated policy setter.
- **Testing** and **Troubleshooting** guides with explicit PASS/FAIL gates.

## What this delivers
An application's mailbox access **scoped** to exactly the mailboxes it is allowed to touch, with a **tested, auditable boundary**: the in-scope read succeeds, the out-of-scope read is **denied**, and the evidence is captured for auditors — using whichever of the two Exchange scoping models fits your estate.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — with the boundary proof (in-scope PASS, out-of-scope DENIED) as the gate and a documented rollback.

## Outcome
Least-privilege mailbox access for every app and managed identity — a scope proven to hold, both models explained, and a tenant-wide report driving the count of unscoped mail permissions to zero — instead of a tenant-wide grant that can reach every mailbox in the organization.
