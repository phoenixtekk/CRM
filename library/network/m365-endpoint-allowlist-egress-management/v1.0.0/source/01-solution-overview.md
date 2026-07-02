# Solution Overview

## The problem this solves

Regulated and security-conscious organizations run **tight egress filtering**: outbound internet
traffic is denied by default and only explicitly allowed destinations (by IP address, port, or URL)
are permitted through a proxy or firewall. This is a sound security posture — but it collides with a
fact about modern device management: **Microsoft 365, Intune, Windows Autopilot, Microsoft Defender,
and Microsoft Entra ID are cloud services.** A device that is being enrolled, managed, protected, and
updated must reach a **specific, published set of Microsoft endpoints** to do any of it.

When the allow-list is incomplete, the failure is quiet and confusing:

- **Autopilot / enrollment stalls** — a new device sits at a provisioning screen, or enrollment
  errors out, because it cannot reach the enrollment or device-registration endpoints.
- **Policies never sync** — Intune shows a device as enrolled, but configuration, compliance, and app
  policies never land because the device management check-in endpoint is blocked.
- **Updates fail silently** — Windows Update / delivery of content fails or hangs because content and
  update endpoints are blocked.
- **Defender / Entra features degrade** — Defender cloud protection, or Entra sign-in / device
  registration, fail because their endpoints were never added.

None of these produce an obvious "the firewall blocked you" message on the device. They look like
random breakage. The fix is not to loosen the firewall — it is to **administer the allow-list
precisely**: derive the required destinations, allow exactly those, validate that they are reachable,
and keep the list current as Microsoft changes it.

## The Microsoft required-endpoints model

Microsoft publishes the network destinations its cloud services need, and — critically — it publishes
them in a **machine-readable, versioned form** so you never have to guess or hardcode addresses.

### The Microsoft 365 IP Address and URL web service

Microsoft operates a public **Microsoft 365 IP Address and URL web service** (commonly called the
"endpoints web service"). It returns, as structured data, the current set of URLs, IP address ranges,
and ports that Microsoft 365 uses, organized into **endpoint sets**. Each endpoint set carries
attributes you use to build a correct, minimal allow-list:

- **id** — a stable numeric identifier for the endpoint set.
- **serviceArea** — which workload it belongs to (for example Exchange, SharePoint, Skype/Teams, or
  the common/identity area that Entra and other shared services use).
- **urls** — the URLs (often with wildcards) the service uses.
- **ips** — the IPv4/IPv6 CIDR ranges the service uses.
- **tcpPorts / udpPorts** — the ports required.
- **category** — **Optimize**, **Allow**, or **Default**. Optimize and Allow are the endpoints
  required for the service to work correctly and should always be permitted; Default endpoints are
  broadly used and can typically be sent to the general internet path.
- **required** — a true/false flag marking endpoints that are mandatory for connectivity.
- **expressRoute**, **notes** — routing hints and human-readable context.

The service also exposes a **version endpoint** so you can detect when the published set has changed
without re-downloading everything. **Every endpoint set is keyed to an "instance"** — for most
organizations the instance is **Worldwide**; sovereign/government clouds (for example US Government
GCC High, DoD, and the China cloud) have their own instances with different addresses. You must query
the instance that matches your tenant.

> **Why derive instead of hardcode.** Microsoft updates these lists regularly (new ranges, retired
> ranges, added URLs). Any allow-list you type in by hand is stale the moment an update publishes.
> The correct operating model is: **pull the current set from the web service, transform it into your
> proxy/firewall's format, and re-pull on a schedule to catch drift.** This solution and its scripts
> are built around that model — they never ship a fixed list of IPs.

### The services that depend on these endpoints

- **Microsoft 365** (Exchange Online, SharePoint Online / OneDrive, Teams, the common/identity area)
  — the core productivity workloads, served by the endpoint sets above.
- **Microsoft Entra ID** — identity, sign-in, device registration, and Conditional Access. Its
  destinations sit largely in the **common** service area of the M365 endpoints, plus the Entra /
  sign-in host names. Nothing device-management-related works if identity is blocked.
- **Microsoft Intune** — device enrollment and management check-in. Intune's required network
  endpoints (the enrollment and device-management host names and ranges, plus the shared M365
  common/identity and content dependencies) are documented by Microsoft as **Intune network
  endpoints**; treat them as a required set alongside the M365 common area.
- **Windows Autopilot** — provisioning of new devices. Autopilot rides on top of Entra (device
  registration), Intune (enrollment), and Windows/content endpoints; it has **no separate transport**
  — if those are allowed, Autopilot works.
- **Microsoft Defender** — endpoint protection cloud services (cloud-delivered protection, sample
  submission, and telemetry) have their own documented endpoint set that must be reachable for
  full protection.
- **Windows Update / content delivery** — the update and content-download endpoints that let managed
  devices actually receive updates and app content.

The practical rule: build the allow-list from **(a)** the M365 web service **Optimize + Allow +
required** endpoints for your instance, plus **(b)** the documented **Intune**, **Autopilot
dependency**, and **Defender** endpoints, and treat that union as the required set for cloud-managed
devices behind your filter.

## The allow-list lifecycle

An allow-list is not a one-time build; it is a maintained object. This solution runs it as a loop:

1. **Derive** — pull the current required IP/Port/URL set from the Microsoft web service (for your
   instance) plus the documented Intune/Autopilot/Defender endpoints. Produce a single normalized
   **required-set** document.
2. **Build** — turn the required set into concrete **allow-list entries / proxy exceptions** on the
   proxy or firewall you administer. Name the objects consistently (this solution specifies the
   names) so they are auditable and reusable.
3. **Validate** — from a device inside the filtered network, confirm each required destination is
   actually reachable on its required port(s). Reachability, not "we added it," is the pass criterion.
4. **Pilot** — apply and validate on a small pilot scope first, and confirm the real workflows
   (enrollment, policy sync, update) succeed end to end before touching the fleet.
5. **Expand** — roll the validated allow-list out to the broader environment through change control.
6. **Keep current** — on a schedule, re-pull the web service, compare against the version you built
   from, and generate the **delta** (added/removed endpoints) so you update the allow-list *before*
   drift causes failures. Never let the live list silently diverge from Microsoft's published set.

## Deployment model

This solution follows the standard staged model with pass/fail gates at each transition:

**Assess → Configure → Pilot → Validate → Expand.**

- **Assess** — confirm prerequisites (Requirements Guide), inventory the current filter state, and
  derive the current required set.
- **Configure** — build the named allow-list entries / proxy exceptions from the required set.
- **Pilot** — apply to a named pilot group only.
- **Validate** — prove reachability and prove the real workflows succeed on the pilot (Testing Guide).
- **Expand** — extend to the fleet, then operate the keep-current loop.

The five PowerShell scripts included map onto this loop: **Discovery** (derive the required set and
capture current filter state), **Validation** (per-endpoint reachability), **Report** (allow-list
coverage / gap analysis), **Remediation** (generate allow-list updates — preview first), and
**Set-ScopeTargeting** (build the pilot target group — preview first).
