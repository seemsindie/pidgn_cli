#!/bin/sh
# zzz CLI installer
#
# Usage:
#   curl -fsSL https://zzz.indielab.link/install.sh | sh
#
# Options (environment variables):
#   ZZZ_VERSION     - Install a specific version (default: latest)
#   ZZZ_INSTALL_DIR - Installation directory (default: ~/.zzz/bin)
#
# Supported platforms:
#   macOS (arm64, x86_64)
#   Linux (x86_64, aarch64)

set -eu

REPO="seemsindie/zzz_cli"
INSTALL_DIR="${ZZZ_INSTALL_DIR:-$HOME/.zzz/bin}"
BINARY_NAME="zzz"
BASE_URL="https://github.com/${REPO}/releases"

# Colors (disabled if not a terminal)
if [ -t 1 ]; then
    BOLD='\033[1m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    RED='\033[0;31m'
    RESET='\033[0m'
else
    BOLD='' GREEN='' YELLOW='' RED='' RESET=''
fi

info()  { printf "${GREEN}info${RESET}  %s\n" "$1"; }
warn()  { printf "${YELLOW}warn${RESET}  %s\n" "$1"; }
error() { printf "${RED}error${RESET} %s\n" "$1" >&2; exit 1; }

main() {
    printf "\n${BOLD}zzz CLI installer${RESET}\n\n"

    need_cmd curl
    need_cmd tar
    need_cmd uname

    detect_platform
    detect_arch
    get_version

    TARBALL="zzz-cli-${VERSION}-${ARCH}-${PLATFORM}.tar.gz"
    URL="${BASE_URL}/download/${VERSION}/${TARBALL}"

    info "Platform:     ${PLATFORM} ${ARCH}"
    info "Version:      ${VERSION}"
    info "Install path: ${INSTALL_DIR}/${BINARY_NAME}"
    printf "\n"

    TMPDIR=$(mktemp -d)
    trap 'rm -rf "${TMPDIR}"' EXIT

    info "Downloading ${TARBALL}..."
    http_code=$(curl -fsSL -w "%{http_code}" -o "${TMPDIR}/${TARBALL}" "${URL}" 2>/dev/null) || true

    if [ ! -f "${TMPDIR}/${TARBALL}" ] || [ "${http_code}" != "200" ]; then
        error "Download failed (HTTP ${http_code}). Check that version ${VERSION} exists at:\n       ${URL}"
    fi

    info "Extracting..."
    tar -xzf "${TMPDIR}/${TARBALL}" -C "${TMPDIR}"

    mkdir -p "${INSTALL_DIR}"
    mv "${TMPDIR}/${BINARY_NAME}" "${INSTALL_DIR}/${BINARY_NAME}"
    chmod +x "${INSTALL_DIR}/${BINARY_NAME}"

    printf "\n${GREEN}${BOLD}zzz CLI ${VERSION} installed successfully!${RESET}\n\n"

    # Check if INSTALL_DIR is in PATH
    case ":${PATH}:" in
        *":${INSTALL_DIR}:"*) ;;
        *)
            detect_shell_profile
            warn "${INSTALL_DIR} is not in your PATH."
            printf "\n  Add it by running:\n\n"
            printf "    echo 'export PATH=\"${INSTALL_DIR}:\$PATH\"' >> ${SHELL_PROFILE}\n"
            printf "    source ${SHELL_PROFILE}\n\n"
            ;;
    esac

    info "Run 'zzz version' to verify."
    printf "\n"
}

detect_platform() {
    OS=$(uname -s)
    case "${OS}" in
        Linux)  PLATFORM="linux" ;;
        Darwin) PLATFORM="macos" ;;
        *)      error "Unsupported OS: ${OS}. Only Linux and macOS are supported." ;;
    esac
}

detect_arch() {
    MACHINE=$(uname -m)
    case "${MACHINE}" in
        x86_64|amd64)  ARCH="x86_64" ;;
        aarch64|arm64) ARCH="aarch64" ;;
        *)             error "Unsupported architecture: ${MACHINE}. Only x86_64 and aarch64 are supported." ;;
    esac
}

get_version() {
    if [ -n "${ZZZ_VERSION:-}" ]; then
        VERSION="${ZZZ_VERSION}"
        return
    fi

    info "Fetching latest version..."
    VERSION=$(curl -fsSL -H "Accept: application/json" "${BASE_URL}/latest" 2>/dev/null \
        | sed -n 's/.*"tag_name" *: *"\([^"]*\)".*/\1/p') || true

    if [ -z "${VERSION}" ]; then
        error "Could not determine latest version. Set ZZZ_VERSION manually:\n       ZZZ_VERSION=v0.1.0 curl -fsSL https://zzz.indielab.link/install.sh | sh"
    fi
}

detect_shell_profile() {
    CURRENT_SHELL=$(basename "${SHELL:-sh}")
    case "${CURRENT_SHELL}" in
        zsh)  SHELL_PROFILE="~/.zshrc" ;;
        bash)
            if [ -f "$HOME/.bash_profile" ]; then
                SHELL_PROFILE="~/.bash_profile"
            else
                SHELL_PROFILE="~/.bashrc"
            fi
            ;;
        fish) SHELL_PROFILE="~/.config/fish/config.fish" ;;
        *)    SHELL_PROFILE="~/.profile" ;;
    esac
}

need_cmd() {
    if ! command -v "$1" > /dev/null 2>&1; then
        error "Required command '$1' not found. Please install it and try again."
    fi
}

main
