# OC2MMIG-Remediation.sh — guided, DRY-RUN-by-default remediation of promotion parity gaps.
#
# PURPOSE
#     Close the common parity gaps a compare turns up on a target: re-import the retained CMA bundle,
#     re-deploy an in-scope Inbound Web Service with iwsdeploy, or re-run the code post-install for
#     the promoted build. DRY-RUN by default — it prints the exact command it would run and changes
#     nothing until you pass --apply. Even with --apply it acts only on the target you name and the
#     bundle/IWS you name; it never invents scope.
#
# HOW TO RUN
#     dry-run (default, safe) prints the plan:
#       ./OC2MMIG-Remediation.sh your-target-env --bundle your-bundle-file --iws your-iws-app
#     to actually perform it, add --apply (source splenviron first; run in the change window):
#       ./OC2MMIG-Remediation.sh your-target-env --bundle your-bundle-file --iws your-iws-app --apply
#
# EXPECTED RESULTS
#     Dry-run: a numbered plan of the exact import/iwsdeploy/post-install commands, then
#     "DRY-RUN — nothing changed." With --apply: each step runs and reports success/failure; stop on
#     the first failure and re-compare with OC2MMIG-Report before continuing.
#
# NOTES
#     White-label, the repeatable way. DRY-RUN by default; --apply is the only way it mutates, and
#     only inside a change window with a verified backup. QA/Prod IWS deployment is command-line
#     iwsdeploy (the portal is dev-only). Verify utility names/switches for your C2M version.

set -u

TARGET="${1:-your-target-env}"; shift || true
BUNDLE=""; IWS=""; APPLY="no"

while [ $# -gt 0 ]; do
    case "$1" in
        --bundle) BUNDLE="${2:-}"; shift 2 ;;
        --iws)    IWS="${2:-}";    shift 2 ;;
        --apply)  APPLY="yes";     shift   ;;
        *) echo "Unknown option: $1"; exit 2 ;;
    esac
done

echo ""
echo "=== OC2MMIG Remediation — target: ${TARGET} (mode: $( [ "${APPLY}" = yes ] && echo APPLY || echo DRY-RUN )) ==="

# Build the ordered plan from what the caller asked to fix.
STEP=0
run_or_show() {
    STEP=$((STEP+1))
    echo ""
    echo "  [${STEP}] $1"
    echo "      \$ $2"
    if [ "${APPLY}" = "yes" ]; then
        eval "$2"
        rc=$?
        [ $rc -ne 0 ] && { echo "      FAILED (rc=$rc) — stop, investigate, re-compare before continuing."; exit $rc; }
        echo "      done."
    fi
}

if [ -n "${BUNDLE}" ]; then
    # Re-import the previously retained CMA bundle into the target import directory.
    run_or_show "Re-import retained CMA bundle into ${TARGET}" \
        "cmaimport.sh -f \"${BUNDLE}\""    # verify utility name/switches for your version
fi

if [ -n "${IWS}" ]; then
    # Re-deploy the named Inbound Web Service (command-line — the portal is non-prod only).
    run_or_show "Re-deploy Inbound Web Service '${IWS}' on ${TARGET}" \
        "iwsdeploy.sh ${IWS}"
fi

if [ -z "${BUNDLE}" ] && [ -z "${IWS}" ]; then
    echo ""
    echo "  Nothing to remediate: pass --bundle your-bundle-file and/or --iws your-iws-app."
    echo "  (Use OC2MMIG-Report to see which parity gap to close.)"
fi

echo ""
if [ "${APPLY}" = "yes" ]; then
    echo "APPLY complete. Re-run OC2MMIG-Report / OC2MMIG-Validation to confirm parity."
else
    echo "DRY-RUN — nothing changed. Re-run with --apply (in a change window, backup verified) to act."
fi
echo "=== end OC2MMIG Remediation (${TARGET}) ==="
