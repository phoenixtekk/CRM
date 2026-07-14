#!/usr/bin/env bash
#
# .SYNOPSIS
#     TUNGW-HealthCheck.sh — Microsoft Tunnel Gateway host health check + log collection. READ-ONLY.
#
# .DESCRIPTION
#     PURPOSE
#         The ongoing-operations health probe for a running Tunnel Gateway server:
#           1. Reports the Tunnel service + container status (via mst-cli and the container runtime).
#           2. Reports the TLS certificate expiry (days remaining) so you rotate before it lapses.
#           3. Probes outbound reachability to Microsoft endpoints (management/health path).
#           4. Optionally COLLECTS a support-bundle/log tarball for troubleshooting or escalation.
#         It only reads state and (with --collect) copies logs into a tarball — it does not change,
#         restart, or reconfigure the gateway.
#     HOW TO RUN
#         chmod +x TUNGW-HealthCheck.sh
#         ./TUNGW-HealthCheck.sh                       # health summary only
#         ./TUNGW-HealthCheck.sh --cert /etc/mstunnel/private/site.pem
#         ./TUNGW-HealthCheck.sh --collect             # also gather a log tarball into /tmp
#     EXPECTED RESULTS
#         A health summary (service/container up, cert days-remaining, endpoint reachability). With
#         --collect, the path to a logs tarball you can attach to a support case.
#
# .NOTES
#     White-label. Read-only (health read + optional log copy). mst-cli subcommands, service names,
#     container names, and endpoints change — VERIFY CURRENT MICROSOFT GUIDANCE. Run as root/sudo so
#     mst-cli and logs are readable.

set -u

CERT_PATH="/etc/mstunnel/private/site.pem"
COLLECT="no"
WARN_DAYS="30"

while [ $# -gt 0 ]; do
  case "$1" in
    --cert)     CERT_PATH="$2"; shift 2 ;;
    --collect)  COLLECT="yes"; shift ;;
    --warn-days) WARN_DAYS="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

pass() { printf '  [OK]   %s\n' "$1"; }
warn() { printf '  [WARN] %s\n' "$1"; }
fail() { printf '  [FAIL] %s\n' "$1"; }

echo ""
echo "=== Microsoft Tunnel Gateway — Health Check (read-only) ==="

# 1. Tunnel service + management CLI.
echo ""
echo "[1] Tunnel service + mst-cli:"
if command -v systemctl >/dev/null 2>&1; then
  # Service unit name has historically been 'mstunnel' — verify current name.
  if systemctl is-active --quiet mstunnel 2>/dev/null; then
    pass "systemd unit 'mstunnel' is active."
  else
    warn "systemd unit 'mstunnel' not active (verify the current service name for your version)."
  fi
fi
if command -v mst-cli >/dev/null 2>&1; then
  pass "mst-cli present."
  echo "  --- mst-cli server show (read-only) ---"
  mst-cli server show 2>/dev/null | sed 's/^/    /' || warn "mst-cli server show returned non-zero (verify subcommand for your version)."
else
  warn "mst-cli not found on PATH — verify the Tunnel agent is installed."
fi

# 2. Container status.
echo ""
echo "[2] Container runtime status:"
RUNTIME=""
command -v podman >/dev/null 2>&1 && RUNTIME="podman"
[ -z "$RUNTIME" ] && command -v docker >/dev/null 2>&1 && RUNTIME="docker"
if [ -n "$RUNTIME" ]; then
  # Tunnel containers have historically been named 'mstunnel-server' / 'mstunnel-agent' — verify.
  CT="$($RUNTIME ps --format '{{.Names}} {{.Status}}' 2>/dev/null | grep -i 'mstunnel' || true)"
  if [ -n "$CT" ]; then
    printf '%s\n' "$CT" | sed 's/^/    /'
    pass "Tunnel container(s) running under $RUNTIME."
  else
    fail "No running 'mstunnel' container found under $RUNTIME."
  fi
else
  warn "No container runtime found on PATH."
fi

# 3. TLS certificate expiry (days remaining).
echo ""
echo "[3] TLS certificate expiry:"
if [ -r "$CERT_PATH" ] && command -v openssl >/dev/null 2>&1; then
  END="$(openssl x509 -enddate -noout -in "$CERT_PATH" 2>/dev/null | sed 's/notAfter=//')"
  if [ -n "$END" ]; then
    END_EPOCH="$(date -d "$END" +%s 2>/dev/null || echo 0)"
    NOW_EPOCH="$(date +%s)"
    if [ "$END_EPOCH" -gt 0 ]; then
      DAYS=$(( (END_EPOCH - NOW_EPOCH) / 86400 ))
      if [ "$DAYS" -lt 0 ]; then
        fail "Certificate EXPIRED ($END). Rotate immediately — clients cannot establish TLS."
      elif [ "$DAYS" -lt "$WARN_DAYS" ]; then
        warn "Certificate expires in $DAYS day(s) ($END). Rotate soon (mst-cli tls_cert update — verify subcommand)."
      else
        pass "Certificate valid — $DAYS day(s) remaining ($END)."
      fi
    fi
  else
    warn "Could not read certificate not-after from $CERT_PATH."
  fi
else
  warn "Certificate not readable at $CERT_PATH or openssl missing (pass --cert)."
fi

# 4. Outbound reachability (management/health path).
echo ""
echo "[4] Outbound reachability to Microsoft endpoints:"
for ep in login.microsoftonline.com graph.microsoft.com manage.microsoft.com; do
  if command -v curl >/dev/null 2>&1 && curl -s -o /dev/null --max-time 8 "https://${ep}"; then
    pass "Reachable: https://${ep}"
  else
    warn "Could not reach https://${ep} — health/check-in needs outbound to Microsoft."
  fi
done

# 5. Optional log collection (support bundle).
if [ "$COLLECT" = "yes" ]; then
  echo ""
  echo "[5] Collecting logs (read-only copy into a tarball):"
  TS="$(date +%Y%m%d-%H%M%S)"
  OUT="/tmp/tungw-logs-${TS}"
  mkdir -p "$OUT" 2>/dev/null
  # Prefer the built-in support bundle if the CLI offers one (verify subcommand for your version).
  if command -v mst-cli >/dev/null 2>&1; then
    mst-cli support 2>/dev/null > "$OUT/mst-cli-support.txt" || echo "(mst-cli support not available on this version)" > "$OUT/mst-cli-support.txt"
    mst-cli server show 2>/dev/null > "$OUT/mst-cli-server-show.txt" || true
  fi
  # Common host log locations (copy if present).
  for src in /var/log/mstunnel /etc/mstunnel; do
    [ -d "$src" ] && cp -r "$src" "$OUT/" 2>/dev/null
  done
  if [ -n "${RUNTIME:-}" ]; then
    $RUNTIME ps -a > "$OUT/container-ps.txt" 2>/dev/null || true
  fi
  journalctl -u mstunnel --no-pager -n 500 > "$OUT/journal-mstunnel.txt" 2>/dev/null || true
  TARBALL="/tmp/tungw-logs-${TS}.tar.gz"
  tar -czf "$TARBALL" -C /tmp "tungw-logs-${TS}" 2>/dev/null && rm -rf "$OUT"
  if [ -f "$TARBALL" ]; then
    pass "Log bundle written: $TARBALL  (review before sharing — may contain host/network detail)."
  else
    warn "Could not create the log tarball; check permissions (run as root/sudo)."
  fi
fi

echo ""
echo "Health check complete (read-only)."
