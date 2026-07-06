# 6. Troubleshooting Guide — Oracle C2M DevOps Release Management & CI/CD Automation

Use `OC2MDEVOPS-Discovery.sh` for environment/pipeline inventory, `OC2MDEVOPS-Validation.py` for the WLST
parity/health signals on a target (servers running, Inbound Web Service modules active), `OC2MDEVOPS-Report.sql`
for the source-vs-target compare, and `OC2MDEVOPS-Remediation.sh` (dry-run by default) to preview corrective
actions before applying. All are read-only where they touch live systems,
except Remediation which only acts when explicitly told to apply. Single-change CMA/`iwsdeploy` behavior is
detailed in the migration sibling.

## A. A pipeline stage runs by hand but not from the pipeline
| Symptom | Cause | Remediation |
|---|---|---|
| An OUAF utility (`iwsdeploy`, `initialSetup`, `threadpoolworker`) works interactively but the pipeline step fails | The pipeline step did not source `splenviron`, so the product environment/path is not set | Source `splenviron` for the environment at the start of the step; confirm the utilities are on the path with `OC2MDEVOPS-Discovery.sh` |
| A step acts against the wrong environment | The wrong environment was sourced, or `SPLEBASE`/`SPLENVIRON` points elsewhere | Verify the sourced environment matches the target; re-run Discovery to confirm the release/patch level of the environment you are actually on |

## B. Config is live but behaves wrong — code is out of step
- Symptom: the promoted configuration is present but logic behaves as it did before the change. Cause: the
  **build was not promoted in lockstep** with the configuration bundle — one stage ran without the other.
  Run `OC2MDEVOPS-Discovery.sh` on source and target and compare the build/patch level; install the
  matching build, run the framework post-install, and re-validate. Promote the release tuple, not a piece.

## C. Inbound Web Services are stale or not active
- The *Deployment Status* zone / `OC2MDEVOPS-Validation.py` shows a service **not current / not active**:
  the IWS metadata migrated with the bundle but the service was not (re)deployed in the deploy stage. On the
  target, source `splenviron` and run `iwsdeploy[.sh]`, then re-check the status.
- IWS deployment "worked in Dev" but not in QA/Prod: the **online IWS deployment portal is supported only in
  non-production**. Use the command-line `iwsdeploy` for QA and Production in the deploy stage.

## D. The deploy left the environment unhealthy
| Symptom | Cause | Remediation |
|---|---|---|
| Managed/admin server down or started out of order after a deploy | The routine-admin lifecycle automation did not run, or ran the stop/start in the wrong order | Re-run the lifecycle step in the defined order; confirm with `OC2MDEVOPS-Validation.py` that servers are up |
| Batch running against a half-promoted schema, or batch left paused | The `threadpoolworker` / batch quiesce-and-resume was skipped or only half-ran | Ensure the deploy stage quiesces *before* install and resumes *after*; re-run the resume step and validate the batch/threadpool health signal |
| Health check fails after a "successful" deploy | A post-deploy readiness signal (domain up, schema reachable, log clean) is not met | Read `OC2MDEVOPS-Validation.py`, address the failing signal (start the service, fix connectivity), then re-validate |

## E. The config import review showed unexpected changes
- CMA fully **replaces** matching objects from the source. If the migrate-config review lists objects you
  did not intend to change, **stop before applying** — the release scope is wider than the change. Inspect
  the release scope with `OC2MDEVOPS-ScopeHelper.sh`, narrow it, rebuild the bundle, and review again.
  (Import/review discipline: migration sibling.)

## F. Compare report shows a gap after a "successful" pipeline run
- "The pipeline ran" is not parity. Run `OC2MDEVOPS-Report.sql` to see exactly which of config-objects /
  build-level / IWS-status is out of parity, remediate that specific cause by re-running the relevant stage
  (re-import the bundle, re-install the build, or re-deploy an IWS), and re-compare. Use
  `OC2MDEVOPS-Remediation.sh` to preview the corrective action first.

## G. A release needs to be rolled back
- Restore the pre-deploy backup of the target, or re-promote the previously retained release (recorded prior
  bundle and build levels) and re-deploy the prior IWS list, then re-run the routine-admin resume. This is
  why every deploy is preceded by a backup and every artifact is kept in source control. For Production,
  perform the rollback inside the same change window.

## H. Diagnostics quick reference
```sh
./OC2MDEVOPS-Discovery.sh   your-env                       # reachability, release/patch, utilities, artifact locations
wlst.sh OC2MDEVOPS-Validation.py your-target               # WLST parity/health: servers running, IWS modules active (vs stale)
sqlplus -s cisadm@source @OC2MDEVOPS-Report.sql your-release > report_source.txt   # then run vs target and diff
./OC2MDEVOPS-ScopeHelper.sh your-release                   # print a release's scope (build, config request, IWS list)
./OC2MDEVOPS-Remediation.sh your-target --iws your-iws-app # dry-run by default; add --apply to act
```

## I. When to escalate
If source and target are at the same level, every stage ran without error, IWS read active, the build levels
match, and the environment health checks pass — but the compare report still shows a gap after
remediation — capture the `OC2MDEVOPS-Discovery.sh`, `OC2MDEVOPS-Validation.py`, and `OC2MDEVOPS-Report.sql`
output and review the pipeline stage definitions and release scope with the
application-development and release teams. For CMA/`iwsdeploy` reference behavior or a suspected framework
defect, raise it on My Oracle Support with the captured output (verify the note/patch for your version).
