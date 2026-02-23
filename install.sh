#!/usr/bin/env bash
#===============================================================================
# N0DM Installer - One-line installation for Arch Linux
# Usage: curl -fsSL https://raw.githubusercontent.com/noeltz/n0dm/main/install.sh | bash
#===============================================================================
set -euo pipefail

#--- Colors --------------------------------------------------------------------
readonly RESET='\033[0m' BOLD='\033[1m' RED='\033[31m' GREEN='\033[32m'
readonly YELLOW='\033[33m' BLUE='\033[34m' CYAN='\033[36m'

print_ok()    { echo -e "${GREEN}✓${RESET} $*"; }
print_err()   { echo -e "${RED}✗${RESET} $*" >&2; }
print_info()  { echo -e "${BLUE}➜${RESET} $*"; }
print_warn()  { echo -e "${YELLOW}⚠${RESET} $*" >&2; }
print_step()  { echo -e "${CYAN}▶${RESET} $*"; }

#--- Check Dependencies --------------------------------------------------------
check_dependencies() {
    print_info "Checking dependencies..."
    
    local missing=()
    
    # Check for yadm
    if ! command -v yadm &>/dev/null; then
        missing+=("yadm")
    fi
    
    # Check for git (required by yadm)
    if ! command -v git &>/dev/null; then
        missing+=("git")
    fi
    
    # Check for curl (needed for installer)
    if ! command -v curl &>/dev/null; then
        missing+=("curl")
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        print_warn "Missing dependencies: ${missing[*]}"
        
        # Check if running as root
        if [[ $EUID -eq 0 ]]; then
            print_err "Don't run this installer as root!"
            exit 1
        fi
        
        # Install missing packages
        print_info "Installing missing packages..."
        if command -v pacman &>/dev/null; then
            sudo pacman -Sy --noconfirm "${missing[@]}"
            print_ok "Dependencies installed"
        else
            print_err "pacman not found. Please install: ${missing[*]}"
            exit 1
        fi
    else
        print_ok "All dependencies satisfied"
    fi
}

#--- Install n0dm --------------------------------------------------------------
install_n0dm() {
    print_info "Installing n0dm..."
    
    # Create bin directory
    mkdir -p ~/.local/bin
    
    # Download n0dm script
    local n0dm_url="https://raw.githubusercontent.com/noeltz/n0dm/main/n0dm"
    if curl -fsSL "$n0dm_url" -o ~/.local/bin/n0dm; then
        chmod +x ~/.local/bin/n0dm
        print_ok "n0dm installed to ~/.local/bin/n0dm"
    else
        print_err "Failed to download n0dm"
        exit 1
    fi
    
    # Check if ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        print_warn "~/.local/bin is not in your PATH"
        echo
        echo "Add this to your ~/.bashrc or ~/.zshrc:"
        echo '  export PATH="$HOME/.local/bin:$PATH"'
        echo
        print_info "Current shell: Adding to PATH temporarily..."
        export PATH="$HOME/.local/bin:$PATH"
    fi
}

#--- Verify Installation -------------------------------------------------------
verify_installation() {
    print_info "Verifying installation..."
    
    if command -v n0dm &>/dev/null; then
        local version
        version=$(n0dm version 2>&1 || echo "unknown")
        print_ok "n0dm is working! ($version)"
    else
        print_err "n0dm command not found"
        print_info "Try running: export PATH=\"$HOME/.local/bin:$PATH\""
        exit 1
    fi
}

#--- Post-Install Help ---------------------------------------------------------
show_next_steps() {
    echo
    echo -e "${BOLD}🎉 Installation complete!${RESET}"
    echo
    echo -e "${BOLD}Next steps:${RESET}"
    echo "  1. Initialize your dotfiles repo:"
    echo -e "     ${CYAN}n0dm init${RESET}"
    echo
    echo "  2. Track your first file:"
    echo -e "     ${CYAN}n0dm track ~/.bashrc${RESET}"
    echo
    echo "  3. Sync to GitHub:"
    echo -e "     ${CYAN}n0dm sync \"Initial commit\"${RESET}"
    echo
    echo -e "${BOLD}Help:${RESET}"
    echo "  - Run ${CYAN}n0dm help${RESET} for all commands"
    echo "  - Visit: https://github.com/noeltz/n0dm"
    echo
}

#--- Main ----------------------------------------------------------------------
main() {
    echo -e "${BOLD}╔════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}║        n0dm Installer v1.0.0           ║${RESET}"
    echo -e "${BOLD}║  Smart Dotfiles Management for Arch    ║${RESET}"
    echo -e "${BOLD}╚════════════════════════════════════════╝${RESET}"
    echo
    
    check_dependencies
    install_n0dm
    verify_installation
    show_next_steps
}

main "$@"
