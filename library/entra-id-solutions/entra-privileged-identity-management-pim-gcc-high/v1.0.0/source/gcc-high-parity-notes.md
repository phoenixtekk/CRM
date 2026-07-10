# GCC High Parity & Compliance Notes — Entra Privileged Identity Management (PIM)

This is the **Government (GCC High)** edition of the PIM solution. It mirrors the commercial
just-in-time-admin method exactly, adapted for Microsoft's **US Government national cloud** (Azure
Government / GCC High). This note collects the national-cloud endpoints, the feature-parity items to
verify, and the compliance/data-residency context specific to government tenants.

> Everything here is technical context for your operators and your ISSO/compliance team. Accreditation
> boundary and impact-level (IL) determinations are the **customer's** decision — this note provides the
> technical facts, not the authorization. Never assume commercial parity: **verify every capability
> against current Microsoft Government documentation.**

## National cloud endpoints

The PIM workflow lives in the GCC High Entra admin center / Azure Government portal, and the included
scripts target the US Gov cloud. Use these hosts in place of the commercial ones:

| Purpose | Commercial | GCC High (this edition) | DoD (IL5) — verify |
|---|---|---|---|
| Sign-in / token host | `login.microsoftonline.com` | `login.microsoftonline.us` | `login.microsoftonline.us` |
| Microsoft Graph | `graph.microsoft.com` | `graph.microsoft.us` | `dod-graph.microsoft.us` |
| Microsoft Graph SDK env | `Global` | `-Environment USGov` | `-Environment USGovDoD` |
| Entra admin center | `entra.microsoft.com` | `entra.microsoft.us` | `entra.microsoft.us` (*verify*) |
| Azure portal (Azure resource-role PIM) | `portal.azure.com` | `portal.azure.us` (Azure Government) | `portal.azure.us` (*verify*) |
| Azure PowerShell env | `AzureCloud` | `Connect-AzAccount -Environment AzureUSGovernment` | `AzureUSGovernment` (*verify*) |
| M365 / admin center | `admin.microsoft.com` | `portal.office365.us` / GCC High admin center | *verify current GCC High URL* |

All five PowerShell scripts (`ENTPIMG-*`) connect with `Connect-MgGraph -Environment USGov`; the Azure
resource-role discovery path uses `Connect-AzAccount -Environment AzureUSGovernment`. For DoD (IL5)
tenants, switch the Graph environment to `USGovDoD` (`dod-graph.microsoft.us`). **Verify the correct
cloud and endpoints for your specific tenant** — GCC High and DoD are distinct clouds with distinct hosts.

## Feature-parity considerations

GCC High and DoD frequently **lag commercial** on feature rollout, previews, and connectors, and some
capabilities are unavailable. For PIM specifically, confirm the following in *current Microsoft
Government documentation* before relying on them — do **not** assume commercial parity:

- **Entra ID P2 availability & licensing** — PIM requires Entra ID P2 (or Entra ID Governance / an E5
  suite that includes it). Government SKUs, seat availability, and bundling differ from commercial.
  *Verify P2/PIM is available and licensed in your GCC High (or DoD) tenant.*
- **PIM for Azure resource roles** — availability and onboarding of Azure resource-role PIM depends on
  Azure Government resource coverage. *Verify Azure Government supports resource-role PIM for your
  subscriptions/management groups.*
- **Access reviews for privileged roles** — the Identity Governance access-review features used in Step 7
  may differ in availability or behavior in government clouds. *Verify access reviews (and auto-apply) are
  available.*
- **PIM alerts** — the built-in alert set (too many Global Administrators, activation without MFA, roles
  assigned outside PIM, stale assignments) and any newer/preview alerts may lag in GCC High/DoD. *Verify
  the alert catalog available in your cloud.*
- **Notifications / email delivery** — activation, approval, and eligible-assignment notifications route
  through the government cloud's mail path; *verify delivery and any custom-recipient options.*
- **Graph API scope names & rule shapes** — Graph scope names and the role-management-policy rule
  schema the `Validate` script reads can vary by cloud and API version. *Verify scope names and rule IDs
  against your tenant.*
- **PIM for Groups / newer PIM capabilities** — any capability beyond directory- and resource-role PIM may
  arrive later (or differently) in government clouds. *Verify availability before designing around it.*

## Compliance & data-residency context (why GCC High)

GCC High exists so US public-sector and defense-industrial-base organizations can meet federal data-
handling obligations that commercial Microsoft 365/Azure cannot. Relevant context for this PIM solution:

- **FedRAMP High** — GCC High / Azure Government are designed to support FedRAMP High authorization
  boundaries. Privileged-access management (just-in-time admin, MFA-on-activation, approval, audit,
  access reviews) directly supports the access-control and audit control families (AC / AU / IA) an
  ISSO must evidence.
- **DoD Impact Levels (IL4 / IL5)** — Azure Government / GCC High and the DoD cloud support IL4 and IL5
  workloads respectively. **Which impact level applies is the customer's ISSO/compliance determination.**
  For IL5, use the DoD endpoints (`dod-graph.microsoft.us`, `-Environment USGovDoD`) — *verify*.
- **CMMC 2.0** — for defense-industrial-base contractors, PIM supports Access Control (AC) and Audit &
  Accountability (AU) practices — least privilege, limiting privileged accounts, and logging privileged
  activity. This solution provides the technical control; your assessor evaluates the practice.
- **ITAR / EAR data residency & US-persons handling** — GCC High provides US-sovereign data residency
  and US-persons operational support, which is why organizations handling ITAR/EAR-controlled technical
  data choose it. Privileged access to that environment is exactly what PIM governs. *Confirm your
  data-residency and US-persons obligations with your compliance team.*

Determinations of accreditation boundary, impact level, and control applicability are the customer's
ISSO/compliance decision. This solution supplies the technical implementation and evidence (discovery,
policy validation, activation audit, access-review status) — not the authorization.

## DoD (IL5) note

Where a tenant operates at **DoD IL5** rather than GCC High, the cloud and endpoints differ:

- Microsoft Graph host: **`dod-graph.microsoft.us`** (not `graph.microsoft.us`).
- Graph SDK: `Connect-MgGraph -Environment USGovDoD`.
- Confirm the correct Entra admin center / Azure Government portal URLs and PIM feature availability for
  the DoD cloud.

All of the above is **"verify against current Microsoft Government documentation"** — DoD feature
availability and endpoints can differ from GCC High and change over time.
