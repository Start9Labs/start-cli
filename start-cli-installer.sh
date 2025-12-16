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

# Prepare installation directory and tempdir
INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"
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

# Locate binary and test
BINARY_PATH="$TEMP_DIR/$BINARY_NAME"
[ -f "$BINARY_PATH" ] || BINARY_PATH="$TEMP_DIR/start-cli"
[ -f "$BINARY_PATH" ] || err "Could not locate binary in the extracted archive."

# Test binary
TEST_BINARY="$TEMP_DIR/start-cli"
cp "$BINARY_PATH" "$TEST_BINARY"
chmod +x "$TEST_BINARY"

printf "%s•%s Testing binary...\n" "$YELLOW" "$RESET"
if "$TEST_BINARY" --version >/dev/null 2>&1; then
    printf "%s✓%s Binary test passed\n" "$GREEN" "$RESET"
else
    printf "%sWarning:%s Binary test failed, continuing...\n" "$YELLOW$BOLD" "$RESET"
fi

# Install/version-aware logic
# Use: start-cli-X.Y.Z (short version) and always update the main symlink
VERSION_SHORT=$(echo "${VERSION#v}" | cut -d- -f1)
CLI_VERSIONED="start-cli-${VERSION_SHORT}"
CLI_FINAL_VERSIONED="$INSTALL_DIR/$CLI_VERSIONED"
CLI_SYMLINK="$INSTALL_DIR/start-cli"

printf "%s•%s Installing as %s ...\n" "$YELLOW" "$RESET" "$CLI_VERSIONED"
cp "$TEST_BINARY" "$CLI_FINAL_VERSIONED"
chmod +x "$CLI_FINAL_VERSIONED"

if [ -L "$CLI_SYMLINK" ]; then
    ln -sf "$CLI_VERSIONED" "$CLI_SYMLINK"
    printf "%s✓%s Updated symlink: start-cli -> %s\n" "$GREEN" "$RESET" "$CLI_VERSIONED"
elif [ -e "$CLI_SYMLINK" ]; then
    printf "%s!%s Found regular file as start-cli, moving to .start-cli.bak\n" "$YELLOW" "$RESET"
    mv "$CLI_SYMLINK" "$INSTALL_DIR/.start-cli.bak"
    ln -sf "$CLI_VERSIONED" "$CLI_SYMLINK"
    printf "%s✓%s Created symlink: start-cli -> %s\n" "$GREEN" "$RESET" "$CLI_VERSIONED"
else
    ln -sf "$CLI_VERSIONED" "$CLI_SYMLINK"
    printf "%s✓%s Created symlink: start-cli -> %s\n" "$GREEN" "$RESET" "$CLI_VERSIONED"
fi
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
# Add .local/bin to PATH for this session if needed
case ":$PATH:" in *:"$HOME/.local/bin:"*) : ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac

# Check for startbox and offer version switching functionality
printf "\n%s•%s Checking for version switching setup...\n" "$YELLOW" "$RESET"

# Check if startbox already exists in ~/.local/bin
if [ -f "$INSTALL_DIR/startbox" ]; then
    printf "%s✓%s startbox already in ~/.local/bin - proceeding with installation\n" "$DIM" "$RESET"
elif command -v startbox >/dev/null 2>&1; then
    # startbox exists in system but not in ~/.local/bin
    printf "%s✓%s startbox found in system\n" "$GREEN" "$RESET"
    
    # Check if switch-start-cli alias already exists
    ALIAS_EXISTS=false
    if command -v switch-start-cli >/dev/null 2>&1 || alias switch-start-cli 2>/dev/null; then
        ALIAS_EXISTS=true
    fi
    
    # Also check in shell config files
    for shell_rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.bash_profile" "$HOME/.profile"; do
        if [ -f "$shell_rc" ] && grep -q "switch-start-cli" "$shell_rc" 2>/dev/null; then
            ALIAS_EXISTS=true
            break
        fi
    done
    
    if [ "$ALIAS_EXISTS" = true ]; then
        printf "%s✓%s switch-start-cli alias already configured - proceeding normally\n" "$DIM" "$RESET"
    else
        # Neither startbox in ~/.local/bin nor switch-start-cli alias exists
        # Offer to set up version switching
        
        # Copy startbox to ~/.local/bin
        printf "%s•%s Preparing version switching capability...\n" "$YELLOW" "$RESET"
        if cp "$(command -v startbox)" "$INSTALL_DIR/startbox" 2>/dev/null; then
            chmod +x "$INSTALL_DIR/startbox"
            printf "%s✓%s startbox copied to ~/.local/bin\n" "$GREEN" "$RESET"
            
            # Offer to integrate switch-start-cli alias
            printf "\n"
            printf "%s┌─ Version Switching Setup ─────────────────────────────────────┐%s\n" "$DIM$BLUE" "$RESET"
            printf "%s│%s                                                               %s│%s\n" "$DIM$BLUE" "$RESET" "$DIM$BLUE" "$RESET"
            printf "%s│%s  Would you like to set up the %sswitch-start-cli%s alias?         %s│%s\n" "$DIM$BLUE" "$RESET" "$WHITE$BOLD" "$RESET" "$DIM$BLUE" "$RESET"
            printf "%s│%s  This allows easy switching between start-cli and startbox.   %s│%s\n" "$DIM$BLUE" "$RESET" "$DIM$BLUE" "$RESET"
            printf "%s│%s                                                               %s│%s\n" "$DIM$BLUE" "$RESET" "$DIM$BLUE" "$RESET"
            printf "%s└───────────────────────────────────────────────────────────────┘%s\n" "$DIM$BLUE" "$RESET"
            printf "\n"
            printf "  %sIntegrate version switching? [y/N]:%s " "$BOLD" "$RESET"
            
            # Read user input
            read -r SWITCH_RESPONSE < /dev/tty
            
            case "$SWITCH_RESPONSE" in
                [yY]|[yY][tT][eE][sS])
                    printf "\n%s•%s Setting up version switching alias...\n" "$YELLOW" "$RESET"
                    
                    # The alias to add - now using startbox
                    SWITCH_ALIAS='alias switch-start-cli='"'"'(cd ~/.local/bin || exit; if [ -L start-cli ] && [ "$(readlink start-cli)" = "startbox" ]; then target=$(ls start-cli-* 2>/dev/null | head -1); [ -z "$target" ] && { echo "No versioned start-cli found"; exit 1; }; ln -sf "$target" start-cli; echo "✅ Switched to start-cli ($(./start-cli --version 2>/dev/null | awk "{print \$NF}"))"; else ln -sf startbox start-cli; echo "✅ Switched to start-cli ($(./start-cli --version 2>/dev/null | awk "{print \$NF}"))"; fi)'"'"
                    
                    ALIAS_UPDATED_COUNT=0
                    
                    # Update shell configs with the alias
                    for shell_rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.bash_profile" "$HOME/.profile"; do
                        if [ -f "$shell_rc" ]; then
                            # Double-check if alias already exists in file
                            if ! grep -q "switch-start-cli" "$shell_rc" 2>/dev/null; then
                                echo "" >> "$shell_rc"
                                echo "# start-cli version switching" >> "$shell_rc"
                                echo "$SWITCH_ALIAS" >> "$shell_rc"
                                ALIAS_UPDATED_COUNT=$((ALIAS_UPDATED_COUNT + 1))
                            fi
                        fi
                    done
                    
                    if [ $ALIAS_UPDATED_COUNT -gt 0 ]; then
                        printf "%s✓%s Version switching alias added to shell configs\n" "$GREEN" "$RESET"
                        printf "%s✓%s Current state: start-cli -> %s\n" "$GREEN" "$RESET" "$CLI_VERSIONED"
                        printf "\n"
                        printf "%sUsage:%s Run %sswitch-start-cli%s to toggle between versions\n" "$BOLD" "$RESET" "$GREEN" "$RESET"
                        printf "       Available after restarting your shell or running:\n"
                        printf "       %ssource ~/$(basename "$PROFILE_FILE")%s\n" "$DIM" "$RESET"
                    else
                        printf "%s✓%s Alias already configured in shell files\n" "$GREEN" "$RESET"
                    fi
                    ;;
                *)
                    printf "%s•%s Skipping version switching setup\n" "$DIM" "$RESET"
                    ;;
            esac
        else
            printf "%sWarning:%s Could not copy startbox - proceeding without version switching\n" "$YELLOW$BOLD" "$RESET"
        fi
    fi
else
    printf "%s•%s startbox not found - proceeding with standard installation\n" "$DIM" "$RESET"
fi

# Success message and commands
INSTALLED_VERSION="unknown"
[ -x "$CLI_SYMLINK" ] && INSTALLED_VERSION=$("$CLI_SYMLINK" --version 2>/dev/null | head -n1 || echo "unknown")

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
printf "  %sstart-cli init-key%s          Initialize developer key\n" "$GREEN" "$RESET"
printf "  %sstart-cli auth login%s        Authenticate login to your StartOS\n" "$GREEN" "$RESET"
printf "  %sstart-cli package list%s      List services\n" "$GREEN" "$RESET"
printf "  %sstart-cli --help%s            Show all commands\n" "$GREEN" "$RESET"
printf "\n"
printf "%sDocumentation:%s https://staging.docs.start9.com\n" "$BLUE" "$RESET"

# Print reload advice last if needed
if [ "$PATH_UPDATE_NEEDED" = true ]; then
  SRC_FILE="$(basename "$PROFILE_FILE")"
  printf "\n%sTo use start-cli immediately, run:%s\n" "$BLUE$BOLD" "$RESET"
  printf "   source ~/%s\n" "$SRC_FILE"
  printf "%sOr open a new terminal.%s\n" "$BLUE" "$RESET"
fi
printf "\n"