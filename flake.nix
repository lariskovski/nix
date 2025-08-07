{
  description = "Cross-platform Nix flake for macOS (nix-darwin) and Linux (Home Manager)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin"; # good for both mac & linux
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    mac-app-util.url = "github:hraban/mac-app-util";

    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      nix-darwin,
      nix-homebrew,
      mac-app-util,
      ...
    }:
    let
      system = builtins.currentSystem;
      username = "larissa";
      sharedHomeManagerModules = [
        (
          { pkgs, ... }:
          {
            nixpkgs.config.allowUnfree = true;

            # Common packages for both macOS and Linux
            home.packages = with pkgs; [
              alacritty
              tmux
              vim
              nixfmt-rfc-style
              atuin
              direnv
              zsh
              zsh-autosuggestions
              zsh-completions
              zsh-powerlevel10k
              zsh-syntax-highlighting
              oh-my-zsh
              git
              gh
              go
              vscode
              awscli2
              google-cloud-sdk
              kubectl
              kubectx
              terraform
              ngrok
            ];

            programs.git = {
              enable = true;
              extraConfig = {
                user.name = "lariskovski";
                user.email = "larissaporto@live.com";
                init.defaultBranch = "main";
              };
            };

            programs.zsh = {
              enable = true;
              enableCompletion = true;
              oh-my-zsh = {
                enable = true;
                # plugins = [ "git" ];
              };
              initExtra =
                let
                  p10k = builtins.readFile ./.p10k.zsh;
                  sources = [
                    "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme"
                    "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
                    "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
                  ];
                  source = map (x: "source ${x}") sources;
                in
                ''
                  # Set editor environment variables
                  export EDITOR=vim
                  export VISUAL=vim

                  . "$HOME/.atuin/bin/env"
                  eval "$(atuin init zsh)"

                  # Add completions to fpath
                  fpath+=${pkgs.zsh-completions}/share/zsh-completions
                  ${p10k}
                  ${builtins.concatStringsSep "\n" source}
                '';
            };

            home.stateVersion = "25.05";
          }
        )
      ];
    in
    {
      # macOS system config
      darwinConfigurations."The-Unreliable-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        modules = [
          (
            { pkgs, ... }:
            {
              nix.settings.experimental-features = "nix-command flakes";
              nixpkgs.config.allowUnfree = true;

              environment.systemPackages = with pkgs; [
                mkalias
                # iterm2
                maccy
                stats
                spotify
                rectangle
                # slack
              ];

              fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

              users.users.${username} = {
                name = username;
                home = "/Users/${username}";
              };

              system.primaryUser = username;
              system.stateVersion = 6;

              system.defaults = {
                dock.autohide = true;
                dock.orientation = "bottom";
                dock.persistent-apps = [
                  "/System/Applications/Mail.app"
                  "${pkgs.vscode}/Applications/Visual Studio Code.app"
                  # "${pkgs.iterm2}/Applications/iTerm2.app"
                  "${pkgs.alacritty}/Applications/Alacritty.app"
                  "${pkgs.spotify}/Applications/Spotify.app"
                  "/Applications/WhatsApp.app"
                ];
                NSGlobalDomain.AppleInterfaceStyle = "Dark";
                NSGlobalDomain.AppleShowScrollBars = "Always";
              };

              homebrew = {
                enable = true;
                brews = [ "mas" ];
                casks = [
                  "orbstack"
                ];
                masApps = {
                  "WhatsApp" = 310633997;
                };
                onActivation = {
                  cleanup = "zap";
                  autoUpdate = true;
                  upgrade = true;
                };
              };

              system.configurationRevision = self.rev or self.dirtyRev or null;
            }
          )

          home-manager.darwinModules.home-manager
          mac-app-util.darwinModules.default
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              user = username;
            };
          }

          {
            home-manager.users.${username} = {
              imports = sharedHomeManagerModules;
            };
          }
        ];
      };

      # Linux Home Manager only (no system)
      homeConfigurations.larissa = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        modules = sharedHomeManagerModules ++ [
          {
            home.username = username;
            home.homeDirectory = "/home/${username}";
          }
        ];
      };
    };
}
