# 6. Troubleshooting Guide — Oracle C2M Environment Migration & Code Promotion (Dev → QA → Prod)

Use `OC2MMIG-Discovery.sh` for environment/config inventory, `OC2MMIG-Validation.sh` for parity signals on
a target, `OC2MMIG-Report.sh` for the source-vs-target compare, and `OC2MMIG-Remediation.sh` (dry-run by
default) to preview corrective actions before applying. All four are read-only where they touch live
systems, except Remediation which only acts when explicitly told to apply.

## A. An object is missing in the target after import
| Symptom | Cause | Remediation |
|---|---|---|
| A configuration object promoted fine in Dev but is absent in the target | No Migration Plan for that (often custom) object type, so it was silently excluded from the bundle | Author a Migration Plan for the object's MO/business object, add it to the Migration Request, re-export and re-import; confirm with `OC2MMIG-Report.sh` |
| An object in the Migration Request never appears in the export | The request's declared scope does not actually include it | Inspect the request with `OC2MMIG-ScopeHelper.sh`, correct the scope, re-export |
| A target-only object you expected to be removed is still present | CMA import **does not delete** target-only records | Retire the object deliberately in the target (import does not clean up); this is by design |

## B. The bundle will not export or import
| Symptom | Cause | Remediation |
|---|---|---|
| Export produces no file | Migration Assistant Configuration missing/incomplete, or export directory not writable | Confirm the master record and directory ownership on the source; re-run `OC2MMIG-Validation.sh` |
| Import cannot find the file | File never reached the target import directory | Verify the transfer path (Requirement 2.5); copy the binary export file into the target import directory and retry |
| Import errors on apply | Source/target framework-version gap or unreconciled dependency | Compare levels with `OC2MMIG-Discovery.sh`; align target to source release/patch, or follow Oracle's cross-version CMA guidance (verify for your version on MOS) |

## C. Inbound Web Services are stale or failing
- The *Deployment Status* zone shows a service **not current** (its service revision differs from the
  deployed value): the IWS metadata migrated with the bundle but the service was not (re)deployed. On the
  target, source `splenviron` and run `iwsdeploy[.sh]`, then re-check the status.
- IWS deployment "worked in Dev" but not in QA/Prod: the **online deployment portal is supported only in
  non-production**. Use the command-line `iwsdeploy` for QA and Production.
- Build fails with no services deployed: at least one Inbound Web Service must be defined before the build
  runs. Confirm the in-scope IWS exist in the target, then re-deploy.

## D. Configuration is live but behaves wrong — code is out of step
- Symptom: the promoted configuration is present but logic behaves as it did before the change. Cause: the
  **code build/patch was not promoted in lockstep** with the bundle. Run `OC2MMIG-Discovery.sh` on source
  and target and compare the build/patch level; install the matching build and re-run the post-install
  steps.

## E. The import review showed unexpected changes
- CMA fully **replaces** matching objects from the source. If the review lists objects you did not intend
  to change, **stop before applying** — your Migration Request scope is wider than the change. Inspect it
  with `OC2MMIG-ScopeHelper.sh`, narrow the request, re-export, and review again.

## F. Compare report shows a gap after a "successful" import
- "Import OK" is not parity. Run `OC2MMIG-Report.sh` to see exactly which of config-objects / IWS-status /
  build-level is out of parity, remediate that specific cause (re-import, re-deploy IWS, or re-apply the
  build), and re-compare. Use `OC2MMIG-Remediation.sh` to preview the corrective action first.

## G. A promotion needs to be rolled back
- Restore the pre-import backup of the target, or re-import the previously retained bundle (recorded prior
  bundle level), and re-deploy the prior IWS/build. This is why every import is preceded by a backup and
  every bundle is kept in version control. For Production, perform the rollback inside the same change
  window.

## H. Diagnostics quick reference
```sh
./OC2MMIG-Discovery.sh   your-env       # release/patch level, CMA readiness, plans/requests present
./OC2MMIG-Validation.sh  your-target    # parity signals: import applied, IWS current, build matched
./OC2MMIG-Report.sh      your-source your-target   # source-vs-target compare for the promoted scope
./OC2MMIG-ScopeHelper.sh your-request   # print a Migration Request's declared scope
./OC2MMIG-Remediation.sh your-target    # dry-run by default; add --apply to act
```

## I. When to escalate
If source and target are at the same level, the bundle imported without error, IWS deployment status reads
current, and the build levels match — but the compare report still shows a gap after remediation — capture
the `OC2MMIG-Discovery.sh`, `OC2MMIG-Validation.sh`, and `OC2MMIG-Report.sh` output and review the
Migration Plans and Migration Request scope with the application-development and release teams. For
CMA reference behavior or a suspected framework defect, raise it on My Oracle Support with the captured
output (verify the note/patch for your version).
