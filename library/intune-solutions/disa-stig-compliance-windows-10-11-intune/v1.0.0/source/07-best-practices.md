# 7. Best Practices — DISA STIG Compliance for Windows 10 & 11 (Microsoft Intune)

- Pilot before you harden the fleet. A small `STIG Win10/11 – Pilot Devices` group soaked against real mission apps catches breakage before it reaches production — the single most important practice, because hardening can break mission apps.
- Prioritize by CAT severity. Deploy CAT I and CAT II first and broadly; add CAT III where practical. Open CAT I findings are the hardest to get accepted, so close them earliest.
- Work from the STIG Viewer / SCAP, not memory. The authoritative rule list, CAT severities, values, and check/fix text live in the current DISA Windows 10/11 STIG. Always configure from the release you obtained.
- Use the settings catalog first, ADMX only when needed. Most rules live in the settings catalog; reserve imported ADMX for the minority of rules that have no catalog equivalent.
- Name and tag everything consistently. Use the `<Purpose> – <Scope> – <Stage>` convention (`STIG Win10/11 – CAT II – Pilot`, etc.) and put the version tag `STIG-Win-vYYYY.MM` in every policy description so the live STIG release is always visible and auditable.
- Track every exception as a POA&M. A healthy, assessable baseline has documented POA&M items, not silent gaps — record the Rule/Vuln ID, CAT, risk, compensating control, owner, and remediation milestone.
- Treat each new STIG release as a change, not a footnote. Run the full Obtain → Diff → Assess/Approve → Update → Re-validate → Record lifecycle. Diff with `STIG-Compare-StigVersion.ps1` so you never miss an added or changed rule.
- Detect drift on a cadence. Run `STIG-Report.ps1` regularly and reapply with `STIG-Remediation.ps1` (default `-WhatIf`) so devices don't quietly fall out of compliance between releases.
- Resolve policy conflicts at the source. If a device repeatedly drifts, find the conflicting Intune policy setting the same rule differently — don't just keep remediating the symptom.
- Keep a rollback ready. Removing a policy assignment (or setting a rule to Not configured) is the fastest safe rollback when hardening breaks a mission app; record what you rolled back as a POA&M item.
- Prove compliance with evidence. Use Intune per-setting/device status plus the report script, reconciled to a STIG Viewer / SCAP scan, as your assessment evidence that each device received the STIG values.
- Distinguish the STIG from the Microsoft baselines. Do not assume a Microsoft security baseline satisfies a STIG assessment; build the STIG rules explicitly and keep the mapping.
