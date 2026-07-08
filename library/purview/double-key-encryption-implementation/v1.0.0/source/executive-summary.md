# Executive Summary — Double Key Encryption (DKE) Implementation, Microsoft Purview

**White-label · Purview Solutions**

For the most sensitive data an organization holds — trade secrets, deal data, regulated records, or
information subject to a sovereignty requirement — standard encryption is not enough on its own,
because the key that protects it lives entirely within the cloud provider. **Double Key Encryption
(DKE)** in Microsoft Purview closes that gap: content is protected by **two** keys — one held by
Microsoft and one held by **you**, in a key service **you** control. Both keys are required to
decrypt, so no one — not Microsoft, not an attacker who compromises the tenant — can read the content
without the key you keep. That control is the deliverable.

This is a complete, deploy-it-in-order package for standing up Double Key Encryption end to end: the
**customer-held DKE key service**, the **Microsoft Entra ID app registration** that secures it, and
the **sensitivity label** wired to your endpoint — piloted on a named group, validated, and expanded
under change control. It is written for an administrator with no prior DKE experience.

## What you get
- A plain-language Solution Overview of how DKE works — the two keys, the customer-held key service,
  the label wiring, and the deliberate trade-offs (DKE content is invisible to cloud content
  services).
- A Requirements Guide with verify / implement-if-missing for every prerequisite (licensing, roles,
  a host for the key service, the client platform, and stakeholders).
- An Implementation Guide of precise, ordered steps — deploy and secure the key service, register the
  app in Entra ID, create and publish the DKE label, pilot, validate, then expand.
- Five PowerShell scripts: configuration discovery, safe remediation (default `-WhatIf`), coverage
  validation, a DKE usage report, and a scope + key-service health helper.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers
A named, reusable set of objects — a customer-held DKE key service, an Entra app registration that
authorizes it, and a Double-Key-Encryption sensitivity label published to a pilot group — deployed on
the assess-configure-pilot model, validated end to end (key held by you, both keys required to
decrypt), with a documented rollback.

## The standard deployment model
**Assess → Design → Configure → Pilot (test scope) → Validate → Expand.**

## Scope boundary
Which data is "most sensitive" and must be double-keyed, and any regulatory or sovereignty
determination, are **compliance, records, privacy, and legal** decisions — this package delivers the
technical capability and the evidence, not the classification determination.

## Outcome
The second key stays under your control in Microsoft Purview — Double Key Encryption configured for
your most sensitive data, the key service you own, and the label wiring proven on a pilot before you
scale.
