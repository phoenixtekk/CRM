# 5. Testing & Acceptance — Commercial-to-GCC High Microsoft 365 & Azure Migration Program (Exchange, SharePoint, Teams, AVD)

Testing is organized as numbered tests, each with an explicit **PASS/FAIL gate**, grouped by workstream. Each workstream also has an **acceptance gate** — the combined condition that must be met before that workstream's wave is declared complete and before the corresponding commercial resources may be decommissioned (Phase 10).

> Run `scripts\GCCHIGH-Validation.ps1` to automate the scripted portions; the manual gates below are operator-verified. Record results in `Validation Results – Program – <Wave NN>`.

---

## Group 1 — Identity & Access

**T1.1 — Target sign-in.** A migrated pilot user signs in at `https://login.microsoftonline.us`.
- PASS: authenticates and reaches the GCC High portal. FAIL: any auth error.

**T1.2 — Licensing.** User holds the assigned GCC High license via `All Migrated Users – Identity – Target`.
- PASS: license shows assigned, services enabled. FAIL: unlicensed/partial.

**T1.3 — Conditional access / MFA.** User is prompted by `CA – Require MFA – Target`; legacy auth blocked.
- PASS: MFA enforced, legacy blocked. FAIL: policy not applied.

**Identity acceptance gate:** T1.1–T1.3 PASS for 100% of the wave's users.

---

## Group 2 — Exchange (mail flow)

**T2.1 — Inbound mail.** Send external → migrated mailbox after MX cutover.
- PASS: delivered to GCC High mailbox within SLA, headers show `*.office365.us` routing. FAIL: NDR/misroute/delay.

**T2.2 — Outbound mail.** Migrated mailbox → external recipient.
- PASS: delivered; SPF/DKIM/DMARC pass at recipient. FAIL: auth failure/quarantine.

**T2.3 — Content parity.** Compare folder counts/recent items + calendar + contacts vs. source baseline.
- PASS: counts within tolerance, calendar/contacts present. FAIL: missing items beyond tolerance.

**T2.4 — Client connectivity.** Outlook (desktop + mobile) connects to `https://outlook.office365.us`.
- PASS: autodiscover resolves, profile connects. FAIL: cannot connect.

**Exchange acceptance gate:** T2.1–T2.4 PASS; zero unresolved NDRs for wave users.

---

## Group 3 — SharePoint / OneDrive (content parity)

**T3.1 — Structure parity.** Site/library/list counts match source baseline.
- PASS: parity within tolerance. FAIL: missing structures.

**T3.2 — File parity + integrity.** File counts and sample checksums/versions match.
- PASS: counts match, samples open, versions present. FAIL: missing/corrupt files.

**T3.3 — Permissions.** Sampled permissions resolve to correct target Entra principals.
- PASS: access correct (incl. deny). FAIL: broken/over-broad permissions.

**SharePoint/OneDrive acceptance gate:** T3.1–T3.3 PASS for all sites in the wave.

---

## Group 4 — Teams (functionality)

**T4.1 — Team & membership.** Each `Team – <SourceName> – Target` exists with correct members/owners.
- PASS: membership matches. FAIL: missing members/owners.

**T4.2 — Channel files.** Channel **Files** tab resolves to the migrated `.us` SharePoint site and files open.
- PASS: files present and open. FAIL: broken file location.

**T4.3 — Collaboration.** Post a message, start a call/meeting in a channel.
- PASS: messaging + calling work. FAIL: feature broken.

**T4.4 — Chat scope confirmation.** Confirm migrated chat history matches the documented in-scope set.
- PASS: matches documented scope. FAIL: scope not as documented.

**Teams acceptance gate:** T4.1–T4.4 PASS for all teams in the wave.

---

## Group 5 — Azure IaaS Servers (failover boot + app validation)

**T5.1 — Replication health.** ASR shows each VM in `Replication Group – Servers – <Wave NN>` 100% synchronized, RPO within target.
- PASS: protected, healthy, RPO met. FAIL: critical/stale.

**T5.2 — Test failover boot.** Isolated test failover boots the VM; OS reaches login.
- PASS: VM boots, OS healthy. FAIL: boot failure/BSOD.

**T5.3 — Application validation.** On the failed-over VM, core service/app starts and responds.
- PASS: app functional. FAIL: app down.

**T5.4 — Networking.** Post-planned-failover VM has correct NIC/NSG/IP and internal DNS resolves.
- PASS: reachable per design. FAIL: connectivity broken.

**Server acceptance gate:** T5.1–T5.4 PASS; test failover validated **before** planned failover.

---

## Group 6 — Azure Apps / PaaS

**T6.1 — Service up.** Each redeployed PaaS resource in `RG – PaaS – Target` is running and reachable on its `.us`/Gov endpoint.
- PASS: healthy. FAIL: down/unreachable.

**T6.2 — Data parity.** Migrated database/storage row/object counts match source baseline.
- PASS: parity within tolerance. FAIL: data loss.

**T6.3 — App auth.** Re-created app registration authenticates against GCC High Entra; redirect URIs work.
- PASS: auth succeeds. FAIL: auth/redirect error.

**PaaS acceptance gate:** T6.1–T6.3 PASS for each app.

---

## Group 7 — AVD / VDI (session host login + profile)

**T7.1 — Host pool health.** `Host Pool – AVD – Target` session hosts show **Available**.
- PASS: hosts available. FAIL: unavailable/errors.

**T7.2 — User login.** A wave user signs in to `Workspace – AVD – Target` / `App Group – Desktop – Target`.
- PASS: desktop loads. FAIL: cannot connect.

**T7.3 — FSLogix profile.** The user's migrated FSLogix container mounts (settings/desktop/docs present).
- PASS: profile loads from `FSLogix Share – Profiles – Target`. FAIL: temp profile/failed mount.

**AVD acceptance gate:** T7.1–T7.3 PASS for the wave's AVD users.

---

## Group 8 — Identity & DNS Cutover (program-level)

**T8.1 — Domain ownership.** Each in-scope domain is verified in the GCC High tenant only.
- PASS: verified in GCC High, released from commercial. FAIL: conflict/unverified.

**T8.2 — DNS records.** MX/autodiscover/SPF/DKIM/DMARC resolve to GCC High values.
- PASS: all correct (`nslookup` confirms). FAIL: stale/incorrect.

**DNS acceptance gate:** T8.1–T8.2 PASS before declaring wave cutover complete.

---

## Program-level exit (per wave)

A wave is **complete** only when **every** workstream acceptance gate above is PASS. **No commercial resource may be decommissioned** (Phase 10) until its wave's gates pass and the grace period defined in `07-best-practices.md` has elapsed.
