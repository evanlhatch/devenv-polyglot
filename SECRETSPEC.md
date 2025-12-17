# SecretSpec Configuration

This project uses [SecretSpec](https://secretspec.dev) for secret management with support for multiple providers (Infisical, 1Password, and system keyring).

## Setup

### 1. Install Dependencies

The following packages are already configured in `devenv.nix`:
- `secretspec` - Secret management tool
- `infisical` - Infisical CLI for secret hydration
- `_1password-cli` - 1Password CLI (commented out due to unfree license)

To enable 1Password support, uncomment `_1password-cli` in `devenv.nix` and set `NIXPKGS_ALLOW_UNFREE=1`.

### 2. Configuration Files

#### Global Configuration (`~/.config/secretspec/config.toml`)
```toml
[providers]
# 1Password integration for team vault
op_vault = "onepassword://worldsorg.1password.com"

# Environment variables provider
env = "env"

# System keyring provider (for Infisical secrets)
keyring = "keyring"

# Fallback chain: tries 1Password first, then keyring
hybrid_chain = ["op_vault", "keyring"]

# Alternative chain that tries keyring first (Infisical), then 1Password
infisical_first_chain = ["keyring", "op_vault"]

[profiles.development]
provider = "hybrid_chain"

[profiles.development.defaults]
providers = ["hybrid_chain"]
required = true

[profiles.production]
provider = "op_vault"

[profiles.production.defaults]
providers = ["op_vault"]
required = true
```

#### Project Configuration (`secretspec.toml`)
Defines required secrets for data pipeline applications:
- AWS S3 credentials
- PostgreSQL connections
- Redis configuration
- API keys

### 3. Secret Hydration

#### Infisical Secrets
Since Infisical doesn't have native SecretSpec support, hydrate secrets into the keyring:
```bash
infisical export --format=dotenv | secretspec import dotenv
```

#### 1Password Secrets
No hydration needed - SecretSpec calls `op` CLI directly at runtime.

### 4. Usage

#### Check Configuration
```bash
secretspec check
```

#### Run Commands with Secrets
```bash
# Basic usage
secretspec run -- your-command

# Example with Go
secretspec run -- go run main.go

# Example with Python
secretspec run -- python script.py

# Example with environment variables
secretspec run -- env
```

#### Get Specific Secrets
```bash
# Get all secrets
secretspec get

# Get specific secret
secretspec get S3_ACCESS_KEY
```

### 5. Provider Chain

SecretSpec tries providers in this order:
1. **1Password** (`op_vault`) - Team vault at `worldsorg.1password.com`
2. **System Keyring** (`keyring`) - Where Infisical secrets are stored
3. **Environment Variables** (`env`) - Fallback for CI/CD

### 6. Development Workflow

1. **Start development shell**:
   ```bash
   devenv shell
   ```

2. **Hydrate Infisical secrets** (if using Infisical):
   ```bash
   infisical export --format=dotenv | secretspec import dotenv
   ```

3. **Verify secrets**:
   ```bash
   secretspec check
   ```

4. **Run your application**:
   ```bash
   secretspec run -- your-app-command
   ```

### 7. Production Considerations

For production:
- Use 1Password as primary source
- Consider using `as_path = true` for certificates/keys
- Set stricter `required = true` for production secrets

### 8. Adding New Secrets

1. Add to `secretspec.toml`:
   ```toml
   [profiles.development]
   NEW_SECRET = { description = "Description", required = true }
   ```

2. Store in Infisical or 1Password
3. Hydrate (if using Infisical)
4. Use in code via `secretspec run`

### 9. Testing

Run the test script to verify setup:
```bash
./test-secretspec.sh
```

## Notes

- **1Password**: Requires `op` CLI and authentication (`op signin`)
- **Infisical**: Requires `infisical` CLI and project setup
- **Keyring**: Used as cache for Infisical secrets
- **Environment Variables**: Fallback for CI/CD systems

## Troubleshooting

1. **"secretspec command not available"**: Run `devenv shell` first
2. **"Secret not found"**: Ensure secrets are hydrated or available in providers
3. **1Password errors**: Run `op signin` to authenticate
4. **Infisical errors**: Ensure `infisical login` and project setup

## References

- [SecretSpec Documentation](https://secretspec.dev)
- [Infisical CLI](https://infisical.com/docs/cli/overview)
- [1Password CLI](https://developer.1password.com/docs/cli)