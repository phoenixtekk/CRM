# 3. Implementation — Remote Desktop (RDP) Security Hardening for Windows Endpoints

Follow these steps **in order**. The *why* for each capability lives in the Solution Overview; the
steps below are deliberately short and exact so you can **click to implement**. Throughout, the
repeatable pattern applies: **Assess → Configure → Pilot → Validate → Expand.** Do everything against
a **pilot group** first — one of these settings (High encryption) is a breaking change.

All admin-center steps use the Microsoft Intune admin center at `https://intune.microsoft.com` unless
noted.

> **This deploys endpoint-side RDP hardening only** on **enrolled, managed** Windows 10/11 devices. It
> does not deploy RD Gateway, firewall, or VPN, and it does not own the credential-theft program. Every
> setting below is an **Administrative Templates** setting delivered through the **Settings Catalog**,
> mapped to a known registry value so you can verify it on the device.

---

## Phase 1 — Assess and prepare

### Step 1. Confirm enrollment, Windows baseline, and RDP posture
1. Go to **Devices → Windows → Windows devices** and confirm the pilot device is **managed**.
2. Open the device → **Hardware** and confirm Windows 10 21H2+ or Windows 11 (current updates).
3. Identify which pilot devices **host** RDP (`fDenyTSConnections = 0`) and which **initiate** it. The
   included `RDPHARD-Report.ps1` helps summarize this across devices.

### Step 2. Identify legacy RDP clients (the one breaking change)
1. Before forcing **High / 128-bit** encryption, list any RDP clients that connect to in-scope hosts —
   old thin clients, embedded clients, third-party RDP tools.
2. Plan to test one legacy client against a piloted host (Testing, Test 5). Modern Windows/macOS and
   current Microsoft Remote Desktop clients negotiate 128-bit; genuinely old clients may be refused.

### Step 3. Confirm your pilot device group
1. In **Entra → Groups**, confirm a **security group of pilot devices** exists (Global Requirement G5 /
   R7). You will assign the profile to this group in Step 7.

---

## Phase 2 — Create the RDP hardening profile

### Step 4. Create the Settings Catalog profile
1. Go to **Devices → Configuration → Create → New policy**.
2. **Platform** = **Windows 10 and later**; **Profile type** = **Settings catalog**. Click **Create**.
3. **Basics → Name:** **`RDP Hardening - Pilot`**. Add a description, e.g. *Endpoint RDP hardening —
   High encryption, always prompt for password, no drive redirection, no saved passwords, Remote
   Assistance disabled, NLA required.* Click **Next**.

### Step 5. Add the five finding settings (plus NLA)
On **Configuration settings**, click **Add settings** and use the settings picker to search each
category below, then set the value shown. The **registry value** each one writes is given so you can
verify on the device; the exact Settings Catalog label wording is **verify in your tenant** (Microsoft
occasionally revises category labels — the registry anchor is the stable truth).

**Category — Administrative Templates → Windows Components → Remote Desktop Services → Remote Desktop
Session Host → Security:**
- **Set client connection encryption level** = **Enabled**, Encryption Level = **High Level** →
  `MinEncryptionLevel = 3` (128-bit). *(This is the breaking-change setting — pilot first.)*
- **Always prompt for password upon connection** = **Enabled** → `fPromptForPassword = 1`.
- **Require user authentication for remote connections by using Network Level Authentication** =
  **Enabled** → `UserAuthentication = 1`.

**Category — …Remote Desktop Session Host → Device and Resource Redirection:**
- **Do not allow drive redirection** = **Enabled** → `fDisableCdm = 1`.

**Category — Administrative Templates → Windows Components → Remote Desktop Services → Remote Desktop
Connection Client:**
- **Do not allow passwords to be saved** = **Enabled** → `DisablePasswordSaving = 1`.

**Category — Administrative Templates → System → Remote Assistance:**
- **Configure Solicited Remote Assistance** = **Disabled** → `fAllowToGetHelp = 0`.
- **Configure Offer Remote Assistance** = **Disabled** → `fAllowUnsolicited = 0`.

> **Tip.** In the Settings Catalog picker, search the exact phrase (e.g. *"Always prompt for password
> upon connection"*) and confirm the **category path** shown matches the one above before selecting —
> several similarly-named RDP settings exist. Keep a short table (setting → value → registry anchor) as
> your record.

### Step 6. Decide on the defense-in-depth extras (deliberate, may be separate)
These are the two items the Overview cross-references. Add them **only** with intent:
- **Restricted Admin / Remote Credential Guard for outbound RDP** — the client-side **Restrict
  delegation of credentials to remote servers** setting (`RestrictedRemoteAdministration`, under
  *Administrative Templates → System → Credentials Delegation*). This protects credentials when this
  device connects **out** to another host, but changes single-sign-on behavior to the remote host. **Its
  full deployment belongs to the credential-theft hardening solution** — deploy it there, separately
  piloted, rather than folding it into this profile. If you do include it here, pilot it on its own.
- **Limit who can log on via RDP** — restrict the **Allow log on through Remote Desktop Services** user
  right (`SeRemoteInteractiveLogonRight`) to a controlled group instead of the broad default. The exact
  user-rights surface in the Settings Catalog is **verify in your tenant**; if it is not exposed as a
  Settings Catalog setting in your tenant, apply it via an Account Protection / security-baseline policy
  or a User Rights Assignment setting and reference the same named group.

### Step 7. Scope tags, assignment, review
1. **Next** through **Scope tags** (set if you use them).
2. **Assignments:** add the **pilot device group** (R7). Do **not** assign to "All devices" yet. Click
   **Next**.
3. **Review + create** → **Create**.

> Prefer automation? Run the included **`RDPHARD-Set-ScopeTargeting.ps1`** (Microsoft Graph) to set or
> adjust the assignment (defaults to **-WhatIf** — preview first, then re-run to apply), and
> **`RDPHARD-Discovery.ps1`** to confirm the profile is present with the expected settings.

---

## Phase 3 — Pilot

### Step 8. Push and confirm the profile
1. On the pilot device, sync Intune (**Settings → Accounts → Access work or school → (account) → Info →
   Sync**, or `dsregcmd /refreshprt` then a policy sync).
2. In Intune → **Devices → Configuration → `RDP Hardening - Pilot` → Device status**, confirm the pilot
   device shows **Succeeded**.
3. *(Optional device-side proof)* On the pilot host, confirm the registry values, e.g.
   `reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v MinEncryptionLevel`
   returns `3`, and `fPromptForPassword`, `fDisableCdm`, `fAllowToGetHelp` are set as intended.

### Step 9. Verify hardened behavior with a live RDP session
1. From a **modern** test client, initiate an RDP session to the pilot host.
2. Confirm the session **prompts for a password** (`fPromptForPassword`), that **local drives do not
   appear** inside the session (`fDisableCdm`), and that the client **cannot save** the password
   (`DisablePasswordSaving`).
3. Confirm the session negotiates a 128-bit-capable connection (High encryption) and that **NLA** is
   enforced (the client authenticates before the full session appears).

### Step 10. Confirm Remote Assistance is closed
1. Attempt to launch **Solicited Remote Assistance** on the pilot device (e.g. `msra.exe /novice`).
2. Confirm it is **blocked/disabled** (`fAllowToGetHelp = 0`), and that unsolicited/offer Remote
   Assistance is likewise disabled (`fAllowUnsolicited = 0`).

---

## Phase 4 — Validate and expand

### Step 11. Validate with the scripts
1. Run **`RDPHARD-Discovery.ps1`** (tenant readiness: the `RDP Hardening - Pilot` Settings Catalog
   profile is present and carries the expected RDP settings).
2. Run **`RDPHARD-Validation.ps1`** to confirm the profile is **assigned** to the intended group and the
   pilot device shows the profile **applied**.
3. Run **`RDPHARD-Report.ps1`** to produce a coverage report (which Windows devices have the RDP
   hardening profile applied).

### Step 12. Remediate gaps (safe by default)
1. If devices are missing or mis-scoped, run **`RDPHARD-Remediation.ps1`** — it **defaults to `-WhatIf`**
   and prints exactly what it would create/assign. Review, then re-run with `-WhatIf:$false` to apply.

### Step 13. Address the credential and network layers (cross-reference)
1. Deploy the **credential-theft hardening solution** for **Restricted Admin / Remote Credential Guard**
   (the credential-delegation side of outbound RDP) — pilot it separately.
2. Confirm your **network-side** RDP controls (RD Gateway, firewall/NSG rules, VPN, JIT VM access) are
   in place; this endpoint profile complements but does not replace them.

### Step 14. Expand in waves
1. Once the pilot passes (Testing gate) **including the legacy-client test**, broaden the profile
   assignment to the next device group, or make it the standard Windows RDP hardening baseline.
2. Roll out in waves, validating each wave with `RDPHARD-Report.ps1` before widening — and re-checking
   the legacy-client impact (R5) for each new population.
