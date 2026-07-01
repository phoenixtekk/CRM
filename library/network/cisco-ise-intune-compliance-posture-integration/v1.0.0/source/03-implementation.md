# Implementation

Follow these steps in order. They implement the **Configure** and **Pilot** phases of the
deployment model. The **Intune / Entra / Graph** steps are click-by-click; the **Cisco ISE**
steps are described at the architectural level and **deferred to Cisco's official
documentation** for the exact console paths.

Reuse the object names exactly as written — later steps and the PowerShell scripts depend on
them:

- App registration: `ISE-Intune-Compliance-Connector`
- Compliance policies: `Compliance – Windows – Baseline`, `Compliance – iOS – Baseline`,
  `Compliance – Android – Baseline`, `Compliance – macOS – Baseline`
- Pilot group: `PILOT – ISE Posture Devices`
- Expansion group: `PROD – ISE Posture Devices`

---

## Step 1 — Register the app in Entra that ISE will use

1. Sign in to `https://entra.microsoft.com` as an administrator (Application Administrator or
   Global Administrator).
2. Go to **Identity → Applications → App registrations → + New registration**.
3. **Name:** `ISE-Intune-Compliance-Connector`.
4. **Supported account types:** *Accounts in this organizational directory only (single
   tenant).*
5. Leave **Redirect URI** empty. Click **Register**.
6. On the app's **Overview** page, copy and save the **Application (client) ID** and the
   **Directory (tenant) ID** — you will enter both into ISE later.

## Step 2 — Grant the app the Microsoft Graph permissions ISE needs

1. In the app, go to **API permissions → + Add a permission → Microsoft Graph →
   Application permissions** (not Delegated — ISE calls Graph as itself, unattended).
2. Add these application permissions:
   - `DeviceManagementManagedDevices.Read.All` — read managed device + compliance state.
   - `DeviceManagementConfiguration.Read.All` — read compliance policy configuration.
3. Click **Add permissions**.
4. Click **Grant admin consent for &lt;your tenant&gt;** and confirm. Every permission must
   show **"Granted for &lt;tenant&gt;"** with a green check before you continue.

> Note: Cisco's documentation lists the exact permission set for your ISE release. The two
> read permissions above cover reading device compliance/enrollment. If your ISE version's
> External MDM flow requires an additional permission, add it here the same way and re-consent.

## Step 3 — Create a client secret for the app

1. In the app, go to **Certificates & secrets → Client secrets → + New client secret**.
2. **Description:** `ISE connector secret`. **Expires:** choose a policy-approved lifetime
   (for example 12 months) and record the renewal date.
3. Click **Add**, then **immediately copy the secret Value** (not the Secret ID). It is shown
   only once. Store it securely — you will paste it into ISE.

## Step 4 — Connect ISE to Intune (architectural — defer to Cisco docs)

In the **Cisco ISE** admin console, add Intune as an **External MDM server** using the
credentials from Steps 1–3. At the architectural level you will supply ISE with:

- The **Directory (tenant) ID** (Step 1).
- The **Application (client) ID** (Step 1).
- The **client secret Value** (Step 3).
- The Microsoft Graph / Entra endpoints ISE authenticates and queries against.

Then use ISE's **Test Connection** on the External MDM server definition and confirm it
succeeds — a successful test proves the app registration, permissions, secret, and network
reachability (R5) are all correct.

> **Vendor boundary:** the exact ISE menu path (for example the External MDM / MDM & UEM
> server area), field labels, and the connection-test button vary by ISE release. **Follow
> Cisco's official ISE documentation for your version** to enter these values and run the
> test. Do not proceed to Step 6 until Cisco's Test Connection reports success.

## Step 5 — Define the named compliance policies in Intune

Create one baseline policy per platform. These define what "compliant" means and are the
substance behind ISE's access decision. For each policy: Intune → **Devices → Compliance →
Policies → + Create policy** → select the platform → name it exactly as below → set the rules →
set the **Actions for noncompliance** → **Assign** to `PILOT – ISE Posture Devices` → **Create**.

### `Compliance – Windows – Baseline`
- Platform: **Windows 10 and later**.
- Rules (Compliance settings): require **BitLocker**, require **Secure Boot**, set a
  **minimum OS version** floor, require **Microsoft Defender Antimalware** on, require a
  **password/PIN** to unlock.
- Actions for noncompliance: **Mark device noncompliant** immediately (or after a short grace
  — see Best Practices), and optionally **Send email to end user**.

### `Compliance – iOS – Baseline`
- Platform: **iOS/iPadOS**.
- Rules: **Jailbroken devices = Block**, **minimum OS version** floor, require a
  **passcode**, require **device encryption** (implicit with passcode on iOS).
- Actions for noncompliance: **Mark device noncompliant** (with grace per policy).

### `Compliance – Android – Baseline`
- Platform: **Android Enterprise** (work profile / fully managed as applicable).
- Rules: **Rooted devices = Block**, require **Play Integrity / SafetyNet** device health,
  **minimum OS version** floor, require **encryption of data storage**, require a
  **password/PIN**.
- Actions for noncompliance: **Mark device noncompliant** (with grace per policy).

### `Compliance – macOS – Baseline`
- Platform: **macOS**.
- Rules: require **FileVault** disk encryption, set a **minimum OS version** floor, require a
  **password** to unlock.
- Actions for noncompliance: **Mark device noncompliant** (with grace per policy).

> Assign every baseline policy to **`PILOT – ISE Posture Devices` only** for now. You expand
> the assignment to `PROD – ISE Posture Devices` in the Expand phase.

## Step 6 — Map compliance to ISE authorization (architectural — defer to Cisco docs)

In the **Cisco ISE** admin console, build the authorization logic that turns the compliance
signal into an access decision. At the architectural level, standardize on this mapping:

- **Device registered = true AND compliant = true** → authorization result **PermitAccess**
  (full network / VPN).
- **Device registered = true AND compliant = false** → authorization result **denies** or
  assigns a **remediation / quarantine** profile (limited VLAN, redirect to remediation).
- **Device registered = false (unmanaged)** → authorization result **denies** or redirects the
  user to the enrollment portal.

Use ISE's MDM compliance dictionary attributes (device registered, device compliant, and
related fields returned from Intune) as the **conditions** in these authorization rules, and
scope the rules to the relevant policy set (VPN, wired 802.1X, wireless).

> **Vendor boundary:** the exact ISE authorization-profile and policy-set construction —
> dictionaries, attribute names, and rule editor — **must be followed from Cisco's official
> ISE documentation for your release.** Build the rules there; this solution defines the
> mapping intent and provides the Intune-side signals they consume.

## Step 7 — Assign to the pilot and stage the gate

1. Confirm the baseline compliance policies (Step 5) are assigned to `PILOT – ISE Posture
   Devices` only.
2. In ISE, scope the new compliance-gating authorization rules so they apply to the pilot
   population first (for example a policy set or condition limited to pilot devices/users),
   per Cisco's documentation.
3. Announce the change window (R7) to pilot users and confirm the rollback is ready.

## Step 8 — Validate (pass/fail gate)

Run the validation before expanding. In summary (full pass/fail steps are in the Testing
guide):

1. **Compliant pilot device** connects → ISE reads registered + compliant → **access
   granted**. *(Pass gate 1.)*
2. **Deliberately non-compliant pilot device** (for example encryption turned off, so Intune
   marks it non-compliant) connects → ISE reads non-compliant → **access denied / quarantined**.
   *(Pass gate 2 — the critical one.)*
3. Use `ISEPOST-Validation.ps1` to confirm the device's compliance/enrollment state as ISE
   reads it, and `ISEPOST-Discovery.ps1` to confirm connector readiness.

Do not expand until **both** gates pass: compliant → granted, and non-compliant → denied.

## Step 9 — Expand

1. Create `PROD – ISE Posture Devices` (or run `ISEPOST-Set-ScopeTargeting.ps1`) and add the
   broader device population in controlled waves.
2. Extend the compliance policy assignments (Step 5) and the ISE authorization rule scope
   (Step 6) from pilot to `PROD – ISE Posture Devices`.
3. Expand in waves, watching the `ISEPOST-Report.ps1` compliance-coverage report between waves.
   Keep the rollback available throughout the rollout.
