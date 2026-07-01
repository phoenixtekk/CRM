# 1. Solution Overview — Microsoft Purview: DLP, Sensitivity Labels & Retention

## What Microsoft Purview information protection is
Microsoft Purview is Microsoft's cloud suite for classifying, protecting, and retaining data across
Microsoft 365. Three capabilities work together:

1. Sensitivity labels — persistent tags (for example `Public`, `General`, `Confidential`,
   `Highly Confidential`) that can encrypt content, apply visual markings, and control sharing. They
   travel with the file and enforce protection wherever the file goes.
2. Data Loss Prevention (DLP) — policies that detect sensitive content (credit-card numbers, health
   identifiers, a matched sensitivity label, and so on) and take action — audit, warn, or block — as
   users share it across Exchange, SharePoint, OneDrive, Teams, and managed endpoints.
3. Retention and records management — labels and policies that keep content for a required period and
   then delete it (or block deletion for records), so the organization meets legal and regulatory
   obligations without hoarding or over-deleting data.

## How it works
1. You design a small sensitivity-label taxonomy and publish it with a label policy so it appears in
   Office apps, Outlook, and the web. Auto-labeling can apply labels automatically based on content.
2. DLP policies reference sensitive-information types and/or sensitivity labels. Each policy is first
   deployed in an audit-only test mode; you review the matches (the DLP audit gate), tune the
   conditions to remove false positives, and only then switch the policy to enforce (warn or block).
3. Retention labels and retention policies set how long content lives and what happens at the end of
   the period. Records management adds regulatory records (declared, immutable) and disposition
   review.
4. Every action is logged in the Microsoft Purview audit and activity explorer, so classification and
   DLP coverage can be reported.

## What you can control
- The label taxonomy, label order/priority, and the protection each label applies (encryption,
  marking, sharing restrictions).
- Where labels are published (users/groups) and whether auto-labeling applies them by content match.
- DLP scope (Exchange, SharePoint, OneDrive, Teams, endpoint devices), the sensitive-information
  types or labels a policy matches, and the action (audit, notify, block) plus policy tips.
- Retention duration, trigger, and end-of-life action (delete, retain, or declare a record); records
  management and disposition review.

## Benefits
- Protection that travels — a sensitivity label encrypts and marks content so it stays protected
  outside the tenant.
- Fewer leaks, fewer false positives — DLP tuned in audit before enforcement blocks real risk without
  blocking legitimate work.
- Defensible retention — content is kept and deleted on a defined schedule, satisfying compliance
  without over-retention.
- Reportable coverage — classification and DLP events are visible per service and fleet-wide.

## Limitations (be honest with buyers)
- Auto-labeling for SharePoint/OneDrive at rest and several DLP/endpoint features require the higher
  Microsoft 365 / Purview plans; the Requirements Guide names the licensing.
- Endpoint DLP requires devices onboarded to Microsoft Purview (the same onboarding used by Defender
  for Endpoint).
- Encryption applied by a label can affect third-party or legacy apps that do not understand the
  protection; pilot before broad enforcement.
- Retention deletion is irreversible once the period elapses; validate the schedule on a pilot scope
  first.

## The standard Phoenixtekk deployment model
> **Design the label taxonomy → publish labels and label policies → configure auto-labeling → build
> DLP in audit and tune → set retention/records → pilot → validate → expand.** Phoenixtekk pattern:
> **Assess → Configure → Pilot → Validate → Expand**, with a DLP audit gate before any policy
> enforces and a documented rollback.
