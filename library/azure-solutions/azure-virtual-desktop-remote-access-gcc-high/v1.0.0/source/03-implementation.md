# Implementation Guide — Azure Virtual Desktop Remote Access (Azure Government / GCC High)

Ordered, click-to-implement steps using the **Azure Government** portals. GCC-High / Azure-Government caveats are called out **inline at the step where they matter**. Follow the deployment model **Assess → Configure → Pilot → Validate → Expand**, and do not pass a stage until its **gate** is green.

> **Before you touch anything:** you are working in the US sovereign cloud. Admin URL is **`portal.azure.us`** (not `portal.azure.com`), and clients subscribe to **`rdweb.wvd.azure.us`** (not `rdweb.wvd.microsoft.com`). Keep the naming convention `<Purpose> – <Scope> – <Stage>` and reuse names verbatim.

---

## Stage 1 — Assess

### Step 1.1 — Confirm you are in Azure Government
1. Browse to **`https://portal.azure.us`** and sign in. Your sign-in must redirect through **`login.microsoftonline.us`**.
2. Top-right → confirm the correct **directory/tenant** (GCC High domains are often `<name>.onmicrosoft.us`).
3. Open **`https://portal.office365.us`** → **Billing → Licenses** and confirm AVD-entitling **Government** SKUs are assigned to your pilot users (R2).

> **Caveat:** If either portal bounces you to `portal.azure.com` / `admin.microsoft.com`, you are on a Commercial/GCC tenant, not GCC High — stop and confirm the tenant (R1) before continuing.

### Step 1.2 — Register the resource provider
1. In `portal.azure.us` → **Subscriptions** → select your subscription → **Resource providers**.
2. Search **`Microsoft.DesktopVirtualization`**. If status is **NotRegistered**, select it → **Register**. Wait for **Registered**.

> Scripted equivalent (Gov): `Connect-AzAccount -Environment AzureUSGovernment` then `Register-AzResourceProvider -ProviderNamespace Microsoft.DesktopVirtualization`.

### Step 1.3 — Confirm roles and endpoints
1. **Subscriptions → Access control (IAM)** → confirm your account has **Contributor/Owner** plus **Desktop Virtualization Contributor** (R3).
2. Allow the **Azure for US Government** session-host and client endpoints through your firewall/proxy (R7 table). Key ones: `*.wvd.azure.us`, `*.service.windows.usgovcloud.microsoft`, `login.microsoftonline.us`, and the `*.usgovcloudapi.net` agent/monitor endpoints.
3. Run **`AVDG-Discovery.ps1`** (read-only) to snapshot the tenant/subscription and confirm the provider, roles, and reachable endpoints.

> **GATE 1 (Assess):** Discovery reports the provider Registered, roles present, and Gov endpoints reachable; all `02-requirements.md` items verified. Do not configure until green.

---

## Stage 2 — Configure

### Step 2.1 — Create the host pool
1. `portal.azure.us` → search **Azure Virtual Desktop** → **Host pools** → **Create**.
2. **Basics:** Subscription, Resource group (e.g., `rg-avd-<scope>-prod`), **Host pool name** = **`AVD Host Pool – <Scope> – Pilot`**, **Location** = your Azure Government region (this sets where host-pool *metadata* is stored).
   > **Caveat:** the **Location** field must be an Azure Government region. Session-host compute can be in any Gov region, but keep it close to users (RTT < 150 ms).
3. **Host pool type:** **Pooled** (multi-session) or **Personal** per your design. Choose a load-balancing algorithm (Breadth-first for pilot is typical).
4. **Validation environment:** set **No** for production pilots unless you intend to receive early service updates.

### Step 2.2 — Add session hosts
1. On the **Virtual Machines** tab of the create flow (or later via **Session hosts → +**), set **Add virtual machines = Yes**.
2. **Image:** pick a supported OS from the **Gov** Marketplace (Windows 11 Enterprise multi-session recommended for pooled). Avoid N/KN/LTSC, 32-bit, Arm64, Ultra/Ephemeral OS disks, and VM Scale Sets (R6).
3. **Name prefix:** e.g., `avdsh-<scope>` (becomes `avdsh-<scope>-0`, `-1`, …).
4. **Identity — choose your model (R5):**
   - **Microsoft Entra ID** (cloud-native): select **Microsoft Entra ID**; optionally tick **Enroll VM with Intune** (supported in Azure Government for Entra-joined hosts).
   - **Active Directory** (AD DS / Entra Domain Services): select **Active Directory**, provide the domain-join UPN/OU.
     > **Caveat:** the domain-join account **must not have MFA enabled**, or the join fails. Hosts joined to **Microsoft Entra Domain Services cannot be managed by Intune**; **Windows Server** hosts cannot enroll in Intune at all.
5. **Networking:** select the VNet/subnet from R7 (same Gov region). Do not assign public IPs; do not open inbound 3389.
6. **Domain/credentials:** provide the local admin (and domain-join, if AD) credentials. Create.
7. Wait until **Session hosts** shows each host **Status = Available**.

> **Caveat (endpoints):** if a host stalls at **Needs assistance** / fails agent registration, the usual cause on Gov is a blocked `.us` endpoint. Re-check `*.wvd.azure.us` and the `*.usgovcloudapi.net` agent endpoints (R7), then run `AVDG-Validation.ps1`.

### Step 2.3 — Create the workspace and application group
1. **Application groups:** an app group (**Desktop** type for full desktop) is created with the host pool. Rename/confirm it as **`AVD App Group – <Scope> – Pilot`**.
2. **Workspaces** → **Create** → **`AVD Workspace – <Scope> – Prod`** → in **Application groups**, **register** the app group above.
   > A published resource only appears to users once its app group is **registered to a workspace** — a common "nothing shows up in the client" cause.

> **GATE 2 (Configure):** host pool, workspace, and app group exist with the agreed names; all session hosts **Available**; app group registered to the workspace.

---

## Stage 3 — Pilot

### Step 3.1 — Assign the pilot group
1. `entra.microsoft.us` → **Groups** → confirm **`AVD Users – <Scope> – Pilot`** (R9) contains only pilot users.
2. In the AVD **Application group → Assignments → +** → add the pilot group. Assign only the pilot group at this stage.

### Step 3.2 — Subscribe clients to the Government feed
> **This is the step most likely to go wrong if you reuse Commercial instructions.** Use the **Gov** feed URL.

- **Windows (Windows App or Remote Desktop client):**
  1. Install **Windows App** (Microsoft Store) or the **Remote Desktop client**.
  2. **Subscribe with URL** → enter **`https://rdweb.wvd.azure.us`** (or feed discovery `https://rdweb.wvd.azure.us/api/arm/feeddiscovery?aadtenant=<yourdomain>`).
  3. Sign in with the Gov work account (`user@<name>.onmicrosoft.us` or your Gov domain).
- **macOS (Windows App):**
  1. Install **Windows App** from the **Mac App Store**.
  2. Open it → **+** → **Add Work or School Account** → sign in with the Gov account → subscribe to the same **`https://rdweb.wvd.azure.us`** feed.
- **Web client (any OS):** browse to **`https://rdweb.wvd.azure.us/arm/webclient/index.html`**.
- **Scripted / URI:** subscribe with `ms-rd:subscribe?url=https://rdweb.wvd.azure.us`; direct connect with `ms-avd:connect?...&env=usgov&version=0`.

> **Caveat:** Do **not** use `rdweb.wvd.microsoft.com` or `client.wvd.microsoft.com` — those are Commercial and will not return Gov resources. The `ms-avd:` `env` value for Azure Government is **`usgov`** (Commercial is `avdarm`).

### Step 3.3 — First connection
1. Each pilot user opens the subscribed workspace, launches the **desktop**, and launches at least one **published app**.
2. Confirm resources appear and the session connects over TCP 443 (RDP Shortpath/UDP is an optimization, not a requirement).

> **GATE 3 (Pilot):** every pilot user (Windows and macOS as applicable) subscribes to the Gov feed, connects to a desktop, and launches a published app.

---

## Stage 4 — Validate

1. Run **`AVDG-Validation.ps1`** (read-only, Gov endpoints) — confirms provider, host-pool/session-host health, workspace/app-group registration, assignment, and endpoint reachability.
2. Run **`AVDG-Report.ps1`** to produce the deployment report (inventory + pass/fail summary) for your change record.
3. Walk the test cases in `05-testing.md`; resolve any failures.

> **GATE 4 (Validate):** all `05-testing.md` cases pass; Report shows no Sev-1/Sev-2 open items.

---

## Stage 5 — Expand

1. Plan waves (e.g., +25 users each). For each wave, run **`AVDG-Set-ScopeTargeting.ps1`** (default **`-WhatIf`**) to preview adding users to **`AVD Users – <Scope> – Pilot`** (or a `– Prod` group), review the plan, then re-run with `-Confirm`/`-WhatIf:$false` to apply.
2. Scale session hosts if needed (add hosts to the pool with the same name prefix); confirm each new host reaches **Available**.
3. Re-run **`AVDG-Validation.ps1`** after each wave.

> **GATE 5 (Expand):** each wave validated before the next is added; host capacity keeps pace with assigned users.

---

## Rollback (per R10 / G6)
- Remove the group assignment from the application group (users lose access immediately, hosts untouched).
- Deallocate/delete session hosts if backing out entirely.
- Unregister the app group from the workspace to hide resources without deleting them.
- Keep the pre-change `AVDG-Discovery.ps1` / `AVDG-Report.ps1` output as the restore reference.
