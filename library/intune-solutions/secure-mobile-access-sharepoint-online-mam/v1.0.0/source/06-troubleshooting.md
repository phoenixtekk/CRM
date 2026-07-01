# 6. Troubleshooting Guide — Secure Mobile Access to SharePoint Online under MAM

Use `SPMAM-Discovery.ps1` for the policy inventory, `SPMAM-Validation.ps1` for a specific user,
`SPMAM-Report.ps1` for coverage, and `SPMAM-Remediation.ps1` (defaults to `-WhatIf`) for safe fixes.
The **Sign-in logs** in Entra (**Monitoring → Sign-in logs**, open a sign-in → **Conditional Access**
/ **Report-only** tab) are your primary evidence for any block.

## Root-cause diagnostic tree — "can't reach the SharePoint Online intranet on mobile"
Work top-down; stop at the first branch that matches.

```
START: user reports the SharePoint Online intranet won't load on mobile
│
├─ Q1. Is the resource SharePoint Online (*.sharepoint.com), or a private/on-prem web app?
│     • Private/on-prem  → ROUTING gap → see section D. A private resource needs Microsoft
│                          Tunnel for MAM (separate solution). STOP.
│     • SharePoint Online → continue.
│
├─ Q2. Which app is the user opening the site in?
│     • Unmanaged Safari / unmanaged Chrome → WRONG ACCESS PATH → see section B. STOP.
│     • SharePoint mobile app or MAM-protected Edge → continue.
│
├─ Q3. Does the block cite a Conditional Access / organization policy? (Sign-in logs)
│     • Yes (approved app / app protection required) → CA BLOCK → go to Q4.
│     • No; sign-in loops / token error → see section E. STOP.
│
├─ Q4. Is an App Protection Policy actually applied to this user for this app?
│     • No APP assigned → MISSING APP GRANT → see section A. STOP.
│     • APP assigned → continue.
│
├─ Q5. Is the CA grant scoped correctly (Office 365, iOS/Android, app-protection grant)?
│     • Misconfigured → CA MISCONFIG → see section C. STOP.
│     • Correct → continue.
│
└─ Q6. Sign-in / token issue (MFA loop, stale token, app not on the work account)?
      • Yes → TOKEN/SIGN-IN → see section E. STOP.
      • No, and Q1–Q5 clean → escalate with the Sign-in log correlation ID → see section G.
```

## A. Missing app-protection grant (CA requires APP, user has none)
| Symptom | Cause | Remediation |
|---|---|---|
| Every mobile sign-in blocked; log shows the app-protection grant **failed** | No App Protection Policy is assigned to the user for the SharePoint/Edge app | Assign `SPO Mobile – App Protection – iOS/Android` to the user's group (Implementation Steps 2–3); run `SPMAM-Validation.ps1`; if the assignment is inconsistent run `SPMAM-Remediation.ps1` |

## B. Wrong access path (blocked in an unmanaged browser)
- CA blocking unmanaged Safari/Chrome is **expected** — those browsers cannot satisfy the
  approved-app / app-protection grant. Do **not** weaken CA.
- Steer the user to the **SharePoint mobile app** or **Microsoft Edge signed in with the work
  account** (Implementation Step 6). Consider deploying a bookmark/deep link that opens the app or
  Edge, and send the one-line "use the SharePoint app or Edge" message.

## C. Conditional Access misconfigured
| Symptom | Cause | Remediation |
|---|---|---|
| Supported app still blocked | CA not targeting **Office 365** / SharePoint Online, or wrong grant | Set **Target resources → Office 365**; set the grant to `Require app protection policy` + `Require approved client app`; run `SPMAM-Discovery.ps1` |
| Policy doesn't apply on mobile | **Device platforms** condition excludes iOS/Android | Set **Conditions → Device platforms → iOS and Android** |
| Admins locked out during rollout | Break-glass accounts not excluded | Exclude the two break-glass accounts from the CA policy (Implementation Step 1) |

## D. Routing — is this really SharePoint Online?
- SharePoint **Online** (`*.sharepoint.com`) is cloud-reachable and needs **no** Microsoft Tunnel;
  if it won't load on the supported path, the cause is APP/CA/token (sections A/C/E), not routing.
- If the "intranet" is actually an **on-premises / private** web app, it needs **Microsoft Tunnel
  for MAM** (separate solution) — a per-app VPN for approved mobile apps. Confirm reachability off
  the corporate network to tell the two apart.

## E. Sign-in / token issues
- MFA nag loop, stale token, or the app is signed into the wrong (personal) account: sign out and
  back in with the **work account** in the managed app, complete MFA, and if needed clear the app's
  data and re-sign-in. Confirm the account is the work account, not a personal Microsoft account.

## F. Diagnostics quick reference
- Entra → **Monitoring → Sign-in logs** → open the failing mobile sign-in → **Conditional Access** /
  **Report-only** tab: which policy applied and which grant failed.
- Intune → **Apps → Monitor → App protection status**: whether the user's app is protected.
- Run `SPMAM-Discovery.ps1` (policy inventory), `SPMAM-Validation.ps1` (per user), and
  `SPMAM-Report.ps1` (coverage) to correlate.

## G. When to escalate
If the resource is SharePoint Online, the App Protection Policy is applied, the CA policy targets
Office 365 with the correct grant and platforms, the user is on a supported app signed into the work
account with MFA complete, and the intranet still won't load — capture the **correlation ID** from
the Sign-in log entry and open a Microsoft support case.
