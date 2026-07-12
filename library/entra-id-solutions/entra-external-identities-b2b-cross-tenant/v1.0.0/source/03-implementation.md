# 3. Implementation Guide — Entra External Identities (B2B) & Cross-Tenant Access

Follow these steps in order, in the **Microsoft Entra admin center** (`https://entra.microsoft.com`),
mostly under **`External Identities`** and **`Protection -> Conditional Access`**. Configure one
partner and a small guest scope first; expand only after the Testing Guide passes.

> Model: set conservative defaults, trust one named partner deliberately, bring guests in through a
> governed access package, enforce a guest-scoped Conditional Access policy (report-only first), and
> recertify with an access review — validated on a pilot before the tenant. Break-glass accounts stay
> excluded from the guest policy throughout.
>
> Naming convention: every object uses `<Purpose> – <Scope> – <Stage>`. The pilot objects are:
> `B2B Pilot – Guest Scope – Pilot` (group), `Partner Approvers – B2B – Pilot` (group),
> `Connected Org – Contoso – Pilot` (connected organization), `External Collaboration Catalog – Partners – Pilot`
> (catalog), `Partner Access – Project X – Pilot` (access package), `Require MFA – Guest Users – Pilot`
> (Conditional Access policy), and `Access Review – Guests – Pilot` (access review). Reuse these exact
> names in testing, troubleshooting, and the scripts. Replace `Contoso` / `Project X` with your real
> partner and project.

## Step 1 — Assess the current baseline
1. Run `ENTB2B-Discovery.ps1` to record the current default cross-tenant access settings, existing organizational settings, guest count, guest-scoped Conditional Access policies, and any access packages/reviews already present. Keep the output as your before-state.
2. Entra -> `External Identities -> Cross-tenant access settings -> Default settings`; note the current inbound and outbound B2B collaboration, direct connect, and trust settings before you change anything.
3. Entra -> `Users`, filter `User type = Guest`; run `ENTB2B-Report.ps1` for a guest-lifecycle snapshot (never signed in, inactive, no sponsor). This is your cleanup candidate list for later.

## Step 2 — Set conservative default cross-tenant access settings
1. Entra -> `External Identities -> Cross-tenant access settings -> Default settings -> Edit inbound defaults`.
2. **B2B collaboration**: allow inbound (so you can still invite guests) but keep it scoped to what you need; **B2B direct connect**: leave inbound **blocked** by default (enable only per-partner if you use Teams shared channels). **Trust settings**: do **not** trust MFA/device claims from unknown tenants by default.
3. `Edit outbound defaults` similarly — allow your users to be invited to partners you approve; block direct connect by default. Save.

> Why conservative defaults: the default policy applies to every tenant you have not explicitly named.
> Locking it down means new/unknown partners get the safe posture and you relax settings only for
> partners you vet in Step 3.

## Step 3 — Add the pilot partner as an organizational setting (trusted deliberately)
1. Entra -> `Cross-tenant access settings -> Organizational settings -> Add organization`; enter the partner tenant domain (for example `contoso.com`). Add.
2. Open the new organization entry -> **Inbound access**. Configure **B2B collaboration** to allow the partner's users (all, or a specific group/app). If you use Teams shared channels with this partner, enable **B2B direct connect** here (only here, not in the default).
3. Open **Trust settings** for this organization and, if the partner is vetted, enable **Trust multi-factor authentication from Microsoft Entra tenants**, **Trust compliant devices**, and/or **Trust hybrid Azure AD joined devices** so their guests satisfy your MFA/device Conditional Access without re-registering.
4. Optionally run `ENTB2B-Set-CrossTenantAccess.ps1 -PartnerTenantId <id> -WhatIf` to preview creating/adjusting this organizational configuration via Graph; re-run without `-WhatIf` once the preview is correct.

## Step 4 — Set guest onboarding controls
1. Entra -> `External Identities -> External collaboration settings`.
2. **Guest invite settings**: choose who can invite (recommended: `Member users and users assigned to specific admin roles can invite`, or restrict to the `Guest Inviter` role). **Guest user access**: restrict guest directory access to the most limited option appropriate for you.
3. **Collaboration restrictions**: optionally allow/deny invitations to specific domains (allow-list the partner domains you approve). Save.
4. (Optional) If you want external users to self-serve, Entra -> `External Identities -> User flows -> New user flow`; create a self-service sign-up flow and attach the identity providers and attributes you allow. Keep this out of the first pilot unless self-service is a pilot requirement.

## Step 5 — Build the pilot scope and approver groups
1. Entra -> `Groups -> New group -> Security`; create `B2B Pilot – Guest Scope – Pilot` (internal users collaborating with the partner). Create.
2. Create `Partner Approvers – B2B – Pilot` with at least two members (they approve the access package and can act as review sponsors). Create.

## Step 6 — Create the entitlement-management catalog, connected org, and access package
1. Entra -> `Identity governance -> Entitlement management -> Catalogs -> New catalog`; name it `External Collaboration Catalog – Partners – Pilot`; set **Enabled for external users = Yes**. Create. Open it -> `Resources -> Add resources` and add the app(s)/group(s) the guest needs.
2. Entra -> `Identity governance -> Entitlement management -> Connected organizations -> Add connected organization`; name it `Connected Org – Contoso – Pilot` and add the partner directory/domain. Add. (This lets you scope "who can request" to the partner org.)
3. In the catalog -> `Access packages -> New access package`; name it `Partner Access – Project X – Pilot`.
   - **Resource roles**: add the app/group role the package grants.
   - **Requests**: For users **not** in your directory -> choose `Specific connected organizations` -> `Connected Org – Contoso – Pilot`. Require approval; set the approver to `Partner Approvers – B2B – Pilot`.
   - **Lifecycle**: set an expiry (for example 90 days) and/or require an access review of assignments. Create.

> This is the governed onboarding path: the partner's users request `Partner Access – Project X – Pilot`,
> an approver approves, they become a guest with exactly the package's access, and the grant expires.
> Full entitlement-management design lives in the `ENTIGA` solution.

## Step 7 — Create the guest-scoped Conditional Access policy (report-only)
1. Entra -> `Protection -> Conditional Access -> Create new policy`; name it `Require MFA – Guest Users – Pilot`.
2. **Users**: Include `Guest or external users` -> select the external user types you want (for example `B2B collaboration guest users`); **Exclude** the two break-glass accounts (and any service accounts that must not be caught).
3. **Target resources**: All cloud apps (or scope to the pilot app first).
4. **Grant**: Require multi-factor authentication (optionally also Require compliant device where you trust the partner's device claims).
5. **Enable policy = Report-only**. Create.
6. Let it run and review `Insights and reporting` / sign-in logs. When impact is understood and only intended external sign-ins are affected, set **Enable policy = On**.

> Report-only first is non-negotiable: it shows exactly who the policy would affect before it can block
> anyone. The Conditional Access baseline itself (personas, named locations, full policy set) is the
> `ENTZTCA` solution — this adds one guest policy on top of it.

## Step 8 — Create the guest access review
1. Entra -> `Identity governance -> Access reviews -> New access review`.
2. **Review type**: `Teams + Groups` or `Applications` — select the group/app the pilot guests have access to (or review the access package's assignments). Name it `Access Review – Guests – Pilot`.
3. **Scope**: `Guest users only`. **Reviewers**: the resource owner or `Partner Approvers – B2B – Pilot` as sponsor (or self-review). **Recurrence**: quarterly. **Settings**: enable `Auto apply results`; set `If reviewers don't respond` to `Take recommendations` (safer than immediate Remove for the first cycle). Create.

## Step 9 — Validate on the pilot scope
1. Have the pilot partner contact request `Partner Access – Project X – Pilot`; confirm an approver in `Partner Approvers – B2B – Pilot` approves and the guest is created with the package's access and an expiry.
2. Sign in as the pilot guest and confirm the `Require MFA – Guest Users – Pilot` policy behaves as expected (report-only shows a would-be MFA requirement; once enforced, MFA is required). Confirm break-glass accounts are unaffected.
3. Run `ENTB2B-Validate.ps1` to confirm the default settings are conservative, the partner org is configured, the guest CA policy exists and excludes break-glass, and the access package/review are in place. Complete the Testing Guide.

## Step 10 — Cleanup stale guests (safe)
1. From Step 1 / `ENTB2B-Report.ps1`, identify guests who never signed in or are long inactive and have no current package or sponsor.
2. Run `ENTB2B-CleanupStaleGuests.ps1 -WhatIf` to preview disabling (then, on a later pass, removing) those guests. Review the preview, then re-run without `-WhatIf` once confirmed. Never include break-glass or internal accounts.

## Step 11 — Enforce and expand to production
1. Switch `Require MFA – Guest Users – Pilot` from report-only to **On** once impact is confirmed.
2. Add more partners as organizational settings (Step 3), each vetted before trusting MFA/device claims; publish more access packages per partner/project.
3. Extend the access review to all guests (or per catalog); tighten `If reviewers don't respond` to `Remove access` once reviewers are reliable.
4. (Optional) Configure cross-tenant synchronization with a partner to auto-provision guests, only after the invitation-based model is proven (see requirement 2.9, *verify*).
5. Re-validate each cycle with `ENTB2B-Validate.ps1` and `ENTB2B-Report.ps1`.

---
### Order of operations
`Assess (Discovery/Report) -> Conservative defaults -> Add partner org + trust -> Guest onboarding controls -> Scope/approver groups -> Catalog + connected org + access package -> Guest CA policy (report-only) -> Guest access review -> Validate -> Cleanup stale guests -> Enforce + expand`
