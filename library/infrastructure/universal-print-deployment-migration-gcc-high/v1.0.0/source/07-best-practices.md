# Best Practices — Universal Print on GCC High

These practices keep a **GCC High** Universal Print deployment correct, compliant, and
retirement-ready. They complement the phase gates in `03-implementation.md` and `05-testing.md`.

## 1. Stay in the sovereign cloud — every time

- **Bookmark only the `.us` portals:** `portal.azure.us`, `portal.office365.us`,
  `intune.microsoft.us`, `entra.microsoft.us`. Never trust a `.com` tab for GCC High work.
- **Every script and Graph call uses `-Environment USGov`.** Make it a review checklist item —
  a missing `-Environment USGov` silently targets Commercial and fails for a GCC High account.
- **Allow the `*.print.azure.us` endpoints explicitly** on proxy/firewall, plus
  `login.microsoftonline.us` and `graph.microsoft.us`. Do not assume Commercial UP URLs cover
  GCC High — they do not.

## 2. License discipline (Government-specific)

- **License admins too.** In Government, administrators must hold an eligible UP license to even
  configure the service — assign it to the operator account first, then wait up to 24 h.
- **Size the job pool from real data.** Each G3/G5 Gov license adds 100 jobs/month to a shared
  pool; unused jobs expire monthly. Use `UPRTG-Report.ps1` + **Usage and Reports** to watch
  consumption and buy 500/10,000-job add-ons *before* you exhaust the pool.
- **A job = one document** regardless of pages/copies/color/duplex — factor that into pool
  sizing.

## 3. Pilot-first, always gate

- Never publish fleet-wide before the pilot passes. Use `UP-Pilot-Users` as the single pilot
  gate, then `UP-Wave1-Users`, `UP-Wave2-Users`, … for controlled expansion.
- **Validate each wave** with Discovery → Validation → Report before the next. A green pilot is
  not permission to skip wave validation.

## 4. Retire print servers safely

- **Prove before you retire.** Decommission a print server only after every printer it hosted is
  Shared in Universal Print and validated in a wave.
- **Soak with the server powered but shares removed** (1–2 weeks) so you have an instant
  fallback before final decommission.
- **Remove the old print path** (GPO print deployment, mapped `\\server\printer`) so clients
  cannot silently keep using the legacy server.

## 5. Respect GCC High parity gaps (design around them)

- **Delegated Administration** (scoped Printer Administrator via Entra administrative units) was
  **coming to GCC High "soon"** at authoring. If you need scoped, per-department admin, **verify
  current GCC High availability** before designing for it; until then, manage centrally with
  **Printer Administrator** / **Printer Technician** roles.
- **macOS client printing** was **not yet available in GCC High** at authoring. Do not promise
  Mac users cloud printing and do not retire a server that is their only path until you **verify
  for GCC High**.
- **No direct-connect UP-ready printers in GCC High yet** — plan on the **connector** for
  existing printers.
- Treat every "verify for GCC High" flag as a real pre-deployment task, because GCC High parity
  changes over time — re-check Microsoft's current Government docs.

## 6. Connector hygiene

- Use a **dedicated, always-on** host (sleep/hibernate disabled, constant internet, .NET 4.8+).
- **Never clone** a registered connector host — parallel clones interfere and block printing.
- If behind a proxy, set the proxy for the **LocalSystem** account (`bitsadmin`) — the connector
  runs as a service, not in a user session.
- Name connectors by site (`UP-Connector-Site1`) and size printers-per-connector per Microsoft
  guidance rather than piling every printer onto one.

## 7. Client-version strategy

- **Prefer Windows 11 22H2+** for pilot and expansion devices — it works natively in GCC High
  with no registry keys.
- Where Windows 10 / older Win 11 must be supported, deploy the **three US Gov registry keys**
  via **Intune** to the user context; standardize the deployment so no device is missed.
- Devices upgraded to Win 11 22H2+ no longer need the keys; leaving them is harmless.

## 8. Naming, targeting, and least privilege

- **Create objects once and reuse them** (`UP-Pilot-Users`, `UP-Pilot-Printer-01`,
  `UP-Connector-Site1`, `UP-<Site>-<Model>-NN`). Consistent names make reports and audits
  legible.
- Target printers to **groups**, never individuals, and build/maintain those groups repeatably
  with `UPRTG-Set-ScopeTargeting.ps1` (always `-WhatIf` first).
- Operate day-to-day as **Printer Administrator**; reserve **Global Administrator** for the
  one-time enable/registration.

## 9. Change safety

- Every remediation runs **`-WhatIf` first** — review the plan, then apply. `UPRTG-Remediation.ps1`
  and `UPRTG-Set-ScopeTargeting.ps1` default to `-WhatIf`.
- Re-run **Discovery → Validation → Report** after any change and keep the dated reports as an
  audit trail.

## 10. Monitoring and lifecycle

- Monthly: run `UPRTG-Report.ps1`, reconcile printers/shares/targeting, and check job-pool
  consumption in **Usage and Reports**.
- Watch Microsoft's Government roadmap/docs for GCC High parity progress (Delegated Admin, macOS,
  direct-connect printers, DoD availability) and revisit any design that was working around a gap.
