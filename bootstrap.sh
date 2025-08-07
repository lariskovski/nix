#!/usr/bin/env bash

# Check if we're running in bash
if [ -z "$BASH_VERSION" ]; then
  echo "This script requires bash. Please run with bash:"
  echo "bash <(curl -sL https://raw.githubusercontent.com/lariskovski/nix/main/bootstrap.sh)"
  exit 1
fi

set -euo pipefail

# === CONFIGURATION ===
REPO_URL="github:lariskovski/nix"
USERNAME="larissa"
HOSTNAME="$(hostname)"
OS="$(uname -s)"

# === FUNCTIONS ===

install_dependencies() {
  echo "📋 Installing required dependencies..."
  
  if [[ "$OS" == "Darwin" ]]; then
    # Check if xz is installed
    if ! command -v xz &>/dev/null; then
      echo "Installing xz..."
      if command -v brew &>/dev/null; then
        brew install xz
      else
        echo "❌ Homebrew not found. Please install xz manually or install Homebrew first:"
        echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        echo "   brew install xz"
        exit 1
      fi
    fi
  elif [[ "$OS" == "Linux" ]]; then
    # Check if xz is installed
    if ! command -v xz &>/dev/null; then
      echo "Installing xz..."
      if command -v apt-get &>/dev/null; then
        sudo apt-get update && sudo apt-get install -y xz-utils
      elif command -v yum &>/dev/null; then
        sudo yum install -y xz
      elif command -v dnf &>/dev/null; then
        sudo dnf install -y xz
      elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm xz
      else
        echo "❌ Could not determine package manager. Please install xz manually."
        exit 1
      fi
    fi
  fi
  
  echo "✅ Dependencies installed."
}

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

  # Ensure Nix is configured for flakes and nix-command
  if [ ! -d "/etc/nix" ]; then
    echo "Creating /etc/nix directory..."
    sudo mkdir -p /etc/nix
  fi  
  # Add experimental features to nix.conf
  if [ ! -f "/etc/nix/nix.conf" ]; then
    echo "Creating /etc/nix/nix.conf..."
    sudo touch /etc/nix/nix.conf
  fi
  # Add experimental features to nix.conf
  echo "Adding experimental features to /etc/nix/nix.conf..."
  echo "experimental-features = nix-command flakes" | sudo tee /etc/nix/nix.conf

  echo "✅ Nix installed."
}

bootstrap_linux() {
  echo "🐧 Setting up Linux Home Manager configuration..."
  nix --extra-experimental-features "nix-command flakes" run home-manager/release-25.05 -- switch --flake ${REPO_URL}#${USERNAME} --no-write-lock-file
}

bootstrap_macos() {
  echo "🍎 Setting up macOS nix-darwin configuration..."

  echo "➡️ Building nix-darwin system..."
  echo "⚠️  Note: You may be prompted for your password for system activation..."
  sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake ${REPO_URL} --no-write-lock-file
}

# === MAIN ===

main() {
  # Check if running as root
  if [[ $EUID -eq 0 ]]; then
    echo "❌ This script should NOT be run as root/sudo!"
    echo "💡 Run it as a regular user: bash <(curl -sL https://raw.githubusercontent.com/lariskovski/nix/main/bootstrap.sh)"
    echo "ℹ️  The script will use sudo internally when needed for system activation."
    exit 1
  fi

  echo "🚀 Bootstrapping system for $OS ($USERNAME@$HOSTNAME)"
  
  # Install dependencies first
  install_dependencies
  
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
