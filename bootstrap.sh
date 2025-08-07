#!/usr/bin/env bash

set -euo pipefail

# === CONFIGURATION ===
REPO_URL="github:lariskovski/nix"
USERNAME="larissa"
HOSTNAME="$(hostname)"
OS="$(uname -s)"

# === FUNCTIONS ===

install_nix() {
  echo "📦 Installing Nix..."
  if [[ "$OS" == "Darwin" ]]; then
    sh <(curl -L https://nixos.org/nix/install) --no-daemon
  elif [[ "$OS" == "Linux" ]]; then
    sh <(curl -L https://nixos.org/nix/install) --daemon
  else
    echo "Unsupported OS: $OS"
    exit 1
  fi

  # shell hooks (Linux/macOS)
  if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  elif [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
    . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
  fi

  echo "✅ Nix installed."
}

bootstrap_linux() {
  echo "🐧 Setting up Linux Home Manager configuration..."
  nix run home-manager/release-25.05 --extra-experimental-features "nix-command flakes" -- switch --flake ${REPO_URL}#homeConfigurations.${USERNAME} --no-write-lock-file
}

bootstrap_macos() {
  echo "🍎 Setting up macOS nix-darwin configuration..."

  echo "➡️ Building nix-darwin system..."
  echo "⚠️  Note: You may be prompted for your password for system activation..."
  sudo nix run nix-darwin --extra-experimental-features "nix-command flakes" -- switch --flake ${REPO_URL} --no-write-lock-file
}

# === MAIN ===

main() {
  # Check if running as root
  if [[ $EUID -eq 0 ]]; then
    echo "❌ This script should NOT be run as root/sudo!"
    echo "💡 Run it as a regular user: sh <(curl -sL https://raw.githubusercontent.com/lariskovski/nix/main/bootstrap.sh)"
    echo "ℹ️  The script will use sudo internally when needed for system activation."
    exit 1
  fi

  echo "🚀 Bootstrapping system for $OS ($USERNAME@$HOSTNAME)"
  # Verifica se o Nix está instalado
  if ! command -v nix &>/dev/null; then
    install_nix
  else
    echo "Nix already installed."
  fi

  if [ "$OS" = "Linux" ]; then
    bootstrap_linux
  elif [ "$OS" = "Darwin" ]; then
    bootstrap_macos
  else
    echo "❌ Unsupported OS: $OS"
    exit 1
  fi

  echo "🎉 Bootstrap completed!"
}

main
