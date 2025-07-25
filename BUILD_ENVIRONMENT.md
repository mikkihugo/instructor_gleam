# Build Environment Setup

This document explains how to set up a proper build environment for the Instructor Gleam library.

## Prerequisites

### 1. Install Gleam

```bash
# Download and install Gleam
curl -L https://github.com/gleam-lang/gleam/releases/download/v1.11.1/gleam-v1.11.1-x86_64-unknown-linux-musl.tar.gz -o gleam.tar.gz
tar -xzf gleam.tar.gz
sudo mv gleam /usr/local/bin/gleam
```

### 2. Install Erlang/OTP

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y erlang

# macOS
brew install erlang

# Other systems: https://www.erlang.org/downloads
```

### 3. Verify Installation

```bash
gleam --version  # Should show: gleam 1.11.1
erl -version     # Should show Erlang version
```

## Building the Project

### Quick Setup

Run the automated setup script:

```bash
./setup_build_env.sh
```

### Manual Setup

1. **Download dependencies:**
   ```bash
   gleam deps download
   ```

2. **Build the project:**
   ```bash
   gleam build
   ```

3. **Run tests:**
   ```bash
   gleam test
   ```

4. **Format code:**
   ```bash
   gleam format
   ```

## Network Requirements

The build process requires internet access to download dependencies from:
- `repo.hex.pm` - Hex package repository
- `hex.pm` - Package metadata
- `packages.hex.pm` - Package downloads

### CI/CD Configuration

For GitHub Actions or other CI environments, ensure these domains are whitelisted:

```yaml
# Example GitHub Actions workflow
name: Build
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Erlang
        run: sudo apt install -y erlang
      - name: Install Gleam
        run: |
          curl -L https://github.com/gleam-lang/gleam/releases/download/v1.11.1/gleam-v1.11.1-x86_64-unknown-linux-musl.tar.gz -o gleam.tar.gz
          tar -xzf gleam.tar.gz
          sudo mv gleam /usr/local/bin/gleam
      - name: Build
        run: |
          gleam deps download
          gleam build
          gleam test
```

## Development Workflow

1. **Make changes** to `.gleam` files
2. **Format code:** `gleam format`
3. **Type check:** `gleam check`
4. **Build:** `gleam build`
5. **Test:** `gleam test`

## Troubleshooting

### Network Issues

If you encounter "Unable to determine package versions" errors:

1. **Check internet connectivity:**
   ```bash
   curl -I https://repo.hex.pm/packages/gleam_stdlib
   ```

2. **Check firewall/proxy settings** - ensure access to hex.pm domains

3. **For corporate networks** - may need to configure proxy settings

### Build Cache

Gleam caches dependencies in:
- `build/packages/` - Downloaded dependencies
- `manifest.toml` - Dependency lock file

To reset: `rm -rf build/ manifest.toml` and re-run `gleam deps download`

## Dependencies

The project uses these core dependencies:

- `gleam_stdlib` - Standard library
- `gleam_http` - HTTP client/server utilities  
- `gleam_httpc` - HTTP client implementation
- `gleam_json` - JSON parsing and encoding
- `gleeunit` - Testing framework (dev dependency)

All dependencies are managed through the Hex package manager and specified in `gleam.toml`.