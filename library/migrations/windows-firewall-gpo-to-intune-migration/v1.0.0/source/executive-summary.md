# Executive Summary — Windows Firewall GPO to Intune Migration

**White-label · Migrations**

Moving Windows Defender Firewall from Group Policy to Microsoft Intune is a known minefield. Do it
before the foundation is ready and you get policy conflicts or merge/loop conditions that leave
devices in an unpredictable state — the firewall is on, but nobody is sure which rules are actually
enforced. Because the firewall governs connectivity, a botched cutover does not just misconfigure a
setting; it can cut a fleet off from line-of-business apps, remote management, or each other.

This is a complete, deploy-it-today package for the controlled migration of Windows Defender
Firewall from GPO to Intune endpoint-security firewall policy, written for an administrator with no
prior migration experience. It does not re-teach net-new firewall design — it is the disciplined
GPO-to-Intune move: inventory the GPO firewall rules, translate them into Intune firewall policy and
firewall rule profiles, manage GPO/Intune coexistence so the two never fight, cut over in rings with
parity validation, and only then retire the GPO firewall settings.

## What you get
- A plain-language Solution Overview of the migration model, GPO-to-Intune rule mapping, and the
  conflict/merge/loop dynamics this migration is built to avoid.
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, ordered Intune steps: inventory, translate, configure
  coexistence, assign in rings, validate parity, retire GPO, expand.
- Five PowerShell scripts for firewall-rule discovery, post-migration rule-parity validation, a
  coverage and conflict report, safe conflict remediation, and a migration-ring group builder.
- Testing and Troubleshooting guides with explicit pass/fail gates and conflict/loop diagnosis.

## What this delivers
A ringed firewall migration — `Migration Ring – Pilot`, `Migration Ring – Wave 1`, and
`Migration Ring – Broad` — in which GPO firewall rules are translated into a named Intune
`Firewall Policy – Migrated Rules – Pilot` and matching `Firewall Rules` profiles, GPO and Intune
coexist without conflict during transition, rule parity is validated on every ring before the next,
and the GPO firewall settings are retired only after parity holds.

## The standard deployment model
Assess → Configure → Pilot → Validate → Expand — with a parity gate and a rollback path at every
ring, because the firewall affects connectivity.

## Outcome
Windows Defender Firewall moved from GPO to Intune — rules translated, conflicts and loops avoided
through managed coexistence, cut over in rings with parity validated, and the legacy GPO firewall
settings cleanly retired — proven on a pilot before you scale.
