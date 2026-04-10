#!/bin/bash
# setup-machine.sh — Bootstrap a machine into the Bee Claude fleet
# Run on any new machine: curl -sL <raw-url> | bash
# Or: bash setup-machine.sh

set -e

REPO="https://github.com/DaCoderMan/bee-claude-workspace.git"
WORKSPACE="$HOME/claude-workspace"
BEE_CLAUDE="/usr/local/bin/bee-claude"

echo "=== Bee Claude Workspace Setup ==="
echo "Machine: $(hostname)"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

# 1. Clone or update workspace
echo ""
echo "[1/4] Setting up workspace at $WORKSPACE..."
if [ -d "$WORKSPACE/.git" ]; then
    cd "$WORKSPACE" && git pull --ff-only
    echo "  → Updated existing workspace"
else
    mkdir -p "$WORKSPACE"
    git clone "$REPO" "$WORKSPACE"
    echo "  → Cloned workspace"
fi

# 2. Install Claude CLI if missing
echo ""
echo "[2/4] Checking Claude CLI..."
if command -v claude &>/dev/null; then
    echo "  → Claude CLI found: $(which claude)"
else
    echo "  → Installing Claude CLI via npm..."
    if command -v npm &>/dev/null; then
        npm install -g @anthropic-ai/claude-code
        echo "  → Installed Claude CLI"
    else
        echo "  ✗ npm not found. Install Node.js first: curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs"
        exit 1
    fi
fi

# 3. Create bee-claude wrapper
echo ""
echo "[3/4] Setting up bee-claude wrapper..."
if [ -f "$BEE_CLAUDE" ]; then
    echo "  → bee-claude already exists"
else
    echo '#!/bin/bash
exec claude --dangerously-skip-permissions "$@"' | sudo tee "$BEE_CLAUDE" > /dev/null
    sudo chmod +x "$BEE_CLAUDE"
    echo "  → Created $BEE_CLAUDE"
fi

# 4. Configure git
echo ""
echo "[4/4] Configuring git..."
cd "$WORKSPACE"
git config user.email "jonathanperlin@gmail.com"
git config user.name "Bee"
echo "  → Git configured"

echo ""
echo "=== Setup Complete ==="
echo "Workspace: $WORKSPACE"
echo "Claude: $(which claude 2>/dev/null || echo 'not installed')"
echo "bee-claude: $(which bee-claude 2>/dev/null || echo 'not installed')"
echo ""
echo "To use: cd $WORKSPACE && bee-claude"
