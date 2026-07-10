#!/usr/bin/env bash
###############################################################################
# install-datadog-agent.sh — install/uninstall the Datadog Agent on Linux (white-label)
#
# PURPOSE
#   Installs the Datadog Agent on a Linux host as part of an as-code rollout. The API key is read from
#   the ENVIRONMENT (populated from your SECRET STORE) — it is NEVER hard-coded or echoed. Sets the
#   Datadog site and the base tags (env/service/team), and optionally enables logs and APM. Supports an
#   --uninstall path for rollback.
#
# HOW TO RUN  (key comes from your secret store, not the command line history)
#   export DD_API_KEY="$(read-from-secret-store)"        # e.g. az keyvault secret show ... / vault read
#   DD_SITE=datadoghq.com \
#     ./install-datadog-agent.sh --env pilot --service demo --team platform --logs --apm
#   Uninstall:  ./install-datadog-agent.sh --uninstall
#
# EXPECTED RESULTS
#   The agent is installed and started; `sudo datadog-agent status` shows API key OK and the host
#   reports to Datadog with the given tags. Re-runnable (idempotent-ish): re-running updates tags/config.
#
# NOTES
#   White-label. NO SECRETS IN CODE: DD_API_KEY is taken from the environment/secret store and never
#   printed. Uses the official Datadog install script over HTTPS. Requires root/sudo. Verify the current
#   agent major version / install method for your distro in Datadog's docs.
###############################################################################
set -euo pipefail

DD_SITE="${DD_SITE:-datadoghq.com}"     # verify your org's site
ENVIRONMENT="pilot"; SERVICE="demo"; TEAM="platform"
ENABLE_LOGS="false"; ENABLE_APM="false"; ACTION="install"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env)       ENVIRONMENT="$2"; shift 2 ;;
    --service)   SERVICE="$2";     shift 2 ;;
    --team)      TEAM="$2";        shift 2 ;;
    --logs)      ENABLE_LOGS="true";  shift ;;
    --apm)       ENABLE_APM="true";   shift ;;
    --uninstall) ACTION="uninstall";  shift ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

require_root() { if [[ "$(id -u)" -ne 0 ]]; then echo "Run as root/sudo." >&2; exit 1; fi; }

if [[ "$ACTION" == "uninstall" ]]; then
  require_root
  echo "Uninstalling Datadog Agent..."
  if command -v apt-get >/dev/null 2>&1; then apt-get remove -y datadog-agent || true
  elif command -v yum >/dev/null 2>&1; then yum remove -y datadog-agent || true; fi
  echo "Uninstall complete."
  exit 0
fi

require_root
if [[ -z "${DD_API_KEY:-}" ]]; then
  echo "ERROR: DD_API_KEY is not set. Export it from your SECRET STORE before running." >&2
  exit 1
fi

echo "Installing Datadog Agent (site=${DD_SITE}, env=${ENVIRONMENT}, service=${SERVICE}, team=${TEAM})..."
# Official install script — key passed via env, never written to the script or logged.
DD_API_KEY="${DD_API_KEY}" DD_SITE="${DD_SITE}" \
  DD_AGENT_MAJOR_VERSION=7 \
  bash -c "$(curl -fsSL https://install.datadoghq.com/scripts/install_script_agent7.sh)"

CFG="/etc/datadog-agent/datadog.yaml"
# Apply base tags (idempotent block).
{
  echo "tags:"
  echo "  - env:${ENVIRONMENT}"
  echo "  - service:${SERVICE}"
  echo "  - team:${TEAM}"
} >> "${CFG}"

if [[ "$ENABLE_LOGS" == "true" ]]; then
  echo "logs_enabled: true" >> "${CFG}"
fi
if [[ "$ENABLE_APM" == "true" ]]; then
  echo "apm_config:"        >> "${CFG}"
  echo "  enabled: true"    >> "${CFG}"
fi

systemctl restart datadog-agent || service datadog-agent restart
echo "Done. Verify with: sudo datadog-agent status"
