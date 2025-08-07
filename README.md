# Nix Configuration

A cross-platform Nix flake configuration for both macOS and Linux systems. This repository provides a unified development environment with consistent tooling across platforms.

## ✨ Features

- **Cross-platform**: Works on both macOS (via nix-darwin) and Linux (via Home Manager)
- **Automated installation**: One-liner bootstrap script
- **Rich toolset**: Includes development tools, shell configuration, and productivity apps
- **macOS integration**: Native app management via Homebrew and Mac App Store

## 🚀 Quick Start

Run this command on a fresh macOS or Linux machine:

```bash
sh <(curl -sL https://raw.githubusercontent.com/lariskovski/nix/main/bootstrap.sh)
```

## 🛠️ How It Works

### macOS
- Installs Nix package manager
- Sets up nix-darwin for system-level configuration
- Configures Homebrew integration
- Installs apps via Mac App Store using `mas`

### Linux
- Installs Nix package manager
- Uses Home Manager for user-level configuration
- Manages dotfiles and user packages

## 🔧 Manual Usage

If you prefer to run commands manually:

### Prerequisites
1. Install Nix (if not already installed):
   ```bash
   # macOS
   sh <(curl -L https://nixos.org/nix/install) --no-daemon
   
   # Linux
   sh <(curl -L https://nixos.org/nix/install) --daemon
   ```

2. Enable flakes (add to `~/.config/nix/nix.conf`):
   ```
   experimental-features = nix-command flakes
   ```

### Apply Configuration

#### macOS (nix-darwin)
```bash
nix run nix-darwin -- switch --flake github:lariskovski/nix
```

#### Linux (Home Manager)
```bash
nix run home-manager/release-25.05 -- switch --flake github:lariskovski/nix#homeConfigurations.larissa
```

## Good Resources

https://github.com/thexyno/nixos-config

https://evantravers.com/articles/2024/02/06/switching-to-nix-darwin-and-flakes/

https://github.com/ryantm/agenix

https://sekun.net/blog/manage-secrets-in-nixos/

