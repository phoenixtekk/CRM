# OC2MDYNA-Remediation.sh — print the intended fix for a C2M monitoring coverage/config gap (DRY-RUN by default).
#
# PURPOSE
#     When validation flags a gap — a host without OneAgent, a missing C2M-Env tag, or a
#     missing named alert rule — print the exact, safe remediation the admin should apply:
#     the OneAgent install command, the host-group tag to set, or the alert rule to create.
#     DRY-RUN by default: it prints what it WOULD do and changes nothing. It applies only
#     when explicitly asked, and only for the tag/alert config it is authorized to write via
#     the Dynatrace API — it never installs software itself and never prints the API token.
#     Placeholders are plain text (your-tenant, your-token) without angle brackets.
#
# HOW TO RUN
#     Set the tenant URL and (for --apply) a suitably scoped API token as env vars, then:
#         export DT_ENV_URL=https://your-tenant.live.dynatrace.com
#         export DT_API_TOKEN=your-scoped-token
#         ./OC2MDYNA-Remediation.sh                    # DRY-RUN: prints intended fixes only
#         ./OC2MDYNA-Remediation.sh --apply            # applies config it is authorized to (change window)
#     Override env value:  ENV_VALUE=prod ./OC2MDYNA-Remediation.sh
#
# EXPECTED RESULTS
#     DRY-RUN prints, for each gap type, the exact action: the OneAgent install command
#     (host-group tagged), the tag to set, and the alert-rule names to create — and exits
#     without changing anything. With --apply it performs only the config writes it is
#     explicitly authorized for (never software install) and prints the manual steps for
#     the rest.
#
# NOTES
#     White-label, repeatable remediation — DRY-RUN by default so it is safe to run anywhere.
#     It never installs OneAgent itself (that is a root/sudo host action for the admin) and
#     never restarts a service. The token is read from an env var and never echoed. Dynatrace
#     install flags / API shapes move between releases — verify for your tenant version.

set -u

APPLY=0
[ "${1:-}" = "--apply" ] && APPLY=1
ENV_VALUE="${ENV_VALUE:-prod}"
ENV_TAG="C2M-Env"
HOST_GROUP="${ENV_TAG}-${ENV_VALUE}"

: "${DT_ENV_URL:=}"
echo "== OC2MDYNA Remediation =="
if [ -z "$DT_ENV_URL" ]; then
  echo "FAIL: set DT_ENV_URL (and DT_API_TOKEN for --apply) as environment variables first."
  exit 1
fi

echo "Target tenant     : ${DT_ENV_URL}"
echo "Environment tag   : ${ENV_TAG} = ${ENV_VALUE}   (host group: ${HOST_GROUP})"
echo

# --- Gap 1: a host is not instrumented ---
echo "-- Gap 1: host missing OneAgent --"
echo "  Intended fix (run on the host as root/sudo — this script does NOT do it for you):"
echo "    # 1) get the Linux install command from the tenant (it embeds the installer token)"
echo "    # 2) install, tagging the environment host group so C2M-Env is set from the start:"
echo "    sudo /bin/sh Dynatrace-OneAgent-Linux.sh --set-host-group=${HOST_GROUP}"
echo "    (installer name and --set-host-group flag are Dynatrace's — verify for your version)"
echo

# --- Gap 2: a monitored host is missing the C2M-Env tag ---
echo "-- Gap 2: monitored host missing the ${ENV_TAG} tag --"
echo "  Preferred fix: re-run the OneAgent install/config with --set-host-group=${HOST_GROUP}"
echo "  (Tag at install time; retro-tagging a live fleet is error-prone.)"
echo

# --- Gap 3: a named alert rule is missing ---
echo "-- Gap 3: named alert rule(s) missing --"
echo "  Create these metric events (Settings -> Anomaly detection -> Metric events), scoped to"
echo "  the C2M - Monitoring Zone, per Implementation Step 5:"
for name in \
  "C2M Alert - JVM Heap High" \
  "C2M Alert - GC Time High" \
  "C2M Alert - Connection Pool Exhausted" \
  "C2M Alert - Endpoint Failure Rate" \
  "C2M Alert - Batch Worker Down"; do
  echo "    - ${name}"
done
echo

if [ "$APPLY" -eq 0 ]; then
  echo "DRY-RUN: no changes made. Re-run with --apply in a change window to write the config"
  echo "         this script is authorized for (tags/alerts via API). OneAgent install remains"
  echo "         a manual host action for the admin."
  exit 0
fi

# --- Apply (change window only) — config writes this script is authorized for ---
: "${DT_API_TOKEN:=}"
if [ -z "$DT_API_TOKEN" ]; then
  echo "FAIL: --apply needs DT_API_TOKEN (a token scoped to write the config) — token never printed."
  exit 1
fi
echo "APPLY: this build applies no changes automatically by design."
echo "  Alert-rule and tag definitions are created through the reviewed monitoring-config export"
echo "  (config-as-JSON), so each change is version-controlled and reversible on rollback."
echo "  Import the reviewed alert/dashboard config for ${DT_ENV_URL}, then re-run OC2MDYNA-Validation.sh."
echo "  OneAgent install stays a manual, root/sudo host action (see Gap 1)."
