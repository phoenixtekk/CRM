# 3. Implementation Guide — Secure Mobile Access to SharePoint Online under MAM

Follow these steps **in order**. App Protection Policies are in the **Microsoft Intune admin
center** (`https://intune.microsoft.com` → **Apps → App protection policies**). Conditional Access
is in **Microsoft Entra** (`https://entra.microsoft.com` → **Protection → Conditional Access**).
**Always start Conditional Access in Report-only.**

> **Model:** Define the App Protection Policies (SharePoint app + Edge) → build the Conditional
> Access grant for Office 365 → confirm and steer users to the supported access path → validate on a
> pilot → expand. This is the resolution: align APP + CA + access path.

> **Naming (reuse these exact names):**
> App Protection Policies: `SPO Mobile – App Protection – iOS` and `SPO Mobile – App Protection – Android`.
> Conditional Access policy: `CA – SPO Mobile – Require APP`.
> Groups: `SPO Mobile – Users – Pilot` and `SPO Mobile – Users – Prod`.

## Step 1 — Create break-glass accounts and the groups
1. Entra → **Users → New user → Create new user**: create two cloud-only emergency-access Global
   Administrators (`breakglass1@…onmicrosoft.com`, `breakglass2@…onmicrosoft.com`) with long random
   passwords stored offline. You will **exclude these two from the CA policy** in Step 5.
2. Entra → **Groups → New group → Security → Name:** `SPO Mobile – Users – Pilot`; add a few
   representative mobile users. **Create.**
3. Create `SPO Mobile – Users – Prod` (the rest of the mobile users). **Create.**

## Step 2 — Create the iOS App Protection Policy (SharePoint app + Edge)
1. Intune → **Apps → App protection policies → Create policy → iOS/iPadOS**.
2. **Name:** `SPO Mobile – App Protection – iOS`. **Next.**
3. **Apps:** **Target policy to → Selected apps → Select public apps →** add **Microsoft SharePoint**
   and **Microsoft Edge**. **Next.**
4. **Data protection:** set **Send org data to other apps → Policy managed apps**;
   **Save copies of org data → Block** (allow **OneDrive/SharePoint** if your policy permits);
   **Receive data from other apps → Policy managed apps**; **Restrict cut, copy, and paste → Policy
   managed apps**. **Next.**
5. **Access requirements:** require an **App PIN**; **Work or school account credentials for access**;
   set the **recheck** timeout to your policy. **Next.**
6. **Conditional launch:** keep the defaults (for example **Max PIN attempts → 5 → Reset PIN**;
   **Offline grace period → 720 min → Block access**). **Next.**
7. **Assignments → Add groups →** `SPO Mobile – Users – Pilot`. **Next → Create.**

## Step 3 — Create the Android App Protection Policy (SharePoint app + Edge)
1. Intune → **Apps → App protection policies → Create policy → Android**.
2. **Name:** `SPO Mobile – App Protection – Android`. **Next.**
3. **Apps → Selected apps → Select public apps →** add **Microsoft SharePoint** and **Microsoft
   Edge**. **Next.**
4. Set **Data protection**, **Access requirements**, and **Conditional launch** to match the iOS
   policy (Step 2.4–2.6). **Next.**
5. **Assignments → Add groups →** `SPO Mobile – Users – Pilot`. **Next → Create.**

## Step 4 — Confirm the routing decision (SharePoint Online = no Tunnel)
1. Confirm the intranet is SharePoint Online: open its URL and verify it resolves to your
   `*.sharepoint.com` tenant over the public internet (test off the corporate network).
2. If it is SharePoint Online, **no Microsoft Tunnel is required** — continue to Step 5.
3. If the "intranet" is actually an on-premises / private web app, **stop**: that resource needs the
   **Microsoft Tunnel for MAM** solution (separate). Do not build a Tunnel for SharePoint Online.

## Step 5 — Create the Conditional Access policy (app-protection grant)
1. Entra → **Protection → Conditional Access → Create new policy.**
2. **Name:** `CA – SPO Mobile – Require APP`.
3. **Users:** **Include →** `SPO Mobile – Users – Pilot`; **Exclude →** the two break-glass accounts.
4. **Target resources → Cloud apps → Include → Select apps → Office 365** (this covers SharePoint
   Online). Do **not** hand-pick only the SharePoint resource; **Office 365** is the supported,
   recommended target.
5. **Conditions → Device platforms → Configure → Yes → Select → iOS and Android.**
6. **Grant → Grant access →** select **Require app protection policy** and **Require approved client
   app**; set **For multiple controls → Require one of the selected controls** (Microsoft recommends
   pairing these two so older approved apps that predate APP are still covered). **Select.**
7. **Enable policy → Report-only.** **Create.**

## Step 6 — Confirm and steer users to the supported access path
1. On a pilot device, open the intranet in the **SharePoint mobile app** (signed in with the work
   account) — it should load. Then open it in **Microsoft Edge** signed in with the work account — it
   should load.
2. Open the same intranet URL in **unmanaged Safari / unmanaged Chrome** — it should be **blocked**
   by CA once enforced (this is expected and correct).
3. Communicate the supported paths to users: "Open the intranet in the SharePoint app, or in
   Microsoft Edge signed in with your work account. Do not use Safari or Chrome." Optionally publish
   a bookmark/link that deep-links into the SharePoint app or Edge.

## Step 7 — Review Report-only impact, then enforce
1. Have pilot users work normally for a day or two using the supported paths.
2. Entra → **Monitoring → Sign-in logs →** open a mobile sign-in → **Report-only** tab to see whether
   `CA – SPO Mobile – Require APP` *would* apply and its result. Run `SPMAM-Discovery.ps1` and
   `SPMAM-Report.ps1` to summarize coverage; resolve any unexpected results.
3. When the pilot is clean, edit the CA policy → **Enable policy → On**. Re-verify pilot users can
   reach the intranet on the supported path and that break-glass accounts are excluded.

## Step 8 — Validate the pilot
1. Run `SPMAM-Validation.ps1` for a pilot user → confirms an App Protection Policy is applied for
   the SharePoint/Edge apps and that the CA app-protection grant is effective for SharePoint Online.
2. Complete the **Testing Guide** (Section 5) and confirm every pass/fail gate.

## Step 9 — Expand to production
1. Add `SPO Mobile – Users – Prod` to the **Include** on all three policies (the two App Protection
   Policies and the CA policy), keeping the break-glass exclusions on CA. Use
   `SPMAM-Set-ScopeTargeting.ps1` to manage the group membership at scale.
2. Roll out in waves; monitor **Sign-in logs** and re-validate with `SPMAM-Validation.ps1` /
   `SPMAM-Report.ps1`.
3. If any assignment is inconsistent, run `SPMAM-Remediation.ps1` (defaults to `-WhatIf`) to preview
   the fix, then re-run with `-WhatIf:$false` to apply.

---
### Order of operations
`Break-glass + groups → iOS App Protection → Android App Protection → routing decision → CA policy (Report-only) → confirm/steer access path → review + enforce → validate → expand`
