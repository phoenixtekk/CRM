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
