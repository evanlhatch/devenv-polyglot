{
  pkgs,
  lib,
  config,
  ...
}:
{
  profiles.cloud = {
    module = {
      enterShell = ''
        export DEVENV_ACTIVE_PROFILES="''${DEVENV_ACTIVE_PROFILES} ☁️ cloud"
      '';

      # 1. Enable devenv's core Helm language support.
      languages.helm = {
        enable = true;
        plugins = [
          "helm-secrets"
          "helm-diff"
          "helm-unittest"
          "helm-s3"
          "helm-git"
          "helm-schema"
        ];
      };

      # 2. Define the package set for the cloud/infrastructure stack.
      packages = with pkgs; [
        # Kubernetes Core Tools and Orchestration
        clusterctl
        kind
        kubectl # Kubernetes CLI
        k9s # Kubernetes TUI
        kustomize # Kubernetes native configuration customization
        fluxcd # GitOps for Kubernetes
        cilium-cli # Cilium CLI for eBPF-based networking, security, and observability
        # crossplane-cli # Extend Kubernetes to manage infrastructure
        talosctl # CLI for Talos Linux
        kubeconform # Kubernetes manifest validation
        kyverno # Kubernetes native policy engine
        # talhelper
        kubeswitch
        # helm-docs

        # Kubernetes Utilities and Observability
        kdash # Kubernetes dashboard TUI
        hubble # Observability for Cilium
        kail # Kubernetes log streamer
        stern # Multi-pod and container log tailing
        # pluto # Find deprecated Kubernetes APIs
        # mirrord # Connect local processes to Kubernetes clusters
        # tetragon # eBPF-based security observability and runtime enforcement

        # Container and Image Tools
        # lazydocker # Docker and Docker Compose TUI
        # crane # Interact with container registries
        # hadolint # Dockerfile linter
        #mdockerfmt # Dockerfile formatter

        # Security and Secrets Management
        # sops # Secrets OPerationS (encrypted secrets management)
        # age # Simple, modern, and secure file encryption
        trivy # Vulnerability scanner for containers and filesystems
        # cosign # Supply chain security for containers
        kubelogin-oidc # OIDC authentication for kubectl

        # Cloud Provider CLIs
        awscli2 # AWS Command Line Interface
        hcloud # Hetzner Cloud CLI

        # Infrastructure as Code (IaC)
        # hclfmt # HCL formatter (Terraform, Packer)
        # opentofu # Terraform-compatible CLI
        # terraform-docs
        # driftctl
        # inframap

        # CI/CD and Automation
        actionlint # GitHub Actions workflow linter
        pinact # GitHub Actions version pinner
        renovate # Automate dependency updates
        velero # Backup and restore Kubernetes cluster resources and persistent volumes

        # Networking and System Utilities
        cloudflared # Cloudflare Tunnel daemon
        wireguard-tools # Userspace tools for WireGuard
        yq-go # YAML/JSON processor
        # omnictl # Omni CLI (general purpose CLI, often used with cloud)
      ];

      # 3. Centralized formatting and linting via treefmt for cloud-native files.
      treefmt.config.programs = {
        # hclfmt.enable = true; # For HashiCorp Configuration Language (HCL)
        # terraform.enable = true; # For Terraform-specific formatting (uses opentofu)
        # hadolint.enable = true; # For Dockerfile linting
        #dockerfmt.enable = true; # For Dockerfile formatting
        # actionlint.enable = true; # For GitHub Actions workflows linting
        # pinact.enable = true; # For pinning GitHub Actions versions
      };
    };
  };
}
