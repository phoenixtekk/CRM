#!/bin/sh
# OC2MSEC-Discovery.sh — read-only discovery of C2M/WebLogic keystores, SSL config, and advertised URL.
#
# PURPOSE
#     Capture the security baseline from the file system and the domain config, without connecting a
#     live edit session. It lists the identity and trust keystore contents with keytool (aliases, entry
#     types, certificate validity/expiry), reads each server's SSL and keystore attributes from the
#     domain config.xml, and reports the OUAF advertised URL/protocol from the product config. Set the
#     inputs as environment variables (no angle brackets): OC2MSEC_IDENTITY, OC2MSEC_TRUST,
#     OC2MSEC_DOMAIN_HOME, SPLEBASE.
#
# HOW TO RUN
#     export OC2MSEC_IDENTITY=your-keystore-dir/C2MSEC-Identity-Pilot.jks
#     export OC2MSEC_TRUST=your-keystore-dir/C2MSEC-Trust-Pilot.jks
#     export OC2MSEC_DOMAIN_HOME=your-domain-home
#     export SPLEBASE=your-product-home
#     sh OC2MSEC-Discovery.sh
#
# EXPECTED RESULTS
#     A written baseline (Security-Baseline-C2M-Discovery.txt) plus on-screen output listing keystore
#     aliases and certificate expiry, the config.xml SSL/keystore lines per server, and the OUAF
#     https/http endpoint. PASS when identity shows a PrivateKeyEntry that is not expired and trust
#     holds the expected CA entries; flag when a Demo keystore or an expired/near-expiry cert appears.
#
# NOTES
#     White-label — the repeatable way to inventory C2M security state before changing it. Read-only;
#     keytool -list never emits private keys, and this script never echoes passphrases (it prompts
#     keytool interactively or lists without a store password where the JDK allows).

set -u

REPORT_NAME="Security Baseline - C2M - Discovery"
OUT_FILE="${OC2MSEC_OUT:-Security-Baseline-C2M-Discovery.txt}"

# Never accept a passphrase on the command line or via an environment variable; keytool -list will
# prompt if a store password is required. Listing certificate metadata does not require the private key.

log() { echo "$1" | tee -a "$OUT_FILE"; }

: > "$OUT_FILE"
log "=== ${REPORT_NAME} ==="
log ""

# --- Keystore inventory (identity + trust) ---
for pair in "IDENTITY:${OC2MSEC_IDENTITY:-}" "TRUST:${OC2MSEC_TRUST:-}"; do
    label=$(echo "$pair" | cut -d: -f1)
    ks=$(echo "$pair" | cut -d: -f2-)
    log "[${label} keystore] ${ks:-not set}"
    if [ -n "$ks" ] && [ -f "$ks" ]; then
        # -rfc/-v exposes only public certificate data (alias, type, validity dates), never keys.
        keytool -list -v -keystore "$ks" 2>/dev/null \
            | grep -E "Alias name:|Entry type:|Valid from:|Owner:|Issuer:" \
            | tee -a "$OUT_FILE"
    else
        log "  (file not found or path not set)"
    fi
    log ""
done

# --- SSL / keystore attributes from domain config.xml (read-only) ---
CFG="${OC2MSEC_DOMAIN_HOME:-}/config/config.xml"
log "[config.xml] ${CFG}"
if [ -f "$CFG" ]; then
    # Surface server SSL and keystore elements without printing any encrypted passphrase values.
    grep -E "<name>|<keystores>|custom-identity-key-store-file-name|custom-trust-key-store-file-name|<enabled>|listen-port|client-certificate-enforced|minimum-tls-protocol-version|server-private-key-alias" "$CFG" \
        | grep -vi "pass-phrase\|passphrase\|credential-encrypted" \
        | tee -a "$OUT_FILE"
else
    log "  (config.xml not found; set OC2MSEC_DOMAIN_HOME)"
fi
log ""

# --- OUAF advertised URL / protocol (read-only) ---
log "[OUAF advertised endpoint] SPLEBASE=${SPLEBASE:-not set}"
if [ -n "${SPLEBASE:-}" ] && [ -d "${SPLEBASE}/etc" ]; then
    # Show http/https endpoint hints from the product config; do not print secrets.
    grep -R -E "https?://|WEB_PROTOCOL|WLHOST|WLPORT|WEB_WLHOST|WEB_WLPORT|WEB_ISAPPVIEWER" "${SPLEBASE}/etc" 2>/dev/null \
        | grep -vi "password\|passwd\|secret\|credential" \
        | head -n 40 \
        | tee -a "$OUT_FILE"
else
    log "  (SPLEBASE/etc not found; set SPLEBASE)"
fi
log ""

log "Wrote ${REPORT_NAME} -> ${OUT_FILE}"
log "Read-only: no configuration was changed."
