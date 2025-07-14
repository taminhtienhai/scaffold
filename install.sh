#!/bin/sh
#
# Installer for the scaffold.sh tool.
#
# This script should be run via curl:
#   curl -fsSL <URL_TO_THIS_SCRIPT> | sh -s -- -i
#
# It can also be downloaded and run manually.

set -e # Exit on first error

# --- Configuration ---
# The URL where the main scaffold.sh script is located.
SOURCE_URL="https://raw.githubusercontent.com/taminhtienhai/scaffold/main/scaffold"

# The location to install the script.
# We use $HOME/.local/bin as it's the standard for user-installed executables
# and doesn't require sudo.
INSTALL_DIR="$HOME/.local/bin"
EXECUTABLE_NAME="scaffold"
INSTALL_PATH="$INSTALL_DIR/$EXECUTABLE_NAME"

# --- Functions ---
log_info() {
    echo "INFO: $1"
}

log_warning() {
    # Print in yellow
    printf "\033[33mWARN: %s\033[0m\n" "$1"
}

log_error() {
    # Print in red
    printf "\033[31mERROR: %s\033[0m\n" "$1" >&2
    exit 1
}

# Function to check if a command is in the user's PATH
is_in_path() {
    command -v "$1" >/dev/null 2>&1
}

# Function to perform the installation
do_install() {
    log_info "Starting installation of the '$EXECUTABLE_NAME' tool..."

    # Check if required tools are available
    if ! is_in_path curl; then
        log_error "'curl' is required but not found. Please install it first."
    fi

    log_info "Downloading script from $SOURCE_URL..."
    # Download the script to a temporary file
    tmp_file=$(mktemp)
    if ! curl -fsSL "$SOURCE_URL" -o "$tmp_file"; then
        log_error "Failed to download the script. Check the URL and your internet connection."
    fi

    log_info "Creating installation directory at $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR"

    log_info "Installing to $INSTALL_PATH..."
    # Move the script to the installation directory and make it executable
    install -m 755 "$tmp_file" "$INSTALL_PATH"

    # Cleanup temporary file
    rm "$tmp_file"

    log_info "Installation successful!"

    # Check if the installation directory is in the PATH
    if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
        log_warning "The directory $INSTALL_DIR is not in your PATH."
        log_warning "You will need to add it to your shell's configuration file (e.g., ~/.bashrc, ~/.zshrc) to run the tool directly."
        log_warning "Add the following line to your shell config:"
        echo
        echo "  export PATH=\"$HOME/.local/bin:\$PATH\""
        echo
        log_warning "After adding it, restart your shell or run 'source ~/.bashrc' (or equivalent)."
        log_info "You can run the tool for now using the full path: $INSTALL_PATH"
    else
        log_info "You can now run the tool by typing: $EXECUTABLE_NAME"
    fi
}

# --- Main Logic ---
do_install