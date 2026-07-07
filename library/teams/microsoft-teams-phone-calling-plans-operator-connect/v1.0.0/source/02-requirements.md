# 2. Requirements — Microsoft Teams Phone (Calling Plans & Operator Connect)

These are the **solution-specific** prerequisites for enabling Teams Phone via Calling Plans and
Operator Connect. They build **on top of** the shared **Global Requirements — Microsoft Teams
Solutions** (`global-requirements-teams.md`), which already cover: a licensed Microsoft 365 + Teams
tenant, least-privilege Teams admin roles, the MicrosoftTeams PowerShell + Graph toolchain, an
identity/group source of truth, a pilot scope + change control, and security/compliance stakeholders.
**Verify the six global requirements first**, then confirm each item below. Each requirement lists
**Description / Why / Verify / Implement if missing**.

---

## 2.1 Teams Phone licensing for every calling user
- **Description:** Each user who will make/receive PSTN calls needs a **Teams Phone** license (Teams
  Phone Standard, or the equivalent included in an eligible suite/add-on). Resource accounts that back
  auto attendants and call queues need a **Microsoft Teams Phone Resource Account** license.
- **Why required:** Enterprise voice, number assignment, and voice apps are gated on Teams Phone
  licensing; without it `Set-CsPhoneNumberAssignment` and voice-policy grants will not apply.
- **How to verify:** M365 admin center → `Billing → Licenses`; or per user
  `Get-CsOnlineUser -Identity <upn> | Select-Object UserPrincipalName,FeatureTypes` and confirm the
  Teams Phone service plan is assigned. (Exact SKU names are **plan-dependent — verify in your tenant**.)
- **How to implement if missing:** Purchase/assign the Teams Phone license (and Resource Account
  licenses) before assigning numbers. Prefer **group-based licensing** for the pilot group so scope is
  managed by membership.

## 2.2 A chosen PSTN path per number — Calling Plan and/or Operator Connect
- **Description:** For each number/user, decide the PSTN path: **Microsoft Calling Plan** (Microsoft is
  the carrier — requires a Calling Plan or pay-as-you-go add-on per user) **or** **Operator Connect**
  (an integrated operator is the carrier — no Microsoft Calling Plan needed).
- **Why required:** The path determines what you must buy, where numbers come from, and the
  `-PhoneNumberType` used at assignment (`CallingPlan` vs `OperatorConnect`).
- **How to verify:** Teams admin center → `Voice → Calling plans` (confirm plans available for your
  country) and `Voice → Operators` (confirm a participating operator is enabled). Availability is
  **country/region- and operator-dependent — verify in your tenant**.
- **How to implement if missing:** For Calling Plans, buy the plan/add-on for the pilot users. For
  Operator Connect, select and enable a participating operator in `Voice → Operators` and complete the
  operator's onboarding so numbers can be provisioned into the tenant.

## 2.3 Phone numbers available to assign
- **Description:** A supply of **user (subscriber) numbers** for people and **service numbers** for
  auto attendants/call queues, obtained via the correct path.
- **Why required:** A user cannot be voice-enabled without a number; a voice app cannot receive
  external calls without a service number.
- **How to verify:** Teams admin center → `Voice → Phone numbers`; or
  `Get-CsPhoneNumberAssignment -CapabilitiesContain UserAssignment` (and `-PstnAssignmentStatus
  Unassigned` to see spare inventory). Number **type/capability matters** — user vs service, calling-plan
  vs operator-connect.
- **How to implement if missing:** **Calling Plans** — `Voice → Phone numbers → Get new numbers`
  (choose user or service subtype) or submit a **port order** (`Voice → Phone numbers → Port` ) to move
  existing numbers. **Operator Connect** — request numbers from the operator; they appear in
  `Phone numbers` once provisioned. Port orders are carrier-driven and can take **days to weeks** —
  plan cutover timing.

## 2.4 Emergency addresses and dynamic-location data (LIS)
- **Description:** Registered **civic (emergency) addresses**, and — for dynamic emergency calling —
  **network identifiers** (subnets, Wi-Fi access points, network switches, and ports) mapped to
  locations in the **Location Information Service (LIS)**.
- **Why required:** Emergency calls must present a **dispatchable location**. A static address can be
  attached to a number; dynamic emergency calling resolves a user's location from where they connect.
  This is the **highest-risk** part of the rollout.
- **How to verify:** Teams admin center → `Locations → Emergency addresses`; or
  `Get-CsOnlineLisCivicAddress` and `Get-CsOnlineLisLocation`. For dynamic mapping, confirm subnets/APs
  are registered (`Get-CsOnlineLisSubnet`, `Get-CsOnlineLisWirelessAccessPoint`).
- **How to implement if missing:** Register validated civic addresses (`New-CsOnlineLisCivicAddress`),
  create places/locations within them (`New-CsOnlineLisLocation`), and map network identifiers
  (`Set-CsOnlineLisSubnet`, `Set-CsOnlineLisWirelessAccessPoint`, `Set-CsOnlineLisSwitch`,
  `Set-CsOnlineLisPort`). **The determination of which addresses are legally required and validated is
  deferred to your facilities/EHS/compliance function** — this solution provides the technical method.

## 2.5 Emergency-call routing responsibility confirmed (carrier/operator)
- **Description:** For Calling Plans and Operator Connect, **emergency calls are routed to the correct
  PSAP by Microsoft / the operator**, not by a customer-defined routing policy. Confirm the
  carrier/operator's emergency-calling support for each country and any **validated test-call** method.
- **Why required:** The customer-side **Emergency Call *Routing* Policy** is a **Direct-Routing**
  control and does **not** apply here; assuming otherwise leaves a gap. You must know how emergency
  routing works for your path and how to safely test it.
- **How to verify:** Review Microsoft's Calling Plan emergency-calling documentation for your country
  and the operator's emergency-calling terms; confirm whether a test-call service exists. Emergency
  behavior is **country/plan-dependent — verify in your tenant/region**.
- **How to implement if missing:** Engage Microsoft/the operator to confirm emergency support and a
  test method **before** going live; schedule the validated emergency test as a pilot gate.

## 2.6 Admin roles for voice, numbers, and emergency configuration
- **Description:** Beyond the global least-privilege Teams roles, confirm the operator has the rights
  to assign numbers, grant voice policies, and manage LIS/emergency data — typically **Teams
  Administrator** (or **Teams Communications Administrator** for voice-scoped work).
- **Why required:** Number assignment, dial plans, calling/emergency policy, and LIS changes require the
  corresponding Teams admin role.
- **How to verify:** M365 admin center / Entra roles → confirm the role; test with a read-only
  `Get-CsPhoneNumberAssignment` and `Get-CsTeamsCallingPolicy`.
- **How to implement if missing:** Have a Global Administrator assign the least-privilege Teams role
  under change control.

## 2.7 Network readiness for voice quality (and dynamic location)
- **Description:** A network that supports real-time media (adequate bandwidth, low latency/jitter, and
  the required Microsoft 365 network endpoints reachable), and — for dynamic emergency calling — a
  documented mapping of sites to subnets/APs/switches.
- **Why required:** Call quality and reliable dynamic-location resolution depend on the network; poor
  media paths cause dropped/garbled calls regardless of licensing.
- **How to verify:** Confirm the Teams media/optimize network endpoints are allowed and QoS (if used)
  is in place; validate a sample site's subnet/AP inventory against LIS.
- **How to implement if missing:** Align the network to Microsoft's Teams network guidance and capture
  the site-to-network-identifier mapping needed for §2.4 before enabling users at that site.

## 2.8 Resource-account service numbers for voice apps (if AAs/CQs are in scope)
- **Description:** For auto attendants and call queues that answer external calls, a **service number**
  (toll or toll-free) associated with a licensed resource account.
- **Why required:** An auto attendant or call queue only receives external calls through a resource
  account that holds a service number. Toll-free service numbers may require **Communications Credits /
  pay-as-you-go** — **verify the current billing model in your tenant**.
- **How to verify:** `Voice → Phone numbers` filtered to service numbers; per app instance
  `Get-CsOnlineApplicationInstance`.
- **How to implement if missing:** Acquire service numbers (Calling Plan `Get new numbers` service
  subtype, or from the operator), create resource accounts, license them (§2.1), and assign the number.

---

*The deployment model is the shared Teams model — **Assess → Design → Configure → Pilot → Validate →
Expand** — with explicit pass/fail gates and a documented rollback for production voice changes.
Automation is delivered as **PowerShell** (MicrosoftTeams module / Graph) with **no hardcoded
credentials or secrets**.*
