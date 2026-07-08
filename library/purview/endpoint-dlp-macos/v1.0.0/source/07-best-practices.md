# 7. Best Practices — Endpoint DLP for macOS (Microsoft Purview)

Field-proven recommendations for a safe, defensible macOS Endpoint DLP rollout.

## Design
- **Simulation first, always.** Create every endpoint policy in **`TestWithoutNotifications`**
  (silent simulation / Audit). Blocking macOS egress is high-impact — validate what a policy *would*
  catch before it interrupts anyone. Advance **TestWithoutNotifications → TestWithNotifications →
  Enable** deliberately, one gate at a time.
- **Scope the Mac pilot by onboarding, not by guesswork.** Endpoint DLP applies to **onboarded**
  devices; control the pilot by onboarding only the pilot Macs first, and keep the policy on the
  **Devices** location only so you're testing macOS behavior in isolation.
- **Let compliance decide *what*, you deliver *how*.** Which content is regulated, what must be blocked
  vs merely audited, and whether an activity is permissible are **compliance/records/privacy/legal**
  determinations. Configure and evidence the control; don't invent the policy.
- **Detect on agreed signals.** Base rules on the **SITs/labels/conditions** data owners signed off —
  not a reflexive "block everything". Over-broad detection creates noise that buries real events.

## Onboarding
- **Push the extensions and Full Disk Access by MDM — never per device.** The macOS **system
  extension**, **network extension**, and **Full Disk Access (PPPC/TCC)** must arrive as MDM profiles
  (Intune or Jamf). A single missing profile means the Mac onboards but **reports nothing** — the
  quietest, most dangerous failure mode.
- **Verify onboarding before you trust the policy.** Confirm each pilot Mac in Purview **device
  onboarding** and drive a test activity that shows up in Activity Explorer **before** assuming the
  policy works. Run **`DLPMac-Onboarding-Check.ps1`** to confirm the profiles are deployed.
- **Reuse the Defender pipeline where present.** macOS Endpoint DLP shares onboarding with Microsoft
  Defender for Endpoint; if MDE is already deployed the extensions may be shared — **verify against
  current Microsoft guidance for your tenant** rather than double-deploying.
- **Stay on supported macOS.** Support is limited to the **three latest major macOS versions** — keep
  the fleet current, and re-verify channel support after a major macOS release.

## Policy and endpoint settings
- **Keep Endpoint DLP settings and rules in lockstep.** The rule's app restriction references the
  `macOS - Restricted Apps` group and its cloud control references your service-domain groups — if the
  group/domain settings drift, the rule acts on the wrong thing. Run **`DLPMac-Validation.ps1`** on
  every change.
- **Mind the browser boundary.** Edge is covered natively; **Chrome/Firefox need the Purview
  extension** for service-domain controls. If the extension isn't deployed, either deploy it or scope
  cloud-egress testing to Edge and say so — don't assume silent coverage.
- **Exclude paths with intent.** File-path exclusions cut noise but can create gaps; document each
  exclusion and why. Never exclude a path that would let regulated content leave unseen.

## Operations
- **Pilot on a few, then wave.** Prove onboarding + simulation on a handful of Macs, pass the gates,
  then expand in waves — each new wave starts in **simulation** before its mode advances.
- **Enforce the highest-risk, lowest-friction channel first.** USB copy is often the cleanest first
  Block; add channels one at a time, watching **`DLPMac-Report.ps1`** for false positives and override
  patterns.
- **Know the one-command rollback.** `Set-DlpCompliancePolicy -Mode TestWithoutNotifications` reverts
  enforcement to silent simulation immediately on next sync. Rehearse it so an over-blocking incident
  is a 30-second fix, not a fire drill.
- **Watch overrides and false positives.** A channel with many user overrides (Block-with-override) or
  false positives is a signal the detection or the channel choice needs tuning — treat it as data, not
  noise.

## Automation & security
- **Run read-only first, -WhatIf before -Commit.** `DLPMac-Discovery` / `DLPMac-Validation` /
  `DLPMac-Report` / `DLPMac-Onboarding-Check` are read-only; **`DLPMac-Set-Policy.ps1`** defaults to
  **-WhatIf** and, even with **-Commit**, only ever creates the policy in **test/simulation** mode —
  enforcement stays a manual, deliberate `Set-DlpCompliancePolicy` step.
- **Least privilege, no secrets.** Connect with the least Purview/Graph scopes each task needs
  (`Connect-IPPSSession` interactively; Graph read scopes for the onboarding check); never place
  credentials, tokens, or secrets in scripts or source control.
- **Evidence is the deliverable.** Export Activity Explorer results (via `DLPMac-Report.ps1`) as the
  audit trail that the control exists and works — this is what makes the macOS DLP posture
  **defensible** to auditors and regulators.
