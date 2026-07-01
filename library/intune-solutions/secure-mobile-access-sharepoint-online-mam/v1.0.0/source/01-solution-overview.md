# 1. Solution Overview — Secure Mobile Access to SharePoint Online under MAM

## What this solves
Employees can open a SharePoint Online intranet on a laptop, but on their phones they get blocked,
bounced back to a sign-in loop, or the link opens in an app that refuses to load the page. Under a
Mobile Application Management (MAM) configuration this is almost never a SharePoint problem — it is
a misalignment between the App Protection Policy, the Conditional Access policy, and the access path
the user takes. This solution is the correct, repeatable way to deliver secure, reliable mobile
access to a SharePoint Online intranet under MAM, plus a diagnostic path to root-cause failures.

## The three things that must agree
Reliable mobile access to SharePoint Online under MAM depends on three layers agreeing. When they
disagree, users are blocked.

1. **App Protection Policies (APP / MAM) — data protection.** An App Protection Policy applies
   data-loss-prevention controls (encryption, copy/paste and save-as limits, an app PIN) to the
   Microsoft apps that touch corporate data — here the SharePoint mobile app and a MAM-protected
   browser (Microsoft Edge). MAM protects the data inside approved apps *without* requiring the
   device to be enrolled or company-owned; that is the whole point of MAM (as opposed to MDM).

2. **Conditional Access (CA) — the gate.** A Conditional Access policy decides who is allowed to
   reach SharePoint Online / Office 365 from mobile and under what conditions. Two grant controls
   matter here: `Require approved client app` (the app must be on Microsoft's approved-apps list)
   and `Require app protection policy` (the app must additionally have an App Protection Policy
   applied). The second is the stronger, recommended control; it is what ties CA to the App
   Protection layer.

3. **The access path — how the user actually opens the site.** On mobile there are two *supported*
   paths to SharePoint Online: the SharePoint mobile app, or the site opened in a MAM-protected
   browser (Microsoft Edge signed in with the work account). An *unsupported* path — the intranet
   opened in unmanaged Safari or unmanaged Chrome — is typically blocked by the Conditional Access
   grant, because those browsers cannot satisfy `Require approved client app` /
   `Require app protection policy`. The fix for "it's blocked in Safari" is not to weaken CA; it is
   to steer the user onto the supported path.

## Why the three must be aligned
- If CA requires an app-protection grant but no App Protection Policy is assigned to the user, every
  mobile sign-in is blocked — the grant can never be satisfied.
- If an App Protection Policy exists but CA does not require it, data protection is optional and
  inconsistently applied — a compliance gap, and unmanaged browsers may still load the site.
- If the policies are perfect but the user opens the intranet in unmanaged Safari, CA blocks them —
  and it looks like an outage when it is really a wrong-path problem.

## The routing decision — is Microsoft Tunnel for MAM required here?
"Can't reach the intranet" sometimes means the resource is not reachable from the internet at all —
a truly internal, on-premises web app behind the corporate firewall. Reaching *that* from a
MAM-protected app requires **Microsoft Tunnel for MAM**, which gives approved mobile apps a per-app
VPN into the private network (cross-reference: the Microsoft Tunnel for MAM solution).

But this solution is about SharePoint **Online**. SharePoint Online is a Microsoft 365 cloud service
reachable over the public internet at your `*.sharepoint.com` tenant — it does **not** require
Microsoft Tunnel. The decision is therefore explicit:

> **Decision:** Is the intranet SharePoint **Online** (`*.sharepoint.com`)? → No Tunnel needed;
> the fix is APP + CA + access path. Is the "intranet" actually an on-premises / private web app
> (even if branded as the intranet)? → That resource needs **Microsoft Tunnel for MAM** (separate
> solution). Confirm which one you are dealing with before you start — it changes the fix.

The diagnostic tree below includes a routing branch so you don't burn time on APP/CA when the real
problem is that the resource is private.

## Root-cause diagnostic tree — "can't reach the SharePoint Online intranet on mobile"
Work top-down; stop at the first branch that matches. Each branch names the confirm step and the
section that fixes it.

```
START: user reports the SharePoint Online intranet won't load on mobile
│
├─ Q1. Is the resource SharePoint Online (*.sharepoint.com), or a private/on-prem web app?
│     • Private/on-prem  → ROUTING gap. SharePoint Online needs no Tunnel; a private
│                          resource needs Microsoft Tunnel for MAM (separate solution). STOP.
│     • SharePoint Online → continue.
│
├─ Q2. Which app is the user opening the site in?
│     • Unmanaged Safari / unmanaged Chrome → WRONG ACCESS PATH. CA is blocking an
│         unapproved browser by design. Fix: steer to the SharePoint mobile app or
│         MAM-protected Edge (Overview + Implementation Step 6 / Troubleshooting B). STOP.
│     • SharePoint mobile app or MAM-protected Edge → continue.
│
├─ Q3. Does the block message cite a Conditional Access / organization policy?
│     • "You can't get here from your current device / need an approved app"
│         → CA BLOCK. Confirm in Entra Sign-in logs → the failing CA policy + which
│           grant failed. Go to Q4 to find which control the user can't meet.
│     • No CA message; sign-in loops / token error → go to Q6.
│
├─ Q4. Is an App Protection Policy actually applied to this user for this app?
│     • No APP assigned → MISSING APP GRANT. CA requires app protection but the user has
│         no APP → grant can never pass. Fix: assign the APP to the user's group
│         (Implementation Steps 2–3; run SPMAM-Validation.ps1). STOP.
│     • APP assigned → continue.
│
├─ Q5. Is the CA grant scoped/configured correctly for SharePoint Online / Office 365?
│     • CA not targeting Office 365 / SharePoint Online, or wrong grant/platform
│         → CA MISCONFIG. Fix the target resource, device platforms, and grant
│           (Implementation Step 5; run SPMAM-Discovery.ps1). STOP.
│     • CA correct → continue.
│
└─ Q6. Sign-in / token issue (MFA nag loop, stale token, app not signed into work account)?
      • Yes → TOKEN/SIGN-IN. Fix: sign out and back in with the work account in the
          managed app; complete MFA; clear the app data if needed (Troubleshooting E). STOP.
      • No, and Q1–Q5 all clean → escalate with Sign-in log correlation ID (Troubleshooting G).
```

## The standard Phoenixtekk deployment model
> **Define the App Protection Policies (SharePoint app + Edge) → build the Conditional Access grant
> for Office 365 → confirm and steer users to the supported access path → validate on a pilot →
> expand.** Phoenixtekk pattern: **Assess → Configure → Pilot → Validate → Expand.**
