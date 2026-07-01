# 1. Solution Overview — Forcepoint Neo to Netskope Migration (Legacy Web Filtering)

## What this migration is
This is a controlled migration of web-filtering enforcement from a legacy agent-based platform
(Forcepoint Neo) to Netskope's Secure Web Gateway (SWG). The legacy Forcepoint Neo agent steers and
filters a device's web traffic today; the goal is to move that enforcement to the Netskope client
without a gap in protection and without two agents fighting over the same outbound traffic. The work
is done in stages — translate policy, run the agents side by side under controlled steering, cut over
ring by ring, validate parity, then remove the legacy agent and decommission the platform.

## Why this is risky (and why a controlled migration matters)
Web filtering sits inline on live user traffic. Two specific failure modes make a naive swap
dangerous, and they are the reason this solution exists:
- Two agents, one traffic path. Both Forcepoint Neo and the Netskope client want to intercept and
  steer outbound web traffic. Run both in enforce mode at once and they collide — duplicated SSL
  inspection, broken certificate chains, dropped or looping connections, and unpredictable which
  agent actually filters a given request. Coexistence must be deliberate: one agent enforces while
  the other is present-but-passive, then they swap.
- Cut over too fast and you lose coverage or break access. Remove Forcepoint before Netskope policy
  is proven and you create a protection gap; flip Netskope to full enforce before policy parity is
  validated and you over-block (broken business apps) or under-block (categories that used to be
  denied now allowed). Staged steering with a parity gate is what prevents both.

Because of this, the migration is never a single switch. It is an assess-translate-coexist-validate
sequence with a pilot/parity gate before any legacy decommission, and a documented rollback at every
stage.

## How it works
1. Inventory the legacy estate: which devices run the Forcepoint Neo agent, and export the current
   Forcepoint web-filtering policy (categories, allow/deny lists, SSL-inspection scope, exceptions).
2. Translate the legacy policy into an equivalent Netskope SWG policy set — the named
   `Translated Web Filtering Policy - Org - Netskope` artifact — mapping legacy categories and
   rules to Netskope real-time-protection policies.
3. Build migration rings (device groups) so the cutover is staged, not fleet-wide.
4. Manage coexistence: deploy the Netskope client in a present-but-passive posture alongside
   Forcepoint, so only one agent enforces at a time and the two never both inspect the same traffic.
5. Cut over a ring: switch that ring's steering from `Forcepoint-steered` to `Netskope-steered`,
   validate parity, then remove the Forcepoint Neo agent from those devices.
6. Validate parity per ring against a fixed category/URL test set, then expand to the next ring.
7. After all rings pass and a final parity gate, decommission the Forcepoint platform.

## Named artifacts (reused verbatim everywhere)
Every object is named `<Purpose> - <Scope> - <Stage>` so the same string is reused across the docs
and scripts:
- `Translated Web Filtering Policy - Org - Netskope` — the Netskope SWG policy set that mirrors the legacy Forcepoint web-filtering policy.
- `Migration Ring - Pilot - Cutover` — the first, small device group cut over to Netskope.
- `Migration Ring - Broad - Cutover` — the remaining fleet, cut over after the pilot passes.
- `Legacy Estate - Forcepoint Neo - Inventory` — the device group representing all endpoints still running the Forcepoint Neo agent.
- `Steering Group - Netskope - Enforce` — devices whose traffic is actively steered to and enforced by Netskope.
- `Coexistence Group - Netskope - Passive` — devices with the Netskope client installed but not yet enforcing (Forcepoint still steers).

## What you can control
- Which devices are in each migration ring and the order they cut over.
- The coexistence posture per ring (which agent enforces; which is passive).
- The translated policy parity (categories, allow/deny, SSL-inspection scope, exceptions).
- The steering cutover point per ring and the legacy-agent removal per ring.
- The decommission gate — legacy platform removed only after all rings pass parity.

## Benefits
- No protection gap — Netskope is proven on a ring before Forcepoint is removed from it.
- No agent collision — coexistence is deliberate; only one agent enforces a given device's traffic.
- Parity, not guesswork — a fixed test set proves the translated policy matches the legacy behavior.
- Staged blast radius — a bad translation or steering issue is caught on the pilot ring, not the fleet.
- Clean decommission — the legacy agent is removed per ring and the platform retired on evidence.

## Limitations (be honest with buyers)
- Exact Netskope and Forcepoint console screens, menu paths, and policy-export steps change over time and are deferred to each vendor's official documentation and your tenant/console.
- Policy translation is a mapping exercise: legacy categories and custom rules do not always map one-to-one to Netskope categories; some require a judgment call and a parity test.
- This solution covers web-filtering enforcement migration; other Forcepoint modules (DLP, CASB, ZTNA) are separate migrations with their own parity work.
- Endpoint agent install/removal and group targeting are managed via Microsoft Intune here; non-Intune-managed estates need an equivalent deployment mechanism.

## The standard deployment model
> Inventory and translate legacy policy -> stand up the translated Netskope policy and coexistence ->
> cut over and validate the pilot ring -> expand ring by ring -> decommission Forcepoint after a final
> parity gate. Pattern: `Assess -> Configure -> Pilot -> Validate -> Expand.`
