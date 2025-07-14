#!/usr/bin/env bash

# Script: scaffold.sh
# Description: Generates a new Java project from an existing local or remote template.
# Author: Gemini
# Version: 1.1.0
# Usage: ./scaffold.sh [OPTIONS]

set -euo pipefail # Exit on error, undefined vars, pipe failures
IFS=$'\n\t'      # Set secure Internal Field Separator

# --- Script Configuration ---
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_VERSION="1.1.0"
readonly TEMP_DIR=$(mktemp -d)

# --- Default Values ---
DEBUG=false
VERBOSE=false
FORCE=false
TEMPLATE_PATH=""
GIT_REPO=""
GROUP_ID=""
ARTIFACT_ID=""
DESCRIPTION="A default description for my awesome app."
AUTHOR="Jane Doe"
OUTPUT_DIR="."

# --- Colors for Output ---
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# --- Logging Functions ---
log() {
    echo -e "${GREEN}[INFO]${NC} $*" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

debug() {
    if [[ "$DEBUG" == "true" ]]; then
        echo -e "${PURPLE}[DEBUG]${NC} $*" >&2
    fi
}

verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${CYAN}[VERBOSE]${NC} $*" >&2
    fi
}

# --- Usage and Version ---
usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS]

Description:
    A CLI tool that generates a new Java project from an existing template.
    It checks for a 'scaffold.ini' file and creates the standard Java
    directory structure based on the groupId and artifactId.

Options:
    -h, --help                  Show this help message and exit
    -v, --version               Show version information and exit
    -d, --debug                 Enable debug mode
    -V, --verbose               Enable verbose output
    -f, --force                 Force operation without confirmation (e.g., overwrite)

Template Options (mutually exclusive):
    -p, --path PATH             Path to the local directory to use as a template.
    -g, --git REMOTE_URL        URL of the git repository to use as a template.

Project Options (overrides scaffold.ini):
    -gid, --group-id GROUP_ID   Java project's groupId (e.g., com.example.app)
    -id, --artifact-id ARTIFACT_ID Java project's artifactId (e.g., my-app)

Output:
    -o, --out DIR               Output project directory (default: current directory)

Examples:
    # Generate from a local template
    $SCRIPT_NAME -p ~/templates/java-template -o ./my-new-project

    # Generate from a remote Git template
    $SCRIPT_NAME -g https://github.com/user/java-template.git -o ./my-new-project

    # Generate and override scaffold.ini values
    $SCRIPT_NAME -p ~/templates/java-template -gid com.mycompany -id my-app

EOF
}

version() {
    echo "$SCRIPT_NAME version $SCRIPT_VERSION"
}

# --- Cleanup and Signal Handlers ---
cleanup() {
    local exit_code=$?
    debug "Cleaning up temporary directory: $TEMP_DIR"
    rm -rf "$TEMP_DIR"
    exit $exit_code
}

trap cleanup EXIT
trap 'error "Script interrupted by user"; exit 130' INT TERM

# --- Utility Functions ---
check_dependencies() {
    local deps=("$@")
    local missing=()
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

# --- Core Logic ---

# Parses the scaffold.ini file and exports the variables
parse_ini_file() {
    local ini_file="$1"
    verbose "Parsing configuration from $ini_file"
    if ! [[ -f "$ini_file" ]]; then
        warn "scaffold.ini not found in template. Using command-line arguments or defaults."
        return
    fi

    # Read and process the INI file
    while IFS='=' read -r key value; do
        # Trim whitespace from key and value
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        log "${key}:${value}"

        # Skip comments and empty lines
        if [[ -z "$key" || "$key" == \#* ]]; then
            continue
        fi
        
        # Assign to global variables if they are not already set by command-line args
        case "$key" in
            ID)          [[ -z "$ARTIFACT_ID" ]] && ARTIFACT_ID="$value" ;;
            GROUP_ID)    [[ -z "$GROUP_ID" ]] && GROUP_ID="$value" ;;
            DESCRIPTION) [[ -z "$DESCRIPTION" ]] && DESCRIPTION="$value" ;;
            AUTHOR)      [[ -z "$AUTHOR" ]] && AUTHOR="$value" ;;
        esac
    done < "$ini_file"
}

# Replaces placeholders and creates Java package structure
replace_placeholders_and_structure() {
    local target_dir="$1"
    verbose "Starting placeholder replacement in $target_dir"

    # --- Step 1: Create Java package structure ---
    local group_id_path="${GROUP_ID//./\/}" # com.vng.example -> com/vng/example
    local artifact_id_path="${ARTIFACT_ID//-/_}" # spring-boot-demo -> spring_boot_demo
    local full_package_path="$group_id_path/$artifact_id_path"
    
    local java_roots=("src/main/java" "src/test/java")
    for root in "${java_roots[@]}"; do
        local source_root="$target_dir/$root"
        if [[ -d "$source_root" ]]; then
            verbose "Found Java source root: $source_root"
            local dest_package_dir="$source_root/$full_package_path"
            
            # Create the full package directory structure
            mkdir -p "$dest_package_dir"
            verbose "Created package structure: $dest_package_dir"
            
            # Move all files from the root into the new package structure
            # Use find to handle cases with no files gracefully
            find "$source_root" -maxdepth 1 -mindepth 1 -not -path "$source_root/$group_id_path*" -exec mv -t "$dest_package_dir" {} +
            
            # Clean up the com/ directory if it was created by the move
            if [ -d "$source_root/com" ]; then
                rm -rf "$source_root/com"
            fi
        fi
    done

    # --- Step 2: Rename files containing placeholders ---
    find "$target_dir" -depth -type f -name '*${*}*' | while read -r file; do
        local new_file_name
        new_file_name=$(echo "$file" | sed "s|\${GROUP_ID}|$GROUP_ID|g" | sed "s|\${ID}|$ARTIFACT_ID|g")
        if [[ "$file" != "$new_file_name" ]]; then
            mv "$file" "$new_file_name"
            verbose "Renamed file: $file -> $new_file_name"
        fi
    done

    # --- Step 3: Replace content within all files ---
    find "$target_dir" -type f -print0 | while IFS= read -r -d $'\0' file; do
        # Use a temporary file for sed to handle in-place editing safely
        local temp_file
        temp_file=$(mktemp)
        sed "s|\${GROUP_ID}|$GROUP_ID|g; s|\${ID}|$ARTIFACT_ID|g; s|\${DESCRIPTION}|$DESCRIPTION|g; s|\${AUTHOR}|$AUTHOR|g" "$file" > "$temp_file" && mv "$temp_file" "$file"
        debug "Processed content in file: $file"
    done
    
    log "Placeholder replacement and structuring complete."
}


# --- Argument Parsing and Validation ---
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help) usage; exit 0 ;;
            -v|--version) version; exit 0 ;;
            -d|--debug) DEBUG=true; shift ;;
            -V|--verbose) VERBOSE=true; shift ;;
            -f|--force) FORCE=true; shift ;;
            -p|--path) TEMPLATE_PATH="$2"; shift 2 ;;
            -g|--git) GIT_REPO="$2"; shift 2 ;;
            -gid|--group-id) GROUP_ID="$2"; shift 2 ;;
            -id|--artifact-id) ARTIFACT_ID="$2"; shift 2 ;;
            -o|--out) OUTPUT_DIR="$2"; shift 2 ;;
            --) shift; break ;;
            -*) error "Unknown option: $1"; usage; exit 1 ;;
            *) # Positional arguments (none expected)
               error "Unknown argument: $1"; usage; exit 1 ;;
        esac
    done
}

validate_args() {
    # Mutually exclusive template source
    if [[ -n "$TEMPLATE_PATH" && -n "$GIT_REPO" ]]; then
        error "Options --path and --git are mutually exclusive."
        usage; exit 1
    fi
    if [[ -z "$TEMPLATE_PATH" && -z "$GIT_REPO" ]]; then
        error "A template source is required. Use --path or --git."
        usage; exit 1
    fi

    # Check local template path
    if [[ -n "$TEMPLATE_PATH" ]]; then
        check_directory "$TEMPLATE_PATH" || exit 1
    fi

    # Check output directory
    if [[ -e "$OUTPUT_DIR" && "$OUTPUT_DIR" != "." ]]; then
        if [[ "$FORCE" == "true" ]]; then
            warn "Output directory '$OUTPUT_DIR' already exists. Overwriting."
            rm -rf "$OUTPUT_DIR"
        else
            error "Output directory '$OUTPUT_DIR' already exists. Use --force to overwrite."
            exit 1
        fi
    fi
    mkdir -p "$OUTPUT_DIR"
    OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)" # Get absolute path
}

# --- Main Function ---
main() {
    parse_args "$@"
    validate_args

    # Show configuration in debug mode
    if [[ "$DEBUG" == "true" ]]; then
        debug "Configuration:"
        debug "  Script: $SCRIPT_NAME v$SCRIPT_VERSION"
        debug "  Template Path: ${TEMPLATE_PATH:-'(none)'}"
        debug "  Git Repo: ${GIT_REPO:-'(none)'}"
        debug "  Group ID: ${GROUP_ID:-'(not set)'}"
        debug "  Artifact ID: ${ARTIFACT_ID:-'(not set)'}"
        debug "  Output Dir: $OUTPUT_DIR"
        debug "  Force: $FORCE"
    fi

    log "Starting $SCRIPT_NAME v$SCRIPT_VERSION"

    # --- Step 1: Fetch Template ---
    local source_template_dir="$TEMP_DIR/source"
    mkdir -p "$source_template_dir"

    if [[ -n "$GIT_REPO" ]]; then
        check_dependencies "git"
        log "Cloning template from $GIT_REPO..."
        if ! git clone --depth 1 "$GIT_REPO" "$source_template_dir"; then
            error "Failed to clone repository: $GIT_REPO"
            exit 1
        fi
    else
        log "Copying local template from $TEMPLATE_PATH..."
        # Use rsync to copy contents, including hidden files
        rsync -a --exclude='.git' "$TEMPLATE_PATH/" "$source_template_dir/"
    fi

    debug "Parsing file..."
    # --- Step 2: Parse Configuration ---
    parse_ini_file "$source_template_dir/scaffold.ini"

    # Validate that required IDs are set
    if [[ -z "$GROUP_ID" ]]; then
        error "Project 'groupId' is not set. Provide it via --group-id or a scaffold.ini file."
        exit 1
    fi
    if [[ -z "$ARTIFACT_ID" ]]; then
        error "Project 'artifactId' (ID) is not set. Provide it via --artifact-id or a scaffold.ini file."
        exit 1
    fi
    
    log "Project Configuration:"
    log "  Group ID:    $GROUP_ID"
    log "  Artifact ID: $ARTIFACT_ID"
    log "  Description: $DESCRIPTION"
    log "  Author:      $AUTHOR"

    # --- Step 3: Copy to Final Destination ---
    verbose "Copying template to final destination: $OUTPUT_DIR"
    rsync -a "$source_template_dir/" "$OUTPUT_DIR/"

    # --- Step 4: Process Placeholders and Create Structure ---
    log "Processing template..."
    replace_placeholders_and_structure "$OUTPUT_DIR"

    log "✅ Project '$ARTIFACT_ID' successfully generated in: $OUTPUT_DIR"
}

# Run main function with all arguments
main "$@"
