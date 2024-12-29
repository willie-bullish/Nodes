#!/data/data/com.termux/files/usr/bin/bash

# Color and formatting definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
RESET='\033[0m'

# Icons for menu options
ICON_INSTALL="🛠️"
ICON_LOGS="📄"
ICON_STOP="⏹️"
ICON_START="▶️"
ICON_WALLET="💰"
ICON_UPDATE="🔄"
ICON_RESTART="♻️"
ICON_EXIT="❌"

# Functions to draw borders and display menu
draw_top_border() {
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${RESET}"
}

draw_middle_border() {
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════╣${RESET}"
}

draw_bottom_border() {
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${RESET}"
}

display_ascii() {
    echo -e "    ${RED}  __           __  _   _       _       _   _____ ${RESET}"
    echo -e "    ${GREEN}  \ \         / / | | | |     | |     | | | |___|  ${RESET}"
    echo -e "    ${BLUE}   \ \   _   / /  | | | |     | |     | | | |=  ${RESET}"
    echo -e "    ${YELLOW}    \ \ /_\ / /   | | |_|___  |_|___  | | |_|___ ${RESET}"
    echo -e "    ${MAGENTA}     \_______/    |_| |_____| |_____| |_| |_____|  ${RESET}"
}

show() {
    echo -e "\033[1;35m$1\033[0m"
}

# Function to check and install jq if not present
install_jq() {
    if ! command -v jq &> /dev/null; then
        show "jq not found, installing..."
        pkg update && pkg install -y jq
        if [ $? -ne 0 ]; then
            show "Failed to install jq. Please check your package manager."
            exit 1
        fi
    fi
}

# Function to check the latest version from GitHub
check_latest_version() {
    for i in {1..3}; do
        LATEST_VERSION=$(curl -s https://api.github.com/repos/hemilabs/heminetwork/releases/latest | jq -r '.tag_name')
        if [ -n "$LATEST_VERSION" ]; then
            show "Latest version available: $LATEST_VERSION"
            return 0
        fi
        show "Attempt $i: Failed to fetch the latest version. Retrying..."
        sleep 2
    done

    show "Failed to fetch the latest version after 3 attempts. Please check your internet connection or GitHub API limits."
    exit 1
}

# Function to install or update the node
install_update_node() {
    echo -e "${GREEN}🛠️  Installing or Updating Node...${RESET}"
    
    install_jq
    check_latest_version

    ARCH=$(uname -m)
    download_required=true

    if [ "$ARCH" == "aarch64" ]; then
        if [ -d "heminetwork_${LATEST_VERSION}_linux_arm64" ]; then
            show "Latest version for ARM64 is already downloaded. Skipping download."
            cd "heminetwork_${LATEST_VERSION}_linux_arm64" || { show "Failed to change directory."; exit 1; }
            download_required=false
        fi
    else
        show "Unsupported architecture: $ARCH"
        exit 1
    fi

    if [ "$download_required" = true ]; then
        show "Downloading for ARM64 architecture..."
        wget --quiet --show-progress "https://github.com/hemilabs/heminetwork/releases/download/$LATEST_VERSION/heminetwork_${LATEST_VERSION}_linux_arm64.tar.gz" -O "heminetwork_${LATEST_VERSION}_linux_arm64.tar.gz"
        tar -xzf "heminetwork_${LATEST_VERSION}_linux_arm64.tar.gz" > /dev/null
        cd "heminetwork_${LATEST_VERSION}_linux_arm64" || { show "Failed to change directory."; exit 1; }
    fi

    echo
    show "Select only one option:"
    show "1. Use new wallet for PoP mining"
    show "2. Use existing wallet for PoP mining"
    read -p "Enter your choice (1/2): " wallet_choice
    echo

    if [ "$wallet_choice" == "1" ]; then
        show "Generating a new wallet..."
        ./keygen -secp256k1 -json -net="testnet" > ~/popm-address.json
        if [ $? -ne 0 ]; then
            show "Failed to generate wallet."
            exit 1
        fi
        cat ~/popm-address.json
        echo
        read -p "Have you saved the above details? (y/N): " saved
        if [[ "$saved" =~ ^[Yy]$ ]]; then
            pubkey_hash=$(jq -r '.pubkey_hash' ~/popm-address.json)
            show "Join: https://discord.gg/hemixyz"
            show "Request faucet from faucet channel to this address: $pubkey_hash"
        else
            show "Details not saved. Exiting."
            exit 1
        fi
    elif [ "$wallet_choice" == "2" ]; then
        read -p "Enter your Private key: " priv_key
        echo
    else
        show "Invalid choice for wallet option."
        exit 1
    fi

    echo
    show "Node setup complete. PoP mining is ready!"
    echo
    read -p "Press Enter to return to the main menu..."
}

# Main menu loop
while true; do
    show_menu() {
        clear
        draw_top_border
        echo -e "Welcome to the Hemi Network Node Management"
        draw_middle_border
        echo -e "${YELLOW}Please choose an option:${RESET}"
        echo -e "1. Install/Update Node"
        echo -e "0. Exit"
        draw_bottom_border
        echo -ne "${YELLOW}Enter your choice [0-1]:${RESET} "
        read choice
    }

    show_menu

    case $choice in
        1) install_update_node ;;
        0) echo -e "${GREEN}❌ Exiting...${RESET}"; exit 0 ;;
        *) echo -e "${RED}❌ Invalid option. Please try again.${RESET}"; sleep 2 ;;
    esac
done
