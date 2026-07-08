# 1. Solution Overview — Browser & Network DLP (Microsoft Purview)

## What this solution is
Users upload sensitive data to the web every day — a document dragged into a personal Google Drive or
Dropbox, a spreadsheet pasted into a consumer AI chat, a file sent through a browser to an unsanctioned
SaaS app. From the network's point of view this is just HTTPS; from a compliance point of view it is
data walking out the door with no control and no record. This solution closes that gap in **Microsoft
Purview** by standing up **Browser & Network DLP** — Endpoint DLP's **browser and domain restrictions**
enforced through the **Microsoft Purview browser extension** and native browser integration — so uploads
to **unsanctioned and personal cloud services** are controlled, evidenced, and defensible.

Concretely, it delivers:

- **Device onboarding readiness** — confirm endpoints are onboarded to Purview (Endpoint DLP can only
  see and control devices it is onboarded to).
- **Browser coverage** — deploy the **Microsoft Purview browser extension** (Chrome, Firefox) and use
  the **native integration in Microsoft Edge**, and configure the **unallowed browsers** list so
  sensitive items can't be moved through a browser Purview can't inspect.
- **Sensitive service domains** — group the web destinations that matter (personal cloud, unsanctioned
  file-sharing/SaaS) into a **sensitive service domain group** and choose the action per activity —
  **Audit**, **Warn (block with override)**, or **Block** — for **uploading to a restricted domain**.
- **A Devices-scoped DLP policy** — conditioned on your sensitivity labels / sensitive information types,
  restricting the "upload to a restricted cloud service domain or access from an unallowed browser"
  activity — authored and **piloted in simulation/test mode first**, validated, then enforced.
- **Evidence** — endpoint egress activity surfaced in Activity Explorer and the unified audit log, so
  you can show what was blocked, warned, or audited.

Everything is done with the **Microsoft Purview portal** (purview.microsoft.com), **Security &
Compliance PowerShell** (`Connect-IPPSSession`), and **Microsoft Graph** — no third-party tooling.

> **Browser & network DLP is one lane of Endpoint DLP.** This solution focuses on **browser uploads to
> unsanctioned/personal web destinations** — the extension, unallowed browsers, sensitive service
> domains, and the upload restriction. Other Endpoint DLP activities (USB/removable media, print,
> clipboard/screen capture, copy-to-network-share) and other DLP locations (Exchange, SharePoint,
> OneDrive, Teams, cloud apps via Defender for Cloud Apps) are the subject of their own dedicated
> solutions. Where this guide reaches the edge of another lane, it points to that lane rather than
> duplicating it.

## Why this matters
- **Browser upload is the most common uncontrolled egress path.** Personal cloud and consumer SaaS are a
  click away in any browser; without browser DLP there is no policy and no record when sensitive data
  goes to them.
- **The browser is a blind spot unless Purview is inside it.** Endpoint DLP inspects browser activity
  through the **Purview extension** (Chrome/Firefox) and **native Edge** integration. A browser without
  that coverage is exactly why the **unallowed browsers** control exists — steer users to a browser
  Purview can see into, or block sensitive movement there.
- **Simulation turns a risky control into a safe rollout.** Blocking uploads tenant-wide on day one
  breaks legitimate work and generates a flood of tickets. Piloting in **simulation/test mode** shows
  exactly what *would* have been blocked — you tune first, enforce second.
- **"We control web uploads of sensitive data" needs evidence.** Auditors and regulators ask for the
  control *and* the proof. Activity Explorer and the audit log make the control defensible.

## How it works
1. **Assess.** Read the tenant's compliance licensing (is Endpoint DLP available on the plan?), device
   onboarding status, existing Devices-scoped DLP policies, and browser-extension readiness — read-only,
   no changes.
2. **Design.** Decide the **in-scope data** (which sensitivity labels / sensitive information types make
   an upload "sensitive"), the **destination groups** (personal cloud + unsanctioned SaaS), the
   **unallowed browsers** stance, and the **action ladder** (Audit → Warn → Block) per destination
   group.
3. **Configure.** Onboard/confirm devices, deploy the Purview browser extension, build the **sensitive
   service domain group** in Endpoint DLP settings, and author the **Devices-scoped DLP policy** — the
   policy is created in **simulation/test mode**, not enforcing.
4. **Pilot (simulate).** Run the policy in **simulation / test mode** on a pilot ring of devices/users;
   review what it *would* block or warn on in Activity Explorer, and tune the domain group, conditions,
   and actions.
5. **Validate.** Confirm the extension is active, the domain group and unallowed-browser controls behave,
   simulation shows the expected matches with acceptable false positives, and every Testing-Guide gate
   passes on the ring.
6. **Expand (enforce).** Move the tuned policy from simulation to **enforce** (Warn, then Block where
   appropriate), broaden device scope, and keep the audit/Activity-Explorer evidence flowing.

## What you can control
- Which **devices** are in scope (onboarded to Purview; a pilot ring first).
- Which **browsers** are covered (extension on Chrome/Firefox, native Edge) and which are **unallowed**.
- Which **web destinations** are restricted (the sensitive service domain group: personal cloud +
  unsanctioned SaaS).
- What makes an upload **sensitive** (sensitivity labels and/or sensitive information types as the DLP
  condition).
- The **action per activity/destination**: Audit, Warn (block with override + business justification),
  or Block.
- The **policy mode**: simulation/test first, enforce after validation.

## Limitations (be honest with buyers)
- **Endpoint DLP is licensing-gated.** Browser & network DLP capabilities require the appropriate plan
  (**Microsoft 365 E5**, the **E5 Compliance** add-on, or **E5 Information Protection & Governance**) —
  **verify availability against your own tenant and plan.** Some settings are in preview.
- **Coverage depends on the extension and onboarding.** Chrome and Firefox require the **Microsoft
  Purview browser extension**; Edge uses native integration. A device that isn't **onboarded**, or a
  browser without coverage, is why the **unallowed browsers** control exists — it is a steering control,
  not a guarantee against a determined user on unmanaged equipment.
- **The portal is evolving.** Microsoft is actively changing the Purview portal and Endpoint DLP
  settings surfaces. Portal paths (e.g. *Data Loss Prevention → Endpoint DLP settings → Browser and
  domain restrictions to sensitive data*) are cited as of authoring and flagged **"verify in your
  tenant"** — never invented.
- **Some Endpoint DLP settings are portal-managed.** The **sensitive service domain groups**, the
  **unallowed browsers** list, and extension deployment are configured in the **portal / management
  tooling**; the provided scripts assess readiness, author and validate the **DLP policy** (which *does*
  have a supported PowerShell surface), and report activity — they do not invent cmdlets for settings
  Microsoft manages in the portal.
- **Determinations are deferred.** Which data is sensitive enough to restrict, which destinations are
  "unsanctioned," and any regulatory/records/legal obligation are decided by the organization's
  compliance, security, privacy, and legal functions — this solution provides the technical method and
  evidence, not the determination.

## Naming convention (used in every doc and script)
Artifacts follow `<Purpose> – Purview – <Stage>` and are reused verbatim across docs, scripts, and the
portal.

| Artifact | Name |
|---|---|
| Readiness / egress assessment export | `Browser & Network DLP – Egress – Assess` |
| Sensitive service domain group | `Unsanctioned & Personal Cloud – Domain Group` |
| DLP policy (Devices) | `Browser & Network DLP – Devices – Pilot` |
| DLP rule (upload restriction) | `Restrict Upload to Unsanctioned Domains – Rule` |
| Validation snapshot | `Browser & Network DLP – Endpoint – Validation` |
| Egress activity report | `Browser & Network DLP – Egress – Report` |
| Device / extension health map | `Browser & Network DLP – Device Health – Map` |
| Pilot ring | `Browser & Network DLP Pilot Ring – Stage1` |

## The standard deployment model
> Assess the tenant → design the in-scope data, destinations, and action ladder → configure onboarding,
> extension, domain group, and the policy in simulation → pilot on a ring and tune → validate every gate
> → expand to enforce. Pattern: **Assess → Design → Configure → Pilot (simulate) → Validate → Expand
> (enforce).**
