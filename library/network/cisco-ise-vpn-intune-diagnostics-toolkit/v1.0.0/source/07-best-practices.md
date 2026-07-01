# Best Practices — Repeatable Triage, Evidence, and Escalation

The Diagnostic Playbook isolates a failing layer in one incident. These practices make that repeatable across incidents and across the team, so every triage is faster and cleaner than the last. Everything here stays **read-only** and vendor-boundary-aware.

> Reuse names verbatim: **VPN client-authentication certificate**, **VPN configuration profile**, **certificate configuration profile**, **trusted-root certificate profile**, **CISEDIAG-Compliance-Reader**, **CISEDIAG-Pilot-Devices**.

## 1. Triage in a fixed order — top-down, every time

- Always start at **Step 0** (does anyone connect?) before touching a device. It's the single biggest time-saver: it splits shared-service breaks from per-device faults in one check.
- Descend the layers **L1 → L2 → L3 → L4**, never skipping. A confirmed-healthy layer above is a fact you can bank; guessing at L3 while L1 is unverified wastes the incident.
- Treat **L3/L4 symptoms as pointers, not causes.** EAP-TLS failures almost always resolve to an L1 chain/trust fact; posture quarantines resolve to an L4 compliance or connector fact. Let the tree send you back.

## 2. Keep a known-good baseline current

- Maintain at least one working reference device (R7), ideally from **CISEDIAG-Pilot-Devices**, and record its **issuer, template, VPN profile name, and gateway**. Diagnosis is comparison; a baseline turns open questions into diffs.
- Refresh the baseline whenever the CA, ISE server certificate, trusted roots, or VPN profile change. A stale baseline lies.

## 3. Collect evidence first, reason second

- Run `CISEDIAG-Collect.ps1` **once, early** — snapshot the whole device state before you start changing anything, so you have a before/after and don't lose the failing state.
- Prefer the scripts over click-by-click portal checks for anything you'll do more than once: they're consistent, timestamped, and produce a bundle you can attach to the ticket.
- Snapshot **all layers** even when you think you know the branch. The consolidated `CISEDIAG-Report.ps1` frequently reveals a second, quieter fault (e.g. a trusted-root profile that's also failing) that would have caused a repeat incident.

## 4. Read-only discipline

- Diagnostics **observe; they never remediate.** No script here changes device, tenant, or ISE state. This keeps triage safe to run in production, on a user's device, mid-incident, without a change window.
- When you *do* remediate, do it in the owning plane (Intune profile fix, compliance-policy fix, or a Cisco-side change by the ISE admin) — deliberately, under change control for anything shared or outward-facing.

## 5. Respect the vendor boundary

- For **Cisco Secure Client (L2)** and **Cisco ISE (L3/L4)** internals, gather the **evidence the tree names** (the EAP-TLS failure reason, the matched authorization rule, the DART bundle) and read it — but follow **Cisco's official documentation** for exact console navigation and posture-module specifics. Don't invent menu paths; ISE versions differ.
- Author every check on the **Intune/Entra/certificate side** at exact click level — that's where your leverage and precision are.

## 6. Least-privilege, auditable access

- Use **read-only** roles (Global Reader / a custom read role) for portal work, and **read scopes only** for Graph. The toolkit never needs write access.
- For repeatable/unattended reads, use the dedicated **CISEDIAG-Compliance-Reader** app with a **certificate** credential (not a secret in a script). Never hard-code credentials; pass IDs/thumbprints at runtime or from a vault.

## 7. Escalate to Cisco with a complete evidence package

When the fault proves to live inside Cisco Secure Client or ISE, escalate **once, with everything** — don't hand over a symptom. Attach:

- The consolidated `CISEDIAG-Report.ps1` output (proves L1/L2/L4-Intune are healthy on your side).
- The `CISEDIAG-Validate-Certificate.ps1` output (device cert chain, issuer, template, EKU, validity).
- The **Cisco Secure Client DART** bundle (L2 evidence), collected per Cisco docs.
- The **ISE detailed authentication report** for the exact failing attempt (timestamp/username/MAC), with the EAP-TLS failure reason or matched authorization rule highlighted.
- Your known-good reference facts (issuer/template/gateway) so Cisco can compare working vs. failing.

The full escalation checklist lives in `06-troubleshooting.md`. A complete package turns a multi-round Cisco case into a single, decisive one.

## 8. Close the loop

- After every incident, confirm with the matching **gate in `05-testing.md`** and the end-to-end check — a fix isn't done until the report is green and ISE shows success + permit.
- Record the **root-cause layer** on the ticket (L1/L2/L3/L4/shared). Patterns emerge: repeated L1 chain failures mean the trusted-root profile needs attention; repeated L4 quarantines mean the connector needs monitoring. Fix the pattern, not just the incident.
