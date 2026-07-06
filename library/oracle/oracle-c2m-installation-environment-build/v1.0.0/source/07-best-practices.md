# 7. Best Practices — Oracle Customer to Meter (C2M) Installation & Multi-Environment Build

- **Certify the stack before you touch an installer.** Confirm OS, Java, WebLogic 14c, and Oracle
  Database are a combination certified *together* for your C2M release against the MOS certification
  matrix. This is the first gate, not a post-install check — an uncertified stack fails installs, blocks
  patches, and loses supportability.

- **Build non-production first, always.** Build and fully validate `C2MDEV`, then `C2MTST`, and only then
  `C2MPRD` inside an approved change window. Production should be the *third* time you run the procedure,
  not the first.

- **Decide every value up front on a per-environment worksheet.** The OUAF installer is prompt-driven;
  improvising values is how Dev, Test, and Prod drift apart. Fill the worksheet from Oracle's
  installation-worksheet section so the three builds differ only by host/port/DB.

- **Reuse the same object names in every environment.** Keep `C2MDEV`/`C2MTST`/`C2MPRD`, `cissys`,
  `c2m_domain`, `AdminServer`, `c2m_server1`, `CISADM`/`CISUSER`/`CISREAD`, and the `cisusers` role
  identical across tiers. Environment-agnostic names make scripts, runbooks, and defect reproduction
  work across all three.

- **Never hand-edit `ENVIRON.INI`.** It is generated. To change a value, re-run `configureEnv.sh` then
  `initialSetup.sh` so every templated config file is regenerated consistently. Editing the file by hand
  drifts the templates and creates subtle, hard-to-find breakage.

- **Keep the database install separate and DBA-owned.** The schema is loaded by `OraDBI` over the
  tablespaces named in the DBA's `Storage.xml`, with its own (possibly different) Java. Confirm the
  tablespaces exist first — a missing one aborts the install — and always check the
  `Install-Upgrade/logs` before calling the schema done.

- **Incorporate `setUserOverride.sh` into the domain start-up.** The OUAF-required JVM/classpath settings
  from `$SPLEBASE/tools/examples/bin/setUserOverride.sh` must reach the WebLogic domain, or the C2M
  application will not deploy or run correctly. Verify it is applied after every product install or
  rollup.

- **Choose free ports and check them before creating the domain.** On shared hosts, a port collision
  silently blocks domain startup. Verify the Admin/Managed/SSL ports are free (the discovery script
  checks) before you create `c2m_domain`.

- **Back up before every disruptive step and know your rollback.** Before an install, rollup, or schema
  load — especially in Production — back up `$SPLEBASE`, the domain config, and the database, and confirm
  the restore path. The backup is the rollback anchor for Assess → Configure → Pilot → Validate → Expand.

- **Apply required rollups; get patch numbers from MOS.** Post-release rollups are often mandatory for a
  supported install. They are MOS-gated — pull the numbers and readmes from MOS and follow the rollup's
  own instructions; never skip a required rollup to save time.

- **Prove the build survives a bounce.** A green first-start is not a finished environment. Stop and
  start (`spl.sh -stop`/`-start`) and re-validate; a build that does not come back cleanly is not done.

- **Keep secrets out of scripts and configs.** Read database and WebLogic credentials from prompts, the
  OUAF keystore, or the environment — never hard-code them into scripts, ENVIRON.INI overrides, or the
  worksheet you circulate. The supplied automation reads credentials at run time and stores none.

- **Remediate dry-run first.** Run `OC2MINST-Remediation.sh` with no flag to see the planned safe fixes,
  review them, then re-run with `-apply`. Never let an unattended fix touch a Production environment.

- **Record each environment as a reproducible definition.** Save the validated build report with the
  `$SPLENVIRON`, hosts/ports, DB service, and versions. The goal of a multi-environment build is that any
  tier can be rebuilt from its recorded inputs, not reverse-engineered.

- **Hand off the layers this build does not own.** SSO/SSL/keystore, Coherence/JMS/IWS tuning, batch
  scheduling, and monitoring are separate solutions. Deliver a certified, healthy baseline install and
  let the specialized runbooks take it from there — keep this scope clean.
