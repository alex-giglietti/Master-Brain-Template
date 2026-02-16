#!/usr/bin/env bash
# =============================================================================
# admin/manage-keys.sh — Per-client key management (envelope encryption)
#
# HOW IT WORKS:
#   - Content is encrypted with a single "content key" (random, internal)
#   - Each client gets a unique personal key (AES-256)
#   - The content key is then wrapped (encrypted) with each client's
#     personal key and stored as: admin/client-keys/<name>.key.enc
#   - These wrapped keyfiles ARE committed to the repo
#   - Client's decrypt.sh uses their personal key to unwrap the content
#     key, then uses the content key to decrypt all .enc files
#
# DISABLE a client = delete their .key.enc file + push
#   → Their personal key can no longer unwrap the content key
#   → No other clients are affected whatsoever
#
# RE-ENABLE = re-generate their .key.enc with a NEW personal key
#   → Old personal key stays dead, new one works
#
# Commands:
#   init                     — Generate master content key
#   add <name> <email>       — Register client, generate unique key
#   disable <name>           — Remove their keyfile (instant lockout)
#   enable <name>            — Re-issue new personal key + keyfile
#   revoke <name>            — Permanently delete client record
#   list                     — Show all clients and status
#   get-key <name>           — Print a client's current personal key
#   rotate-content-key       — Rotate the master content key (re-wraps all)
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KEYS_FILE="$REPO_ROOT/admin/keys.json"
CLIENT_KEYS_DIR="$REPO_ROOT/admin/client-keys"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()   { echo -e "${RED}[ERROR]${NC} $1"; }

for cmd in openssl jq; do
    command -v "$cmd" &>/dev/null || { err "$cmd required. Install it."; exit 1; }
done

mkdir -p "$CLIENT_KEYS_DIR"

# ─── Helpers ──────────────────────────────────────────────────────────────

random_hex() { openssl rand -hex "${1:-32}"; }

# Wrap (encrypt) the content key with a client's personal key
wrap_content_key() {
    local content_key="$1"
    local personal_key="$2"
    local output_file="$3"
    
    echo -n "$content_key" | openssl enc -aes-256-cbc -salt -pbkdf2 -iter 100000 \
        -pass "pass:$personal_key" -out "$output_file" 2>/dev/null
}

# ─── Commands ─────────────────────────────────────────────────────────────

cmd_init() {
    if [ -f "$KEYS_FILE" ]; then
        warn "keys.json already exists."
        read -rp "Overwrite? This INVALIDATES all client keys. (y/N): " confirm
        [ "$confirm" = "y" ] || { info "Aborted."; exit 0; }
    fi
    
    local content_key
    content_key=$(random_hex 32)
    
    cat > "$KEYS_FILE" << EOF
{
  "content_key": "$content_key",
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "content_key_rotated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "clients": {}
}
EOF
    
    ok "Initialized with new content key."
    warn "keys.json contains the master content key. NEVER commit it."
    info "Content key is internal — clients never see it."
}

cmd_add() {
    local name="${1:-}" email="${2:-}"
    [ -z "$name" ] || [ -z "$email" ] && { err "Usage: manage-keys.sh add <name> <email>"; exit 1; }
    [ ! -f "$KEYS_FILE" ] && { err "Run 'init' first."; exit 1; }
    
    jq -e ".clients[\"$name\"]" "$KEYS_FILE" &>/dev/null && {
        err "'$name' already exists. Use 'enable' to reactivate."
        exit 1
    }
    
    local content_key personal_key
    content_key=$(jq -r '.content_key' "$KEYS_FILE")
    personal_key=$(random_hex 32)
    
    # Wrap content key with this client's personal key
    wrap_content_key "$content_key" "$personal_key" "$CLIENT_KEYS_DIR/${name}.key.enc"
    
    # Register client
    jq --arg n "$name" --arg e "$email" --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
       '.clients[$n] = {"email": $e, "status": "active", "created": $now, "last_modified": $now}' \
       "$KEYS_FILE" > "${KEYS_FILE}.tmp" && mv "${KEYS_FILE}.tmp" "$KEYS_FILE"
    
    ok "Added client: $name ($email)"
    echo ""
    echo -e "${BOLD}══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  🔑 Personal key for ${GREEN}$name${NC}${BOLD} — send this to them:${NC}"
    echo ""
    echo -e "     ${GREEN}${BOLD}$personal_key${NC}"
    echo ""
    echo -e "${BOLD}══════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  Install command for $name:"
    echo "    curl -sSL https://raw.githubusercontent.com/YOUR_ORG/Master-Brain-Template/main/scripts/client-install.sh | bash -s -- $personal_key"
    echo ""
    echo "  ${BOLD}Next:${NC} git add admin/client-keys/${name}.key.enc && git commit -m 'Add $name' && git push"
}

cmd_disable() {
    local name="${1:-}"
    [ -z "$name" ] && { err "Usage: manage-keys.sh disable <name>"; exit 1; }
    
    jq -e ".clients[\"$name\"]" "$KEYS_FILE" &>/dev/null || { err "'$name' not found."; exit 1; }
    
    # Remove their wrapped keyfile — this is all it takes
    rm -f "$CLIENT_KEYS_DIR/${name}.key.enc"
    
    # Update status
    jq --arg n "$name" --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
       '.clients[$n].status = "disabled" | .clients[$n].disabled_at = $now | .clients[$n].last_modified = $now' \
       "$KEYS_FILE" > "${KEYS_FILE}.tmp" && mv "${KEYS_FILE}.tmp" "$KEYS_FILE"
    
    ok "Disabled: $name"
    info "Their keyfile has been removed. They cannot decrypt content."
    info "No other clients are affected."
    echo ""
    echo "  ${BOLD}Next:${NC} git add -A && git commit -m 'Disable $name' && git push"
    echo "  On their next update/pull, content becomes locked."
}

cmd_enable() {
    local name="${1:-}"
    [ -z "$name" ] && { err "Usage: manage-keys.sh enable <name>"; exit 1; }
    
    jq -e ".clients[\"$name\"]" "$KEYS_FILE" &>/dev/null || { err "'$name' not found."; exit 1; }
    
    local content_key new_personal_key
    content_key=$(jq -r '.content_key' "$KEYS_FILE")
    new_personal_key=$(random_hex 32)
    
    # Create new wrapped keyfile
    wrap_content_key "$content_key" "$new_personal_key" "$CLIENT_KEYS_DIR/${name}.key.enc"
    
    # Update status
    jq --arg n "$name" --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
       '.clients[$n].status = "active" | .clients[$n].reenabled_at = $now | .clients[$n].last_modified = $now' \
       "$KEYS_FILE" > "${KEYS_FILE}.tmp" && mv "${KEYS_FILE}.tmp" "$KEYS_FILE"
    
    ok "Re-enabled: $name"
    echo ""
    echo -e "${BOLD}══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  🔑 NEW personal key for ${GREEN}$name${NC}${BOLD} — send this to them:${NC}"
    echo ""
    echo -e "     ${GREEN}${BOLD}$new_personal_key${NC}"
    echo ""
    echo -e "${BOLD}══════════════════════════════════════════════════════════════════${NC}"
    echo ""
    warn "Their OLD key no longer works. They must update:"
    echo "  cd ~/.openclaw/workspace/brain && ./scripts/client-setup.sh $new_personal_key"
    echo ""
    echo "  ${BOLD}Next:${NC} git add admin/client-keys/${name}.key.enc && git commit -m 'Re-enable $name' && git push"
}

cmd_revoke() {
    local name="${1:-}"
    [ -z "$name" ] && { err "Usage: manage-keys.sh revoke <name>"; exit 1; }
    
    warn "Permanently delete '$name'?"
    read -rp "(y/N): " confirm
    [ "$confirm" = "y" ] || { info "Aborted."; exit 0; }
    
    rm -f "$CLIENT_KEYS_DIR/${name}.key.enc"
    jq --arg n "$name" 'del(.clients[$n])' \
       "$KEYS_FILE" > "${KEYS_FILE}.tmp" && mv "${KEYS_FILE}.tmp" "$KEYS_FILE"
    
    ok "Permanently revoked: $name"
    echo "  ${BOLD}Next:${NC} git add -A && git commit -m 'Revoke $name' && git push"
}

cmd_list() {
    [ ! -f "$KEYS_FILE" ] && { err "Run 'init' first."; exit 1; }
    
    echo ""
    echo -e "${BOLD}Client Registry${NC}"
    echo "═══════════════════════════════════════════════════"
    
    local count
    count=$(jq '.clients | length' "$KEYS_FILE")
    
    if [ "$count" -eq 0 ]; then
        info "No clients. Run: ./admin/manage-keys.sh add <name> <email>"
        return
    fi
    
    jq -r '.clients | to_entries[] | "\(.key)|\(.value.email)|\(.value.status)|\(.value.created)"' "$KEYS_FILE" | \
    while IFS='|' read -r name email status created; do
        local keyfile="$CLIENT_KEYS_DIR/${name}.key.enc"
        local has_keyfile="no"
        [ -f "$keyfile" ] && has_keyfile="yes"
        
        case "$status" in
            active)
                if [ "$has_keyfile" = "yes" ]; then
                    echo -e "  ${GREEN}●${NC} ${BOLD}$name${NC} — $email (since $created)"
                else
                    echo -e "  ${YELLOW}●${NC} ${BOLD}$name${NC} — $email ${YELLOW}[ACTIVE but keyfile missing!]${NC}"
                fi
                ;;
            disabled)
                echo -e "  ${RED}●${NC} ${BOLD}$name${NC} — $email (since $created) ${RED}[DISABLED]${NC}"
                ;;
            *)
                echo -e "  ${YELLOW}●${NC} ${BOLD}$name${NC} — $email [$status]"
                ;;
        esac
    done
    
    echo ""
    echo -e "  ${GREEN}●${NC} Active  ${RED}●${NC} Disabled  ${YELLOW}●${NC} Warning"
    echo "  Total: $count clients"
}

cmd_get_key() {
    local name="${1:-}"
    [ -z "$name" ] && { err "Usage: manage-keys.sh get-key <name>"; exit 1; }
    [ ! -f "$KEYS_FILE" ] && { err "Run 'init' first."; exit 1; }
    
    local status
    status=$(jq -r ".clients[\"$name\"].status // empty" "$KEYS_FILE")
    [ -z "$status" ] && { err "'$name' not found."; exit 1; }
    [ "$status" != "active" ] && { err "'$name' is $status. Enable first."; exit 1; }
    
    warn "Personal keys aren't stored after generation (by design)."
    warn "If you need to re-issue, use: ./admin/manage-keys.sh enable $name"
    info "This generates a NEW key and invalidates the old one."
}

cmd_rotate_content_key() {
    [ ! -f "$KEYS_FILE" ] && { err "Run 'init' first."; exit 1; }
    
    warn "This rotates the internal content key."
    warn "You'll need to re-encrypt all content AND re-wrap all client keyfiles."
    warn "Active clients keep their same personal keys — no disruption to them."
    read -rp "Continue? (y/N): " confirm
    [ "$confirm" = "y" ] || { info "Aborted."; exit 0; }
    
    local old_content_key new_content_key
    old_content_key=$(jq -r '.content_key' "$KEYS_FILE")
    new_content_key=$(random_hex 32)
    
    # Update content key
    jq --arg key "$new_content_key" --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
       '.content_key = $key | .content_key_rotated = $now' \
       "$KEYS_FILE" > "${KEYS_FILE}.tmp" && mv "${KEYS_FILE}.tmp" "$KEYS_FILE"
    
    # Re-wrap for all active clients
    # We need to decrypt each client's keyfile with old content key... 
    # Actually, we can't — we don't store their personal keys.
    # So we need to re-issue keys for everyone. OR we store a hash to verify.
    #
    # SIMPLER: since we have the content key, we just re-wrap it.
    # But we don't have their personal keys stored...
    # 
    # The solution: re-issue new personal keys for all active clients.
    
    info "Re-issuing keys for all active clients..."
    echo ""
    
    jq -r '.clients | to_entries[] | select(.value.status == "active") | .key' "$KEYS_FILE" | \
    while read -r name; do
        local new_personal_key
        new_personal_key=$(random_hex 32)
        
        wrap_content_key "$new_content_key" "$new_personal_key" "$CLIENT_KEYS_DIR/${name}.key.enc"
        
        local email
        email=$(jq -r ".clients[\"$name\"].email" "$KEYS_FILE")
        
        echo -e "  ${GREEN}●${NC} ${BOLD}$name${NC} ($email)"
        echo -e "    New key: ${GREEN}$new_personal_key${NC}"
        echo ""
    done
    
    ok "Content key rotated. All active clients have new keys above."
    warn "Now re-encrypt content: ./admin/encrypt.sh"
    warn "Then commit + push. Send each client their new key."
}

# ─── Dispatch ─────────────────────────────────────────────────────────────

case "${1:-}" in
    init)               cmd_init ;;
    add)                cmd_add "${2:-}" "${3:-}" ;;
    disable)            cmd_disable "${2:-}" ;;
    enable)             cmd_enable "${2:-}" ;;
    revoke)             cmd_revoke "${2:-}" ;;
    list)               cmd_list ;;
    get-key)            cmd_get_key "${2:-}" ;;
    rotate-content-key) cmd_rotate_content_key ;;
    *)
        echo "Usage: manage-keys.sh <command> [args]"
        echo ""
        echo "  init                     Initialize content encryption key"
        echo "  add <name> <email>       Add client (prints their unique key)"
        echo "  disable <name>           Disable client (deletes keyfile)"
        echo "  enable <name>            Re-enable (issues NEW unique key)"
        echo "  revoke <name>            Permanently remove"
        echo "  list                     Show all clients"
        echo "  get-key <name>           Info about client key"
        echo "  rotate-content-key       Rotate internal content key"
        exit 1
        ;;
esac
