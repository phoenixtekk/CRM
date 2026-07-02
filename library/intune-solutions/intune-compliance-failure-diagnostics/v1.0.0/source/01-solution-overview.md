# Solution Overview

## What this solution does

A device turns up **non-compliant** in Intune. Conditional Access blocks the user. The
help desk cannot say *which* setting failed, *why* it failed, or *when* it will clear.
People start guessing — and the worst guess is "disable the compliance policy so the user
can work," which strips protection from the whole fleet.

This solution replaces the guesswork with a **root-cause method**. It teaches you exactly
how Intune decides a device is compliant or not, where each result surfaces, and gives you
a symptom-driven decision tree plus five PowerShell scripts to read the **per-setting
failure reason**, understand the **evaluation timing and grace period**, see the
**Conditional Access blast radius**, and remediate **safely** — without turning policy off
for everyone.

## How compliance evaluation actually works

Compliance in Intune is a chain. A break anywhere in the chain shows up at the end as
"non-compliant," so you must read the chain from left to right:

**Policy → per-setting state → grace period → device compliance state → Conditional Access gate**

1. **Compliance policy.** In the admin center you author a **Compliance policy** under
   **Devices → Manage devices → Compliance** (older tenants: **Devices → Compliance
   policies → Policies**). A policy is a named object (for example
   `Win-Baseline-Compliance`) that contains one or more **settings** — BitLocker,
   Secure Boot, Minimum OS version, Firewall, Antivirus, Defender signatures, a
   **Custom compliance** script result, and so on. The policy is **assigned** to a group.

2. **Per-setting state.** The device's Intune management extension evaluates **each
   setting independently** and reports a state per setting: **Compliant**, **Not
   compliant**, **Error**, or **Not applicable**. This is the single most important fact
   in the whole solution: **a device is only as compliant as its worst setting.** One
   failing setting makes the whole device non-compliant, even if every other setting
   passes. The per-setting result — including the failure reason string — is what your
   diagnosis is built on.

3. **Grace period (Actions for noncompliance).** Each compliance policy has an **Actions
   for noncompliance** tab. The default action is **Mark device noncompliant** with a
   schedule of **Immediately (0 days)**, but you can set a grace period (for example
   `1 day` or `3 days`). During grace, the device has *failed a setting* but is still
   reported **Compliant** to Conditional Access — the clock is running. When the grace
   period **expires**, the device flips to **Not compliant** and CA can block it. A device
   that "was fine yesterday and is blocked today" with no config change is almost always a
   **grace expiry**, not a new failure.

4. **Device compliance state.** Intune rolls the per-setting states (and grace) up into
   one **device compliance state** shown on the device blade and in reports. If the device
   has policies from more than one source, the **least-compliant** result wins.

5. **Conditional Access gate.** Conditional Access lives in **Entra** (not Intune) under
   **Protection → Conditional Access → Policies**. A CA policy with the grant control
   **Require device to be marked as compliant** reads the device compliance state at
   sign-in. Compliant → access granted. Not compliant → access blocked (or a different
   grant applied). **CA is the thing the user feels** — but the *cause* is upstream in the
   per-setting state. Never diagnose the block at the CA layer alone.

## Evaluation timing — why results lag

Compliance is **not** instant. Understanding the timing prevents the most common false
alarm ("I fixed it but it still says non-compliant"):

- The device evaluates compliance on a **check-in cycle** (typically every ~8 hours, and
  shortly after enrollment/restart). A fix applied on the device is not reflected until the
  **next check-in and report**.
- Forcing a sync (device **Settings → Accounts → Access work or school → Info → Sync**, or
  Intune **device → Sync**) triggers an earlier check-in, but the **report** in the console
  still needs a few minutes to update.
- Conditional Access reads the **last reported** state. Even after the device reports
  compliant, the user may need to **sign out and back in** (or wait for token refresh) for
  CA to re-read it.

So there are three clocks to keep straight: **device evaluation**, **report freshness**,
and **CA token/sign-in**. A "still failing" symptom is often just one of these clocks not
having ticked yet.

## Where results surface (know every window)

You will read the same failure from several places; each shows a different slice:

- **Per device:** Intune → **Devices → All devices → <device> → Device compliance**. Shows
  each assigned policy and, expanding a policy, the **per-setting** state and the **failure
  reason**. This is your primary diagnostic surface.
- **Per policy:** Intune → **Devices → Compliance → <policy> → Device status** /
  **Per-setting status**. Shows how many devices fail, and which setting fails most.
- **Fleet:** Intune → **Devices → Monitor → Noncompliant devices**, and **Reports →
  Device compliance**. Shows the population and trend.
- **Conditional Access impact:** Entra → **Protection → Conditional Access → Policies**
  (which policies require compliance and who they target), and **Sign-in logs** (filter by
  user/device to see whether a CA "Require compliant device" control **failed** at
  sign-in). This is how you measure the **blast radius** of a non-compliant device.

## The diagnostic model

Every diagnosis in this solution answers five questions, in order:

1. **Which setting failed?** (read the per-setting state and reason — never assume)
2. **Is this timing, or a real failure?** (evaluation lag vs an actual failing setting)
3. **Has grace expired?** (failed-but-in-grace vs failed-and-enforced)
4. **Built-in or custom rule?** (a native setting vs a Custom compliance script result)
5. **What does Conditional Access do about it?** (the blast radius — who is blocked)

Answer those five and you know the root cause and the safe fix. The **Diagnostic Playbook**
(`03-implementation.md`) is the symptom tree that walks each branch; the scripts read the
raw data so you are never guessing.
