# 3. Implementation Guide — Conditional Access Integration (Government / GCC High)

Follow these steps **in order**. In GCC High, Conditional Access is in **Microsoft Entra**
(**`https://entra.microsoft.us`** → **Protection → Conditional Access**). The **same** CA node also
appears in the Intune admin center (`https://intune.microsoft.us` → **Endpoint security →
Conditional access**) — either portal builds the same policies. **Always start in Report-only.**

> **Government caveat (read first):** every portal below is a **`*.us`** sovereign-cloud URL. If a
> link opens `entra.microsoft.com`, `portal.azure.com`, or `login.microsoftonline.com`, stop — you
> are on the Commercial cloud, and changes there do **not** affect your GCC High tenant.

> **Model:** Break-glass first → policies in Report-only → review → enable → expand.

## Step 1 — Create and exclude break-glass accounts
1. `https://entra.microsoft.us` → **Users → New user → Create new user**. Create two cloud-only
   accounts, e.g. `breakglass1@<yourtenant>.onmicrosoft.us` and
   `breakglass2@<yourtenant>.onmicrosoft.us` (use your real tenant — the domain ends in
   **`.onmicrosoft.us`**, not `.onmicrosoft.com`).
2. Assign both the **Global Administrator** role; set long random passwords and store them offline.
3. You will **exclude these two accounts from every CA policy** in the steps below.

## Step 2 — Create the pilot group
1. `https://entra.microsoft.us` → **Groups → New group** → **Security** → name it
   **`CA-Pilot-Gov`** → add your pilot users. **Create**.

## Step 3 — (If replacing legacy MFA Trusted IPs) create IP-based named locations
> **GCC High caveat:** design location policies on **named locations**, not the legacy per-tenant
> "MFA Trusted IPs" service settings. Named locations are the supported, forward-compatible way to
> express trusted networks, and they are available in GCC High. [Microsoft — CA network
> signals](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-assignment-network)
1. **Protection → Conditional Access → Named locations → + IP ranges location.**
2. **Name:** `Named-Trusted-Office-Egress`. Add your office egress IPv4/IPv6 CIDR ranges. Mark
   **Mark as trusted location** if appropriate. **Create.**
3. You will reference this named location in later policies instead of MFA Trusted IPs.
   *(Skip this step if you are not doing location-based policies.)*

## Step 4 — Policy: require compliant device for Microsoft 365
1. **Protection → Conditional Access → Create new policy.**
2. **Name:** `CA - Require Compliant Device - M365 (Gov)`.
3. **Users:** Include `CA-Pilot-Gov`; **Exclude** the two break-glass accounts.
4. **Target resources:** Cloud apps → **Office 365**.
5. **Grant:** Grant access → **Require device to be marked as compliant** (and/or **Require
   Microsoft Entra hybrid joined device**); **Require all the selected controls**.
6. **Enable policy:** **Report-only**. Click **Create**.

## Step 5 — Policy: require MFA
1. **Create new policy** → **Name:** `CA - Require MFA - All Apps (Gov)`.
2. **Users:** Include `CA-Pilot-Gov`; **Exclude** break-glass accounts.
3. **Target resources:** All cloud apps.
4. **Grant:** **Require multifactor authentication**.
5. **Enable policy:** **Report-only**. **Create**.

## Step 6 — Policy: block legacy authentication
1. **Create new policy** → **Name:** `CA - Block Legacy Auth (Gov)`.
2. **Users:** Include `CA-Pilot-Gov`; **Exclude** break-glass accounts.
3. **Target resources:** All cloud apps. **Conditions → Client apps →** set **Configure = Yes**,
   then select **Exchange ActiveSync clients** and **Other clients**.
4. **Grant:** **Block access**.
5. **Enable policy:** **Report-only**. **Create**.

## Step 7 — (Optional) require app protection for mobile
1. **Create new policy** → **Name:** `CA - Require App Protection - Mobile (Gov)`.
2. **Users:** `CA-Pilot-Gov` (exclude break-glass). **Conditions → Device platforms →** iOS,
   Android.
3. **Grant:** **Require app protection policy** (and **Require approved client app**);
   **Require one of the selected controls**. **Report-only → Create**.

## Step 8 — Review Report-only impact
1. Have pilot users sign in normally for a day or two (their sign-ins hit
   `login.microsoftonline.us`).
2. `https://entra.microsoft.us` → **Monitoring & health → Sign-in logs →** open a sign-in →
   **Report-only** tab to see which policies *would* apply and the result.
3. Run **`CAIG-Report.ps1`** (policies + recent sign-in CA results) to summarize impact. Resolve any
   unexpected would-blocks.
   > **GCC High caveat:** the **CA policy PowerPoint export** is Commercial-only today — use the
   > sign-in logs, the **What If** tool, and `CAIG-Report.ps1` for review/evidence instead.

## Step 9 — Enable enforcement
1. For each policy, edit **Enable policy → On**. Start with **Block Legacy Auth** and **Require
   MFA**, then **Require Compliant Device**.
2. Before flipping any policy On, run **`CAIG-Validation.ps1`** to confirm the break-glass accounts
   are still excluded from every policy.
3. Re-verify pilot users can work and break-glass accounts are excluded.

## Step 10 — Expand to production
1. Change each policy's **Users** from `CA-Pilot-Gov` to **All users** (keeping break-glass
   exclusions). Use **`CAIG-Set-ScopeTargeting.ps1`** (defaults to `-WhatIf`) to preview the
   include/exclude change before applying it.
2. Roll out in waves; monitor sign-in logs. Re-validate with **`CAIG-Validation.ps1`**.

> **Do NOT design around Global Secure Access.** GSA / network-based Conditional Access is **not
> available in GCC High** — express network trust with IP-based named locations (Step 3) instead.
> [Microsoft — GSA known
> limitations](https://learn.microsoft.com/en-us/entra/global-secure-access/reference-current-known-limitations)

---
### Order of operations
`Break-glass → Pilot group → (Named locations) → Compliant-device (RO) → MFA (RO) → Block legacy (RO) → App protection (RO) → Review → Enable → Expand`
