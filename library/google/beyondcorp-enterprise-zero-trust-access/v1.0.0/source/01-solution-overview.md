# 1. Solution Overview — BeyondCorp Enterprise: Zero-Trust Access for Apps & Google Cloud

## What this solution is
This is the repeatable way to replace network-location trust with identity- and context-aware
zero-trust access for an enterprise's web applications, virtual machines, and Google Cloud resources.
It implements **BeyondCorp Enterprise** — Google Cloud's zero-trust access model — using three
building blocks that work together:

- **Access Context Manager** — where you define **access levels**: named, reusable conditions that
  combine who the caller is with the context of the request (device state, IP/geo, corporate-managed
  status, time). An access level is a boolean the platform re-evaluates on every request.
- **Identity-Aware Proxy (IAP)** — the enforcement point that sits *in front of* an application or VM.
  A request never reaches the backend until IAP has authenticated the user and checked that they are
  both authorized (IAM) and satisfy any bound access level (context). IAP works for HTTPS web apps
  behind a Google load balancer and, via **IAP TCP forwarding**, for SSH/RDP to VMs — removing the
  need for a bastion host reachable over a VPN.
- **Context-aware access bindings** — the IAM binding that attaches an access level to a principal's
  access to a resource, so a grant reads "this group may reach this app **only when** they meet this
  access level," not just "this group may reach this app."

The result: access is granted **per request, on who and what — not where**. A device inside a VPN is
no longer automatically trusted; a laptop that fails device posture is denied even from the corporate
IP range; and remote access to internal apps no longer depends on a VPN concentrator at all.

Google Cloud Console layouts, `gcloud` command surfaces, and specific BeyondCorp Enterprise
capabilities change over time and are owned by Google. Where a capability, tier, or preview feature is
version-dependent (for example, device-trust signal sources, Chrome Enterprise Premium licensing for
certain device signals, or IAP support for a given resource type), this solution **cites it or flags
"verify in your organization"** rather than inventing an exact path.

## How this differs from Workspace Context-Aware Access
The organization may already run **Context-Aware Access (CAA)** in the **Google Admin console** to
gate access to **Google Workspace** apps (Gmail, Drive, Calendar) by device and context. That is a
**Workspace** control, configured under Admin console → Security → Access and data control →
Context-Aware Access, and it protects Google's own SaaS apps.

**This solution is the Google Cloud / BeyondCorp Enterprise side of the same idea** — it protects
**your own applications and VMs and Google Cloud resources**, configured with **Access Context
Manager + IAP + Cloud IAM** in the **Google Cloud Console** (not the Admin console). The two share the
same conceptual model (identity + device + context) and can share device-trust signals, but they are
distinct products with distinct admin surfaces. This solution is explicit about which console each
step belongs in so the two are not conflated. Where Workspace CAA and BeyondCorp access levels can
draw on the same device signals, that overlap is noted; the configuration itself is done per surface.

## The reference design
The pilot-first reference design has five layers:

1. **Access levels (Access Context Manager)** — a small, named set of reusable conditions, e.g.
   `Access Level – Corp-Managed – v1` (corporate-managed device + allowed region) and
   `Access Level – Trusted-Network – v1` (allowed corporate IP ranges). Basic access levels use
   attribute conditions; custom access levels use **Common Expression Language (CEL)**. Access levels
   live at the Organization node so every project can reference them.
2. **Device-trust signals** — the inputs an access level tests. Depending on licensing and enrollment,
   signals can come from **endpoint verification / Chrome Enterprise**, corporate-managed device
   status, or an integrated endpoint-management partner. Because signal sources and their licensing are
   version- and tier-dependent, the solution names the signal it relies on and flags **"verify the
   signal source and license in your organization."**
3. **Identity-Aware Proxy (IAP)** — enabled in front of a pilot web app (behind an external/internal
   HTTPS load balancer) and, separately, for **IAP TCP forwarding** to a pilot VM for SSH. IAP becomes
   the single front door; the backend is not reachable directly.
4. **Context-aware access bindings** — IAM policy on the IAP-protected resource that grants the pilot
   group `roles/iap.httpsResourceAccessor` (web) or the TCP-forwarding role (VMs) **conditioned on**
   the access level. Access is allowed only when identity **and** context both pass.
5. **VPN retirement path** — once the app/VM are reachable through IAP with context enforced, the
   corresponding VPN route and firewall exposure for that app are removed, so the app is no longer
   reachable by network position at all.

## Benefits
- **No implicit network trust.** A request is judged on identity + device + context every time, so a
  compromised device or a caller on the "right" network is not automatically allowed.
- **VPN reduction/retirement.** Internal apps and VM SSH move behind IAP, removing whole classes of
  VPN exposure and the flat lateral access a VPN grants.
- **Least-privilege, per-app.** Each app/VM gets its own IAM + access-level policy; there is no
  all-or-nothing tunnel.
- **Auditable.** IAP and Cloud Audit Logs record who reached what, from what context — every allow and
  deny is evidence.
- **Reusable policy.** Access levels are defined once and referenced across many resources.

## Limitations and boundaries
- **IAP resource support is specific.** IAP fronts HTTPS load-balanced web apps, App Engine, and (via
  TCP forwarding) VMs; not every workload type is IAP-eligible. Confirm eligibility for each target —
  **verify in your organization.**
- **Device signals depend on licensing/enrollment.** Richer device-trust signals may require Chrome
  Enterprise Premium / endpoint verification enrollment. The solution states the dependency and flags
  it for verification rather than assuming a tier.
- **This is not the Workspace CAA product** (see above) and does not configure Workspace app access.
- **Legal/records/compliance determinations are deferred** to the org's legal, records, and compliance
  functions; this solution provides the technical access-control method and the evidence.
- **IaC is at the pattern level** — Terraform / Cloud Foundation Toolkit blueprints are shown as a
  pattern with representative snippets; module internals are deferred to the tool's own docs.

## Deployment model
This solution follows the house model: **Assess → Design → Configure → Pilot → Validate → Expand**,
pilot-first. Access levels and IAP are configured against a **named pilot app and a named pilot VM**
with a **named pilot group** first; explicit **pass/fail gates** confirm that access is *granted* on
identity+context and *denied* otherwise before any VPN path is retired or the pattern is expanded.
Every org-wide or production-affecting change has a **documented rollback**.
