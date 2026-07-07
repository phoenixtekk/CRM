# 3. Implementation Guide — Microsoft Teams Apps & Integration Governance

Follow these steps **in order**. Posture and inventory come from the **Teams admin center**
(`https://admin.teams.microsoft.com`), the **MicrosoftTeams PowerShell module**, and **Microsoft
Graph**; every policy change is run with `-WhatIf` first. Artifact names follow the
`<Purpose> – <Scope> – <Stage>` convention from the Overview and are reused verbatim.

> **Model:** Read the current app posture and consent grants, design the allow/block + policy set,
> configure it, assign to a **pilot** group first, validate that vetted apps work and risky ones are
> blocked, then expand org-wide and stand up the recurring review.
> Pattern: **Assess → Design → Configure → Pilot → Validate → Expand.**
>
> **Government cloud:** substitute `admin.teams.microsoft.us` and the `*.office365.us` endpoints, and
> **verify app availability in your tenant** — store-app sets differ.

## Step 1 — Read the current app posture (Assess)
1. Teams admin center → `Teams apps → Manage apps`. Note the counts of Allowed vs Blocked apps and the org-wide app settings (are third-party apps and custom apps allowed?).
2. Review `Teams apps → Permission policies` and `Setup policies` — note the **Global (Org-wide default)** instances and any existing custom policies.
3. Run `TEAMSAPPS-Discovery.ps1` to capture the authoritative baseline via the MicrosoftTeams module and Graph: all permission/setup policies, the full app catalog with each app's **distribution method** (`store` / `organization` / `sideloaded`), and per-team installed apps. It flags sideloaded and organization-published (LOB) apps for review.

## Step 2 — Review consented Graph permissions (Assess)
1. Run `TEAMSAPPS-ConsentReport.ps1` to pull each app's service principal and its **delegated** (`oauth2PermissionGrants`) and **application** (`appRoleAssignments`) permissions from Entra, risk-flagged against the high-risk baseline (Requirement 2.6). It writes `Consent Review – Teams Apps – Report`.
2. In the Teams admin center, open a few flagged apps → the **Permissions** tab to corroborate the requested Microsoft Graph permissions shown for the app.
3. Hand the report to your security/app-governance stakeholders — the *appropriateness* decision is theirs (see Overview limitations).

## Step 3 — Triage into allow / block / needs-review (Design)
1. Using the discovery and consent outputs and the vetting criteria (Requirement 2.5), classify every in-use and requested app in `App Vetting Register – Apps – AllStages` into:
   - **Vetted** → goes on `App Allow List – Vetted – Prod`.
   - **Blocked** → goes on `App Block List – Blocked – Prod`.
   - **Needs-review** → unknown publisher or high-risk permissions; stays blocked until the workflow clears it.
2. Decide the class-level org-wide stance: are third-party apps allowed at all? Are custom (LOB) apps allowed, and who may upload them?

## Step 4 — Set org-wide app settings and allow/block (Configure)
1. Teams admin center → `Teams apps → Manage apps → Org-wide app settings`. Set the baseline `Org-wide App Settings – Tenant – Prod`:
   - **Third-party apps** — on or off per your Step 3 decision.
   - **Custom apps** (upload/sideload) — on only if you permit LOB uploads; otherwise off.
   - **Microsoft apps** — typically allowed.
2. On the Manage apps page, **Allow** the apps on `App Allow List – Vetted – Prod` and **Block** the apps on `App Block List – Blocked – Prod`.
   > These Org-wide-app-settings and per-app allow/block toggles are **admin-center-driven**; PowerShell/Graph parity for these specific toggles is partial and version-dependent — **verify the exact cmdlet/endpoint in your tenant** before scripting them. The scripts below drive the fully-scriptable **policies**; use the portal for these class/allow-block toggles unless you have confirmed cmdlet support.

## Step 5 — Build the app permission and setup policies (Configure)
1. Run `TEAMSAPPS-Configure.ps1 -WhatIf` to preview creating the policies (default is dry-run — no changes):
   - `App Permission Policy – Pilot – Pilot` — allows only the vetted app list for each class (Microsoft / third-party / custom), all others blocked.
   - `App Setup Policy – Standard – Prod` — pins the approved core apps in the app bar and sets whether users may pin their own apps.
   - (Optional) `App Setup Policy – Frontline – Prod` — a tighter pinned set for frontline/shared-device users.
2. Review the previewed policy bodies. Re-run with `-Commit` to create them:
   `TEAMSAPPS-Configure.ps1 -Commit`. Under the hood this uses `New-/Set-CsTeamsAppPermissionPolicy` and `New-/Set-CsTeamsAppSetupPolicy`.

## Step 6 — Assign policies to the pilot group (Pilot)
1. Run `TEAMSAPPS-Set-ScopeTargeting.ps1 -WhatIf -PolicyGroup "App Governance Pilot – Users – Pilot"` to preview assigning `App Permission Policy – Pilot – Pilot` and `App Setup Policy – Standard – Prod` to the pilot members (default dry-run, no changes).
2. Re-run with `-Commit` to apply: it calls `Grant-CsTeamsAppPermissionPolicy` and `Grant-CsTeamsAppSetupPolicy` per pilot user. **Do not** touch the Global policy yet.

## Step 7 — Validate the pilot (Validate)
1. Run `TEAMSAPPS-Validation.ps1 -PolicyGroup "App Governance Pilot – Users – Pilot"` — it confirms each pilot user is assigned the intended policies and that the policies allow only the vetted list.
2. As a pilot user, confirm in the Teams client: a **vetted** app installs, a **blocked** app is not available, and the pinned apps appear as configured.
3. Complete the **Testing Guide** and clear the pass/fail gate before expanding.

## Step 8 — Expand org-wide (Expand)
1. Once the pilot passes the gate, promote the settings to the **Global** policies: run `TEAMSAPPS-Configure.ps1 -WhatIf` targeting the Global permission and setup policy, review, then `-Commit`. This makes `App Permission Policy – Standard – Prod` the effective org-wide default (or updates the Global instance in place).
2. Assign any population-specific policies (e.g. `App Setup Policy – Frontline – Prod`) to their groups with `TEAMSAPPS-Set-ScopeTargeting.ps1 -Commit`.
3. Communicate the change; keep a **rollback** ready (Step 9).

## Step 9 — Rollback path (documented, always ready)
1. To revert a user population, re-assign the **Global (Org-wide default)** permission and setup policies with `Grant-CsTeamsAppPermissionPolicy -Global`-equivalent via `TEAMSAPPS-Set-ScopeTargeting.ps1` (it supports resetting a group back to Global), or re-Allow a blocked app on the Manage apps page.
2. Because the pilot proved the settings on a tolerant group first, a full-population rollback is rarely needed — but the path is: reset assignment → re-allow the specific app → re-review.

## Step 10 — Stand up the recurring review (Expand)
1. Schedule the read-only chain monthly: `TEAMSAPPS-Discovery.ps1` → `TEAMSAPPS-ConsentReport.ps1` → `TEAMSAPPS-Validation.ps1`. Each run refreshes the catalog, new sideloaded/LOB apps, and new consent grants.
2. Route any new or changed app through `App Vetting Register – Apps – AllStages`; update the allow/block lists and re-run `TEAMSAPPS-Configure.ps1` when the vetted set changes — keeping the collaboration supply chain governed as the catalog evolves.

---
### Order of operations
`Read posture → Review consent → Triage (allow/block/review) → Org-wide settings + allow/block → Build policies (-WhatIf → -Commit) → Assign to pilot → Validate → Expand to Global → Rollback ready → Recurring review`
