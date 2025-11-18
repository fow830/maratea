#!/bin/bash
# Script to setup Turborepo remote cache

set -e

echo "⚡ Turborepo Remote Cache Setup"
echo "==============================="
echo ""

# Check if turbo is available
if ! command -v turbo &> /dev/null && ! command -v npx &> /dev/null; then
    echo "❌ turbo or npx is not installed"
    exit 1
fi

echo "1. Creating Turborepo account..."
echo "   Visit: https://turbo.build"
echo "   Sign up and create a team"
echo ""

read -p "Press Enter after creating account and team..."

echo ""
echo "2. Logging in to Turborepo..."
npx turbo login

echo ""
echo "3. Linking to team..."
read -p "Enter your team name: " TEAM_NAME

if [ -n "$TEAM_NAME" ]; then
    npx turbo link --team "$TEAM_NAME"
    echo "✅ Linked to team: $TEAM_NAME"
else
    echo "⚠️  Skipping team link"
fi

echo ""
echo "4. Testing remote cache..."
echo "   Running build to test cache..."
npx turbo build --force

echo ""
echo "✅ Turborepo remote cache setup complete!"
echo ""
echo "To use in CI/CD:"
echo "  1. Get your token: npx turbo login (copy token)"
echo "  2. Set GitHub secrets:"
echo "     - TURBO_TOKEN: your token"
echo "     - TURBO_TEAM: $TEAM_NAME"
echo ""

