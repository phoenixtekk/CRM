# 7. Best Practices — SCCM Task Sequence Troubleshooting & Status Message Analysis

- **Always read the phase-correct log.** Most stalled troubleshooting is someone reading the wrong
  `smsts.log`. Confirm the phase (WinPE vs. full OS) first, then open the matching path.
- **Capture the exit code before anything else.** The non-zero exit code from the `11124`/`11170`
  message is the fastest key to the root cause — record it, then confirm in the log.
- **Enable command support (F8) on boot images** in your lab/pilot so you can browse
  `x:\windows\temp\smstslog` live during a WinPE failure. Disable it on production boot images.
- **Use CMTrace / OneTrace, never Notepad.** Timeline view and error highlighting turn a sprawling
  log into a readable failure chain.
- **Save a reusable status message query.** Keep `TS Execution Errors – OSD – Triage` so every
  engineer triages the same way instead of rebuilding the query each time.
- **Check content status early.** A large share of OSD failures are content on an unreachable or
  unhealthy DP — verify **Content Status** and boundary groups before deeper digging.
- **Keep the boot image current.** Add the right NIC/storage drivers and update DPs after any hardware
  refresh; a missing boot NIC driver is the classic PXE/network failure.
- **Fix the class, not the symptom.** Classify (content / driver / network / app / reboot / variable)
  and apply the class fix — re-imaging without a diagnosis just repeats the failure.
- **Record every resolution.** A short log of ID → exit code → cause → fix compounds: the second
  occurrence of a failure should be minutes, not hours.
- **Pilot the runbook on real failures.** Validate it on at least two distinct failures before making
  it the team standard — assign once, repeat everywhere.
