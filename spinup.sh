#!/bin/bash
set -euo pipefail

# spinup.sh — GitHub repo + devcontainer setup CLI
# Usage: ./spinup.sh [options]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# --- Helper functions ---

die() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

info() {
    echo -e "${CYAN}$1${NC}"
}

success() {
    echo -e "${GREEN}$1${NC}"
}

warn() {
    echo -e "${YELLOW}$1${NC}"
}

# Detect available runtimes from Dockerfile templates
detect_runtimes() {
    local runtimes=()
    for f in "$TEMPLATES_DIR/dockerfiles/Dockerfile."*; do
        [ -f "$f" ] || continue
        local name="${f##*.}"
        runtimes+=("$name")
    done
    echo "${runtimes[@]}"
}

# Load runtime config
load_runtime_conf() {
    local runtime="$1"
    local conf_file="$TEMPLATES_DIR/runtime.conf/${runtime}.conf"
    [ -f "$conf_file" ] || die "Runtime config not found: $conf_file"
    source "$conf_file"
}

# --- Argument parsing ---

REPO_NAME=""
RUNTIME=""
VERSION=""
CLONE_PATH="$(cd "$(dirname "$0")/.." && pwd)"
CLONE_PATH_SET=false
VISIBILITY="private"
DESCRIPTION=""

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -n, --name <name>         Repository name
  -r, --runtime <runtime>   Runtime ($(detect_runtimes | tr ' ' '/'))
  -v, --version <version>   Runtime version
  -p, --path <path>         Clone destination (default: spinup parent directory)
  --public                  Public repository (default: private)
  -d, --description <desc>  Repository description
  -h, --help                Show this help
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--name)
            REPO_NAME="$2"
            shift 2
            ;;
        -r|--runtime)
            RUNTIME="$2"
            shift 2
            ;;
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -p|--path)
            CLONE_PATH="$2"
            CLONE_PATH_SET=true
            shift 2
            ;;
        --public)
            VISIBILITY="public"
            shift
            ;;
        -d|--description)
            DESCRIPTION="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            die "Unknown option: $1"
            ;;
    esac
done

# --- Prerequisite checks ---

command -v gh >/dev/null 2>&1 || die "gh (GitHub CLI) is not installed. Install it first: https://cli.github.com"
command -v git >/dev/null 2>&1 || die "git is not installed."

if ! gh auth status >/dev/null 2>&1; then
    die "Not authenticated with GitHub. Run 'gh auth login' first."
fi


# --- Interactive input ---

AVAILABLE_RUNTIMES=($(detect_runtimes))
[ ${#AVAILABLE_RUNTIMES[@]} -eq 0 ] && die "No runtime templates found in $TEMPLATES_DIR/dockerfiles/"

# 1. Repository name
if [ -z "$REPO_NAME" ]; then
    echo -e "${BOLD}Repository name:${NC}"
    read -r REPO_NAME
    [ -z "$REPO_NAME" ] && die "Repository name is required."
fi

# 2. Runtime selection
if [ -z "$RUNTIME" ]; then
    echo -e "\n${BOLD}Select runtime:${NC}"
    PS3="Enter number: "
    select rt in "${AVAILABLE_RUNTIMES[@]}"; do
        if [ -n "$rt" ]; then
            RUNTIME="$rt"
            break
        fi
        echo "Invalid selection. Try again."
    done
fi

# Validate runtime
local_dockerfile="$TEMPLATES_DIR/dockerfiles/Dockerfile.$RUNTIME"
[ -f "$local_dockerfile" ] || die "Unknown runtime: $RUNTIME (no Dockerfile.$RUNTIME found)"

# 3. Version selection
load_runtime_conf "$RUNTIME"

if [ -z "$VERSION" ]; then
    echo -e "\n${BOLD}Select $RUNTIME version (default: $LTS):${NC}"
    IFS=' ' read -ra VERSION_OPTIONS <<< "$OPTIONS"
    PS3="Enter number: "
    select ver in "${VERSION_OPTIONS[@]}"; do
        if [ -n "$ver" ]; then
            VERSION="$ver"
            break
        fi
        echo "Invalid selection. Try again."
    done
fi

# Default to LTS if still empty
[ -z "$VERSION" ] && VERSION="$LTS"

# 4. Visibility
if [ "$VISIBILITY" = "private" ]; then
    echo -e "\n${BOLD}Visibility [private/public] (default: private):${NC}"
    read -r vis_input
    if [ "$vis_input" = "public" ]; then
        VISIBILITY="public"
    fi
fi

# 5. Description
if [ -z "$DESCRIPTION" ]; then
    echo -e "\n${BOLD}Description (optional, Enter to skip):${NC}"
    read -r DESCRIPTION
fi

# 6. Clone path
if [ "$CLONE_PATH_SET" = false ]; then
    echo -e "\n${BOLD}Clone path (default: $CLONE_PATH):${NC}"
    read -r path_input
    if [ -n "$path_input" ]; then
        # 相対パスを絶対パスに変換
        if [[ "$path_input" = /* ]]; then
            CLONE_PATH="$path_input"
        else
            CLONE_PATH="$PWD/$path_input"
        fi
    fi
fi

# Clone先ディレクトリの存在確認
[ -d "$CLONE_PATH" ] || die "Clone path does not exist: $CLONE_PATH"

# --- Confirmation ---

echo ""
echo -e "${BOLD}=== Summary ===${NC}"
echo -e "  Repository:  ${CYAN}$REPO_NAME${NC}"
echo -e "  Runtime:     ${CYAN}$RUNTIME $VERSION${NC}"
echo -e "  Visibility:  ${CYAN}$VISIBILITY${NC}"
echo -e "  Clone path:  ${CYAN}$CLONE_PATH/$REPO_NAME${NC}"
[ -n "$DESCRIPTION" ] && echo -e "  Description: ${CYAN}$DESCRIPTION${NC}"
echo ""

read -r -p "Proceed? [y/N] " confirm
[[ "$confirm" =~ ^[yY]$ ]] || { echo "Aborted."; exit 0; }

# --- Create repository ---

info "\nCreating GitHub repository..."

GH_ARGS=(repo create "$REPO_NAME" "--$VISIBILITY" --clone)
[ -n "$DESCRIPTION" ] && GH_ARGS+=(-d "$DESCRIPTION")

cd "$CLONE_PATH"
gh "${GH_ARGS[@]}"

PROJECT_DIR="$CLONE_PATH/$REPO_NAME"
cd "$PROJECT_DIR"

# --- Set up devcontainer ---

info "Setting up .devcontainer..."

mkdir -p .devcontainer

# Copy and process Dockerfile (replace {{VERSION}})
sed "s/{{VERSION}}/$VERSION/g" "$TEMPLATES_DIR/dockerfiles/Dockerfile.$RUNTIME" > .devcontainer/Dockerfile

# Copy devcontainer.json
cp "$TEMPLATES_DIR/devcontainer/devcontainer.$RUNTIME.json" .devcontainer/devcontainer.json

# Copy and process init-firewall.sh (inject extra domains)
EXTRA_DOMAIN_LIST=""
FIREWALL_DOMAINS_FILE="$TEMPLATES_DIR/firewall-domains/${RUNTIME}.txt"
if [ -f "$FIREWALL_DOMAINS_FILE" ]; then
    while IFS= read -r domain; do
        [ -z "$domain" ] && continue
        [[ "$domain" =~ ^# ]] && continue
        EXTRA_DOMAIN_LIST="$EXTRA_DOMAIN_LIST $domain"
    done < "$FIREWALL_DOMAINS_FILE"
    EXTRA_DOMAIN_LIST="${EXTRA_DOMAIN_LIST# }"  # trim leading space
fi

sed "s|^EXTRA_DOMAINS=\"\"|EXTRA_DOMAINS=\"$EXTRA_DOMAIN_LIST\"|" "$TEMPLATES_DIR/init-firewall.sh" > .devcontainer/init-firewall.sh
chmod +x .devcontainer/init-firewall.sh

# Copy .gitignore
GITIGNORE_FILE="$TEMPLATES_DIR/gitignore/${RUNTIME}.gitignore"
if [ -f "$GITIGNORE_FILE" ]; then
    cp "$GITIGNORE_FILE" .gitignore
else
    touch .gitignore
fi

# --- Set up sample code ---

SAMPLE_DIR="$TEMPLATES_DIR/sample-code/$RUNTIME"
if [ -d "$SAMPLE_DIR" ]; then
    info "Setting up sample code..."

    # Copy all files preserving directory structure
    (cd "$SAMPLE_DIR" && find . -type f | while read -r file; do
        dest="${file#./}"
        dest_dir="$(dirname "$dest")"
        [ "$dest_dir" != "." ] && mkdir -p "$PROJECT_DIR/$dest_dir"

        # .tmpl files: strip extension after processing
        if [[ "$dest" == *.tmpl ]]; then
            final="${dest%.tmpl}"
            sed -e "s/{{PROJECT_NAME}}/$REPO_NAME/g" \
                -e "s/{{VERSION}}/$VERSION/g" \
                "$SAMPLE_DIR/$dest" > "$PROJECT_DIR/$final"
        else
            sed -e "s/{{PROJECT_NAME}}/$REPO_NAME/g" \
                -e "s/{{VERSION}}/$VERSION/g" \
                "$SAMPLE_DIR/$dest" > "$PROJECT_DIR/$dest"
        fi
    done)
fi

# --- Initial commit ---

info "Creating initial commit..."

git add -A
git commit -m "Initial setup: $RUNTIME $VERSION devcontainer"
git push -u origin main

# --- Done ---

echo ""
success "Done! Project created at: $PROJECT_DIR"
info "Spawning a new shell in the project directory..."
info "Press Ctrl-D or type 'exit' to return to your original location."
echo ""
echo "Run 'claude' to start developing!"

cd "$PROJECT_DIR"
exec "$SHELL"
