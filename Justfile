# Verify if your local Nix configuration allows binary caches
check-cache:
    @echo "🔍 Checking Nix Daemon trust settings for user: $(whoami)..."
    @# Get the trusted-users list from the daemon
    @current_trusted=$(nix show-config trusted-users --extra-experimental-features nix-command | awk -F'= ' '{print $2}')
    @# Check if current user is in that list
    @if echo "$current_trusted" | grep -q "$(whoami)"; then \
        echo "✅ Success: You are a trusted Nix user."; \
        echo "   Caches (Cosmic, Flox, etc.) will be used."; \
    else \
        echo "❌ Warning: You are NOT a trusted Nix user."; \
        echo "   Nix will IGNORE the custom binary caches and build from source."; \
        echo ""; \
        echo "   👉 FIX: Run this on your host terminal (not inside devenv):"; \
        echo "      echo 'trusted-users = root $(whoami)' | sudo tee -a /etc/nix/nix.conf"; \
        echo "      # Then restart Nix daemon:"; \
        echo "      # macOS: sudo launchctl kickstart -k system/org.nixos.nix-daemon"; \
        echo "      # Linux: sudo systemctl restart nix-daemon"; \
    fi
