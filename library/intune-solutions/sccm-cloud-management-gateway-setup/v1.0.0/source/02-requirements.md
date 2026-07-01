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
