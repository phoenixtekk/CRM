# Configuration Manager Cloud Management Gateway (CMG) Setup & Operations

> **Version 1.0.0** · Category: Intune Solutions · Solution code: CMG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Configuration Manager Cloud Management Gateway (CMG)

Intune Solutions

Your laptops left the building and never came back. Remote and hybrid Windows devices that used to
sit on the LAN now rarely touch the corporate network, so Configuration Manager can't reach them:
policy goes stale, software updates stall, inventory goes dark, and you can't tell a healthy device
from a dead one. A Cloud Management Gateway (CMG) fixes that — an Azure-hosted front door that lets
Configuration Manager manage internet-based clients securely, with no VPN and no inbound firewall
holes.

This is a complete, deploy-it-today package for standing up a CMG against your Configuration Manager
current branch site, written for an administrator with no prior CMG experience.

## What you get
- A plain-language Solution Overview of how a CMG works, the CMG plus connection point design, and
  token vs. PKI authentication.
- A Requirements Guide with verify / implement-if-missing for every prerequisite — supported site
  version, Azure subscription, Entra app registrations, the server authentication certificate, the
  client auth model, Enhanced HTTP, and content design.
- An Implementation Guide of precise, ordered steps: Azure onboarding, creating the CMG cloud service,
  adding the connection point, enabling the management point and software update point for CMG
  traffic, and configuring clients for cloud management.
- Five PowerShell scripts for environment-readiness discovery, CMG/client connectivity validation, an
  internet-client health and reach report, safe client remediation, and a cloud-management settings
  helper.
- Testing and Troubleshooting guides with explicit pass/fail gates.

## What this delivers
A secure Azure front door — the `CMG – Internet Clients – Pilot` cloud service plus a CMG connection
point — that relays management traffic from internet clients to your on-premises management point and
software update point, authenticated by Microsoft Entra ID token or PKI, with no VPN and no inbound
firewall holes.

## The deployment model
Assess → Configure → Pilot → Validate → Expand.

## Outcome
Internet-based Windows clients fully manageable from Configuration Manager — receiving policy,
software updates, and inventory over a secure Azure front door — deployable by a single administrator
and proven on a pilot before you scale.


---


# 1. Solution Overview — Configuration Manager Cloud Management Gateway (CMG)

## What a Cloud Management Gateway is
A Cloud Management Gateway (CMG) is a service you deploy in Microsoft Azure that lets Configuration
Manager (Microsoft Endpoint Configuration Manager / SCCM current branch) manage Windows clients
that are on the internet — laptops that left the LAN and rarely come back. The CMG is a secure
front door: clients on the internet authenticate to it, and it forwards their management traffic to
your on-premises Configuration Manager site through a companion component called the CMG connection
point. No VPN is required, and no inbound firewall holes are opened to your site — all traffic is
outbound from the client to Azure and outbound from your site server to Azure.

## How it works
1. A `CMG – Internet Clients – Pilot` cloud service is deployed in your Azure subscription. It is the
   public endpoint internet clients reach (an Azure cloud service, fronted by a DNS name and a server
   authentication certificate).
2. A CMG connection point site system role inside your Configuration Manager site connects outbound to
   the CMG and relays client traffic to the management point (MP) and software update point (SUP).
3. Internet clients authenticate using either Microsoft Entra ID (Azure AD) token-based authentication
   (the modern default, no client PKI certificate needed) or PKI client authentication certificates.
4. The management point and software update point are configured to allow CMG traffic, so internet
   clients receive policy, send hardware/software inventory, run software deployments, and get
   software updates.
5. Clients are told they may use the CMG through the `Cloud Services` client settings, and you assign
   them to a pilot collection first (`CMG – Internet Clients – Pilot`) before expanding.
6. CMG health, client reach, and traffic are monitored in the Configuration Manager console and the
   Azure portal.

## Token vs. PKI authentication (pick one model)
- Microsoft Entra ID token authentication (recommended): clients that are Entra-joined or
  hybrid-Entra-joined authenticate with a token. This avoids issuing and managing client PKI
  certificates. It requires the site to be onboarded to Azure AD (Cloud Management) and clients to be
  Entra-registered.
- PKI client authentication: clients present a client authentication certificate issued by your
  internal CA. Use this when devices are not Entra-joined. It requires distributing client
  certificates and trusting your CA chain.
- Either way, the CMG itself always needs a server authentication certificate that internet clients
  trust (commonly a public certificate matching the CMG DNS name).

## What you can control
- Which clients may use the CMG (via `Cloud Services` client settings and collection scoping).
- Authentication model (Entra token and/or PKI client certificates).
- Whether the management point and software update point allow CMG traffic.
- Content delivery to internet clients (CMG can act as a cloud distribution point / serve content).
- Capacity (number of CMG virtual machine instances) and cost.

## Benefits
- Reach — internet-based clients receive policy, updates, inventory, and deployments with no VPN.
- Security — no inbound firewall ports to your site; traffic is outbound to Azure, authenticated by
  token or PKI, and TLS-encrypted.
- Visibility — devices that used to go dark off-LAN report health and inventory again.
- Coexistence — works alongside on-premises management points and distribution points, and alongside
  co-management with Microsoft Intune.

## Limitations (be honest with buyers)
- A CMG runs in Azure and incurs ongoing Azure cost (compute, storage, egress) that you must budget.
- It requires a supported Configuration Manager current branch version and an Azure subscription you
  control.
- The CMG server authentication certificate (and, for PKI auth, client certificates) is real
  certificate work — your CA/PKI team is involved.
- A CMG manages Configuration Manager clients; it is not a replacement for Intune. In co-managed
  environments, decide which authority owns each workload.

## The standard deployment model
> Onboard Azure → create the `CMG – Internet Clients – Pilot` cloud service → add the CMG connection
> point → enable the MP and SUP for CMG → configure clients for cloud management → pilot → validate →
> expand. The repeatable model: Assess → Configure → Pilot → Validate → Expand.


---


# 2. Requirements Guide — Configuration Manager Cloud Management Gateway (CMG)

Verify every requirement before configuring. Each entry: Description · Why required · How to verify ·
How to implement if missing. Category-wide prerequisites are in
`global-requirements-intune-solutions.md`.

## 2.1 Supported Configuration Manager current branch
Description: A supported Configuration Manager current branch site (CMG support and the VM-scale-set
CMG model require a current, in-support build).
Why required: Older builds either lack CMG or use the retired classic cloud-service model.
How to verify: Configuration Manager console → Administration → Site Configuration → Sites → your
site → Properties shows the version; or run `CMG-Discovery.ps1`.
How to implement if missing: Update Configuration Manager to a supported current branch via
Administration → Updates and Servicing before proceeding.

## 2.2 Azure subscription you control
Description: An Azure subscription in the same Microsoft Entra ID tenant, where the
`CMG – Internet Clients – Pilot` cloud service will be deployed.
Why required: The CMG runs as a service in Azure and bills to this subscription.
How to verify: Sign in to `https://portal.azure.com`; confirm an active subscription and the Owner /
Contributor rights needed to create resources.
How to implement if missing: Create or obtain an Azure subscription in your tenant and grant the
deploying account Contributor on the target resource group.

## 2.3 Azure services onboarding (Cloud Management Azure service + app registrations)
Description: Configuration Manager onboarded to Azure with the Cloud Management Azure service, which
creates two Microsoft Entra app registrations: a web app (server) and a native client app.
Name them `CMG – Cloud Management – Server App` and `CMG – Cloud Management – Client App`.
Why required: These app registrations let the site authenticate to Azure and let clients obtain
Entra ID tokens for token-based CMG authentication.
How to verify: Console → Administration → Cloud Services → Azure Services lists a Cloud Management
service; Entra → `https://entra.microsoft.com` → App registrations shows both apps. Run
`CMG-Discovery.ps1` to report onboarding state.
How to implement if missing: Console → Administration → Cloud Services → Azure Services → Configure
Azure Services → choose Cloud Management → create/import the server and client apps using the names
above.

## 2.4 CMG server authentication certificate
Description: A server authentication certificate whose subject/SAN matches the CMG DNS name
(for example `CMG.contoso.com`), trusted by internet clients. Use the subject name
`CMG – Internet Clients – Server Auth`.
Why required: Internet clients establish TLS to the CMG using this certificate; an untrusted or
mismatched certificate breaks all CMG connectivity.
How to verify: Confirm the certificate is exportable with its private key (PFX) and that its name
matches the planned CMG DNS name; check the expiry. Run `CMG-Validation.ps1` to test the public
endpoint once deployed.
How to implement if missing: Request the certificate from a public CA (recommended for a public DNS
name) or from your internal CA if clients trust that chain. Defer CA-specific steps to your CA/PKI
team; you need a PFX with the private key and the correct subject/SAN.

## 2.5 Public DNS name (CNAME) for the CMG
Description: A public DNS CNAME (for example `CMG.contoso.com`) that you will point at the Azure CMG
service endpoint, matching the server certificate subject.
Why required: Clients must resolve and reach the CMG by the certificate's name.
How to verify: Confirm you can create the public DNS record in your external DNS zone.
How to implement if missing: Have your DNS team prepare to create the CNAME; the exact target value is
shown by Configuration Manager after the CMG is provisioned.

## 2.6 Client authentication model (Entra token or PKI)
Description: Decide and verify how internet clients authenticate — Microsoft Entra ID token
(default; requires Entra-joined / hybrid-joined, Entra-registered clients) or PKI client
authentication certificates (subject name `CMG – Internet Clients – Client Auth`).
Why required: Clients cannot use the CMG without a working authentication method.
How to verify: For token: Entra → Devices shows the device joined/registered; for PKI: the client
holds a valid client authentication certificate. Run `CMG-Validation.ps1` on a client.
How to implement if missing: For token, ensure Entra join/registration and that the Cloud Management
onboarding (2.3) is complete; for PKI, issue client authentication certificates from your CA (defer
issuance specifics to your CA/PKI team).

## 2.7 Enhanced HTTP or PKI on site systems
Description: The site is configured for Enhanced HTTP (e-HTTP) or full PKI so the management point can
accept token-authenticated CMG traffic securely.
Why required: Token-based CMG authentication relies on Enhanced HTTP (or PKI) at the management point.
How to verify: Console → Administration → Site Configuration → Sites → your site → Properties →
Communication Security shows HTTPS or Enhanced HTTP enabled.
How to implement if missing: Enable Enhanced HTTP (or configure PKI) on the site Communication
Security tab.

## 2.8 Outbound internet from the site server / connection point host
Description: The server hosting the CMG connection point can reach Azure over outbound HTTPS (443).
Why required: The connection point initiates an outbound connection to the CMG; no inbound ports are
opened.
How to verify: From the connection point host, confirm outbound 443 to Azure is allowed.
How to implement if missing: Allow outbound HTTPS to Azure / the CMG service endpoints through the
proxy/firewall.

## 2.9 Boundary and content design for internet clients
Description: A plan for how internet clients get content (CMG serving content as a cloud DP, or a
cloud-based / internet-facing distribution point), and the collection scoping for the pilot.
Why required: Internet clients still need software/update content; without a content path,
deployments stall.
How to verify: Console → Administration → Distribution Points and the CMG content settings; confirm a
content path for internet clients.
How to implement if missing: Enable the CMG to serve content (or stand up an appropriate internet
content source) and target the `CMG – Internet Clients – Pilot` collection first.

---
## Checklist
- [ ] Supported Configuration Manager current branch — `CMG-Discovery.ps1`
- [ ] Azure subscription with Contributor rights
- [ ] Cloud Management onboarding + `CMG – Cloud Management – Server App` / `Client App`
- [ ] `CMG – Internet Clients – Server Auth` certificate (PFX) ready
- [ ] Public DNS CNAME for the CMG name
- [ ] Client auth model chosen (Entra token or PKI `CMG – Internet Clients – Client Auth`)
- [ ] Enhanced HTTP (or PKI) enabled on site systems
- [ ] Outbound 443 to Azure from the connection point host
- [ ] Content path for internet clients + `CMG – Internet Clients – Pilot` collection


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** Phoenixtekk solution in the **Intune Solutions**
category. They are published once at the category level so individual listings stay small.
Confirm these before deploying *any* Intune solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every cloud and Intune-managed resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers all configuration, compliance, and security policies.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating policies and enrollment settings requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted Windows devices are enrolled and manageable.
**Why:** Policies only reach enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every Phoenixtekk solution is piloted before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
**Description:** Windows 10 21H2+ or Windows 11 with current updates.
**Why:** Modern Intune features assume a patched, supported OS.
**Verify:** `winver`, or Intune → device → **Hardware**.
**Implement:** Deploy **Update rings** or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

---
**The Phoenixtekk deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# 3. Implementation Guide — Configuration Manager Cloud Management Gateway (CMG)

Follow these steps in order. Work in the Configuration Manager console (Administration and Assets and
Compliance workspaces), the Azure portal (`https://portal.azure.com`), and the Microsoft Entra admin
center (`https://entra.microsoft.com`).

> Model: stand the CMG up against a small pilot collection first, prove internet clients are managed,
> then expand. Nothing reaches production before passing the pilot gate. The repeatable model:
> Assess → Configure → Pilot → Validate → Expand.

## Step 1 — Onboard Configuration Manager to Azure (Cloud Management)
1. Console → Administration → Cloud Services → Azure Services → Configure Azure Services.
2. Name the service `CMG – Cloud Management` and choose Cloud Management. Next.
3. Create (or import) the two Microsoft Entra app registrations when prompted:
   - Server app: `CMG – Cloud Management – Server App`.
   - Client app: `CMG – Cloud Management – Client App`.
4. Sign in with an account that can grant admin consent; complete the wizard. Finish.
5. In Entra (`https://entra.microsoft.com` → Identity → Applications → App registrations) confirm both
   apps exist with the names above.

## Step 2 — Create the pilot collection
1. Console → Assets and Compliance → Device Collections → Create Device Collection.
2. Name: `CMG – Internet Clients – Pilot`. Limiting collection: All Systems (or your standard
   limiting collection). Next.
3. Add a few representative internet/remote devices (direct membership or a query). Complete the
   wizard.

## Step 3 — Import the CMG server authentication certificate
1. Have the `CMG – Internet Clients – Server Auth` certificate available as a PFX (with private key)
   from your CA/PKI team, matching the planned public DNS name (for example `CMG.contoso.com`).
2. Keep the PFX and its password ready; you will supply it in Step 4.

## Step 4 — Create the CMG cloud service
1. Console → Administration → Cloud Services → Cloud Management Gateway → Create Cloud Management
   Gateway.
2. Sign in to your Azure subscription when prompted (use the account with Contributor rights). Next.
3. Settings:
   - Service name (cloud service): `CMG – Internet Clients – Pilot`.
   - Region: the Azure region nearest your clients.
   - Resource group: select or create one (for example `rg-cmg-pilot`).
   - VM instances: start with 1 for the pilot.
   - Certificate file: browse to the `CMG – Internet Clients – Server Auth` PFX and enter its
     password. The CMG service name is derived from the certificate subject/SAN.
   - Leave Verify Client Certificate Revocation set per your environment (clear it only if you have no
     CRL path for client certs; confirm with your CA/PKI team).
4. Next through the remaining pages, accept the cost notice, and Create.
5. Wait until Administration → Cloud Services → Cloud Management Gateway shows the service status
   Ready (provisioning takes several minutes). Run `CMG-Validation.ps1` to confirm the public endpoint
   responds.

## Step 5 — Create the public DNS CNAME
1. In Azure / the CMG properties, note the CMG service endpoint (the `*.cloudapp.azure.com` target).
2. Have your DNS team create the public CNAME (for example `CMG.contoso.com`) pointing at that target,
   matching the certificate subject from Step 3.
3. Confirm the name resolves publicly before continuing.

## Step 6 — Add the CMG connection point
1. Console → Administration → Site Configuration → Servers and Site System Roles.
2. Select the site system server that will host the role (must have outbound 443 to Azure) → Add Site
   System Roles.
3. Choose Cloud Management Gateway connection point. Select the `CMG – Internet Clients – Pilot`
   gateway you created. Complete the wizard.
4. Confirm the role installs (check `CMGConnector` status in the console and monitoring logs).

## Step 7 — Enable the management point and software update point for CMG traffic
1. Console → Administration → Site Configuration → Servers and Site System Roles → select the
   management point role → Properties → enable Allow Configuration Manager cloud management gateway
   traffic. OK.
2. Repeat for the software update point role: Properties → enable Allow Configuration Manager cloud
   management gateway traffic. OK.

## Step 8 — Configure clients for cloud management
1. Console → Administration → Client Settings → create a custom client settings object named
   `CMG – Internet Clients – Client Settings`.
2. Open the Cloud Services page and set:
   - Allow access to cloud distribution point: Yes (if the CMG serves content).
   - Automatically register new Windows 10 (and later) domain joined devices with Microsoft Entra ID:
     Yes (required for hybrid token authentication).
   - Enable clients to use a cloud management gateway: Yes.
3. Deploy these client settings to the `CMG – Internet Clients – Pilot` collection. OK.

## Step 9 — Apply on a pilot client
1. On a pilot internet client, open the Configuration Manager control panel applet → Actions → run
   Machine Policy Retrieval & Evaluation Cycle.
2. Confirm the client picked up the cloud management gateway internet management point. Run
   `CMG-Validation.ps1` on the client to confirm it can reach the CMG and authenticate.

## Step 10 — Validate the pilot (gate)
1. Run `CMG-Report.ps1` to list internet clients, their last policy/inventory time, and CMG health.
2. Confirm pilot clients receive policy, return inventory, and can install a deployed application or
   update over the CMG. Complete the Testing Guide.
3. Do not expand until the pilot passes the gate in the Testing Guide.

## Step 11 — Expand to production
1. Increase CMG VM instances if capacity requires it (Cloud Management Gateway → Properties).
2. Deploy the `CMG – Internet Clients – Client Settings` to your broader internet-client collection.
3. Re-validate with `CMG-Report.ps1` after each wave; keep the pilot collection for future change
   testing.

---
### Order of operations
`Azure onboarding → pilot collection → server cert → CMG cloud service → public DNS → connection point
→ MP + SUP for CMG → client settings → apply → validate (gate) → expand`


---


# 5. Testing Guide — Configuration Manager Cloud Management Gateway (CMG)

Run after the CMG and connection point are in place (Implementation Step 10) and again after each
expansion wave.

## Test 1 — CMG service is Ready
Do: Console → Administration → Cloud Services → Cloud Management Gateway → check the
`CMG – Internet Clients – Pilot` service.
Expected: Status shows Ready (green); no provisioning or certificate errors.

## Test 2 — Connection point is healthy
Do: Console → Administration → Cloud Services → Cloud Management Gateway → Connection Analyzer (or
review the CMG connection point status).
Expected: The connection point connects outbound to the CMG; the analyzer reports the channel and the
management/SUP endpoints reachable.

## Test 3 — Public endpoint and certificate
Do: From an internet host run `CMG-Validation.ps1` (or browse the CMG name).
Expected: The CMG DNS name resolves, TLS succeeds against the `CMG – Internet Clients – Server Auth`
certificate, and the certificate is valid and not expired.

## Test 4 — Client uses the CMG
Do: On a pilot internet client run `CMG-Validation.ps1`, or check the Configuration Manager control
panel applet → Network shows an internet/CMG management point.
Expected: The client reports an internet-facing management point and authenticates (token or PKI).

## Test 5 — Policy and inventory flow
Do: On a pilot client trigger Machine Policy Retrieval and a Hardware Inventory Cycle; then run
`CMG-Report.ps1`.
Expected: The client's last policy and last inventory times update within the report; the device is no
longer dark.

## Test 6 — Content / deployment over the CMG
Do: Deploy a small required application or a software update to `CMG – Internet Clients – Pilot`.
Expected: The pilot internet client downloads content via the CMG (or configured internet content
source) and installs successfully.

## Test 7 — Fleet report
Do: Run `CMG-Report.ps1`.
Expected: A clear list of internet clients with CMG reachability, last policy/inventory time, and
overall CMG health.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–6 pass for `CMG – Internet Clients – Pilot`; a deployment installs over the CMG |
| Expand pass | Tests 1–5 and 7 pass for each new wave before widening client settings |


---


# 6. Troubleshooting Guide — Configuration Manager Cloud Management Gateway (CMG)

Use `CMG-Discovery.ps1` for environment readiness and `CMG-Validation.ps1` for endpoint/client state,
`CMG-Report.ps1` for internet-client health, and `CMG-Remediation.ps1` for safe client fixes.

## A. CMG service won't reach Ready
| Symptom | Cause | Remediation |
|---|---|---|
| Cloud Management Gateway stuck Provisioning / Error | Wrong certificate, bad PFX password, or Azure rights | Re-check the `CMG – Internet Clients – Server Auth` PFX and password; confirm Contributor on the resource group; recreate the service |
| Certificate name mismatch | CMG service name (from cert subject) ≠ planned DNS name | Reissue the cert with the correct subject/SAN, or align the DNS CNAME to the cert name |

## B. Connection point unhealthy
| Symptom | Cause | Remediation |
|---|---|---|
| Connection Analyzer fails to reach the CMG | Outbound 443 to Azure blocked from the connection point host | Allow outbound HTTPS to Azure / the CMG endpoints; re-run the analyzer |
| MP/SUP not reachable through the channel | MP/SUP not enabled for CMG traffic | Enable "Allow Configuration Manager cloud management gateway traffic" on the MP and SUP roles (Implementation Step 7) |

## C. Client won't use the CMG
| Symptom | Cause | Remediation |
|---|---|---|
| Client shows no internet management point | Cloud-management client settings not applied | Confirm `CMG – Internet Clients – Client Settings` is deployed to the client's collection; run a Machine Policy cycle or `CMG-Remediation.ps1` |
| Client reaches CMG but is rejected | Authentication failing (token or PKI) | For token: confirm Entra join/registration and Cloud Management onboarding; for PKI: confirm a valid client auth cert and CRL reachability |

## D. Authentication / Enhanced HTTP issues
- Token authentication requires Enhanced HTTP (or PKI) on the site systems; if the MP isn't accepting
  token traffic, verify Enhanced HTTP is enabled (Communication Security) and the Cloud Management
  onboarding (server/client app registrations) is complete and consented.

## E. Content / deployments stall over the internet
- Internet clients with no content path cannot install deployments. Enable the CMG to serve content
  (or provide another internet content source) and confirm the deployment targets the internet client
  collection.

## F. Certificate expiry (silent outage)
- An expired `CMG – Internet Clients – Server Auth` certificate breaks all internet management with no
  warning. Track expiry; renew and re-upload the PFX to the CMG ahead of time with your CA/PKI team.

## G. Diagnostics quick reference
```powershell
# Site / role readiness (run on the site server with the ConfigMgr console installed)
Import-Module "$env:SMS_ADMIN_UI_PATH\..\ConfigurationManager.psd1"
Get-CMCloudManagementGateway | Select Name, State, ServiceStatus
Get-CMCloudManagementGatewayConnectionPoint | Select SiteCode, NetworkOSPath

# Public endpoint reachability (run from an internet host)
Test-NetConnection -ComputerName 'CMG.contoso.com' -Port 443

# On a client: ConfigMgr client log locations
# CcmExec.log, ClientLocation.log, CMGHttpHandler.log under C:\Windows\CCM\Logs
```

## H. When to escalate
If the CMG is Ready, the connection point passes the analyzer, the MP/SUP are enabled for CMG, the
client has the cloud-management settings and a valid auth method, and clients still cannot be managed,
collect the client logs above plus the CMG service logs and open a Microsoft support case.


---


# 7. Best Practices — Configuration Manager Cloud Management Gateway (CMG)

- Pilot first, always. Stand the CMG up against `CMG – Internet Clients – Pilot` and prove policy,
  inventory, and a real deployment over the internet before widening client settings — this is the
  single most important practice.
- Prefer Microsoft Entra ID token authentication. For Entra-joined / hybrid-joined fleets, token auth
  avoids issuing and managing client PKI certificates; reserve PKI client auth for devices that cannot
  be Entra-registered.
- Name the CMG by its certificate. The CMG service name comes from the
  `CMG – Internet Clients – Server Auth` certificate subject/SAN; match the public DNS CNAME to it
  exactly, or clients cannot connect.
- Watch certificate expiry. The server authentication certificate expiring silently breaks all
  internet management; track the expiry and renew ahead of time with your CA/PKI team.
- Keep it outbound-only. Never open inbound firewall ports to the site for CMG; all traffic is
  outbound from clients to Azure and from the connection point to Azure.
- Enable Enhanced HTTP. For token-based auth, Enhanced HTTP on the site systems is the clean path;
  use full PKI only where your environment already requires it.
- Right-size CMG instances. Start at one VM instance for the pilot and scale instances only as real
  internet-client load and content demand require — Azure cost scales with instances and egress.
- Plan the content path. Decide up front whether the CMG serves content or you use another internet
  content source, so internet deployments do not stall.
- Coexist deliberately. Alongside co-management with Microsoft Intune, decide which authority owns
  each workload so the two do not conflict.
- Monitor continuously. Use the Connection Analyzer and `CMG-Report.ps1` each cycle to catch a dark
  client, an unhealthy connection point, or an aging certificate early.
- Document the build. Record the CMG name, region, resource group, certificate subject/expiry, auth
  model, and assigned collections for audits and repeatability.


---


# 8. Deliverables Summary — Configuration Manager Cloud Management Gateway (CMG)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What a CMG is, the CMG + connection point design, token vs. PKI auth, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: Azure onboarding, CMG service, connection point, MP/SUP, client settings |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `CMG-Discovery.ps1` | Reports environment readiness: site version, Azure/Cloud Management onboarding, CMG roles, Enhanced HTTP (read-only) |
| `CMG-Validation.ps1` | Tests CMG public endpoint, certificate, and a client's ability to reach/authenticate to the CMG (read-only) |
| `CMG-Report.ps1` | Internet-client health and reach report: last policy/inventory time and CMG health (read-only) |
| `CMG-Remediation.ps1` | Safe remediation of misconfigured clients (policy/USO triggers, cloud settings); defaults to -WhatIf |
| `CMG-Set-CloudManagementTargeting.ps1` | Cloud-management settings helper: scopes the cloud-management client settings to a collection; defaults to -WhatIf |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the model: Assess → Configure → Pilot → Validate → Expand.

## Outcome
Internet-based Windows clients fully manageable from Configuration Manager — receiving policy,
software updates, and inventory over a secure Azure front door — proven on a pilot before you scale.
