# --- Core Logic ---

# Parses the scaffold.ini file
parse_ini_file() {
    local ini_file="$1"
    verbose "Parsing configuration from $ini_file"
    if ! [[ -f "$ini_file" ]]; then
        warn "scaffold.ini not found in template. Using command-line arguments or defaults."
        return
    fi

    # get_ini_value() {
    #     local key_to_find="$1"
    #     local found_value
    #     found_value=$(grep -E "^[[:space:]]*${key_to_find}[[:space:]]*=" "$ini_file" | head -n 1 | cut -d'=' -f2- | xargs)
    #     echo "$found_value"
    # }

    ini_load "$ini_file"

    if [[ -z "$ARTIFACT_ID" ]]; then ARTIFACT_ID=${ini["ID"]}; fi
    if [[ -z "$GROUP_ID" ]]; then GROUP_ID=${ini["GROUP_ID"]}; fi
    
    PRE_HOOK=${ini["PRE_HOOK"]:-}
    POST_HOOK=${ini["POST_HOOK"]:-}

    local desc_from_file; desc_from_file=${ini["DESCRIPTION"]:-}
    if [[ -n "$desc_from_file" ]]; then DESCRIPTION="$desc_from_file"; fi

    local author_from_file; author_from_file=${ini["AUTHOR"]:-"Unknown"}
    if [[ -n "$author_from_file" ]]; then AUTHOR="$author_from_file"; fi
}

# Replaces placeholders and creates Java package structure
replace_placeholders_and_structure() {
    local target_dir="$1"
    verbose "Starting placeholder replacement in $target_dir"

    local group_id_path="${GROUP_ID//./\/}"
    local artifact_id_path="${ARTIFACT_ID//-/}"
    local full_package_path="$group_id_path/$artifact_id_path"
    
    for root in "src/main/java" "src/test/java"; do
        local dest_package_dir="$target_dir/$root/$full_package_path"
        mkdir -p "$dest_package_dir"
        verbose "Created package structure: $dest_package_dir"
    done

    find "$target_dir" -depth -type f -name '*${*}*' | while read -r file; do
        local new_file_name; new_file_name=$(echo "$file" | sed "s|\${GROUP_ID}|$GROUP_ID|g; s|\${ID}|$ARTIFACT_ID|g")
        if [[ "$file" != "$new_file_name" ]]; then
            mv "$file" "$new_file_name"
            verbose "Renamed file: $file -> $new_file_name"
        fi
    done

    find "$target_dir" -type f -print0 | while IFS= read -r -d $'\0' file; do
        local temp_file; temp_file=$(mktemp)
        sed "s|\${GROUP_ID}|$GROUP_ID|g; s|\${ID}|$ARTIFACT_ID|g; s|\${DESCRIPTION}|$DESCRIPTION|g; s|\${AUTHOR}|$AUTHOR|g" "$file" > "$temp_file" && mv "$temp_file" "$file"
        debug "Processed content in file: $file"
    done
    
    log "Placeholder replacement and structuring complete."
}

execute_hook() {
    local hook_command="$1"
    local hook_name="$2"

    if [[ -z "$hook_command" ]]; then
        debug "No $hook_name hook script defined. Skipping."
        return
    fi
    hook_command="${hook_command#\"}"
    hook_command="${hook_command#\'}"

    hook_command="${hook_command%\"}"
    hook_command="${hook_command%\'}"

    log "Executing $hook_name hook..."
    verbose "Running command: $hook_command"

    (
        cd "$OUTPUT_DIR"
        if ! eval "$hook_command"; then
            error "$hook_name hook failed. Command: '$hook_command'"
            exit 1
        fi
    )
    log "$hook_name hook executed successfully."
}
