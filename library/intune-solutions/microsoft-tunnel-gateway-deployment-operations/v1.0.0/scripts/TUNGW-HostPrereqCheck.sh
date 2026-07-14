#!/usr/bin/env bash
#
# .SYNOPSIS
#     TUNGW-HostPrereqCheck.sh — Microsoft Tunnel Gateway Linux host readiness check. READ-ONLY.
#
# .DESCRIPTION
#     PURPOSE
#         Verifies a Linux host is ready to run the Microsoft Tunnel Gateway BEFORE you install:
#           1. Distribution + kernel version (so you can compare against current supported list).
#           2. Container runtime present (Podman or Docker) and its service state.
#           3. IP forwarding readiness (the gateway routes client traffic to internal networks).
#           4. TLS certificate files present + not-after (expiry) date.
#           5. Inbound listener port free/reachable and outbound reachability to Microsoft endpoints
#              and to a sample internal resource.
#         It ONLY reads/probes — it changes nothing on the host.
#     HOW TO RUN
#         chmod +x TUNGW-HostPrereqCheck.sh
#         ./TUNGW-HostPrereqCheck.sh \
#             --cert /etc/mstunnel/certs/site.pem \
#             --port 443 \
#             --internal 10.10.0.10 \
#             --fqdn tunnel.contoso.com
#         All flags optional; sensible defaults are used and clearly reported.
#     EXPECTED RESULTS
#         A PASS/WARN/FAIL line per check. Resolve every FAIL (and review WARN) before running the
#         Microsoft Tunnel installer.
#
# .NOTES
#     White-label. Read-only (no changes). Distribution/runtime/port/endpoint specifics change —
#     VERIFY CURRENT MICROSOFT GUIDANCE for the supported distro/version, runtime, ports, and the
#     required outbound Microsoft endpoint list before provisioning.

set -u

# ---- Defaults (override via flags) ----
CERT_PATH="/etc/mstunnel/private/site.pem"
LISTEN_PORT="443"
INTERNAL_HOST=""
TUNNEL_FQDN=""

while [ $# -gt 0 ]; do
  case "$1" in
    --cert)     CERT_PATH="$2"; shift 2 ;;
    --port)     LISTEN_PORT="$2"; shift 2 ;;
    --internal) INTERNAL_HOST="$2"; shift 2 ;;
    --fqdn)     TUNNEL_FQDN="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

pass() { printf '  [PASS] %s\n' "$1"; }
warn() { printf '  [WARN] %s\n' "$1"; }
fail() { printf '  [FAIL] %s\n' "$1"; }

echo ""
echo "=== Microsoft Tunnel Gateway — Host Prerequisite Check (read-only) ==="

# 1. Distribution + kernel.
echo ""
echo "[1] OS distribution + kernel:"
if [ -r /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  pass "Distro: ${PRETTY_NAME:-unknown}"
else
  warn "Could not read /etc/os-release."
fi
pass "Kernel: $(uname -r)  (verify against current Microsoft-supported list)"

# 2. Container runtime.
echo ""
echo "[2] Container runtime:"
RUNTIME=""
if command -v podman >/dev/null 2>&1; then
  RUNTIME="podman"; pass "Podman present: $(podman --version 2>/dev/null)"
elif command -v docker >/dev/null 2>&1; then
  RUNTIME="docker"; pass "Docker present: $(docker --version 2>/dev/null)"
else
  fail "Neither Podman nor Docker found — install the runtime supported for your distro."
fi
if [ -n "$RUNTIME" ]; then
  if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet "$RUNTIME" 2>/dev/null; then
    pass "$RUNTIME service is active."
  else
    warn "$RUNTIME service not reported active by systemctl (may be socket-activated/rootless)."
  fi
fi

# 3. IP forwarding readiness (report only — do NOT change).
echo ""
echo "[3] IP forwarding readiness:"
IPF="$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null || echo '?')"
if [ "$IPF" = "1" ]; then
  pass "net.ipv4.ip_forward = 1 (enabled)."
else
  warn "net.ipv4.ip_forward = ${IPF} — the Tunnel installer/host must forward client traffic; confirm your config enables it."
fi

# 4. TLS certificate file + expiry.
echo ""
echo "[4] TLS certificate:"
if [ -r "$CERT_PATH" ]; then
  pass "Certificate file present: $CERT_PATH"
  if command -v openssl >/dev/null 2>&1; then
    NOTAFTER="$(openssl x509 -enddate -noout -in "$CERT_PATH" 2>/dev/null | sed 's/notAfter=//')"
    SUBJECT="$(openssl x509 -subject -noout -in "$CERT_PATH" 2>/dev/null | sed 's/subject=//')"
    SANS="$(openssl x509 -ext subjectAltName -noout -in "$CERT_PATH" 2>/dev/null | tr -d ' ')"
    [ -n "$NOTAFTER" ] && pass "Not-after (expiry): $NOTAFTER"
    [ -n "$SUBJECT" ] && pass "Subject: $SUBJECT"
    if [ -n "$TUNNEL_FQDN" ]; then
      if printf '%s' "$SANS" | grep -qi "$TUNNEL_FQDN"; then
        pass "FQDN '$TUNNEL_FQDN' found in Subject Alternative Name."
      else
        warn "FQDN '$TUNNEL_FQDN' NOT found in SAN — clients connect by FQDN; the cert must cover it."
      fi
    fi
  else
    warn "openssl not found — cannot read cert expiry/SAN. Verify manually."
  fi
else
  fail "Certificate file not readable at $CERT_PATH (pass --cert to point at the real path)."
fi

# 5a. Inbound listener port.
echo ""
echo "[5] Inbound listener port ${LISTEN_PORT}:"
if command -v ss >/dev/null 2>&1; then
  if ss -tlnH "( sport = :${LISTEN_PORT} )" 2>/dev/null | grep -q ":${LISTEN_PORT}"; then
    warn "Port ${LISTEN_PORT} is already in use — the Tunnel listener needs it free (or choose another port)."
  else
    pass "Port ${LISTEN_PORT} is free for the Tunnel listener."
  fi
else
  warn "ss not available — verify port ${LISTEN_PORT} availability manually."
fi

# 5b. Outbound reachability to Microsoft endpoints (verify current list).
echo ""
echo "[6] Outbound reachability to Microsoft endpoints (verify current required list):"
for ep in login.microsoftonline.com graph.microsoft.com manage.microsoft.com; do
  if command -v curl >/dev/null 2>&1; then
    if curl -s -o /dev/null --max-time 8 "https://${ep}"; then
      pass "Reachable: https://${ep}"
    else
      warn "Could not reach https://${ep} (may be blocked by proxy/firewall — allow Microsoft ranges)."
    fi
  else
    warn "curl not found — cannot probe https://${ep}."
  fi
done

# 5c. Internal resource reachability (the gateway must reach what it publishes).
echo ""
echo "[7] Internal resource reachability:"
if [ -n "$INTERNAL_HOST" ]; then
  if command -v ping >/dev/null 2>&1 && ping -c1 -W3 "$INTERNAL_HOST" >/dev/null 2>&1; then
    pass "Internal host $INTERNAL_HOST responds to ping."
  else
    warn "Could not ping $INTERNAL_HOST (ICMP may be blocked; verify the route/service another way)."
  fi
else
  warn "No --internal host supplied; skipping internal reachability check."
fi

echo ""
echo "Prerequisite check complete (read-only). Resolve any [FAIL] before installing the Tunnel Gateway."
