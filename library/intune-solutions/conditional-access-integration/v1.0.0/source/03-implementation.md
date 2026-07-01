# 3. Implementation Guide — Conditional Access Integration

Follow these steps **in order**. Conditional Access is in **Microsoft Entra**
(`https://entra.microsoft.com` → **Protection → Conditional Access**). **Always start in Report-only.**

> **Model:** Break-glass first → policies in Report-only → review → enable → expand.

## Step 1 — Create and exclude break-glass accounts
1. Entra → **Users → New user** → create two cloud-only `breakglass1@…onmicrosoft.com` and `breakglass2@…onmicrosoft.com` Global Administrators with long random passwords (store offline).
2. You will **exclude these two accounts from every CA policy** in the steps below.

## Step 2 — Create the pilot group
1. Entra → **Groups → New group** → Security → `CA-Pilot` → add pilot users. **Create**.

## Step 3 — Policy: require compliant device for Microsoft 365
1. **Protection → Conditional Access → Create new policy.**
2. **Name:** `CA - Require Compliant Device - M365`.
3. **Users:** Include `CA-Pilot`; **Exclude** the two break-glass accounts.
4. **Target resources:** Cloud apps → **Office 365**.
5. **Grant:** Grant access → **Require device to be marked as compliant** (and/or **Require Microsoft Entra hybrid joined device**); **Require all the selected controls**.
6. **Enable policy:** **Report-only**. Click **Create**.

## Step 4 — Policy: require MFA
1. **Create new policy** → **Name:** `CA - Require MFA - All Apps`.
2. **Users:** Include `CA-Pilot`; **Exclude** break-glass accounts.
3. **Target resources:** All cloud apps.
4. **Grant:** **Require multifactor authentication**.
5. **Enable policy:** **Report-only**. **Create**.

## Step 5 — Policy: block legacy authentication
1. **Create new policy** → **Name:** `CA - Block Legacy Auth`.
2. **Users:** Include `CA-Pilot`; **Exclude** break-glass accounts.
3. **Target resources:** All cloud apps. **Conditions → Client apps →** select **Exchange ActiveSync clients** and **Other clients**.
4. **Grant:** **Block access**.
5. **Enable policy:** **Report-only**. **Create**.

## Step 6 — (Optional) require app protection for mobile
1. **Create new policy** → **Name:** `CA - Require App Protection - Mobile`.
2. **Users:** `CA-Pilot` (exclude break-glass). **Conditions → Device platforms →** iOS, Android.
3. **Grant:** **Require app protection policy** (and **Require approved client app**). **Report-only → Create**.

## Step 7 — Review Report-only impact
1. Have pilot users sign in normally for a day or two.
2. Entra → **Monitoring → Sign-in logs →** open a sign-in → **Report-only** tab to see which policies *would* apply and the result.
3. Run **`CAI-PolicyReport.ps1`** and **`CAI-SignInReport.ps1`** to summarize impact. Resolve any unexpected blocks.

## Step 8 — Enable enforcement
1. For each policy, edit **Enable policy → On**. Start with **Block Legacy Auth** and **Require MFA**, then **Require Compliant Device**.
2. Re-verify pilot users can work and break-glass accounts are excluded.

## Step 9 — Expand to production
1. Change each policy's **Users** from `CA-Pilot` to **All users** (keeping break-glass exclusions).
2. Roll out in waves; monitor sign-in logs. Re-validate with **`CAI-Validation.ps1`**.

---
### Order of operations
`Break-glass → Pilot group → Compliant-device (RO) → MFA (RO) → Block legacy (RO) → App protection (RO) → Review → Enable → Expand`
