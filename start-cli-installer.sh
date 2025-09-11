#!/bin/sh
# start-cli installer for StartOS development
# Downloads and installs start-cli from official GitHub releases

set -e
set -u
# set -x

# Colors for better visual appeal (safe fallbacks)
if command -v tput >/dev/null 2>&1; then
    BOLD=$(tput bold 2>/dev/null || echo '')
    BLUE=$(tput setaf 4 2>/dev/null || echo '')
    GREEN=$(tput setaf 2 2>/dev/null || echo '')
    YELLOW=$(tput setaf 3 2>/dev/null || echo '')
    RED=$(tput setaf 1 2>/dev/null || echo '')
    WHITE=$(tput setaf 7 2>/dev/null || echo '')
    RESET=$(tput sgr0 2>/dev/null || echo '')
    DIM=$(tput dim 2>/dev/null || echo '')
else
    BOLD='' BLUE='' GREEN='' YELLOW='' RED='' WHITE='' RESET='' DIM=''
fi

# ASCII Header - Clean and properly centered
printf "\n"
printf "%s┌───────────────────────────────────────────────────────────────┐%s\n" "$DIM$RED" "$RESET"
printf "%s│%s                                                               %s│%s\n" "$DIM$RED" "$RESET" "$DIM$RED" "$RESET"
printf "%s│%s                           %sstart-cli%s                           %s│%s\n" "$DIM$RED" "$RESET" "$WHITE$BOLD" "$RESET" "$DIM$RED" "$RESET"
printf "%s│%s                                                               %s│%s\n" "$DIM$RED" "$RESET" "$DIM$RED" "$RESET"
printf "%s│%s                %sStartOS Command Line Interface%s                 %s│%s\n" "$DIM$RED" "$RESET" "$DIM" "$RESET" "$DIM$RED" "$RESET"
printf "%s│%s              %sOfficial tool for .s9pk development%s              %s│%s\n" "$DIM$RED" "$RESET" "$DIM" "$RESET" "$DIM$RED" "$RESET"
printf "%s│%s                                                               %s│%s\n" "$DIM$RED" "$RESET" "$DIM$RED" "$RESET"
printf "%s└───────────────────────────────────────────────────────────────┘%s\n" "$DIM$RED" "$RESET"
printf "\n"

# Helper functions
err() {
    printf "%sError:%s %s\n" "$RED$BOLD" "$RESET" "$1" >&2
    exit 1
}

# Dependency checks
for cmd in curl tar; do
    command -v "$cmd" >/dev/null 2>&1 || err "Required command '$cmd' is not installed."
done
command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1 || err "Required command 'sha256sum' or 'shasum' is not installed."

# Detect platform
OS=$(uname -s)
ARCH=$(uname -m)

# Map to start-cli's naming convention
case "$OS" in
    Darwin) 
        OS_NAME="apple-darwin"
        DISPLAY_OS="macOS"
        ;;
    Linux) 
        OS_NAME="unknown-linux-musl"
        DISPLAY_OS="Linux"
        ;;
    *)
        err "Unsupported operating system: $OS. start-cli supports macOS and Linux only."
        ;;
esac

case "$ARCH" in
    x86_64)
        ARCH_NAME="x86_64"
        DISPLAY_ARCH="Intel/AMD64"
        ;;
    arm64|aarch64)
        ARCH_NAME="aarch64" 
        DISPLAY_ARCH="ARM64"
        ;;
    *)
        err "Unsupported architecture: $ARCH. start-cli supports x86_64 and ARM64 only."
        ;;
esac

# Fetch latest version from GitHub
printf "%s•%s Fetching latest version info from GitHub...\n" "$YELLOW" "$RESET"
LATEST_RELEASE_URL="https://api.github.com/repos/Start9Labs/start-cli/releases/latest"

VERSION=$(curl -fsSL "$LATEST_RELEASE_URL" 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$VERSION" ]; then
    err "Could not determine latest version from GitHub API."
fi
printf "%s✓%s Found version: %s%s%s\n" "$GREEN" "$RESET" "$BOLD" "$VERSION" "$RESET"

# Set download info based on fetched version
FILENAME="start-cli-${ARCH_NAME}-${OS_NAME}.tar.gz"
BINARY_NAME="start-cli-${ARCH_NAME}-${OS_NAME}"
DOWNLOAD_URL="https://github.com/Start9Labs/start-cli/releases/download/${VERSION}/${FILENAME}"
CHECKSUM_URL="https://github.com/Start9Labs/start-cli/releases/download/${VERSION}/sha256sums.txt"

# System information (dynamically aligned)
BOX_WIDTH=63  # Total width inside the borders
printf "%s┌─ System Information ──────────────────────────────────────────┐%s\n" "$DIM" "$RESET"

# Calculate platform line padding
PLATFORM_TEXT="$DISPLAY_OS ($DISPLAY_ARCH)"
PLATFORM_LABEL="  Platform: "
PLATFORM_SPACES=$((BOX_WIDTH - ${#PLATFORM_LABEL} - ${#PLATFORM_TEXT}))
printf "%s│%s%s%s%s%*s%s│%s\n" "$DIM" "$RESET" "$PLATFORM_LABEL" "$GREEN" "$PLATFORM_TEXT" "$PLATFORM_SPACES" "" "$RESET$DIM" "$RESET"

# Calculate version line padding  
VERSION_TEXT="${VERSION#v}"
VERSION_LABEL="  Version:  "
VERSION_SPACES=$((BOX_WIDTH - ${#VERSION_LABEL} - ${#VERSION_TEXT}))
printf "%s│%s%s%s%s%*s%s│%s\n" "$DIM" "$RESET" "$VERSION_LABEL" "$GREEN" "$VERSION_TEXT" "$VERSION_SPACES" "" "$RESET$DIM" "$RESET"

printf "%s└───────────────────────────────────────────────────────────────┘%s\n" "$DIM" "$RESET"

# Create directories
printf "%s•%s Creating directories...\n" "$YELLOW" "$RESET"
mkdir -p "$HOME/.local/bin"

# Use /tmp to avoid directory issues when piped from curl
TEMP_DIR="/tmp/start-cli-install-$$"
trap "rm -rf '$TEMP_DIR'" EXIT
mkdir -p "$TEMP_DIR"

# Download
printf "%s•%s Downloading from GitHub releases...\n" "$YELLOW" "$RESET"
if ! COLUMNS=65 curl --progress-bar -fL "$DOWNLOAD_URL" -o "$TEMP_DIR/$FILENAME"; then
    err "Failed to download from GitHub: $DOWNLOAD_URL"
fi
printf "%s✓%s Download completed\n" "$GREEN" "$RESET"

# Verify checksum
printf "%s•%s Verifying checksum...\n" "$YELLOW" "$RESET"
if ! curl -fsSL "$CHECKSUM_URL" -o "$TEMP_DIR/sha256sums.txt"; then
    err "Failed to download checksums file: $CHECKSUM_URL"
fi

EXPECTED_CHECKSUM=$(grep "$FILENAME" "$TEMP_DIR/sha256sums.txt" | awk '{print $1}')

if command -v sha256sum >/dev/null 2>&1; then
    ACTUAL_CHECKSUM=$(sha256sum "$TEMP_DIR/$FILENAME" | awk '{print $1}')
else # Fallback to shasum on macOS
    ACTUAL_CHECKSUM=$(shasum -a 256 "$TEMP_DIR/$FILENAME" | awk '{print $1}')
fi

if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
    err "Checksum mismatch! The downloaded file may be corrupt or tampered with."
fi
printf "%s✓%s Checksum verified\n" "$GREEN" "$RESET"

# Extract
printf "%s•%s Extracting archive...\n" "$YELLOW" "$RESET"
if ! tar -xzf "$TEMP_DIR/$FILENAME" -C "$TEMP_DIR"; then
    err "Failed to extract archive."
fi
printf "%s✓%s Archive extracted\n" "$GREEN" "$RESET"
# Locate binary
printf "%s•%s Locating binary...\n" "$YELLOW" "$RESET"
BINARY_PATH="$TEMP_DIR/$BINARY_NAME"

if [ -f "$BINARY_PATH" ]; then
    printf "%s✓%s Binary located\n" "$GREEN" "$RESET"
elif [ -f "$TEMP_DIR/start-cli" ]; then
    printf "%s✓%s Binary located\n" "$GREEN" "$RESET"
    BINARY_PATH="$TEMP_DIR/start-cli"
else
    err "Could not locate binary in the extracted archive."
fi

# Test binary (rename first to fix the bug)
TEST_BINARY="$TEMP_DIR/start-cli"
cp "$BINARY_PATH" "$TEST_BINARY"
chmod +x "$TEST_BINARY"

printf "%s•%s Testing binary...\n" "$YELLOW" "$RESET"
if "$TEST_BINARY" --version >/dev/null 2>&1; then
    VERSION_OUTPUT=$("$TEST_BINARY" --version 2>/dev/null | head -n1)
    printf "%s✓%s Binary test passed\n" "$GREEN" "$RESET"
else
    printf "%sWarning:%s Binary test failed, continuing...\n" "$YELLOW$BOLD" "$RESET"
fi

# Install
printf "%s•%s Installing to ~/.local/bin...\n" "$YELLOW" "$RESET"
cp "$TEST_BINARY" "$HOME/.local/bin/start-cli"
chmod +x "$HOME/.local/bin/start-cli"
printf "%s✓%s Installation completed\n" "$GREEN" "$RESET"

# Update shell configs
printf "%s•%s Updating shell configurations...\n" "$YELLOW" "$RESET"
PATH_UPDATE='export PATH="$HOME/.local/bin:$PATH"'
UPDATED_FILES=""

for shell_rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    if [ -f "$shell_rc" ] && ! grep -qF -- "$PATH_UPDATE" "$shell_rc" 2>/dev/null; then
        echo "$PATH_UPDATE" >> "$shell_rc"
        if [ -z "$UPDATED_FILES" ]; then
            UPDATED_FILES="$(basename "$shell_rc")"
        else
            UPDATED_FILES="$UPDATED_FILES, $(basename "$shell_rc")"
        fi
    fi
done

if [ -n "$UPDATED_FILES" ]; then
    printf "%s✓%s Added PATH to: %s%s%s\n" "$GREEN" "$RESET" "$GREEN" "$UPDATED_FILES" "$RESET"
else
    printf "%s✓%s No shell config updates needed\n" "$GREEN" "$RESET"
fi

# Get installed version
INSTALLED_VERSION="unknown"
if [ -x "$HOME/.local/bin/start-cli" ]; then
    INSTALLED_VERSION=$("$HOME/.local/bin/start-cli" --version 2>/dev/null | head -n1 || echo "unknown")
fi

# Success message (centered alignment)
printf "\n"
printf "%s┌───────────────────────────────────────────────────────────────┐%s\n" "$DIM$GREEN" "$RESET"
printf "%s│%s%20s%s%sINSTALLATION SUCCESSFUL%s%s%20s%s│%s\n" "$DIM$GREEN" "$RESET" "" "$RESET" "$GREEN" "$RESET" "$DIM$GREEN" "" "$DIM$GREEN" "$RESET"
printf "%s└───────────────────────────────────────────────────────────────┘%s\n" "$DIM$GREEN" "$RESET"
printf "\n"
printf "%sLocation:%s ~/.local/bin/start-cli\n" "$BOLD" "$RESET"
printf "%sVersion:%s  %s\n" "$BOLD" "$RESET" "$INSTALLED_VERSION"
printf "\n"

# Make available in current session
export PATH="$HOME/.local/bin:$PATH"

printf "%s•%s Making available in current session...\n" "$BLUE" "$RESET"

if command -v start-cli >/dev/null 2>&1; then
    printf "%s✓%s %sstart-cli%s is ready!\n" "$GREEN" "$RESET" "$WHITE$BOLD" "$RESET"
    printf "\n"

    # Clean command reference
    printf "%sCommon Commands:%s\n" "$BOLD" "$RESET"
    printf "%s────────────────────────────────────────────────────────────────%s\n" "$DIM" "$RESET"
    printf "  %sstart-cli init%s              Initialize developer key\n" "$GREEN" "$RESET"
    printf "  %sstart-cli auth login%s        Authanticate login to your StartOS\n" "$GREEN" "$RESET"
    printf "  %sstart-cli package list%s      List services\n" "$GREEN" "$RESET"
    printf "  %sstart-cli --help%s            Show all commands\n" "$GREEN" "$RESET"
    printf "\n"
    printf "%sDocumentation:%s https://staging.docs.start9.com\n" "$BLUE" "$RESET"
else
    printf "%sNote:%s For new terminal sessions, %sstart-cli%s will be available automatically\n" "$BLUE$BOLD" "$RESET" "$WHITE$BOLD" "$RESET"
    printf "      For this session: export PATH=\"\$HOME/.local/bin:\$PATH\"\n"
fi

printf "\n"
