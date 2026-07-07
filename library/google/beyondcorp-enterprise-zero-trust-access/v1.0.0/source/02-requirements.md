# 2. Requirements — BeyondCorp Enterprise: Zero-Trust Access

This solution assumes the **six shared GCP foundation requirements** in
`global-requirements-gcp.md` are already met: a **GCP Organization** linked to Cloud Identity /
Workspace, **Organization-level administrative access**, a **Cloud Billing account**, the
**`gcloud`/IaC toolchain with API enablement**, a **resource-hierarchy/naming/pilot design**, and
**security/network/governance stakeholder engagement**. Do not re-do those here — verify them, then
satisfy the solution-specific prerequisites below before starting Implementation.

Follow the naming convention `<Purpose> – <Scope> – <Stage>` for every artifact (e.g.
`Access Level – Corp-Managed – v1`, `IAP App – Pilot`, `Pilot Group – ZeroTrust`).

---

## 2.1 Access Context Manager enabled with an access policy on the Organization
- **Description:** The **Access Context Manager** API enabled and an **organization-scoped access
  policy** in place. Access levels are children of this access policy and are referenced by both
  VPC Service Controls and IAP context-aware access.
- **Why required:** Access levels (the identity+device+context conditions this solution enforces) can
  only be created inside an access policy; without it there is nowhere to define them.
- **How to verify:** `gcloud access-context-manager policies list --organization <ORG_ID>` returns a
  policy. Confirm the Access Context Manager API is enabled
  (`gcloud services list --enabled | grep accesscontextmanager`).
- **How to implement if missing:** Enable the API
  (`gcloud services enable accesscontextmanager.googleapis.com`) and create the org access policy
  (`gcloud access-context-manager policies create --organization <ORG_ID> --title "<title>"`). Only
  one scoped access policy per organization applies to the whole org — **verify** whether one already
  exists (often created by the Landing Zone or VPC-SC solution) before creating a second.

## 2.2 A pilot web application behind a Google Cloud HTTPS load balancer
- **Description:** A **named pilot web app** (`IAP App – Pilot`) served through an **external or
  internal HTTPS load balancer** with a backend service, on a project you control. IAP for web apps is
  enabled on the load balancer's backend service.
- **Why required:** IAP for HTTPS protects apps that sit behind a Google load balancer backend service;
  the app must be in that shape before IAP can front it.
- **How to verify:** In the Console (Network services → Load balancing) confirm the HTTPS load balancer
  and backend service; the app is reachable at its URL over HTTPS.
- **How to implement if missing:** Deploy the pilot app behind an HTTPS load balancer (or App Engine,
  which IAP also supports). Exact load-balancer setup is deferred to Google's load-balancing docs;
  IAP eligibility of the specific app type should be confirmed — **verify in your organization.**

## 2.3 A pilot VM for IAP TCP forwarding (SSH)
- **Description:** A **named pilot Compute Engine VM** (`IAP VM – Pilot`) that today is reached over SSH
  (often via a bastion/VPN), which you will move to **IAP TCP forwarding**.
- **Why required:** IAP TCP forwarding is the mechanism that replaces bastion/VPN SSH access with
  context-checked, brokered connections; a target VM is needed to pilot it.
- **How to verify:** The VM exists (`gcloud compute instances list`) and you can currently SSH to it.
- **How to implement if missing:** Create a VM in the pilot project. Ensure a firewall rule allows
  ingress on the SSH port **from the IAP TCP forwarding IP range `35.235.240.0/20`** (this is the
  documented IAP forwarding range) rather than from the internet or the VPN.

## 2.4 A device-trust signal source (and its licensing)
- **Description:** A source of **device-trust signals** the access levels will test — for example
  **endpoint verification / Chrome Enterprise** device attributes, corporate-managed device status, or
  an integrated endpoint-management partner signal.
- **Why required:** The "what" in "who and what" — the device condition in an access level — needs a
  real signal to evaluate; without it access levels can only test identity and network attributes.
- **How to verify:** Confirm which signal source is available and enrolled for the pilot devices, and
  confirm the **license tier** that unlocks it (some device signals require **Chrome Enterprise
  Premium** / endpoint-verification enrollment). **Verify the exact signal source and license in your
  organization** — these are tier- and version-dependent and must not be assumed.
- **How to implement if missing:** Enroll pilot devices in the chosen signal source and provision the
  required license before building device-conditioned access levels. If no device signal is yet
  available, start with an identity + network (IP/geo) access level and add the device condition once
  the signal source is live.

## 2.5 Pilot identity group(s) and least-privilege admin roles
- **Description:** A **named pilot group** (`Pilot Group – ZeroTrust`) in Cloud Identity for the users
  who will test access, and the least-privilege admin roles needed to configure this solution:
  `roles/accesscontextmanager.policyAdmin` (manage access levels),
  `roles/iap.admin` (manage IAP settings), and the ability to set IAM on the target resources.
- **Why required:** Bindings target groups, not individuals; and configuring access levels + IAP
  requires the specific admin roles, granted narrowly rather than via broad org-admin.
- **How to verify:** The group exists and the operator holds the roles
  (`gcloud organizations get-iam-policy <ORG_ID>` / project-level `get-iam-policy`).
- **How to implement if missing:** Create the pilot group; have a super-admin grant the named roles
  under change control.

## 2.6 IAP and required APIs enabled on target projects
- **Description:** The **Identity-Aware Proxy API** (`iap.googleapis.com`) and Compute Engine API
  enabled on the projects hosting the pilot app and VM, plus the OAuth consent/brand configured for IAP
  where required for web apps.
- **Why required:** IAP cannot be turned on for a resource until its API is enabled; web IAP requires an
  OAuth brand/consent screen on the project.
- **How to verify:** `gcloud services list --enabled` shows `iap.googleapis.com`; in the Console the
  IAP page loads for the project.
- **How to implement if missing:** `gcloud services enable iap.googleapis.com compute.googleapis.com`;
  configure the OAuth brand/consent as prompted the first time IAP for web is enabled (steps are
  version-dependent — follow the in-console prompt / current IAP docs).

## 2.7 A documented rollback and change window
- **Description:** An agreed **rollback procedure** and **change window** for enabling IAP / binding
  access levels / retiring a VPN path, since these change how users reach an app.
- **Why required:** Zero-trust enforcement can lock users out if a signal or binding is wrong; a
  rollback (disable IAP enforcement / detach the access-level condition / re-open the prior path) must
  be ready before production-affecting changes.
- **How to verify:** The rollback steps and approver are written down and the pilot group is briefed.
- **How to implement if missing:** Capture the rollback (see Implementation §rollback) and confirm the
  approver before the first enforcement change.
