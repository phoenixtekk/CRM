# Executive Summary

You changed a Wi-Fi setting in Intune — a new password, a proxy, a security type — the profile shows
**Succeeded**, and the devices are still on the old configuration. Nothing you re-push, sync, or
restart changes it. This is one of the most common and most confusing Intune symptoms, because every
signal in the console says the change worked.

It usually did not fail. It **never reached the saved network on the device** — because Intune does
not reliably rewrite a Wi-Fi network the device has *already* joined. Microsoft documents this
directly: after you change the password on an existing Wi-Fi profile, *"some users may not get the
new profile."* The same behavior applies to a changed proxy, SSID, or security type. The device keeps
the network it already has, the profile still reports Succeeded (delivery, not application), and the
admin is left re-pushing blindly.

This solution replaces that guesswork with a **symptom-driven remediation playbook** for Intune Wi-Fi
configuration profiles that will not update across **Windows, iOS/iPadOS, and Android**. You start
from what you observe, follow the branch, run the exact checks, and land on the one cause that owns
the failure — then apply the reliable remediation: a **new, correctly-named replacement profile** and
a controlled remove-and-re-add, rather than editing the stale profile in place and hoping.

It covers the two hardest real-world variants head-on:

- **Proxy placement.** Where the proxy actually lives in a Wi-Fi profile per platform, and the single
  most common mistake — putting a URL or a `host/path` in the **manual** proxy field (which is a
  **host + port**, never a URL), or a bare hostname in the **automatic** field (which is a **PAC
  URL**). Get this wrong and the network connects but all traffic breaks.
- **Cisco Meraki.** How to tell whether the change is being masked by Meraki — either the **Meraki
  dashboard** (the wireless-infrastructure side: APs, SSIDs, RADIUS, group policies) or **Meraki
  Systems Manager** (Meraki's own MDM, which pushes its *own* Wi-Fi payload and can compete with
  Intune for the same SSID) — and how to establish which system is authoritative before you touch the
  Intune profile.

You receive the diagnostic playbook, a requirements guide, testing gates that **prove the corrected
settings actually applied on a device** (not just that Intune says so), a troubleshooting guide, best
practices, and **five PowerShell scripts** (read-only by default) that export your Wi-Fi profiles and
assignments, detect duplicates and conflicts, compare *reported* state against *applied* state on the
device, and help you build the corrected replacement profile safely.

The result: the exact reason your Wi-Fi change is not reflecting — isolated to one cause — and a
repeatable, low-risk pattern to fix it and keep it fixed, on every platform, on every future change.
