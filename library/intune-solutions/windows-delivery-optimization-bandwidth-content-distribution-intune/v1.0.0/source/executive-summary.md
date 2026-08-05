# Executive Summary — Windows Delivery Optimization (Bandwidth Savings & Peer Content Distribution)

Every managed Windows device downloads a great deal of content from Microsoft: monthly quality
updates and annual feature updates, Microsoft Store apps, Microsoft 365 Apps updates, **Intune Win32
apps**, and **Autopilot / Enrollment Status Page** payloads during provisioning. Multiplied across a
fleet — and especially across branch offices on modest internet circuits — that traffic saturates
WAN links, slows provisioning, and drives up bandwidth cost. **Delivery Optimization (DO)** is the
built-in Windows content-delivery engine that fixes this: devices share already-downloaded content
with peers on the same network and pull from an on-network cache, so the same bytes cross the
internet **once** instead of once per device.

This solution configures Delivery Optimization the repeatable way — through the **Intune Settings
Catalog** — so a novice administrator can turn a fleet of devices that each download everything
independently into a **coordinated, bandwidth-efficient** estate. It is deliberately scoped to the
**content-delivery / bandwidth layer**: *how* content reaches devices efficiently. It does **not**
decide *what* patches deploy or *when* (that is Windows Update for Business), how third-party apps are
patched, or how Win32 apps are packaged — DO optimizes the delivery *underneath* all of those.

**What you get:** a click-by-click implementation that sets the correct **Download Mode**, scopes
peer groups accurately across sites and subnets with **GroupIDSource**, applies sensible **bandwidth
throttling** (absolute and percentage, business-hours-aware) and **cache** sizing, assigned
**pilot → production**; a decision-level overview of **Microsoft Connected Cache (MCC)** so you know
when your org needs an on-network cache node (the full MCC standup is a separate future engagement);
and **monitoring** that proves the savings using the built-in `Get-DeliveryOptimizationStatus` /
`Get-DeliveryOptimizationPerfSnap` cmdlets and the Intune Delivery Optimization report.

**Outcome:** less WAN and internet bandwidth consumed for the same updates and apps, faster branch-office
provisioning, and hard numbers — peer-vs-HTTP-vs-cache bytes — that demonstrate the saving to the
business. Deployable by a single administrator, validated on a pilot before you expand.

**Effort model:** *Assess → Configure → Pilot → Validate → Expand.*
