# Executive Summary — Exchange Online Mailbox Automation with Logic Apps Managed Identity (Microsoft Azure)

**White-label · Azure Solutions**

A team builds an Azure **Logic Apps** workflow to act on an Exchange Online mailbox and tries to authenticate it with the Logic App's **managed identity** using the **Office 365 Outlook** connector's *"When a new email arrives"* trigger — and it simply does not work. This is not a misconfiguration you can fix in the trigger's settings.

**Root cause:** the Office 365 Outlook connector authenticates as a **user / service account** through a stored OAuth connection. It has no way to authenticate as a managed identity, so the trigger cannot bind to one. The usual "workaround" — pointing the connection at a licensed service-account mailbox — reintroduces exactly the stored-credential and shared-account risk the managed identity was meant to remove. *(Whether any specific connector operation supports managed identity is a product detail that changes — verify against current Microsoft documentation.)*

This solution delivers the **supported fix**: stop using that connector and drive the mailbox through **Microsoft Graph**, with the Logic App's managed identity holding a **least-privilege application permission** (`Mail.Read`) that is **scoped to exactly one mailbox** — not the whole tenant. This is a complete, **deploy-it-today** package written for an administrator with no prior Graph or managed-identity experience.

## What you get
- A plain-language **Solution Overview** that states the root cause, presents the Graph design, and gives a **webhook-vs-polling decision table** — pointing to the sibling products that go deep on each pattern, and to the sibling that goes deep on mailbox scoping.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite.
- An **Implementation Guide** of precise, ordered steps: enable the identity, grant the `Mail.Read` app role with admin consent, **scope the access to one mailbox**, and build the Graph read with managed-identity authentication.
- Five **PowerShell scripts** (Microsoft.Graph) for discovery, least-privilege validation, an application-permission/scope report, the in-scope/out-of-scope **boundary test**, and a `-WhatIf`-defaulted helper that assigns the app role.
- **Testing** and **Troubleshooting** guides, starting with the exact "the trigger won't accept the managed identity" symptom.

## What this delivers
A Logic App that reads its mailbox as its **managed identity** — **no service account, no stored OAuth connection** — with a single application permission scoped to a single mailbox and an explicit out-of-scope test that must fail before go-live. The same authenticated, scoped identity then underpins either an event-driven (change-notification) or a polling trigger pattern.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — with a least-privilege, one-mailbox scope as the non-negotiable gate.

## Outcome
Mailbox automation that authenticates the modern, supported way — credential-free managed identity over Microsoft Graph, provably limited to one mailbox — instead of a connector that quietly falls back to a stored service-account credential. Deployable by a single administrator and validated before you scale.
