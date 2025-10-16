# Release Checklist for Hex Publication

This document outlines the steps to publish the Instructor Gleam package to Hex.

## Pre-Release Checklist

- [x] **Version Number**: Updated to 1.0.0 in `gleam.toml`
- [x] **Description**: Enhanced with comprehensive feature list
- [x] **License**: MIT license properly specified in `gleam.toml` and `LICENSE` file
- [x] **Repository**: GitHub repository configured in `gleam.toml`
- [x] **Links**: Added repository and issues links for Hex page
- [x] **CHANGELOG**: Updated with complete 1.0.0 release notes
- [x] **README**: Comprehensive documentation with examples
- [x] **Code Quality**:
  - [x] All files formatted with `gleam format`
  - [x] Zero compiler warnings
  - [x] All tests passing (20 tests)
- [x] **Documentation**:
  - [x] README with quick start guide
  - [x] Examples in `examples/` directory
  - [x] Development guide in `.github/AGENTS.md`
- [x] **Dependencies**: All dependencies properly specified with version constraints
- [x] **Clean Repository**: No Elixir-specific files remaining

## Publication Steps

### 1. Create a Hex Account (if needed)
- Sign up at https://hex.pm
- Verify your email address

### 2. Authenticate with Hex
The package maintainer needs to authenticate:
```bash
# Set environment variables (recommended for CI/CD)
export HEXPM_USER=your_username
export HEXPM_PASS=your_password

# Or authenticate interactively with mix (requires Elixir installed)
mix hex.user auth
```

### 3. Build and Validate
Before publishing, ensure the package builds correctly:
```bash
# Build the package
gleam build

# Run tests
gleam test

# Format check
gleam format --check

# Generate documentation (optional, for preview)
gleam docs build
```

### 4. Publish to Hex
```bash
# Publish the package
gleam publish

# The command will:
# - Build a tarball of your package
# - Validate the package metadata
# - Upload to Hex
# - Prompt for confirmation
```

### 5. Publish Documentation to HexDocs
```bash
# Publish documentation
gleam docs publish
```

### 6. Post-Publication

After successful publication:

1. **Verify on Hex**: Check https://hex.pm/packages/instructor
2. **Verify Documentation**: Check https://hexdocs.pm/instructor/
3. **Create GitHub Release**:
   - Tag: `v1.0.0`
   - Title: `Release 1.0.0 - Initial Gleam Release`
   - Description: Copy from CHANGELOG.md
4. **Announce**:
   - Gleam Discord community
   - GitHub Discussions
   - Social media if applicable

## Troubleshooting

### Common Issues

**Package name already taken**:
- Choose a different name in `gleam.toml`
- Consider: `instructor_gleam`, `gleam_instructor`, etc.

**Authentication failed**:
- Verify credentials
- Check if you have publishing rights
- Ensure Hex API key is valid

**Validation errors**:
- Check `gleam.toml` has all required fields
- Ensure version follows semantic versioning
- Verify license is in SPDX format

**Build failures**:
- Run `gleam clean` and rebuild
- Check all dependencies are available
- Verify Gleam version compatibility

## Version Management

For future releases:

1. Update version in `gleam.toml`
2. Update CHANGELOG.md with changes
3. Create a git tag: `git tag -a v1.x.x -m "Release 1.x.x"`
4. Push tag: `git push origin v1.x.x`
5. Run `gleam publish` again

## Contact

For issues with publication:
- Gleam Discord: https://discord.gg/Fm8Pwmy
- Hex Support: https://hex.pm/docs/faq
- GitHub Issues: https://github.com/mikkihugo/instructor_gleam/issues
