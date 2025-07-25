#!/bin/bash
# Setup script for Instructor Gleam - Production Build Environment
set -e

echo "🚀 Setting up Instructor Gleam build environment..."

# Check if we're in a network-restricted environment
if ! curl -s --connect-timeout 5 https://repo.hex.pm/packages/gleam_stdlib > /dev/null 2>&1; then
    echo "⚠️  Network connectivity issue detected."
    echo "This appears to be a restricted environment that cannot reach repo.hex.pm"
    echo ""
    echo "To fix this in a normal environment:"
    echo "1. Ensure internet connectivity to repo.hex.pm"
    echo "2. Run: gleam deps download"
    echo "3. Run: gleam build"
    echo "4. Run: gleam test"
    echo ""
    echo "For CI environments, ensure these domains are whitelisted:"
    echo "- repo.hex.pm"
    echo "- hex.pm"
    echo "- packages.hex.pm"
    exit 1
fi

# Install dependencies and build
echo "📦 Downloading dependencies..."
gleam deps download

echo "🔨 Building project..."
gleam build

echo "🧪 Running tests..."
gleam test

echo "✅ Build environment setup complete!"
echo ""
echo "You can now use the following commands:"
echo "- gleam build       # Build the project"
echo "- gleam test        # Run tests"
echo "- gleam run         # Run the project"
echo "- gleam format      # Format code"
echo "- gleam check       # Type check without building"