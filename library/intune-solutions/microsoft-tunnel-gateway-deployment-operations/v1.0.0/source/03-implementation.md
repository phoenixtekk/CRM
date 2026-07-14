# 3. Implementation Guide — Microsoft Tunnel Gateway: Deployment, VPN Configuration & Ongoing Operations

Follow these steps **in order**. Control-plane steps are in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`); host steps run on the **Linux gateway server** as root/sudo. Build
the control-plane configuration **first**, then install the server so it joins a Site that already has
a Server Configuration waiting for it.

> **Model:** Groups → Site → Server Configuration → assign config to Site → install the Linux gateway
> (TLS cert + register) → deploy the Defender client app → per-platform VPN connection profiles →
> report-only Conditional Access → Pilot gate → Expand (add HA servers, enforce CA). Pattern:
> **Assess → Configure → Pilot → Validate → Expand.**

> **Portal paths and object names drift.** Menu labels and some settings change over time and by cloud
> (Commercial vs Government). Where a value could change it is flagged **[verify current Microsoft
> guidance]**. Confirm the exact wording in your tenant as you go.

## Step 0 — Assess (run the prerequisite check first)
1. On the Linux host, copy and run `TUNGW-HostPrereqCheck.sh` (read-only). It reports the distribution,
   kernel, container runtime, IP-forwarding readiness, the TLS cert files + expiry, inbound listener
   port, and outbound reachability to Microsoft endpoints and to a sample internal resource.
2. From the admin workstation, run `TUNGW-Discovery.ps1` (read-only) to inventory any existing Tunnel
   Sites, Server Configurations, and VPN profiles so you do not collide with them.
3. Resolve every failed check before continuing (see the Requirements Guide).

## Step 1 — Create the device groups
1. Entra → **Groups → New group → Security** → name `Tunnel Devices – Pilot` (a few representative
   iOS/Android devices or their users). **Create**.
2. Create `Tunnel Devices – Broad` (the rest of the target fleet). **Create**.

## Step 2 — Create the Site
The Site is the logical unit clients point at by FQDN; servers join a Site.
1. Intune → **Tenant administration → Microsoft Tunnel Gateway** → **Create site** (or **Sites → Create**).
   **[verify current Microsoft guidance]** on the exact menu label.
2. **Name:** `Tunnel Site – HQ – Prod`.
3. **Public IP address or FQDN:** `tunnel.contoso.com` — the name clients will connect to (or the
   load-balancer VIP FQDN for HA).
4. Leave **Server configuration** unset for now (you assign it in Step 3b) or select it after Step 3a.
   **Save / Create.**

## Step 3a — Create the Server Configuration
This holds the routing and network settings every server in the Site inherits.
1. Intune → **Tenant administration → Microsoft Tunnel Gateway → Server configurations → Create**.
2. **Name:** `Tunnel Server Config – Split Tunnel – Prod`.
3. **Connection type / routing:** choose **Split tunnel** (recommended). Configure:
   - **IP address range (client address pool):** the private CIDR the gateway hands to connected
     clients (must not overlap your internal ranges), e.g. `169.254.0.0/16` or a reserved private
     range you own. **[verify current Microsoft guidance]** on defaults/limits.
   - **Server port (listener):** the inbound TLS port, default **443** (change only if 443 is taken;
     it must match the firewall rule and the client profile). **[verify current Microsoft guidance]**.
   - **DNS servers:** the internal DNS server IPs clients should use while connected.
   - **DNS suffix search** (optional): your internal domain suffix, e.g. `corp.contoso.com`.
   - **Include routes (split tunnel):** the internal CIDR ranges that SHOULD go through the Tunnel,
     e.g. `10.0.0.0/8`, `172.16.0.0/12`. Only these are tunneled; everything else goes direct.
   - **Exclude routes** (optional): subnets inside the include ranges that should NOT be tunneled.
   - *(Full tunnel alternative:* set the configuration to route **all** traffic through the Tunnel —
     use only if policy requires all egress via corporate; expect higher gateway load.)*
4. **(Optional) Automatic server upgrades:** if you want servers to self-update, enable the automatic
   upgrade option and set the maintenance window. **[verify current Microsoft guidance]** — leave off
   for a controlled first rollout; enable later for fleet operations.
5. **Save / Create.**

## Step 3b — Assign the Server Configuration to the Site
1. Open `Tunnel Site – HQ – Prod` → set **Server configuration** = `Tunnel Server Config – Split Tunnel
   – Prod`. **Save.**
The Site now has routing waiting for the first server.

## Step 4 — Install the Tunnel Gateway on the Linux host
Run on the Linux server as root/sudo. **[verify current Microsoft guidance]** for the current download
URL, script name, and cert file layout — these change.
1. **Place the TLS certificate files** where the installer expects them (commonly a setup directory
   for the full-chain certificate `.pem`/`.crt` and the private key). Confirm ownership/permissions are
   restrictive.
2. **Download and run the Microsoft Tunnel install script** (historically retrieved from the Microsoft
   Tunnel download URL, e.g. `mstunnel-setup`), as root. The script pulls the container image into your
   Podman/Docker runtime and steps through setup.
3. **Provide the requested inputs** during setup: the TLS certificate + key + chain, the Site the
   server should join (`Tunnel Site – HQ – Prod`), and the listener port if not default.
4. **Register the server with Intune:** when prompted, sign in with an account that has the required
   Intune role (Intune Administrator or the delegated Tunnel role) to enroll the server into the Site.
5. **Confirm the service is running:** the host runs a Tunnel service (e.g. a `systemd` unit) and the
   management CLI (`mst-cli`). Run `mst-cli server show` / the health command to confirm the server is
   up and connected. Run `TUNGW-HealthCheck.sh` for a consolidated status.
6. In Intune → **Microsoft Tunnel Gateway → Health status / Servers**, confirm the new server appears
   under `Tunnel Site – HQ – Prod` and reports **healthy**.

## Step 5 — Deploy the Microsoft Defender for Endpoint client app (mobile)
1. Intune → **Apps → All apps → Add** → add **Microsoft Defender for Endpoint** for **iOS/iPadOS** and
   for **Android**. **[verify current Microsoft guidance]** on the current Tunnel client app.
2. **Assign** each to `Tunnel Devices – Pilot`. Wait until pilot devices report the app installed —
   the VPN profile needs the client present to connect.

## Step 6 — Create the per-platform VPN connection profiles
Create one profile per platform, all pointing at `Tunnel Site – HQ – Prod`. Assign each to
`Tunnel Devices – Pilot` first.

### Step 6a — iOS/iPadOS (natively supported)
1. Intune → **Devices → Configuration → Create → New policy**.
2. **Platform:** iOS/iPadOS. **Profile type:** **Templates → VPN**. **Create**.
3. **Name:** `Tunnel VPN – iOS – Pilot`.
4. **Connection type:** **Microsoft Tunnel**. **[verify current Microsoft guidance]** on the label.
5. **Base VPN:** select the Tunnel **Site** = `Tunnel Site – HQ – Prod`; set the **connection name**
   users see; set **authentication** = the method chosen in Requirements (Entra, or the client
   certificate `Tunnel Client Cert – SCEP – Pilot`).
6. **(Optional) Per-app VPN / On-demand:** to scope the Tunnel to specific apps, configure **per-app
   VPN** and associate the target apps; set **on-demand rules** if the Tunnel should connect
   automatically for internal domains.
7. **Assignments → Add groups →** `Tunnel Devices – Pilot`. **Next → Create.**

### Step 6b — Android (natively supported)
1. **Devices → Configuration → Create → New policy** → **Platform:** Android Enterprise → **Profile
   type:** **VPN**. **Create**.
2. **Name:** `Tunnel VPN – Android – Pilot`.
3. **Connection type:** **Microsoft Tunnel**; **Base VPN → Site** = `Tunnel Site – HQ – Prod`; set the
   connection name and authentication method.
4. **(Optional) Per-app VPN:** associate the apps that should trigger the Tunnel.
5. **Assignments →** `Tunnel Devices – Pilot`. **Next → Create.**

### Step 6c — Windows (verify support first)
> **Before creating this profile, confirm Windows is currently a supported Microsoft Tunnel client**
> for your tenant/cloud. **[verify current Microsoft guidance]** — native device-Tunnel client support
> has centered on iOS/Android; do not promise Windows Tunnel connectivity until verified.
1. If (and only if) supported: **Devices → Configuration → Create → New policy** → **Platform:**
   Windows 10 and later → **Profile type:** **Templates → VPN** (or the current Tunnel-capable VPN
   type). **Create**.
2. **Name:** `Tunnel VPN – Windows – Pilot`. Select the **Microsoft Tunnel** connection type / Site
   `Tunnel Site – HQ – Prod` if offered, set authentication, and assign to `Tunnel Devices – Pilot`.
3. If native Tunnel support is **not** available for Windows, do **not** fabricate a profile — see
   Best Practices → "Where to go next" for the adjacent approach, and record the gap.

### Step 6d — macOS (verify support first)
> **Same caveat as Windows.** **[verify current Microsoft guidance]** on macOS device-Tunnel client
> support before creating this profile.
1. If supported: **Devices → Configuration → Create → New policy** → **Platform:** macOS → **Profile
   type:** **VPN** (Tunnel-capable type) → **Name:** `Tunnel VPN – macOS – Pilot`; Site
   `Tunnel Site – HQ – Prod`; authentication; assign to `Tunnel Devices – Pilot`.
2. If unsupported, record the gap and use the adjacent approach in Best Practices — do not invent a
   capability.

## Step 7 — Conditional Access (report-only first)
Gate the Tunnel so only compliant devices connect — but start in **report-only** so you never lock out
your pilot.
1. Entra → **Security → Conditional Access → Policies → New policy**.
2. **Name:** `Tunnel Access – Compliant Devices – Report-Only`.
3. **Users:** the pilot users/group. **Target resources:** the app(s) the Tunnel fronts, per your
   design. **Grant:** **Require device to be marked as compliant** (and/or require MFA per policy).
4. **Enable policy:** **Report-only.** **Create.**
5. Review report-only results (Entra → **Monitoring → Sign-in logs → Report-only** tab) before you
   move it to **On** at Expand.

## Step 8 — Apply on a pilot device and validate
1. On a pilot iOS/Android device with the Defender app installed, force an Intune sync and open the
   Defender/Tunnel client; initiate the VPN connection defined by `Tunnel VPN – iOS – Pilot` /
   `Tunnel VPN – Android – Pilot`.
2. Confirm the VPN connects, DNS resolves internal names, and you can reach a resource inside an
   **include route** (and, for split tunnel, that non-included traffic goes direct).
3. Run `TUNGW-Validate.ps1` for the device and `TUNGW-HealthCheck.sh` on the server. Complete the
   **Testing Guide**.

## Step 9 — Pilot gate
Do not expand until, on `Tunnel Devices – Pilot`: the VPN profile shows **Succeeded**; the client
connects; an internal include-route resource is reachable; split-tunnel routing behaves as configured;
the server reports **healthy**; and report-only Conditional Access shows the expected result with no
unexpected blocks. **Rollback:** unassign the VPN profiles from `Tunnel Devices – Pilot` (devices drop
the profile at next sync); the gateway keeps running with no client impact.

## Step 10 — Expand to production
1. Add `Tunnel Devices – Broad` to each validated VPN profile (or clone to `– Broad` names).
2. **Add HA servers:** install one or more additional Tunnel servers into `Tunnel Site – HQ – Prod`
   (repeat Step 4 on each host), place them behind the **L4/TCP passthrough** load balancer, and point
   the Site FQDN at the VIP. Validate each server reports healthy with `TUNGW-HealthCheck.sh`.
3. **Move Conditional Access to On:** after report-only looks clean, switch
   `Tunnel Access – Compliant Devices – Report-Only` to **On** (consider renaming to `– Enforced`).
4. Run `TUNGW-Report.ps1` for fleet profile + server-health status.

---
### Order of operations
`Assess (prereq check + discovery) → Groups → Site → Server Configuration → assign config to Site →
install gateway (TLS + register) → Defender app → VPN profiles (iOS, Android, +Windows/macOS if
supported) → report-only CA → Pilot gate → Expand (HA servers + LB + enforce CA)`
