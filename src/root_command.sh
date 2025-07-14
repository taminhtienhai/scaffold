set -euo pipefail
IFS=$'\n\t'

# --- Script Configuration ---
readonly SCRIPT_NAME="scaffold"
readonly SCRIPT_VERSION="1.2.0"
readonly TEMP_DIR=$(mktemp -d)

# --- Global Variables ---
DEBUG=${args[--debug]:-}
VERBOSE=${args[--verbose]:-}
FORCE=${args[--force]:-}
TEMPLATE_PATH=${args[--path]:-}
GIT_REPO=${args[--git]:-}
GIT_SUB_DIR=${args[--gitsubdir]:-}
GROUP_ID=${args[--group-id]:-}
ARTIFACT_ID=${args[--artifact-id]:-}
OUTPUT_DIR=${args[--out]:-.}
DESCRIPTION="A default description for my awesome app."
AUTHOR="Jane Doe"
PRE_HOOK=""
POST_HOOK=""

# --- Cleanup ---
cleanup() {
    local exit_code=$?
    debug "Cleaning up temporary directory: $TEMP_DIR"
    rm -rf "$TEMP_DIR"
    rm -f "$OUTPUT_DIR/scaffold.ini"
    exit $exit_code
}
trap cleanup EXIT
trap 'error "Script interrupted by user"; exit 130' INT TERM

# --- Main Logic ---
main() {
    if [[ -n "${args[--deps]:-}" ]]; then
        print_dependencies
        exit 0
    fi

    validate_args

    if [[ "$DEBUG" -eq 1 ]]; then
        debug "Configuration:"
        debug "  Template Path: ${TEMPLATE_PATH:-(none)}"
        debug "  Git Repo: ${GIT_REPO:-(none)}"
        debug "  Group ID: ${GROUP_ID:-(not set)}"
        debug "  Artifact ID: ${ARTIFACT_ID:-(not set)}"
        debug "  Output Dir: $OUTPUT_DIR"
        debug "  Force: $FORCE"
    fi

    log "Starting $SCRIPT_NAME v$SCRIPT_VERSION"

    local source_template_dir="$TEMP_DIR/source"
    mkdir -p "$source_template_dir"

    check_dependencies "rsync"
    if [[ -n "$GIT_REPO" ]]; then
        check_dependencies "git"
        log "Cloning template from $GIT_REPO..."
        git clone --depth 1 "$GIT_REPO" "$source_template_dir" || { error "Failed to clone repository: $GIT_REPO"; exit 1; }

        if ! [[ -z "$GIT_SUB_DIR" ]]; then
            source_template_dir="$source_template_dir/$GIT_SUB_DIR"
        fi
    else
        log "Copying local template from $TEMPLATE_PATH..."
        rsync -a --exclude='.git' --exclude='.gradle' --exclude='.env' "$TEMPLATE_PATH/" "$source_template_dir/"
    fi

    parse_ini_file "$source_template_dir/scaffold.ini"

    prompt_for_input "Enter Group ID (e.g., com.example.app)" GROUP_ID
    prompt_for_input "Enter Artifact ID (e.g., my-app)" ARTIFACT_ID

    if [[ -z "$GROUP_ID" || -z "$ARTIFACT_ID" ]]; then
        error "GroupID and ArtifactID are required."
        exit 1
    fi
    
    log "Project Configuration:"
    log "  Group ID:    $GROUP_ID"
    log "  Artifact ID: $ARTIFACT_ID"

    execute_hook "$PRE_HOOK" "pre-scaffolding"

    rsync -a "$source_template_dir/" "$OUTPUT_DIR/"
    log "Processing template..."
    replace_placeholders_and_structure "$OUTPUT_DIR"

    execute_hook "$POST_HOOK" "post-scaffolding"

    log "✅ Project '$ARTIFACT_ID' successfully generated in: $OUTPUT_DIR"
}

main