#!/bin/bash
# Syntax validation script - checks Gleam syntax without building
set -e

echo "🔍 Validating Gleam syntax..."

# Check if Gleam is installed
if ! command -v gleam &> /dev/null; then
    echo "❌ Gleam is not installed. Please install Gleam first."
    exit 1
fi

echo "✅ Gleam is installed: $(gleam --version)"

# Check code formatting
echo "📏 Checking code formatting..."
if gleam format --check src/; then
    echo "✅ All source files are properly formatted"
else
    echo "❌ Some files need formatting. Run 'gleam format src/' to fix."
    exit 1
fi

# Note about dependency validation
echo ""
echo "📦 Dependency validation requires network access to repo.hex.pm"
echo "In a network-enabled environment, run:"
echo "  - gleam check    # Type check with dependencies"
echo "  - gleam build    # Full build"
echo "  - gleam test     # Run tests"

echo ""
echo "✅ Syntax validation complete!"
echo "🎯 Code structure and formatting are valid"