# 3. Implementation Guide — Microsoft Tunnel for MAM

Follow these steps in order. Intune steps are in the Microsoft Intune admin center
(`https://intune.microsoft.com`); the gateway install runs on the Linux host.

> Model: stand up the Tunnel Gateway on Linux, define a Server configuration and a Site, install the
> gateway/connector, then create the Tunnel (MAM) configuration and target the MAM apps. Validate one
> managed app reaching one internal resource on the pilot before you expand.

Named objects (create with these exact names and reuse them verbatim):

| Object | Name |
|---|---|
| Pilot Entra group | `Tunnel MAM Users – Pilot – Ring1` |
| Broad Entra group | `Tunnel MAM Users – Production – Broad` |
| Server configuration | `Tunnel Server Config – Intranet – Prod` |
| Site | `Tunnel Site – Intranet – Prod` |
| iOS app protection policy | `App Protection – iOS – Prod` |
| Android app protection policy | `App Protection – Android – Prod` |
| iOS Tunnel (MAM) app config | `Tunnel MAM Config – iOS – Prod` |
| Android Tunnel (MAM) app config | `Tunnel MAM Config – Android – Prod` |

## Step 1 — Create the groups
1. Entra → Groups → New group → Security → `Tunnel MAM Users – Pilot – Ring1` (a few pilot users).
   Create.
2. Create `Tunnel MAM Users – Production – Broad` (the broader population). Create.

## Step 2 — Create the Server configuration
1. Intune → Tenant administration → Microsoft Tunnel Gateway → Server configurations → Create.
2. Name: `Tunnel Server Config – Intranet – Prod`. Next.
3. IP address range: the client VPN address pool (a private subnet not colliding with your network).
4. DNS servers: your internal DNS servers. DNS suffix search: your internal domain suffix(es).
5. Split tunneling: add Include routes for only the internal subnets the apps must reach (recommended
   for MAM). Leave the rest excluded so non-internal traffic goes direct.
6. Server port: `443` (must be open inbound to the gateway). Next → Create.

## Step 3 — Create the Site
1. Intune → Tenant administration → Microsoft Tunnel Gateway → Sites → Create.
2. Name: `Tunnel Site – Intranet – Prod`.
3. Public IP address or FQDN: the public FQDN clients use (must match the TLS certificate).
4. Server configuration: select `Tunnel Server Config – Intranet – Prod`. Create.

## Step 4 — Install the Tunnel Gateway on the Linux host
1. Intune → Tenant administration → Microsoft Tunnel Gateway → Servers → Create → download the
   installation script and note the site to join (`Tunnel Site – Intranet – Prod`).
2. On the supported Linux host, stage the TLS certificate (with private key and full chain) where the
   script expects it, then run the Microsoft installation script (`mstunnel-setup`) as root. It pulls
   the gateway container (Docker/Podman) and installs the connector agent.
3. During setup, sign in with an Intune administrator when prompted (this registers the connector),
   and select the site `Tunnel Site – Intranet – Prod` so the server inherits
   `Tunnel Server Config – Intranet – Prod`.
4. After install, verify on the host with `mst-cli server show` (and `mst-cli agent info`), then in
   Intune confirm Servers shows the new server Healthy under the site.

## Step 5 — Create the iOS/Android app protection policies (if not already present)
1. Intune → Apps → App protection policies → Create policy → iOS/iPadOS.
2. Name: `App Protection – iOS – Prod`. Target the in-scope apps (include Microsoft Edge, bundle ID
   `com.microsoft.msedge`, and any LOB apps). Assign to `Tunnel MAM Users – Pilot – Ring1`. Create.
3. Repeat for Android: Create policy → Android → `App Protection – Android – Prod` (include Microsoft
   Edge, package `com.microsoft.emmx`, and LOB apps). Assign to `Tunnel MAM Users – Pilot – Ring1`.
   Create.

## Step 6 — Create the Tunnel (MAM) configuration — iOS
1. Intune → Apps → App configuration policies → Add → Managed apps.
2. Name: `Tunnel MAM Config – iOS – Prod`. Under Public apps, add the in-scope iOS apps (Microsoft
   Edge and any LOB apps).
3. In settings, enable the Microsoft Tunnel connection: select the site
   `Tunnel Site – Intranet – Prod` (and per-app VPN / connection type as prompted). Set the DNS/proxy
   values if your environment needs them.
4. Assignments → add `Tunnel MAM Users – Pilot – Ring1`. Create.

## Step 7 — Create the Tunnel (MAM) configuration — Android
1. Intune → Apps → App configuration policies → Add → Managed apps.
2. Name: `Tunnel MAM Config – Android – Prod`. Add the in-scope Android apps (Microsoft Edge and any
   LOB apps).
3. Enable the Microsoft Tunnel connection and select the site `Tunnel Site – Intranet – Prod`; set
   DNS/proxy values as needed.
4. Assignments → add `Tunnel MAM Users – Pilot – Ring1`. Create.

## Step 8 — Apply on a pilot device
1. On a pilot iOS/Android device, sign in to Microsoft Edge (or the LOB app) with the pilot user and
   complete the app-protection enrollment prompt; install the Microsoft Defender / Tunnel client if
   the platform prompts for it (Tunnel for MAM uses the tunnel client component).
2. Let policy apply, then confirm the app shows the tunnel is available (the managed app prompts to
   connect when reaching an internal route).

## Step 9 — Validate a managed app reaching an internal resource
1. In the managed app (for example Microsoft Edge), browse to an internal-only resource FQDN that is
   inside a split-tunnel Include route.
2. Confirm the page loads only in the managed app and only for the internal name — a non-managed
   browser on the same phone should not reach it.
3. Run `TUNMAM-Validation.ps1` for the Intune-side health signal and `TUNMAM-Report.ps1` for usage.
   Complete the Testing Guide.

## Step 10 — Pilot gate and expand
1. Pilot gate: only proceed if the Testing Guide passes for the pilot group (server Healthy, managed
   app reaches the internal resource, non-managed apps do not).
2. Expand: add `Tunnel MAM Users – Production – Broad` to the app protection policies and the Tunnel
   (MAM) configurations (`Tunnel MAM Config – iOS – Prod` / `Tunnel MAM Config – Android – Prod`).
3. Rollback: remove the broad group's assignment from the Tunnel (MAM) configurations to revert to
   pilot-only without deleting the gateway. Re-validate each ring with `TUNMAM-Report.ps1`.

---
### Order of operations
`Groups → Server configuration → Site → Install gateway/connector → App protection policies → Tunnel (MAM) config iOS → Tunnel (MAM) config Android → Apply → Validate → Expand`
