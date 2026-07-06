# OC2MDEVOPS-Remediation.sh — guided, DRY-RUN-by-default remediation of release-pipeline gaps.
#
# PURPOSE
#     Close the common gaps the validate stage turns up on a target: re-import the retained CMA config
#     bundle, re-install/post-install the promoted code build, re-deploy an in-scope Inbound Web
#     Service with iwsdeploy, or re-run a routine-admin action (resume the threadpoolworker / restart a
#     server in order). DRY-RUN by default — it prints the exact command it would run and changes
#     nothing until you pass --apply. Even with --apply it acts only on the target you name and the
#     bundle/build/iws/action you name; it never invents scope.
#
# HOW TO RUN
#     dry-run (default, safe) prints the plan:
#       ./OC2MDEVOPS-Remediation.sh your-target-env --bundle your-bundle-file --iws your-iws-app --resume-batch
#     to actually perform it, add --apply (source splenviron first; run in the change window):
#       ./OC2MDEVOPS-Remediation.sh your-target-env --iws your-iws-app --apply
#     Options: --bundle FILE  --build DIR  --iws APP  --resume-batch  --apply
#
# EXPECTED RESULTS
#     Dry-run: a numbered plan of the exact import / install / iwsdeploy / batch-resume commands, then
#     "DRY-RUN — nothing changed." With --apply: each step runs and reports success/failure; stop on
#     the first failure and re-validate with OC2MDEVOPS-Report.sql before continuing.
#
# NOTES
#     White-label, the repeatable way. DRY-RUN by default; --apply is the only way it mutates, and only
#     inside a change window with a verified backup. QA/Prod IWS deployment is command-line iwsdeploy
#     (the portal is dev-only). Verify utility names/switches for your C2M version (C2M 25.4 / min v2.9).

set -u

TARGET="${1:-your-target-env}"; shift || true
BUNDLE=""; BUILD=""; IWS=""; RESUME_BATCH="no"; APPLY="no"

while [ $# -gt 0 ]; do
    case "$1" in
        --bundle)       BUNDLE="${2:-}"; shift 2 ;;
        --build)        BUILD="${2:-}";  shift 2 ;;
        --iws)          IWS="${2:-}";     shift 2 ;;
        --resume-batch) RESUME_BATCH="yes"; shift ;;
        --apply)        APPLY="yes";        shift ;;
        *) echo "Unknown option: $1"; exit 2 ;;
    esac
done

echo ""
echo "=== OC2MDEVOPS Remediation — target: ${TARGET} (mode: $( [ "${APPLY}" = yes ] && echo APPLY || echo DRY-RUN )) ==="

STEP=0
run_or_show() {
    STEP=$((STEP+1))
    echo ""
    echo "  [${STEP}] $1"
    echo "      \$ $2"
    if [ "${APPLY}" = "yes" ]; then
        eval "$2"
        rc=$?
        [ $rc -ne 0 ] && { echo "      FAILED (rc=$rc) — stop, investigate, re-validate before continuing."; exit $rc; }
        echo "      done."
    fi
}

if [ -n "${BUILD}" ]; then
    # Re-install the promoted code build and run the framework post-install (verify names for your version).
    run_or_show "Re-install code build on ${TARGET} and run post-install" \
        "( cd \"${BUILD}\" && ./install.sh ) && initialSetup.sh"
fi

if [ -n "${BUNDLE}" ]; then
    # Re-import the previously retained CMA bundle (config stage). Mechanics: migration sibling.
    run_or_show "Re-import retained CMA config bundle into ${TARGET}" \
        "cmaimport.sh -f \"${BUNDLE}\""    # verify utility name/switches for your version
fi

if [ -n "${IWS}" ]; then
    # Re-deploy the named Inbound Web Service (command-line — the portal is non-prod only).
    run_or_show "Re-deploy Inbound Web Service '${IWS}' on ${TARGET}" \
        "iwsdeploy.sh ${IWS}"
fi

if [ "${RESUME_BATCH}" = "yes" ]; then
    # Routine-admin: resume the threadpoolworker after a deploy that quiesced batch.
    run_or_show "Resume threadpoolworker (routine-admin) on ${TARGET}" \
        "threadpoolworker.sh -d Y"    # verify start switch/pool name for your version
fi

if [ -z "${BUNDLE}" ] && [ -z "${BUILD}" ] && [ -z "${IWS}" ] && [ "${RESUME_BATCH}" = "no" ]; then
    echo ""
    echo "  Nothing to remediate: pass one of --bundle FILE / --build DIR / --iws APP / --resume-batch."
    echo "  (Use OC2MDEVOPS-Report.sql and OC2MDEVOPS-Validation.py to see which gap to close.)"
fi

echo ""
if [ "${APPLY}" = "yes" ]; then
    echo "APPLY complete. Re-run OC2MDEVOPS-Report.sql / OC2MDEVOPS-Validation.py to confirm parity + health."
else
    echo "DRY-RUN — nothing changed. Re-run with --apply (in a change window, backup verified) to act."
fi
echo "=== end OC2MDEVOPS Remediation (${TARGET}) ==="
