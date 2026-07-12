# 3. Implementation Guide — Entra Global Secure Access (Internet & Private Access)

Follow these steps **in order**, in the **Microsoft Entra admin center** (`https://entra.microsoft.com`
→ **Global Secure Access**). Names in `code` are the exact objects to create — keep them consistent so
the scripts, testing, and troubleshooting all refer to the same objects. Portal blade names evolve; if a
label differs, match by intent and verify against current Microsoft guidance.

**Object naming convention:** `ENTGSA – <Purpose> – <Scope> – <Stage>`. The objects you will build:

| Object | Name |
|--------|------|
| Pilot user group | `ENTGSA-Pilot` |
| Private Access connector group | `ENTGSA – ConnectorGroup – Datacenter` |
| Published private app (enterprise app) | `ENTGSA – PrivateApp – IntranetWeb – Pilot` |
| Web content filtering policy | `ENTGSA – WebFilter – Baseline` |
| Global Secure Access security profile | `ENTGSA – SecurityProfile – Baseline` |
| Conditional Access (Microsoft/Internet traffic) | `ENTGSA – CA – InternetAccess – Pilot` |
| Conditional Access (Private app) | `ENTGSA – CA – PrivateApp – Pilot` |
| Log Analytics diagnostic setting | `ENTGSA – Diag – TrafficLogs` |

> **Model:** Assess → Configure → Pilot → Validate → Expand. Build each object, scope it to
> **`ENTGSA-Pilot`** and the pilot devices first, prove the gates in §5, then expand. Keep the VPN as a
> fallback until Private Access is trusted. Every production change has a rollback (see end of file).

## Step 1 — Assess and baseline the current state
1. Run **`ENTGSA-Discovery.ps1`** — inventories whether GSA is activated, which forwarding profiles are
   enabled, existing connector groups, published private apps, filtering policies, and any CA policies
   already targeting GSA. On a new tenant this is largely empty.
2. Confirm the pilot group `ENTGSA-Pilot` exists (Entra → **Groups**) with test users, and that you have
   2–5 pilot devices you control.
3. Record the **one private app** you will publish first (Requirement 2.6): its internal FQDN/IP and ports.

## Step 2 — Activate Global Secure Access and enable the Microsoft profile
1. **Global Secure Access → Get started → Activate** (one-time tenant activation).
2. **Global Secure Access → Connect → Traffic forwarding.** Turn on the **Microsoft traffic profile**
   first — it is the lowest-risk profile and enables compliant-network / source-IP restore for M365.
3. Leave the **Internet Access** and **Private Access** profiles **off** for now; you will enable them
   after the client is proven on the pilot.

## Step 3 — Deploy the GSA client to the pilot devices
1. **Global Secure Access → Connect → Client download** — download the client installer.
2. Install it on the **pilot devices** (manually for the pilot, or via Intune for scale — see the Modern
   Endpoint Management catalog for the packaged deployment).
3. Sign in as a `ENTGSA-Pilot` user. Open the client status UI and confirm it shows **Connected** and the
   **Microsoft** channel is **Active**.
4. Run **`ENTGSA-Validate.ps1`** — confirms the Microsoft profile is enabled and the tenant is receiving
   traffic.

## Step 4 — Deploy Private Access connectors
1. On the connector host (Requirement 2.5): **Global Secure Access → Connect → Connectors → Download
   connector service**, install it, and sign in with a GSA admin when prompted.
2. In **Connectors**, confirm the connector shows **Active**. Install a **second** connector for HA.
3. Create a connector group: **Connectors → Connector groups → + New connector group**, name it
   `ENTGSA – ConnectorGroup – Datacenter`, and assign both connectors to it.
4. Run **`ENTGSA-ConnectorHealth.ps1`** — confirms the connector group is healthy and reachable.

## Step 5 — Publish the first private app (ZTNA)
1. **Global Secure Access → Applications → Enterprise applications → + New application** (Global Secure
   Access / Private Access app).
2. **Basics:** Name `ENTGSA – PrivateApp – IntranetWeb – Pilot`; **Connector group** =
   `ENTGSA – ConnectorGroup – Datacenter`.
3. **Application segments → + Add:** enter the app's **internal FQDN or IP**, the **ports/protocols**
   (e.g. TCP 443, or 3389 for RDP), from Requirement 2.6. Add a segment per destination the app needs.
4. **Save** the application.
5. **Users and groups → + Add:** assign **`ENTGSA-Pilot`** (pilot-first — only pilot users get access).
6. Enable the **Private Access** forwarding profile: **Connect → Traffic forwarding → Private Access =
   On** (this profile now carries only the published segments' traffic).
7. If the app uses a private FQDN, configure **Private DNS / DNS suffix** on the app so clients resolve it
   through GSA (Requirement 2.7).

## Step 6 — Enable Internet Access and create the web filtering policy
1. **Global Secure Access → Connect → Traffic forwarding → Internet Access = On** (scoped by CA in
   Step 8 so only pilot users are affected).
2. **Global Secure Access → Secure → Web content filtering policies → + Create policy.**
3. **Name:** `ENTGSA – WebFilter – Baseline`. Add rules that **block** a small, uncontroversial set of
   categories for the pilot (e.g. *Malicious*, *Adult*) — start minimal to avoid breaking legitimate work.
4. **Global Secure Access → Secure → Security profiles → + Create profile.** Name
   `ENTGSA – SecurityProfile – Baseline`; **link** the `ENTGSA – WebFilter – Baseline` policy and set its
   priority. This security profile is what Conditional Access will attach in the next step.

## Step 7 — Wire Conditional Access for the Private app
1. **Entra → Protection → Conditional Access → + New policy.** Name `ENTGSA – CA – PrivateApp – Pilot`.
2. **Users:** include **`ENTGSA-Pilot`**; **exclude** your **break-glass** accounts (global requirement G4).
3. **Target resources:** **Global Secure Access → select the published app** `ENTGSA – PrivateApp –
   IntranetWeb – Pilot` (or the Private Access traffic target).
4. **Grant:** require **Multi-factor authentication** and (if devices are managed) **Require device to be
   marked as compliant**.
5. **Session:** enable **Customize continuous access evaluation** so revocation is near-real-time.
6. **Enable policy:** **Report-only** first. Create.

## Step 8 — Wire Conditional Access for Internet/Microsoft traffic + the security profile
1. **+ New policy.** Name `ENTGSA – CA – InternetAccess – Pilot`.
2. **Users:** include **`ENTGSA-Pilot`**; **exclude break-glass**.
3. **Target resources:** **Global Secure Access → Internet traffic** (and **Microsoft traffic** if you
   want to require compliant-network for M365).
4. **Session → Use Global Secure Access security profile →** select `ENTGSA – SecurityProfile – Baseline`
   so the web filtering is enforced for pilot users' internet traffic.
5. **Grant:** require **MFA** / **compliant device** as your standard dictates.
6. **Enable policy: Report-only** first. Create.
7. Review both policies' **report-only** impact (Entra → **Conditional Access → Insights**), then switch
   each to **On** once the pilot confirms no legitimate access is blocked.

## Step 9 — Turn on GSA traffic logging
1. **Global Secure Access → Monitor → (or Entra → Diagnostic settings for Global Secure Access)** →
   **+ Add diagnostic setting**. Name `ENTGSA – Diag – TrafficLogs`.
2. Select the GSA log categories (enriched network traffic / Microsoft 365 traffic logs) and **send to
   Log Analytics workspace** (Requirement 2.8).
3. Run **`ENTGSA-Report.ps1`** after some pilot activity — it runs the KQL and should return traffic rows.

## Step 10 — Validate the pilot (the gates)
Run **`ENTGSA-Validate.ps1`** and confirm on `ENTGSA-Pilot` (see §5 for the full matrix):
- **G1 Microsoft traffic** — client shows Microsoft channel active; M365 traffic is tunneled.
- **G2 Private app, no VPN** — with the **VPN disconnected**, a pilot user reaches
  `ENTGSA – PrivateApp – IntranetWeb – Pilot` via its FQDN, and **cannot** reach other internal hosts.
- **G3 Internet filtering** — a blocked category is blocked; normal sites work.
- **G4 Conditional Access + CAE** — access requires MFA/compliant device; revoking the session cuts access.

**Pass** = all four gates green. **Fail** = fix before expanding (see §6).

## Step 11 — Expand in waves (retire the VPN app-by-app)
1. **Expand the client fleet** — deploy the GSA client to more device groups via Intune, one wave at a time.
2. **Publish more private apps** using the same convention (`ENTGSA – PrivateApp – <App> – Prod`) and,
   as each is proven, **remove that app's VPN route** — retiring the VPN incrementally.
3. **Broaden CA scope** from `ENTGSA-Pilot` to the intended population; switch both policies from
   **Report-only** to **On**.
4. **Tighten web filtering** — add categories/FQDNs to `ENTGSA – WebFilter – Baseline` in measured steps,
   watching the logs for false blocks.
5. Re-run **`ENTGSA-Validate.ps1`** and **`ENTGSA-Report.ps1`** after each wave to capture evidence.

> **Rollback (any step):** disable rather than delete. Turn a **forwarding profile Off** (Connect →
> Traffic forwarding) to stop capturing that traffic class; set a **CA policy to Report-only** or Off; set
> a published app's users back to `ENTGSA-Pilot`; **stop** the connector service to fail Private Access
> back to the VPN. Keep the **VPN available** for every app until its Private Access path is validated.
> Break-glass accounts are excluded from all GSA CA policies so an edge/CA fault never locks out admins.

---
### Order of operations
`Assess (Discovery) → activate + Microsoft profile → client to pilot → connectors + group → publish
private app → Internet Access + web filter + security profile → CA (private) → CA (internet) → traffic
logging → validate the 4 gates → expand + retire VPN in waves`
