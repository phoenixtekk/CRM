# Executive Summary — Event-Driven Mail Processing with Microsoft Graph Change Notifications (Logic Apps + Managed Identity)

**White-label · Azure Solutions**

Polling a mailbox on a timer is slow and wasteful, and the Office 365 Outlook connector **cannot use a managed identity** — so it drags a stored service-account credential along with it. The event-driven answer is a **Microsoft Graph change-notification (webhook) subscription**: the moment a message arrives in the target mailbox, Graph POSTs a notification to your Logic App, which reads the message and processes it — in near real time, with **no polling and no stored credentials**.

This is a complete, **deploy-it-today** package for standing up that pattern end to end, written for an administrator with no prior Graph-subscription experience. It authenticates with the Logic App's **managed identity** holding a **least-privilege application permission scoped to one mailbox** — no service account, no secret, no O365 connection.

## What you get
- A plain-language **Solution Overview** of the subscription + receiver architecture, why event-driven beats the connector and the poll, and where it fits alongside the parent product (#1), the polling alternative (#3), and the mailbox-scoping deep-dive (#4).
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite — the public HTTPS endpoint, managed identity, application permission + admin consent, target mailbox, Microsoft.Graph module, TLS, and national-cloud endpoints.
- An **Implementation Guide** of precise, ordered steps — enable the identity, grant and consent the least-privilege permission, scope access to the one mailbox, build the receiver with the **validation handshake** and **clientState** check, create the subscription, and build the **renewal + catch-up** workflow.
- Five **PowerShell scripts** (Microsoft.Graph) for subscription/permission discovery, PASS/FAIL validation, a subscription inventory report with CSV, a `-WhatIf`-gated renewal helper, and a notification-evidence checker.
- **Testing** and **Troubleshooting** guides for a confident, durable rollout.

## What this delivers
A **Graph change-notification subscription** on the target mailbox, a **Logic App receiver** that answers Graph's validation handshake, verifies `clientState`, and reads the changed message via **managed identity** — plus the operational hard parts most guides skip: **subscription renewal before expiry, missed-notification recovery via a catch-up read, and dedup/idempotency** so a duplicate or dropped notification never means double-processing or lost mail. Mailbox access is **least-privilege, scoped to one mailbox**.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — with an explicit end-to-end event test and a documented rollback (delete the subscription; the mailbox is untouched).

## Outcome
Near-real-time, credential-free mail processing that stays reliable — instead of poll latency, a stored service account, and subscriptions that silently expire — deployable by a single administrator and validated on a pilot mailbox before you scale.

*Version-specific Graph details — maximum subscription lifetime, renewal cadence, supported resources, permission names, encrypted-payload rules, national-cloud endpoints, and Consumption-vs-Standard hosting — are flagged throughout to **verify against current Microsoft documentation** rather than asserted.*
