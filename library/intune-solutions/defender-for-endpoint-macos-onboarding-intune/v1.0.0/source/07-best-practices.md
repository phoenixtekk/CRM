# 7. Best Practices — Microsoft Defender for Endpoint for macOS (Deployment & Onboarding via Intune)

- **Profiles first, onboarding second — always.** The single most important practice: deliver and
  confirm the five capability profiles (System Extensions → Full Disk Access → Network Filter →
  Background Services → Notifications) **before** the app and the onboarding package. Onboarding a Mac
  whose extensions and Full Disk Access are not yet approved yields a silently degraded agent that
  looks onboarded but protects nothing.
- **Follow the extension-approval order.** System Extensions must be approved so the endpoint-security
  and network extensions can load; Full Disk Access (PPPC/TCC) must be granted so the endpoint-security
  extension can read the disk; the Network Filter must pre-approve the network extension so protection
  can attach. Each depends on the one before — assign them together, but verify them in this order.
- **Prefer supervised (ADE) Macs.** Automated Device Enrollment lets Intune silently approve system
  extensions and network filters with no user interaction; on unsupervised Macs users may face one-time
  prompts. Enroll via ADE where you can.
- **Health, not the green tick, is the finish line.** A device showing "onboarded" in the portal is
  not proof of protection. Gate on `mdatp health` reporting healthy with `real_time_protection_enabled`
  true and the extensions running (`systemextensionsctl list`).
- **Pilot before you onboard the fleet.** A small `MDE macOS – Pilot Devices` group soaked for several
  business days catches a missing approval or a bad onboarding package on a few Macs instead of all of
  them.
- **Use Microsoft's published identifiers — never invent them.** The Defender team identifier,
  extension bundle identifiers, network extension identifier, PPPC code requirement, and the onboarding
  package are Microsoft-published and tenant-specific. Always take them from the current Microsoft docs
  and your tenant's Defender-portal download.
- **Use the right macOS surface for each payload.** Prefer the Settings catalog / Templates where the
  payload is exposed; use a custom `.mobileconfig` (Templates → Custom) for the onboarding payload and
  for any capability payload the catalog cannot reach.
- **Name and tag everything consistently.** Use the `MDE macOS – <purpose>` convention (`MDE macOS –
  System Extensions`, `– Onboarding`, etc.) and put the tag `MDE-macOS` in every profile/app
  description so the object set is easy to find and audit.
- **Keep the APNs certificate alive.** Apple management — and therefore every MDE profile and the
  onboarding payload — stops the moment the Apple MDM Push certificate expires. Track its renewal date
  and renew with the same Apple ID before expiry.
- **Expand in the same order you deployed.** When adding production, assign the five capability profiles
  to the production group and confirm they apply **before** assigning the app and then the onboarding
  profile. Roll out in waves and re-check posture after each wave.
- **Keep a rollback ready.** Removing the `MDE macOS – Onboarding` assignment offboards cleanly on the
  next cycle; use it to fix a bad onboarding or a degraded agent, then reconfirm the capability profiles
  and reassign onboarding. Never re-onboard on top of missing approvals.
- **Prove protection with evidence.** Use `mdatp health`, `systemextensionsctl list`, the Defender
  portal device state, and `MACMDE-Report.ps1` as your audit evidence that each Mac is genuinely
  onboarded and healthy.
