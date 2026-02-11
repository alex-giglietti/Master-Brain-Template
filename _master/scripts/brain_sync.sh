#!/bin/bash
set -euo pipefail

# ─── CONFIG (auto-filled from git remote) ────────────────────────────
REPO="${BRAIN_REPO:-alex-giglietti/Master-Brain-Template}"
BRANCH="${BRAIN_BRANCH:-main}"
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
TOKEN="${GITHUB_TOKEN:-}"
BRAIN_KEY="${BRAIN_KEY:-}"

PROTECTED_DIRS=("memory" "brand" "vision")
PROTECTED_FILES=("USER.md" "IDENTITY.md")
ENCRYPTED_DIR="encrypted"
BRAIN_EXT=".brain"

# ─── PARSE ARGS ───────────────────────────────────────────────────────
CHECK_ONLY=false; FORCE=false; FRESH=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --check)     CHECK_ONLY=true; shift ;;
        --force)     FORCE=true; shift ;;
        --fresh)     FRESH=true; shift ;;
        --workspace) WORKSPACE="$2"; shift 2 ;;
        --repo)      REPO="$2"; shift 2 ;;
        --branch)    BRANCH="$2"; shift 2 ;;
        --token)     TOKEN="$2"; shift 2 ;;
        --key)       BRAIN_KEY="$2"; shift 2 ;;
        *)           echo "Unknown: $1"; exit 1 ;;
    esac
done

GREEN='\033[92m'; YELLOW='\033[93m'; RED='\033[91m'; BLUE='\033[94m'
CYAN='\033[96m'; DIM='\033[2m'; BOLD='\033[1m'; RESET='\033[0m'
log()  { echo -e "  $1 $2"; }
hdr()  { echo -e "\n${BOLD}${CYAN}$(printf '─%.0s' {1..60})${RESET}\n  ${BOLD}🧠 $1${RESET}\n${BOLD}${CYAN}$(printf '─%.0s' {1..60})${RESET}\n"; }

is_protected_dir() { for d in "${PROTECTED_DIRS[@]}"; do [[ "$1" == "$d" ]] && return 0; done; return 1; }
is_protected_file() { for f in "${PROTECTED_FILES[@]}"; do [[ "$1" == "$f" ]] && return 0; done; return 1; }

VERSION_FILE="$WORKSPACE/.brain_version"
get_ver() { [[ -f "$VERSION_FILE" ]] && python3 -c "import json; print(json.load(open('$VERSION_FILE')).get('version',''))" 2>/dev/null || echo ""; }
save_ver() {
    python3 -c "
import json; from datetime import datetime, timezone
json.dump({'version':'$1','repo':'$REPO','installed_at':datetime.now(timezone.utc).isoformat(),'synced_at':datetime.now(timezone.utc).isoformat()},open('$VERSION_FILE','w'),indent=2)"
}

hdr "AIM Brain Sync"
INSTALLED_VER=$(get_ver); IS_FIRST=false; [[ -z "$INSTALLED_VER" ]] && IS_FIRST=true
log "📍" "Workspace: $WORKSPACE"; log "📦" "Repo: $REPO ($BRANCH)"; log "📌" "Installed: v${INSTALLED_VER:-none}"
$IS_FIRST && log "🆕" "${GREEN}First install — full setup${RESET}"

[[ -n "$TOKEN" ]] && REPO_URL="https://${TOKEN}@github.com/${REPO}.git" || REPO_URL="https://github.com/${REPO}.git"

if $CHECK_ONLY; then
    RV=$(curl -sf "https://raw.githubusercontent.com/${REPO}/${BRANCH}/manifest.json" | python3 -c "import json,sys;print(json.load(sys.stdin).get('version',''))" 2>/dev/null || echo "")
    [[ -n "$RV" ]] && { [[ "$RV" == "$INSTALLED_VER" ]] && log "✅" "${GREEN}Up to date (v${RV})${RESET}" || log "🔄" "${YELLOW}Update available: v${INSTALLED_VER:-none} → v${RV}${RESET}"; } || log "⚠️" "${YELLOW}Could not check${RESET}"
    exit 0
fi

$FRESH && { echo -e "\n${RED}${BOLD}⚠️  --fresh overwrites EVERYTHING!${RESET}"; read -p "  Type 'yes': " c; [[ "$c" != "yes" ]] && exit 0; }

TEMP=$(mktemp -d); trap "rm -rf $TEMP" EXIT
log "⬇️" "${BLUE}Fetching latest brain...${RESET}"
git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TEMP" 2>/dev/null
rm -rf "$TEMP/.git"

RV="unknown"; CL=""
[[ -f "$TEMP/manifest.json" ]] && { RV=$(python3 -c "import json;print(json.load(open('$TEMP/manifest.json')).get('version','unknown'))"); CL=$(python3 -c "import json;print(json.load(open('$TEMP/manifest.json')).get('changelog',''))"); }

! $FORCE && ! $FRESH && [[ "$INSTALLED_VER" == "$RV" ]] && { log "✅" "${GREEN}Already up to date (v${RV})${RESET}"; exit 0; }
$IS_FIRST && log "📥" "${GREEN}Installing v${RV}${RESET}" || log "🔄" "${YELLOW}Updating: v${INSTALLED_VER:-none} → v${RV}${RESET}"

# ─── Handle encrypted content ─────────────────────────────────────────
ENCRYPTED_DIRS_LIST=$(python3 -c "import json;m=json.load(open('$TEMP/manifest.json'));print(' '.join(m.get('encrypted_dirs',[])))" 2>/dev/null || echo "")
HAS_ENCRYPTED=false
[[ -n "$ENCRYPTED_DIRS_LIST" && -d "$TEMP/$ENCRYPTED_DIR" ]] && HAS_ENCRYPTED=true

if $HAS_ENCRYPTED; then
    if [[ -z "$BRAIN_KEY" ]]; then
        echo ""
        log "🔒" "${RED}This brain contains encrypted premium content.${RESET}"
        log "❌" "${RED}BRAIN_KEY is required but not set.${RESET}"
        echo ""
        log "💡" "${YELLOW}Set your key:  export BRAIN_KEY=\"your-key-here\"${RESET}"
        log "💡" "${YELLOW}Or in .env:    BRAIN_KEY=your-key-here${RESET}"
        log "💡" "${YELLOW}Contact AIM to get your license key.${RESET}"
        echo ""
        exit 1
    fi

    if ! command -v openssl &>/dev/null; then
        log "❌" "${RED}openssl is required for decryption but was not found${RESET}"
        exit 1
    fi

    log "🔐" "${CYAN}Decrypting premium modules...${RESET}"
    for dir_name in $ENCRYPTED_DIRS_LIST; do
        brain_file="$TEMP/$ENCRYPTED_DIR/${dir_name}${BRAIN_EXT}"
        [[ ! -f "$brain_file" ]] && { log "⚠️" "${YELLOW}${dir_name}${BRAIN_EXT} — not found, skipping${RESET}"; continue; }

        tmp_archive=$(mktemp --suffix=.tar.gz)
        log "🔓" "${BLUE}${dir_name}/ — decrypting...${RESET}"
        if ! openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -in "$brain_file" -out "$tmp_archive" -pass "pass:$BRAIN_KEY" 2>/dev/null; then
            log "❌" "${RED}Decryption failed — your BRAIN_KEY is invalid.${RESET}"
            log "💡" "${YELLOW}Double-check your key or contact AIM for a valid license.${RESET}"
            rm -f "$tmp_archive"
            exit 1
        fi

        log "✅" "${GREEN}${dir_name}/ — decrypted${RESET}"
        tar xzf "$tmp_archive" -C "$TEMP"
        rm -f "$tmp_archive"
    done
    echo ""
fi

mkdir -p "$WORKSPACE"
SRC="$TEMP"; [[ -d "$TEMP/template" ]] && SRC="$TEMP/template"
echo ""

UPD=(); SKP=(); SDD=()
for item in "$SRC"/*; do
    [[ ! -e "$item" ]] && continue; name=$(basename "$item"); dest="$WORKSPACE/$name"
    case "$name" in .*|manifest.json|README.md|LICENSE|.gitignore|.env.example|update.sh|update.py|brain_sync.py|encrypted) continue ;; esac

    if [[ -d "$item" ]] && is_protected_dir "$name"; then
        [[ -d "$dest" ]] && ! $FRESH && { log "🔒" "$name/ — protected"; SKP+=("$name"); } || { log "🌱" "${GREEN}$name/ — seeding${RESET}"; [[ -d "$dest" ]] && rm -rf "$dest"; cp -r "$item" "$dest"; SDD+=("$name"); }; continue; fi
    if [[ -f "$item" ]] && is_protected_file "$name"; then
        [[ -f "$dest" ]] && ! $FRESH && { log "🔒" "$name — protected"; SKP+=("$name"); } || { log "🌱" "${GREEN}$name — seeding${RESET}"; cp "$item" "$dest"; SDD+=("$name"); }; continue; fi

    [[ -d "$item" ]] && { log "🔄" "${BLUE}$name/ — updating${RESET}"; [[ -d "$dest" ]] && rm -rf "$dest"; cp -r "$item" "$dest"; } || { log "🔄" "${BLUE}$name — updating${RESET}"; cp "$item" "$dest"; }
    UPD+=("$name")
done

[[ -d "$TEMP/_master" ]] && { log "🔧" "${BLUE}_master/ — updating${RESET}"; [[ -d "$WORKSPACE/_master" ]] && rm -rf "$WORKSPACE/_master"; cp -r "$TEMP/_master" "$WORKSPACE/_master"; UPD+=("_master"); }

save_ver "$RV"
echo ""; hdr "Sync Complete"
log "✅" "${GREEN}Brain v${RV}${RESET}"
$HAS_ENCRYPTED && log "🔐" "${GREEN}Premium content decrypted${RESET}"
[[ -n "$CL" ]] && log "📝" "What's new: $CL"
[[ ${#UPD[@]} -gt 0 ]] && log "🔄" "Updated: $(IFS=', '; echo "${UPD[*]}")"
[[ ${#SDD[@]} -gt 0 ]] && log "🌱" "Seeded: $(IFS=', '; echo "${SDD[*]}")"
[[ ${#SKP[@]} -gt 0 ]] && log "🔒" "Protected: $(IFS=', '; echo "${SKP[*]}")"
echo ""
