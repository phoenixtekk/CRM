# 1. Solution Overview — Windows Firewall GPO to Intune Migration

## What this migration is
This solution moves Windows Defender Firewall management from Active Directory Group Policy (GPO) to
Microsoft Intune endpoint-security firewall policy. It is not net-new firewall design — it assumes
you already have working firewall rules in GPO and need to relocate that enforcement to Intune
without breaking connectivity. The deliverable is a controlled, ringed cutover: inventory what GPO
enforces, translate it into Intune firewall objects, run both side by side without conflict during
transition, validate rule parity, then retire the GPO firewall settings.

## Why move firewall management to Intune
- Cloud-managed, internet-facing devices do not reliably receive GPO; a domain-joined-only firewall
  policy leaves remote and Entra-joined devices unmanaged or inconsistently managed.
- Intune gives a single endpoint-security surface (`Endpoint security` → `Firewall`) with assignment
  by Entra group, per-device reporting, and no dependency on line-of-sight to a domain controller.
- Co-management and modern provisioning (Autopilot, Entra join) expect endpoint security to live in
  Intune, not GPO.

## Why this migration is risky (the *why* behind the discipline)
Group Policy and Intune can both write Windows Defender Firewall settings to the same device. When
both are active and unmanaged, three failure modes appear:
- Conflict — GPO and Intune set the same firewall setting to different values; the device's effective
  state becomes ambiguous and can flip between policy refreshes.
- Merge condition — local, GPO, and Intune (MDM) rules all merge into the effective rule set. If you
  do not control rule merging, you get unexpected union behavior: rules you thought you removed are
  still enforced from another source.
- Merge loop — GPO re-asserts a firewall setting on its refresh cycle while Intune re-asserts a
  conflicting value on its check-in; the device oscillates and never settles, and reporting shows
  intermittent compliance. This is the pain point this solution is built to avoid.

Because the firewall governs connectivity, an unmanaged conflict does not fail safe — it can block
inbound management, RDP/Remote Help, or LOB traffic. That is why the migration is staged
(inventory → translate → coexist → ring → validate → retire) rather than a flip of a switch.

## How GPO firewall rules map to Intune
| GPO firewall concept | Intune endpoint-security equivalent |
|---|---|
| Firewall profile state (Domain/Private/Public on, default inbound/outbound action, stealth, logging) | A `Firewall Policy` (profile `Windows Firewall`) — one policy enabling the three profiles with the same defaults |
| Individual inbound/outbound allow/block rules | `Firewall Rules` profile entries (one rule each: name, direction, action, protocol/ports, program, address scope) |
| GPO scoping by OU / security group | Intune assignment to an Entra security group (the migration ring) |
| GPO refresh / gpupdate | Intune device check-in / sync |

A single GPO firewall section typically becomes one `Firewall Policy` (the profile defaults) plus one
or more `Firewall Rules` profiles (the explicit rules), assigned to the same ring group.

## The coexistence model (how conflicts/loops are avoided)
During transition, every in-scope device is targeted by GPO and Intune at once. The migration
controls this so they never fight:
1. Translate first, assign nothing — build the Intune objects but do not assign them until the device
   is ready to leave GPO.
2. Move a device out of GPO firewall scope at the same moment it enters the Intune ring — one
   authority per device, never two enforcing the same firewall settings.
3. Control rule merging explicitly in the Intune policy so local/GPO leftovers cannot silently
   re-merge.
4. Validate parity (the Intune effective rule set equals the old GPO rule set) before advancing.

## The named artifacts this solution creates
All objects follow `<Purpose> – <Scope> – <Stage>` and are reused verbatim throughout the guides:
- Groups: `FW Migration – Pilot Devices – Stage Pilot`, `FW Migration – Wave 1 Devices – Stage Wave1`,
  `FW Migration – Fleet Devices – Stage Broad`.
- Firewall policy (profile defaults): `Firewall Policy – Migrated Rules – Pilot`,
  `Firewall Policy – Migrated Rules – Broad`.
- Firewall rules profiles: `Firewall Rules – Migrated Inbound – Pilot`,
  `Firewall Rules – Migrated Outbound – Pilot` (and the Broad equivalents).
- Migration rings: `Migration Ring – Pilot`, `Migration Ring – Wave 1`, `Migration Ring – Broad`.

## The standard deployment model
> Assess (inventory GPO firewall rules) → Configure (translate to Intune policy + rules,
> set coexistence) → Pilot (`Migration Ring – Pilot`) → Validate (rule parity + connectivity) →
> Expand (waves, then retire GPO). repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**
