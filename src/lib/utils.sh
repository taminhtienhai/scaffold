# --- Utility Functions ---
check_dependencies() {
    local deps=("$@")
    local missing=()
    log "Checking for: ${deps[*]}"
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required dependencies: ${missing[*]}"
        error "Please install them and try again."
        exit 1
    fi
}

check_directory() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        error "Directory not found: $dir"
        return 1
    fi
    if [[ ! -r "$dir" ]]; then
        error "Directory not readable: $dir"
        return 1
    fi
    return 0
}

print_dependencies() {
    echo "Required dependencies for $SCRIPT_NAME:"
    echo "  - rsync: For copying local templates."
    echo "  - git:   For cloning remote templates."
    echo ""
    echo "The script also uses common core utilities like: sed, grep, find, cut, xargs, mkdir, mv, rm."
}

prompt_for_input() {
    local prompt_message="$1"
    local -n var_to_set="$2"

    while [[ -z "${var_to_set}" ]]; do
        echo -e -n "${YELLOW}${prompt_message}:${NC} " >&2
        read -r var_to_set
        if [[ -z "${var_to_set}" ]]; then
            warn "This value cannot be empty."
        fi
    done
}
