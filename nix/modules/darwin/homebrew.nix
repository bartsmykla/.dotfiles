{ pkgs, lib, ... }:

{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      # "none" = don't remove unlisted packages (safe)
      # "uninstall" = remove unlisted packages
      # "zap" = remove + delete all data (DANGEROUS)
      cleanup = "none";
    };

    # Third-party taps
    taps = [
      "bufbuild/buf"                          # Protocol buffers
      "speakeasy-api/tap"                     # API tooling
      "aquaproj/aqua"                         # Version manager
      "derailed/popeye"                       # Kubernetes linter
      "mutagen-io/mutagen"                    # File sync
      "helm/tap"                              # Helm charts
      "grafana/grafana"                       # Monitoring
    ];

    # Formulas not available in nixpkgs
    brews = [
      "derailed/popeye/popeye"                # Kubernetes cluster linter
      "mutagen-io/mutagen/mutagen"            # File sync
      "lnav"                                  # Log viewer
      "kumactl"                               # Kuma service mesh CLI
      "swiftlint"                             # Swift linter
      "vale"                                  # Prose linter
      "commitlint"                            # Commit message linter
      "check-jsonschema"                      # JSON Schema validator
      "aqua"                                  # CLI version manager
      "mise"                                  # Tool version manager
      "uv"                                    # Python package manager
      "cloudflared"                           # Cloudflare Tunnel client
      "jump"                                  # Directory bookmarking
      "gh"                                    # GitHub CLI (latest, auto-updating)
    ];

    # GUI Applications (casks)
    casks = [
      "1password-cli"                         # Password manager CLI
      "alfred"                                # Productivity launcher
      "hammerspoon"                           # macOS automation
      "rectangle"                             # Window management
      "ghostty"                               # Fast native terminal emulator
      "insomnia"                              # API client
      "chatgpt"                               # OpenAI ChatGPT
      "claude"                                # Anthropic Claude
      "orbstack"                              # Docker/Linux VMs
      "gcloud-cli"                            # Google Cloud CLI
      "discord"                               # Voice/text chat
      "signal"                                # Secure messaging
      "hiddenbar"                             # Menu bar management
      "raycast"                               # Productivity launcher
      # send-to-kindle - removed: cask disabled upstream 2026-06-01 (use amazon.com/sendtokindle)
      "omnigraffle"                           # Diagramming tool
      "gpg-suite"                             # GPG encryption
      "steelseries-gg"                        # Gaming peripherals
      "font-fira-code"                        # Programming font
      "font-fira-code-nerd-font"              # Nerd font variant
      "font-fira-mono-nerd-font"              # Monospace nerd font
    ];
  };
}
