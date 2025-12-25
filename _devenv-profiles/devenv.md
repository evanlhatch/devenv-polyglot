Non-Nixos users must follow these steps for binary caches to download deps instead of building from source

# 1. Add their user to trusted-users in the HOST nix config
echo "trusted-users = root $USER" | sudo tee -a /etc/nix/nix.conf

# 2. Restart the daemon to apply changes
# Linux (systemd)
sudo systemctl restart nix-daemon

# macOS
sudo launchctl kickstart -k system/org.nixos.nix-daemon
