# 1. Solution Overview — Intune Wi-Fi Profile Remediation (Changes Not Applying)

## The problem this solves
You edit an Intune **Wi-Fi configuration profile** — change the pre-shared key, add or change a
**proxy**, switch the security type, correct the SSID — save it, and it reports **Succeeded**. But the
devices never change. They keep connecting with the old settings, the old proxy, or the old saved
network. You re-push, force a sync, reboot, and re-check: still Succeeded, still unchanged.

This toolkit replaces that loop with a **structured, symptom-driven method** specific to Wi-Fi
profiles. You follow the change along the path it actually travels — from the Intune profile to the
**saved network on the device** — isolate the one place it breaks, and apply the reliable remediation
for that cause.

> **Scope boundary.** This product owns **Wi-Fi configuration profiles that will not update or reflect
> a change**. It is *not* the general configuration-profile toolkit and *not* a Wi-Fi *deployment*
> product. For general "policy assigned but not applying" diagnosis across any configuration profile
> (assignment, filters, sync, CSP errors, conflicts), use the **Intune Device Configuration & Policy
> Troubleshooting Toolkit** — this Wi-Fi product reuses that layered model and points to it rather
> than repeating it. For first-time **802.1X / certificate-based Wi-Fi deployment** (SCEP/PKCS, trusted
> root, RADIUS), use the certificate-Wi-Fi and Wi-Fi-deployment products; this toolkit references
> them and does not reproduce certificate deployment.

## Why a modified Wi-Fi profile so often does not update in place — the crux
A device that has already joined a Wi-Fi network keeps that network as a **saved network** (a "known
network" on Windows, a saved network on Android, an installed Wi-Fi payload inside the MDM profile on
iOS/iPadOS). When you change the Intune profile, Intune re-delivers the payload — but the device does
**not** reliably overwrite a network it already has with the same SSID.

Microsoft states this plainly for the most common case, a changed password: after you change the
password on an existing profile and save it, *"some users may not get the new profile."* The same
behavior is observed for other in-place edits (proxy, security type, auto-connect). The profile still
reports **Succeeded** in Intune because **delivery succeeded** — the payload reached the device — even
though **application** (rewriting the live saved network) did not. That split between *reported* and
*applied* is the heart of nearly every "Wi-Fi change not reflecting" case.

Because of this, the **reliable remediation is not to edit the existing profile in place**. It is to
deploy a **new, correctly-configured replacement profile** (a distinct profile object, and — where the
change is to the network itself — often a controlled remove-and-re-add of the old saved network), so
the device treats it as a new network to install rather than a known network to leave alone. This
toolkit's playbook is built around that pattern.

## How a Wi-Fi change travels — and where it stalls
A Wi-Fi change must pass through the same delivery layers as any configuration profile **and** one
extra Wi-Fi-specific layer:

1. **Assignment & scope** — the profile is assigned to the right Entra group, in the right
   (device vs user) context, not blocked by a filter. *(General layer — deferred to the configuration
   toolkit.)*
2. **Sync / delivery** — the device checks in and receives the payload. *(General layer.)*
3. **Certificate dependency** (enterprise/802.1X profiles only) — the Trusted Root and SCEP/PKCS
   profiles the Wi-Fi profile depends on must be present first, or the Wi-Fi payload is skipped as
   *pending certificates*. *(Deferred to the certificate-Wi-Fi product; flagged here as a checkpoint.)*
4. **Application to the saved network** — **the Wi-Fi-specific layer this product owns.** Even after
   the payload is delivered, the device must actually create or overwrite the saved network. For a
   *changed* profile targeting an SSID the device already knows, this is exactly where it silently
   does nothing.
5. **Report** — the device reports **Succeeded/Failed**, which reflects **delivery**, not whether the
   live network on the device matches your intent.

The **Diagnostic Playbook** (document 3) starts at Step 0 (establish the facts) and then branches by
symptom to the layer that owns each failure — with the in-place-update crux, proxy placement, and
Meraki as the worked branches.

## The Meraki interaction — which system is authoritative
When Cisco Meraki is in the environment, "changes not reflecting" often means **something other than
Intune owns the setting**. Two very different Meraki products are commonly confused:

- **Meraki dashboard** — the **wireless-infrastructure** side: access points, broadcast SSIDs, RADIUS,
  VLANs, and per-SSID **group policies**. This controls the *network*, not the device's saved-profile
  or client-side proxy. If the behavior you are chasing (e.g. a forced proxy, a splash page, an
  authentication method) is enforced by the AP/SSID, editing the Intune Wi-Fi profile will never
  change it — the dashboard is authoritative for that.
- **Meraki Systems Manager (SM)** — Meraki's **own MDM/UEM**, which pushes its own **Wi-Fi Settings
  payload** (SSID, auto-join, and — on Apple only — proxy) to enrolled endpoints. If a device is
  enrolled in Meraki SM as well, it can carry a **second managed Wi-Fi profile for the same SSID**,
  and your Intune change may be masked by the Meraki payload. On **iOS/iPadOS a device can be
  MDM-enrolled to only one server**, so if it is enrolled in Meraki SM it is not taking Intune Wi-Fi
  profiles at all (and vice-versa) — a frequent root cause that no amount of Intune re-pushing fixes.

Branch D walks the exact checks to tell which system owns the setting. Meraki console internals change
over time; where a Meraki-side step is version-sensitive, the playbook says **verify against current
Cisco Meraki documentation** rather than guessing.

## What you get
- A plain-language model of how a Wi-Fi change travels and why an in-place edit stalls (this document).
- A **Requirements Guide** (roles, Graph read access, device access) with verify/implement for each.
- A **Diagnostic Playbook** — Step 0 plus labelled branches A–F, each: symptom → how to confirm →
  exact fix → re-validate.
- **Five PowerShell scripts**: preflight, export Wi-Fi profiles + assignments + duplicate/conflict
  detection, on-device Windows validation (`netsh wlan` + effective proxy), reported-vs-applied state
  report, and a guarded remediation helper (`-WhatIf` by default) that builds the corrected/renamed
  profile or removes the stale saved network.
- **Testing** gates that prove the corrected settings actually applied on a device, plus
  **Troubleshooting** and **Best Practices**.

## The repeatable method
> **Establish the facts → follow the change to the saved network → isolate the one cause → deploy a
> corrected replacement profile (don't edit in place) → prove it applied on a device.** The repeatable
> shape behind every branch: **Assess → Configure → Pilot → Validate → Expand.**
