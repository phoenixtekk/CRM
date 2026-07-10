# 7. Best Practices — Cloud Sync Provisioning Triage

- **Read the provisioning log first.** The **provisioning logs** (searchable by AD `ObjectGuid`) are
  the authoritative statement of what the service decided and why. Start every "not provisioning" case
  by reading the object's log entry — don't theorize before you've read `JoinNotFound` (or whatever the
  real reason is) with your own eyes.
- **Confirm which engine you actually run.** Cloud sync and Connect Sync are different products with
  different tooling. Before touching anything, confirm this is **cloud sync** (a provisioning agent, a
  configuration under **Entra Connect → Cloud sync**) and not **Connect Sync** (the `ADSync` service) —
  applying Connect Sync habits to a cloud sync configuration wastes the incident.
- **Remember provision on demand ignores scope.** On-demand runs the pipeline for one object regardless
  of the scoping filters, so an on-demand skip is usually *not* about scope for that run — while the
  **scheduled cycle only creates in-scope users**. Diagnose scope against the scheduled behaviour.
- **Suspect a pre-existing target when history includes another sync method.** A leftover from an
  earlier Connect Sync deployment, or a cloud-only account with the same `userPrincipalName` /
  `proxyAddresses`, is the most common reason an object matches to nothing new and is skipped.
  Reconcile duplicates before assuming the engine is broken.
- **After any scope or configuration change, restart provisioning.** Cloud sync uses watermarks to skip
  already-seen objects; changing scope does not automatically re-evaluate them. Restart provisioning to
  clear watermarks so objects are re-discovered.
- **Never test with a built-in account.** `IsCriticalSystemObject` objects (built-in users and groups)
  and replication-victim objects are filtered out by design. Always test provisioning with an ordinary
  user in a known in-scope OU.
- **Treat quarantine as a symptom, not a cause.** A quarantined job means the target consistently
  rejected calls (often bad admin credentials). Fix the underlying auth failure, then clear quarantine
  / restart — clearing quarantine without fixing the cause just re-quarantines.
- **Respect the object-deletion threshold.** In Connect + cloud sync coexistence the accidental-
  deletion safeguard can block a run. Investigate *why* the run wants to change that many objects before
  disabling the safeguard, and **re-enable it** after the run.
- **Keep the agent healthy and reachable.** The **"Microsoft Entra Provisioning Agent"** and
  **"Microsoft Entra Connect Agent Updater"** services must be Running, the agent Healthy in the portal,
  and outbound **80/443** to the documented endpoints open. An unhealthy agent silently stops exporting.
- **Diagnose read-only; remediate under change control.** The tenant-wide actions (re-enabling org
  sync, clearing quarantine, disabling the deletion safeguard) affect every synced object. Keep
  diagnosis read-only, and make the change through your change process with a named approver.
- **Close the loop.** Record the root-cause condition on the ticket (already-exists / out-of-scope /
  critical object / quarantine / SP missing / threshold / agent), the `ObjectGuid`, and the
  provisioning-log action before and after. A named root cause makes the next case faster.
