# --- Argument Validation ---
validate_args() {
    if [[ -n "$TEMPLATE_PATH" && -n "$GIT_REPO" ]]; then
        error "Options --path and --git are mutually exclusive."
        exit 1
    fi
    if [[ -z "$TEMPLATE_PATH" && -z "$GIT_REPO" ]]; then
        error "A template source is required. Use --path or --git."
        exit 1
    fi

    if [[ -n "$TEMPLATE_PATH" ]]; then
        check_directory "$TEMPLATE_PATH" || exit 1
    fi

    if [[ -e "$OUTPUT_DIR" && "$OUTPUT_DIR" != "." ]]; then
        if [[ "$FORCE" -eq "1" ]]; then
            warn "Output directory '$OUTPUT_DIR' already exists. Overwriting."
            rm -rf "$OUTPUT_DIR"
        else
            error "Output directory '$OUTPUT_DIR' already exists. Use --force to overwrite."
            exit 1
        fi
    fi
    mkdir -p "$OUTPUT_DIR"
    OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"
}
