# 1. Solution Overview — Double Key Encryption (DKE) Implementation, Microsoft Purview

## What Double Key Encryption is
Double Key Encryption (DKE) is a Microsoft Purview Information Protection capability for the
organization's **most sensitive** data. Content protected with a DKE sensitivity label is encrypted
with **two** keys:

1. A **Microsoft-held key**, stored in Azure as part of Microsoft Purview / Azure Rights Management —
   the same key used by ordinary sensitivity-label encryption.
2. A **customer-held key**, stored in a **key service that you deploy and control** (the DKE service),
   which never leaves your control.

**Both keys are required to decrypt the content.** Because Microsoft never holds your key, no one can
read DKE-protected content without access to your key service — not Microsoft, and not an adversary
who compromises your Microsoft 365 tenant. That is the entire point: you keep control of the second
key.

## How it works
1. You deploy the **DKE key service** — an open-source reference web service published by Microsoft —
   onto hosting **you** control (for example an Azure App Service web app or an on-premises/IIS
   server). The service holds your key pair and exposes a public-key endpoint plus a
   decrypt/wrap-unwrap endpoint over HTTPS.
2. You **register the DKE service as an application in Microsoft Entra ID** and secure its endpoints
   with OAuth, so only authorized users in your tenant can request the customer-held key operations.
3. In the Microsoft Purview portal you create a **sensitivity label** whose encryption is set to
   **Use Double Key Encryption**, and you enter your DKE **endpoint URL** on the label. You publish
   the label with a label policy to a pilot group.
4. A user applies the DKE label to a document or email in a supported Office client. The client
   obtains the Microsoft key from Azure and the **customer key from your DKE service** (after the
   user authenticates); the content is double-encrypted. To open it later, the client must again reach
   **both** key sources.

## What you control
- **Where your key lives** — in a service you deploy, on hosting you own, in a region you choose (a
  sovereignty and custody control).
- **Who can use the key** — through the Entra ID app registration, OAuth, and the authorized-user
  configuration on the DKE service.
- **Which data is double-keyed** — through the DKE sensitivity label and where you publish it (a small
  named audience for the most sensitive data, not everyone).
- **Availability of the second key** — because decryption depends on your service, its uptime and
  reachability are yours to run.

## Benefits
- **Customer key custody** — the second key is yours; Microsoft cannot decrypt the content, which is
  exactly what the most sensitive data and many sovereignty requirements call for.
- **Defense in depth for the crown jewels** — a tenant compromise does not expose DKE content without
  also compromising your separate key service.
- **Same label experience** — users apply a sensitivity label like any other; the double-key
  mechanics are transparent to them.
- **Defensible and evidenced** — the capability is configured, piloted, and validated, with a clear
  record of the key you hold.

## Limitations (be honest with buyers)
- **DKE content is invisible to cloud content services — by design.** Because Microsoft cannot decrypt
  it, DKE-protected content **cannot** be inspected by content-based DLP, indexed for eDiscovery
  content search, scanned by Microsoft 365 co-authoring/AutoSave, or read by Copilot or other cloud
  processing. Reserve DKE for the small set of data where that trade-off is acceptable. **Verify the
  current list of unsupported services for your tenant** in Microsoft's documentation.
- **Client-platform support is limited and evolving.** DKE labels are applied through built-in
  labeling in **Office desktop apps on Windows**; web and other platforms have historically not
  supported DKE. **Verify current platform/client support for your tenant** before you scope users.
- **You run the key service.** Its availability, patching, backup, and disaster recovery are your
  responsibility; if the service is unreachable, DKE content cannot be opened.
- **Licensing-gated.** DKE requires the appropriate Microsoft 365 / Purview plan (see the Requirements
  Guide) — **verify your licensing/tenant.**

## The standard deployment model
> **Deploy the customer-held key service → secure it with an Entra ID app registration → create and
> publish the DKE label → pilot on a named group → validate (both keys required, key held by you) →
> expand under change control.** Repeatable pattern: **Assess → Design → Configure → Pilot → Validate
> → Expand**, with a documented rollback at every stage.

*Which data is sensitive enough to warrant DKE, and any regulatory or sovereignty applicability, are
deferred to the organization's compliance, records, privacy, and legal functions — this solution
provides the technical configuration and the evidence, not the determination.*
