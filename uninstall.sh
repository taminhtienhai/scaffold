#!/bin/sh
#
# Uninstaller for the scaffold.sh tool.
#

set -e # Exit on first error

# --- Configuration ---
INSTALL_DIR="$HOME/.local/bin"
EXECUTABLE_NAME="scaffold"
INSTALL_PATH="$INSTALL_DIR/$EXECUTABLE_NAME"

# --- Functions ---
log_info() {
    echo "INFO: $1"
}

log_success() {
    # Print in green
    printf "\033[32mSUCCESS: %s\033[0m\n" "$1"
}

log_warning() {
    # Print in yellow
    printf "\033[33mWARN: %s\033[0m\n" "$1"
}

# --- Main Logic ---
log_info "Starting uninstallation of the '$EXECUTABLE_NAME' tool..."

if [ -f "$INSTALL_PATH" ]; then
    log_info "Removing $INSTALL_PATH..."
    rm "$INSTALL_PATH"
    log_success "Uninstallation successful!"
else
    log_warning "The executable '$EXECUTABLE_NAME' was not found at $INSTALL_PATH."
    log_warning "No action taken."
fi

log_info "If you added '$INSTALL_DIR' to your PATH, you may want to remove it from your shell configuration file (e.g., ~/.bashrc, ~/.zshrc)."

