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
# IMPORTANT: CHANGE THIS TO YOUR SCRIPT'S ACTUAL URL
SOURCE_URL="https://raw.githubusercontent.com/taminhtienhai/scaffold/main/scaffold"

# The location to install the script. /usr/local/bin is standard for user-installed executables.
INSTALL_DIR="/usr/local/bin"
EXECUTABLE_NAME="scaffold"
INSTALL_PATH="$INSTALL_DIR/$EXECUTABLE_NAME"

# --- Functions ---
log_info() {
    echo "INFO: $1"
}

log_error() {
    echo "ERROR: $1" >&2
    exit 1
}

# Function to perform the installation
do_install() {
    log_info "Starting installation of the '$EXECUTABLE_NAME' tool..."

    # Check for root privileges, as we need them to write to the install directory
    if [ "$(id -u)" -ne 0 ]; then
        log_error "This installer requires root privileges. Please run with 'sudo'."
    fi

    # Check if required tools are available
    if ! command -v curl >/dev/null; then
        log_error "'curl' is required but not found. Please install it first."
    fi

    log_info "Downloading script from $SOURCE_URL..."
    # Download the script to a temporary file
    tmp_file=$(mktemp)
    if ! curl -fsSL "$SOURCE_URL" -o "$tmp_file"; then
        log_error "Failed to download the script. Check the URL and your internet connection."
    fi

    log_info "Installing to $INSTALL_PATH..."
    # Move the script to the installation directory
    install -m 755 "$tmp_file" "$INSTALL_PATH"

    # Cleanup temporary file
    rm "$tmp_file"

    log_info "Installation successful!"
    log_info "You can now run the tool by typing: scaffold"
}

# --- Main Logic ---
# The script is designed to be run with `-i` to trigger the installation.
if [ "$1" = "-i" ]; then
    do_install
else
    echo "This is an installer script for the 'scaffold' tool."
    echo "Please run it like this:"
    echo "  curl -fsSL <URL> | sudo sh -s -- -i"
fi
