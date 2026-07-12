# 5. Testing & Validation — Migrate & Protect Applications with Entra

Validate on the **pilot** (`ENTAPPMIG-Pilot`) first, **while AD FS stays live**. Each test has a
**pass/fail** signal. Do not cut over or expand until all gates pass. Reference scripts are named in each
row.

## Test matrix

| # | Gate | What you do | Pass signal | Fail signal |
|---|------|-------------|-------------|-------------|
| 1 | **G1 AD FS app on Entra** | A pilot user signs into `ENTAPPMIG – App – LOBSaml – Pilot` via Entra (test SSO / My Apps) | Sign-in succeeds through **Entra** with the app functioning | Sign-in fails / app errors |
| 2 | **G1 Claims parity** | Inspect the SAML/OIDC token the app receives | Required claims (NameID + attributes) match the AD FS values | Missing/wrong claims; app rejects the user |
| 3 | **G2 Published app, no VPN** | With the **VPN disconnected**, browse the external URL of `ENTAPPMIG – AppProxy – Intranet – Pilot` | Entra pre-auth, then the app loads over App Proxy | App unreachable / still needs VPN |
| 4 | **G2 Pre-auth enforced** | Try the external URL unauthenticated | Redirected to Entra sign-in before the app is reached | App served without authentication |
| 5 | **G3 SCIM provision** | **Provision on demand** a pilot user for `ENTAPPMIG – App – ScimSaaS – Pilot` | User is **created/updated** in the SaaS app | Provision fails / no change in the app |
| 6 | **G3 SCIM deprovision** | Remove a pilot user from scope and re-provision | User is **disabled/deprovisioned** in the app | User remains active in the app |
| 7 | **G4 Conditional Access** | Access a migrated app under `ENTAPPMIG – CA – MigratedApps – Pilot` | **MFA / compliant device** enforced as configured | Access granted without the required control |
| 8 | **G4 Least privilege** | Sign in as a user **not** in `ENTAPPMIG-Pilot` | Access denied (not assigned) | Non-assigned user reaches the app |

## Automated checks
- **`ENTAPPMIG-Discovery.ps1`** — inventories AD FS relying parties (from an AD FS server where reachable),
  the AD FS application activity report, Entra enterprise apps, and App Proxy connector groups, so you can
  confirm the named objects exist and track migration progress.
- **`ENTAPPMIG-Validate.ps1`** — checks each **named** object from §3 is present and correctly wired (the
  migrated app has SSO config + `ENTAPPMIG-Pilot` assigned; the App Proxy app has pre-auth = Entra and a
  connector group; the SCIM app has provisioning enabled + scoped; the CA policy targets the apps and
  excludes break-glass) and **flags gaps** — the automated form of the gate table.
- **`ENTAPPMIG-Provisioning.ps1`** — reports SCIM **provisioning status** and recent sync results, and can
  **preview** an on-demand provision (gated `-WhatIf` / `-Commit`).
- **`ENTAPPMIG-Report.ps1`** — exports **sign-in evidence** for the migrated apps (Graph sign-in logs, and
  optional **KQL** against Log Analytics): who signed in, via which app, and the CA result — the cutover
  and audit artifact.
- **`ENTAPPMIG-Cutover.ps1`** — pre-cutover readiness summary (app config, assignments, CA coverage) with a
  **preview-only** default so you never flip a live app by accident.

## Reference KQL (sign-in logs for migrated apps)
Run in **Log Analytics** (or via `ENTAPPMIG-Report.ps1`). Field names may differ by tenant — verify schema.

```kql
// Sign-ins to the migrated apps, last 24h, with CA result
SigninLogs
| where TimeGenerated > ago(24h)
| where AppDisplayName startswith "ENTAPPMIG"
| summarize Signins = count() by AppDisplayName, UserPrincipalName, ResultType, ConditionalAccessStatus
| order by Signins desc
```

## Evidence to capture (for cutover / audit)
- Screenshot: pilot user signed into the migrated AD FS app **via Entra** (My Apps), with the token claims.
- Screenshot: the published app loading **with VPN off** after Entra pre-auth.
- Provisioning **on-demand** result showing a user created/updated (and later deprovisioned).
- CA **Insights / report-only** results before enforcement, and enforcement confirmed after.
- `ENTAPPMIG-Report.ps1` export of sign-ins per app with CA status.

## Exit criteria (before Cutover / Expand)
- [ ] G1 — the migrated app authenticates **via Entra** with correct claims (AD FS still live)
- [ ] G2 — the published app loads **without VPN** and enforces Entra pre-auth
- [ ] G3 — SCIM **provisions and deprovisions** a pilot user
- [ ] G4 — Conditional Access enforces MFA/compliant device on the migrated apps
- [ ] `ENTAPPMIG-Validate.ps1` shows no gaps for the pilot objects
- [ ] `ENTAPPMIG-Report.ps1` produces clean sign-in evidence per app
