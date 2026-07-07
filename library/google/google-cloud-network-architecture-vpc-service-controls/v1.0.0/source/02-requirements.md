# Requirements

These are the **solution-specific** prerequisites for building the Shared VPC + private-access
network and the VPC Service Controls perimeters. They build **on top of** the shared category
requirements in **`global-requirements-gcp.md`** (a linked Google Cloud Organization on Cloud
Identity/Workspace, Organization-level admin access, a Cloud Billing account, the `gcloud`/Python
toolchain with API enablement, an agreed resource-hierarchy & naming design, and engaged
security/network/governance stakeholders). Verify those first; the items below are what this solution
additionally needs. Each item lists **Description / Why required / How to verify / How to implement if
missing.**

---

## 1. Network administration roles at the host project and organization

- **Description:** The engineer(s) running this solution hold the network roles at the correct scope:
  `roles/compute.networkAdmin` and `roles/compute.securityAdmin` on the **host project**
  (`Net-Host – Prod – Shared-VPC`), `roles/compute.xpnAdmin` (Shared VPC Admin) at the
  **organization or Network folder**, and `roles/accesscontextmanager.policyAdmin` plus
  `roles/accesscontextmanager.policyEditor` at the organization for Access Context Manager / VPC-SC.
- **Why required:** Creating the Shared VPC and attaching service projects requires the XPN
  (Shared VPC) admin role; building perimeters and access levels requires the Access Context Manager
  policy admin role. Without them the create/attach/perimeter steps fail with permission errors.
- **How to verify:**
  `gcloud organizations get-iam-policy ORG_ID --flatten="bindings[].members" --filter="bindings.members:USER"`
  and `gcloud projects get-iam-policy NET_HOST_PROJECT_ID …` — confirm the roles above.
- **How to implement if missing:** Have an Organization Administrator grant the roles under change
  control, at the **narrowest scope** that works (folder over org where possible), and record the
  grant in the change ticket.

## 2. A dedicated Shared VPC host project (and target service projects)

- **Description:** A project reserved to be the **Shared VPC host** (`Net-Host – Prod – Shared-VPC`),
  containing no workloads, plus the **service projects** that will attach and consume its subnets
  (`App-A – Prod`, `Data-A – Prod`, …). A **pilot service project** is nominated to validate on first.
- **Why required:** Shared VPC requires a clean host project to own the network; mixing workloads into
  the host project blurs the separation of duties this design depends on.
- **How to verify:** `gcloud compute shared-vpc get-host-project SERVICE_PROJECT_ID` (empty if not yet
  attached); confirm the host project exists and has the Compute Engine API enabled.
- **How to implement if missing:** Create the host and service projects under the Network/workload
  folders per the naming convention; enable `compute.googleapis.com` on each.

## 3. Non-overlapping IP address plan (subnets + secondary ranges)

- **Description:** An allocated, **non-overlapping** RFC 1918 (and/or PDP) IP plan for the regional
  subnets, including **secondary ranges** for GKE Pods and Services where container platforms are in
  scope, plan for the **restricted/private Google API VIP** routes, and reserved space for PSC.
- **Why required:** Overlapping ranges break hybrid routing (VPN/Interconnect) and VPC peering, and
  cannot be changed non-disruptively later. Private Google Access and PSC need known routes/ranges.
- **How to verify:** Compare the proposed CIDRs against on-prem and any existing VPCs/peered networks;
  confirm no overlap with `10.0.0.0/8` allocations already in use and with the Google API VIP ranges.
- **How to implement if missing:** Produce an IP allocation table (region → primary CIDR → secondary
  ranges) reviewed by the network team before any subnet is created.

## 4. Private access foundations: DNS and the restricted API VIP route

- **Description:** The ability to configure **Cloud DNS** private zones so that
  `*.googleapis.com`/`private.googleapis.com`/`restricted.googleapis.com` resolve to the correct
  VIP ranges, and to add the **route to the restricted VIP** (`199.36.153.4/30` for the restricted
  range — **verify the current documented VIP ranges** in Google's "Private Google Access" docs, as
  ranges are published there) used to keep API traffic inside a VPC-SC perimeter.
- **Why required:** Private Google Access and the VPC-SC "restricted" path only work when DNS resolves
  API hostnames to the private/restricted VIP and a route exists to reach it.
- **How to verify:** From a test VM with no external IP, `nslookup storage.googleapis.com` returns the
  restricted/private VIP, and a `gcloud storage ls` succeeds without public egress.
- **How to implement if missing:** Create the Cloud DNS response-policy / private zone and the static
  route to the restricted VIP as part of the implementation Configure step.

## 5. Access Context Manager access policy (the container for access levels & perimeters)

- **Description:** An **organization-scoped access policy** in Access Context Manager (there is one
  scoped policy per organization for VPC-SC use, plus optional scoped policies for delegated admin —
  **verify current scoping model in your org**). Perimeters and access levels live inside it.
- **Why required:** Access levels and service perimeters cannot be created without an access policy to
  hold them; VPC-SC references the org access policy.
- **How to verify:** `gcloud access-context-manager policies list --organization=ORG_ID` returns a
  policy (note its NAME/ID for later commands).
- **How to implement if missing:**
  `gcloud access-context-manager policies create --organization=ORG_ID --title="Org Access Policy"`
  (Organization admin), then record the policy ID for the perimeter steps.

## 6. Required APIs enabled on the in-scope projects

- **Description:** The APIs this solution uses enabled on the host and in-scope projects:
  `compute.googleapis.com`, `dns.googleapis.com`, `accesscontextmanager.googleapis.com`,
  `servicenetworking.googleapis.com` (for PSC/private services access where used), plus the APIs of
  the **services the perimeter will protect** (e.g. `storage.googleapis.com`, `bigquery.googleapis.com`,
  and `aiplatform.googleapis.com` for Vertex AI / Gemini — **verify which are VPC-SC supported for your
  services**).
- **Why required:** VPC-SC can only restrict a service whose API is enabled and supported; private
  access and DNS steps need their APIs on.
- **How to verify:** `gcloud services list --enabled --project=PROJECT_ID` includes the APIs above.
- **How to implement if missing:** `gcloud services enable <api> --project=PROJECT_ID` for each,
  under change control.

## 7. A logging & monitoring sink for VPC-SC and firewall audit

- **Description:** A destination (Cloud Logging bucket / log sink, and optionally BigQuery) able to
  receive **VPC-SC dry-run violation logs** and **firewall/VPC Flow Logs**, with query access for the
  engineer reviewing the pilot.
- **Why required:** The whole dry-run-first method depends on being able to **read what the perimeter
  would have blocked**; without the logs there is no evidence to gate enforcement on.
- **How to verify:** Confirm Cloud Audit Logs are on for the in-scope services and that
  `resource.type="audited_resource"` VPC-SC entries (dry-run) are queryable in Logs Explorer.
- **How to implement if missing:** Enable Data Access audit logs for the protected services, and
  create a log sink/bucket the reviewer can query, before turning on the dry-run perimeter.
