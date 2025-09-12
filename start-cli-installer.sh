#!/bin/sh
# start-cli installer for StartOS development
# Downloads and installs start-cli from official GitHub releases

set -e
set -u

# Color scheme
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

# ASCII Header
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

err() { printf "%sError:%s %s\n" "$RED$BOLD" "$RESET" "$1" >&2; exit 1; }

# Dependency checks
for cmd in curl tar; do
    command -v "$cmd" >/dev/null 2>&1 || err "Required command '$cmd' is not installed."
done

SHA_CMD=""
if command -v sha256sum >/dev/null 2>&1; then
    SHA_CMD="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
    SHA_CMD="shasum -a 256"
else
    err "Required command 'sha256sum' or 'shasum' is not installed."
fi

# Detect platform
OS=$(uname -s)
ARCH=$(uname -m)

case "$OS" in
    Darwin)  OS_NAME="apple-darwin"; DISPLAY_OS="macOS" ;;
    Linux)   OS_NAME="unknown-linux-musl"; DISPLAY_OS="Linux" ;;
    *)       err "Unsupported operating system: $OS. start-cli supports macOS and Linux only." ;;
esac

case "$ARCH" in
    x86_64)       ARCH_NAME="x86_64";   DISPLAY_ARCH="Intel/AMD64" ;;
    arm64|aarch64) ARCH_NAME="aarch64"; DISPLAY_ARCH="ARM64" ;;
    *)             err "Unsupported architecture: $ARCH. start-cli supports x86_64 and ARM64 only." ;;
esac

# Fetch latest version
printf "%s•%s Fetching latest version info from GitHub...\n" "$YELLOW" "$RESET"
LATEST_RELEASE_URL="https://api.github.com/repos/Start9Labs/start-cli/releases/latest"
VERSION=$(curl -fsSL "$LATEST_RELEASE_URL" 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z "$VERSION" ]; then
    err "Could not determine latest version from GitHub API."
fi
printf "%s✓%s Found version: %s%s%s\n" "$GREEN" "$RESET" "$BOLD" "$VERSION" "$RESET"

FILENAME="start-cli-${ARCH_NAME}-${OS_NAME}.tar.gz"
BINARY_NAME="start-cli-${ARCH_NAME}-${OS_NAME}"
DOWNLOAD_URL="https://github.com/Start9Labs/start-cli/releases/download/${VERSION}/${FILENAME}"
CHECKSUM_URL="https://github.com/Start9Labs/start-cli/releases/download/${VERSION}/sha256sums.txt"

# System display
BOX_WIDTH=63
PLATFORM_TEXT="$DISPLAY_OS ($DISPLAY_ARCH)"
PLATFORM_LABEL="  Platform: "
PLATFORM_SPACES=$((BOX_WIDTH - ${#PLATFORM_LABEL} - ${#PLATFORM_TEXT}))
printf "%s┌─ System Information ──────────────────────────────────────────┐%s\n" "$DIM" "$RESET"
printf "%s│%s%s%s%s%*s%s│%s\n" "$DIM" "$RESET" "$PLATFORM_LABEL" "$GREEN" "$PLATFORM_TEXT" "$PLATFORM_SPACES" "" "$RESET$DIM" "$RESET"
VERSION_TEXT="${VERSION#v}"
VERSION_LABEL="  Version:  "
VERSION_SPACES=$((BOX_WIDTH - ${#VERSION_LABEL} - ${#VERSION_TEXT}))
printf "%s│%s%s%s%s%*s%s│%s\n" "$DIM" "$RESET" "$VERSION_LABEL" "$GREEN" "$VERSION_TEXT" "$VERSION_SPACES" "" "$RESET$DIM" "$RESET"
printf "%s└───────────────────────────────────────────────────────────────┘%s\n" "$DIM" "$RESET"

# Create directories and temp
printf "%s•%s Creating directories...\n" "$YELLOW" "$RESET"
mkdir -p "$HOME/.local/bin"
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
curl -fsSL "$CHECKSUM_URL" -o "$TEMP_DIR/sha256sums.txt" || err "Failed to download checksums file: $CHECKSUM_URL"
EXPECTED_CHECKSUM=$(grep "$FILENAME" "$TEMP_DIR/sha256sums.txt" | awk '{print $1}')
ACTUAL_CHECKSUM=$($SHA_CMD "$TEMP_DIR/$FILENAME" | awk '{print $1}')
[ "$EXPECTED_CHECKSUM" = "$ACTUAL_CHECKSUM" ] || err "Checksum mismatch! Downloaded file may be corrupted."
printf "%s✓%s Checksum verified\n" "$GREEN" "$RESET"

# Extract
printf "%s•%s Extracting archive...\n" "$YELLOW" "$RESET"
tar -xzf "$TEMP_DIR/$FILENAME" -C "$TEMP_DIR" || err "Failed to extract archive."
printf "%s✓%s Archive extracted\n" "$GREEN" "$RESET"
# Locate binary
printf "%s•%s Locating binary...\n" "$YELLOW" "$RESET"
BINARY_PATH="$TEMP_DIR/$BINARY_NAME"
[ -f "$BINARY_PATH" ] || BINARY_PATH="$TEMP_DIR/start-cli"
[ -f "$BINARY_PATH" ] || err "Could not locate binary in the extracted archive."

# Test binary
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

# Update shell configuration for PATH
printf "%s•%s Updating shell configuration for PATH...\n" "$YELLOW" "$RESET"
PATH_BLOCK='
# >>> start-cli initialize >>>
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
# <<< start-cli initialize <<<
'
detect_shell=${SHELL##*/}
is_macos=false; [ "$(uname -s)" = "Darwin" ] && is_macos=true
choose_profile_file() {
  case "$detect_shell" in
    zsh)  $is_macos && echo "$HOME/.zprofile" || echo "$HOME/.zshrc" ;;
    bash) $is_macos && echo "$HOME/.bash_profile" || echo "$HOME/.bashrc" ;;
    *)    echo "$HOME/.profile" ;;
  esac
}
PROFILE_FILE="$(choose_profile_file)"
[ -f "$PROFILE_FILE" ] || touch "$PROFILE_FILE"
PATH_UPDATE_NEEDED=false
if grep -E '(^|\s)export\s+PATH="\$HOME/\.local/bin:\$PATH"' "$PROFILE_FILE" | grep -vE '^\s*#' >/dev/null || \
   grep -F 'case ":$PATH:" in' "$PROFILE_FILE" >/dev/null
then
  printf "%s✓%s Appropriate PATH already present in %s%s%s\n" "$GREEN" "$RESET" "$BOLD" "$(basename "$PROFILE_FILE")" "$RESET"
else
  printf "%s%s\n" "$PATH_BLOCK" >> "$PROFILE_FILE"
  printf "%s✓%s Added PATH block to %s%s%s\n" "$GREEN" "$RESET" "$BOLD" "$(basename "$PROFILE_FILE")" "$RESET"
  PATH_UPDATE_NEEDED=true
fi

# Update session if needed
case ":$PATH:" in
  *:"$HOME/.local/bin:"*) : ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# Success message and commands
INSTALLED_VERSION="unknown"
[ -x "$HOME/.local/bin/start-cli" ] && INSTALLED_VERSION=$("$HOME/.local/bin/start-cli" --version 2>/dev/null | head -n1 || echo "unknown")

printf "\n"
printf "%s┌───────────────────────────────────────────────────────────────┐%s\n" "$DIM$GREEN" "$RESET"
printf "%s│%s%20s%s%sINSTALLATION SUCCESSFUL%s%s%20s%s│%s\n" "$DIM$GREEN" "$RESET" "" "$RESET" "$GREEN" "$RESET" "$DIM$GREEN" "" "$DIM$GREEN" "$RESET"
printf "%s└───────────────────────────────────────────────────────────────┘%s\n" "$DIM$GREEN" "$RESET"
printf "\n"
printf "%sLocation:%s ~/.local/bin/start-cli\n" "$BOLD" "$RESET"
printf "%sVersion:%s  %s\n" "$BOLD" "$RESET" "$INSTALLED_VERSION"
printf "\n"

printf "%sCommon Commands:%s\n" "$BOLD" "$RESET"
printf "%s────────────────────────────────────────────────────────────────%s\n" "$DIM" "$RESET"
printf "  %sstart-cli init%s              Initialize developer key\n" "$GREEN" "$RESET"
printf "  %sstart-cli auth login%s        Authenticate login to your StartOS\n" "$GREEN" "$RESET"
printf "  %sstart-cli package list%s      List services\n" "$GREEN" "$RESET"
printf "  %sstart-cli --help%s            Show all commands\n" "$GREEN" "$RESET"
printf "\n"
printf "%sDocumentation:%s https://staging.docs.start9.com\n" "$BLUE" "$RESET"

# Final reload info
if [ "$PATH_UPDATE_NEEDED" = true ]; then
  SRC_FILE="$(basename "$PROFILE_FILE")"
  printf "\n%sTo use start-cli immediately, run:%s\n" "$BLUE$BOLD" "$RESET"
  printf "   source ~/%s\n" "$SRC_FILE"
  printf "%sOr open a new terminal.%s\n" "$BLUE" "$RESET"
fi
printf "\n"