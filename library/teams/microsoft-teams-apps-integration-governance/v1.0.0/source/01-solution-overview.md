# 1. Solution Overview — Microsoft Teams Apps & Integration Governance

## What this solution is
Every app, bot, tab, connector, and message extension added to Microsoft Teams becomes part of your
collaboration surface — and many of them request access to chat, channel, file, and directory data
through Microsoft Graph. Left ungoverned, the Teams app catalog is an unmanaged software supply chain:
any user can install almost anything, custom line-of-business (LOB) apps get sideloaded with no review,
and third-party apps accumulate broad consented permissions nobody is watching. This solution is a
repeatable way to **govern which apps run in Teams and what they can reach** — using the **Teams admin
center** (`https://admin.teams.microsoft.com`), the **MicrosoftTeams PowerShell module**, and
**Microsoft Graph**, with no third-party tooling.

It puts five controls in place and keeps them in place: **app permission policies** (which apps a user
may install), **app setup policies** (which apps are installed and pinned for them), **org-wide
allow/block** on the Manage apps page, **custom/LOB and third-party app management** (who can upload,
what is published to the tenant catalog), and **admin-consent / Graph-permission review** for the
permissions apps actually hold — all fed by an **app-vetting workflow** so new apps are approved before
they are available.

## Why this matters
- App governance is off by default in the permissive direction: in many tenants users can install most store apps and even upload custom apps until you deliberately scope it down.
- The risk isn't the app UI — it's the **permissions**. A message-extension or bot that has been granted `Files.Read.All`, `Mail.Read`, or `Chat.Read.All` can egress collaboration data far beyond the channel it lives in.
- Custom/LOB apps are sideloaded straight into Teams; without an upload policy and a vetting gate, unreviewed internal apps ship with whatever permissions their developer requested.
- One-time cleanups regress. New apps appear in the store, users request new integrations, and developers publish new LOB versions every month — the value is in the **standing policy set plus a recurring review**, not a single sweep.

## How it works
1. The current posture is read: app permission policies (`Get-CsTeamsAppPermissionPolicy`), app setup policies (`Get-CsTeamsAppSetupPolicy`), the org-wide app settings, and the full app catalog with each app's **distribution method** — `store` (third-party), `organization` (tenant-published LOB), or `sideloaded` (uploaded) — read from Microsoft Graph (`/appCatalogs/teamsApps`).
2. Installed apps are inventoried per team and per user (Graph `installedApps`) so you can see what is actually deployed, not just what is allowed.
3. The consented **Graph permissions** each app holds are pulled from Entra — delegated grants (`oauth2PermissionGrants`) and application permissions (`appRoleAssignments`) on each app's service principal — and **risk-flagged** against a high-impact scope list (mail, files, directory, full-access).
4. Apps are triaged into **vetted** (approved, allowed), **blocked** (disallowed org-wide), and **needs-review** (unknown publisher or risky permissions) through the vetting workflow.
5. **App permission policies** are configured to allow only vetted apps for a given user population; **app setup policies** define what is installed and pinned; **org-wide settings** allow/block third-party and custom apps and set who can upload LOB apps.
6. Everything is validated on a **pilot** user group first, then expanded org-wide, and re-reviewed on a recurring cadence as the catalog and consent grants change.

## The five governance controls
- **App permission policies** — control which apps a user is *allowed to install* (all apps, only specific allowed apps, all-except-blocked, or none), by class: Microsoft apps, third-party apps, custom apps.
- **App setup policies** — control which apps are *installed and pinned* for a user, the app bar order, and whether users may pin apps themselves.
- **Org-wide allow/block** — on the Manage apps page, allow or block an individual app tenant-wide; org-wide app settings toggle whole classes (third-party apps on/off, custom apps on/off).
- **Custom/LOB & third-party management** — who may upload custom apps, and what is published to the org (tenant) app catalog for internal distribution.
- **Consent & Graph-permission review** — the delegated and application permissions each app's service principal holds in Entra, reviewed and risk-flagged.

## What you can control
- Which apps are on the vetted allow list and which are blocked org-wide.
- Whether third-party apps and custom (LOB) apps are permitted at all, and for whom.
- Who may upload/sideload custom apps (org-wide setting and per-policy).
- What is pinned into the app bar for each user population, and whether users can pin their own apps.
- The pilot population that receives the tightened policies first, before any org-wide change.
- The cadence of the recurring app + consent review.

## Limitations (be honest with buyers)
- Some Manage apps actions (individual-app allow/block, org-wide app settings toggles, and the custom-app upload setting) are **admin-center-driven**; PowerShell/Graph parity for those specific toggles is partial and **version-dependent — verify the exact cmdlet/endpoint in your tenant** before scripting them. Policy creation, assignment, and pinning are fully scriptable via the MicrosoftTeams module.
- Microsoft has signalled that **app permission policies are converging with the org-wide/per-app availability model** on the Manage apps page; the exact management surface is evolving — this solution uses both and flags where behavior is transitioning, so **verify current behavior in your tenant**.
- Blocking or removing an app that a team actively uses is **high-impact** — a pinned workflow can disappear for users. Pilot first and communicate.
- **Government clouds (GCC/GCC High/DoD)** differ in available store apps, portal URLs (e.g. `*.office365.us` / `admin.teams.microsoft.us`), and third-party app availability — **verify in your tenant**; this guide uses the commercial paths as the default.
- Whether a specific consented permission is *appropriate* is a **security/compliance determination**; this solution surfaces and risk-flags the permissions and provides the method — the approval decision belongs to your security and app-governance stakeholders.

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim
across the docs, scripts, and admin center. The standard set:

| Artifact | Name |
|---|---|
| App permission policy (production standard) | `App Permission Policy – Standard – Prod` |
| App permission policy (pilot) | `App Permission Policy – Pilot – Pilot` |
| App setup policy (production standard) | `App Setup Policy – Standard – Prod` |
| App setup policy (frontline) | `App Setup Policy – Frontline – Prod` |
| Org-wide app settings baseline | `Org-wide App Settings – Tenant – Prod` |
| Vetted allow list | `App Allow List – Vetted – Prod` |
| Org-wide block list | `App Block List – Blocked – Prod` |
| App vetting register / workflow | `App Vetting Register – Apps – AllStages` |
| Pilot policy target group | `App Governance Pilot – Users – Pilot` |
| Consent / permission review report | `Consent Review – Teams Apps – Report` |

## The standard deployment model
> Read the current app posture and consent grants → design the allow/block + policy set → configure
> policies and org-wide settings → assign to a **pilot** group first → validate that vetted apps work
> and risky ones are blocked → expand org-wide and stand up the recurring review.
> Pattern: **Assess → Design → Configure → Pilot → Validate → Expand.**
