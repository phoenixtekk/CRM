# 2. Requirements Guide — Container Labeling (Teams, Groups & Sites)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (the six
shared requirements: compliance licensing, least-privilege Purview roles, the S&C PowerShell + Graph
toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders, and a pilot scope with
change control) — those are referenced here, not repeated.

## 2.1 Sensitivity-label licensing, plus Entra ID P1 for device/sharing controls
**Description:** A tenant licensed for **sensitivity labels** (Microsoft 365 E3 includes manual
labeling; container labeling works on this baseline for privacy/guest/external-sharing), **plus
Microsoft Entra ID P1** for the **unmanaged-device access** control (limited/blocked access via
Conditional Access) and SharePoint site-level Conditional Access. (Global Requirement 1.)
**Why:** The privacy, guest, and external-sharing container settings work on the labeling baseline; the
**unmanaged-device Conditional Access** settings are gated on Entra ID P1 + SharePoint.
**Verify:** M365 admin center → `Billing → Licenses` shows the label + Entra ID P1 SKUs;
`IPCONT-Check-Prereqs.ps1` reports the label and P1 signals. Confirm the container-label scope appears in
the Purview portal.
**Implement:** Assign/purchase Entra ID P1 (or a plan that includes it) before configuring the
unmanaged-device access settings. Where P1 is unavailable, scope the labels to privacy/guest/external
sharing only and record the device-access control as deferred. **Verify against your own plan.**

## 2.2 Least-privilege roles across Purview, Entra, and SharePoint
**Description:** **Information Protection Admin** (or **Compliance Administrator**) to author and publish
container labels; a **Global Administrator** or **Groups Administrator** for the one-time
`EnableMIPLabels` directory setting; a **SharePoint Administrator** for the SharePoint tenant/site
external-sharing and Conditional Access baseline. (Global Requirement 2 — least privilege.)
**Why:** Container labeling spans three surfaces — the label (Purview), the group directory setting
(Entra), and the site sharing/CA behavior (SharePoint) — each with its own least-privilege role.
**Verify:** Purview portal → `Settings → Roles & scopes → Permissions` shows Information Protection Admin;
Entra shows the Groups/Global Admin; SharePoint admin center access confirmed. `Connect-IPPSSession`
succeeds.
**Implement:** Assign the least-privilege role on each surface; reserve Global Administrator only for the
one-time enablement and Graph admin-consent steps.

## 2.3 Security & Compliance PowerShell, Graph, and SharePoint Online toolchain
**Description:** A workstation with **ExchangeOnlineManagement** (`Connect-IPPSSession`), the
**Microsoft Graph PowerShell SDK**, the **AIPService** module (provides `Execute-AzureAdLabelSync`), and
the **Microsoft.Online.SharePoint.PowerShell** module (`Connect-SPOService`), with a modern-auth/MFA
admin. (Global Requirement 3.)
**Why:** Labels are read via S&C PowerShell; container labeling is enabled and applied via Graph; the
label sync uses AIPService; site sharing/CA state is read/set via SharePoint Online Management Shell.
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement, Microsoft.Graph.Authentication,
AIPService, Microsoft.Online.SharePoint.PowerShell`; the connect cmdlets succeed.
`IPCONT-Check-Prereqs.ps1` reports which modules/connections are present.
**Implement:** `Install-Module ExchangeOnlineManagement, Microsoft.Graph, AIPService,
Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser`; confirm modern-auth sign-in.

## 2.4 Graph permission scopes (read-first; write only to apply)
**Description:** Delegated Graph scopes — **read** for discovery/validation/reporting
(`Group.Read.All`, `Directory.Read.All`, `Sites.Read.All`, `InformationProtectionPolicy.Read`), and
**write** only for the enablement/apply steps (`Directory.ReadWrite.All` for the `Group.Unified`
directory setting, `Group.ReadWrite.All` to set a group's `assignedLabels`).
**Why:** The safe-by-default scripts read state with read scopes; write scopes are consented only when
you enable container labeling or apply a label.
**Verify:** `IPCONT-Discover-Containers.ps1` (read-only) connects with read scopes and reports if consent
is missing; the apply script requests write scopes explicitly.
**Implement:** Consent read scopes at first `Connect-MgGraph`; a Global Administrator grants admin
consent for the write scopes once in Entra (`Identity → Applications → Enterprise applications`).

## 2.5 Container labeling **enabled** for the tenant (`EnableMIPLabels`)
**Description:** The Entra **`Group.Unified`** directory setting **`EnableMIPLabels = True`**, plus a
one-time **`Execute-AzureAdLabelSync`** so sensitivity labels are available to Groups/Teams/Sites.
**Why:** Until `EnableMIPLabels` is `True` and labels are synced, container-scoped labels **cannot be
applied** to Teams/Groups/Sites — this is the gate for everything else.
**Verify:** `IPCONT-Check-Prereqs.ps1` reads the `Group.Unified` setting and reports `EnableMIPLabels`;
in the Purview portal, the container-scope option is selectable on a label.
**Implement:** Run `IPCONT-Set-ContainerLabels.ps1 -EnablePrerequisites -Commit` (one-time; wraps the
`Group.Unified` setting update and `Execute-AzureAdLabelSync`). This is a **tenant-level change** — pilot
and change-control it. **Verify the exact method against current Microsoft guidance for your tenant** —
the directory-settings surface is evolving (legacy AzureADPreview vs Microsoft Graph).

## 2.6 Container-scoped sensitivity labels authored and published
**Description:** The container labels (`Container – General`, `Container – Confidential`,
`Container – Highly Confidential`) authored in the Purview portal with scope **Groups & sites** and their
privacy/guest/external-sharing/device settings, published via the **`Container Labels – Groups & Sites –
Policy`** label policy.
**Why:** A label must exist and be published to a user before that user can apply it to a container; the
policy is what surfaces the labels in Teams/SharePoint.
**Verify:** `Get-Label` lists the container labels; `Get-LabelPolicy` shows the policy;
`IPCONT-Check-Prereqs.ps1` confirms container-scoped labels are present. Confirm the labels appear when
creating a Team/site as a policy member.
**Implement:** Author the labels (Implementation Guide Step 3) and publish them to the pilot user group
first, then expand.

## 2.7 SharePoint external-sharing baseline compatible with the labels
**Description:** The SharePoint **tenant** external-sharing level (`Get-SPOTenant.SharingCapability`) must
be **at least as permissive** as the most permissive label setting you intend to use — a label cannot
grant sharing broader than the tenant allows.
**Why:** Container labels **tighten** sharing per site; they cannot loosen it beyond the tenant ceiling.
If the tenant is "Only people in your organization," a label's "New and existing guests" has no effect.
**Verify:** `IPCONT-Check-Prereqs.ps1` reports the tenant `SharingCapability` and
`ConditionalAccessPolicy`. Confirm it against the label taxonomy.
**Implement:** Adjust the SharePoint tenant sharing baseline (SharePoint admin, change-controlled) so the
label taxonomy is expressible; record the baseline in `Container Scope – Map`.

## 2.8 In-scope containers, data-classification intent, and stakeholders
**Description:** The **Teams/Groups/Sites in scope**, the **classification intent** that maps data
sensitivity to the three tiers, and engagement with **compliance, data-owner, privacy, security, and
legal** stakeholders (Global Requirements 4 & 5).
**Why:** Which container gets which label is a business/classification decision, and guest access has
privacy/legal implications — the determination is the stakeholders', the implementation is yours.
**Verify:** The in-scope container list and the tier mapping are agreed; named approvers recorded.
`IPCONT-Discover-Containers.ps1` produces the inventory to map against.
**Implement:** Capture the classification intent and tier mapping before applying labels.

## 2.9 A pilot ring and change control
**Description:** A **pilot ring** — `Container Labels – Pilot Ring – Stage1`: a small set of named
Teams/Groups/Sites **and** a pilot user group for the label policy — plus a **change-control** process
(Global Requirement 6).
**Why:** Guest-access, external-sharing, and device-access changes are high-impact; prove them on a ring
before the estate. Applying a "Block access from unmanaged devices" label to a busy site without piloting
will generate help-desk tickets.
**Verify:** The ring (containers + users) is defined and a change window/approval path exists.
**Implement:** Define the ring and agree change control before applying labels or enabling tenant-wide.

---
## Checklist
- [ ] Sensitivity-label licensing confirmed; Entra ID P1 available for device/sharing controls (or device control deferred)
- [ ] Information Protection Admin (Purview), Groups/Global Admin (Entra), SharePoint Admin assigned least-privilege
- [ ] ExchangeOnlineManagement + Graph SDK + AIPService + SharePoint Online Shell installed; connects succeed
- [ ] Graph read scopes consented; write scopes reserved for enable/apply
- [ ] `EnableMIPLabels = True` + `Execute-AzureAdLabelSync` done (or scheduled, pilot-first)
- [ ] Container labels authored (Groups & sites scope) and `Container Labels – Groups & Sites – Policy` published to pilot users
- [ ] SharePoint tenant `SharingCapability` compatible with the label taxonomy
- [ ] In-scope containers + tier mapping agreed; stakeholders named
- [ ] `Container Labels – Pilot Ring – Stage1` (containers + users) defined; change control agreed
