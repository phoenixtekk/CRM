# Executive Summary — Secure Microsoft 365 Copilot: Oversharing & SharePoint Permissions Remediation

## What this is
A self-guided, field-tested playbook that closes the **Copilot oversharing gap** at its source — the
**SharePoint Online and OneDrive permissions** that decide what Copilot can surface. Copilot creates no
new access; it inherits every grant a user already has. On the day Copilot is enabled, every
over-shared site, every "Everyone Except External Users" (EEEU) grant, every anonymous link, and every
stale permission becomes one prompt away. This solution finds that exposure, fixes it, and proves
Copilot only returns what it should.

## The outcome
- **A measured inventory of oversharing** — broad-access sites, EEEU / organization-wide grants,
  anonymous ("Anyone") links, and stale permissions across the in-scope SharePoint/OneDrive estate.
- **Remediated access** — broad grants removed or scoped, high-risk sites fenced with **SharePoint
  Advanced Management (SAM)** controls (**Restricted Access Control**, **Restricted Content Discovery**)
  and, as an interim stopgap, tenant **Restricted SharePoint Search**.
- **Sensitivity-label + DLP alignment** so the corrected boundaries are reinforced by information
  protection, not just sharing settings.
- **Proof it worked** — a re-measure showing the oversharing signal reduced, plus a Copilot-side
  verification that a test user can no longer surface content they should not reach.

## The boundary
This solution remediates **SharePoint/OneDrive access and discovery scope** so Copilot honors the real
boundary. It is the SharePoint-permissions counterpart to the Copilot data-governance solution
(labels + DLP for Copilot), and it references — rather than duplicates — the Purview information-
protection build. **SharePoint Advanced Management, Restricted Content Discovery, and Restricted
SharePoint Search are licensing-/tenant-dependent and evolving — availability is flagged "verify," never
assumed.** **Data-owner decisions** — who *should* have access to a given site, what is "too broad," and
which content must be fenced — remain with the **site owners and the business**; this package supplies
the discovery, the technical remediation method, and the evidence, not the access determinations.

## Effort
A competent M365/SharePoint administrator can run the **Assess → Configure → Pilot → Validate → Expand**
model in roughly **2–5 working days** for a pilot ring, then repeat the pattern per wave. Discovery,
validation, and reporting are automated with read-only PowerShell (Microsoft Graph / PnP PowerShell);
every change is previewed with `-WhatIf` and piloted before broad rollout.

## What is delivered
Eight guides (this summary, overview, requirements, implementation, testing, troubleshooting, best
practices, deliverables) and **five safe-by-default PowerShell scripts** (read-only discovery,
validation, reporting; `-WhatIf`-gated remediation; access-review workbook) — all white-label, no
secrets in code, delivered as a Complete Solution Package (PDF + Word + scripts).
