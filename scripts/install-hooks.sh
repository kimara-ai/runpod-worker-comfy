#!/bin/bash

# Install Git hooks for conventional commits enforcement
echo "Installing git hooks..."

# Ensure scripts directory exists
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$SCRIPT_DIR/../.git/hooks"

# Create the commit-msg hook
cat > "$HOOKS_DIR/commit-msg" << 'EOF'
#!/bin/bash

# Conventional Commit Types
# feat:     A new feature (minor release)
# fix:      A bug fix (patch release)
# docs:     Documentation changes
# style:    Changes that don't affect code meaning (formatting, etc)
# refactor: Code change that neither fixes a bug nor adds a feature
# perf:     Performance improvements (patch release)
# test:     Adding or improving tests
# build:    Changes to build system or dependencies
# ci:       Changes to CI configuration files
# chore:    Other changes that don't modify src or test files

COMMIT_MSG_FILE=$1
COMMIT_MSG=$(cat $COMMIT_MSG_FILE)

# Skip merge commits
if [[ $COMMIT_MSG == Merge* ]]; then
  exit 0
fi

# Skip semantic-release commits
if [[ $COMMIT_MSG == chore\(release\)* ]]; then
  exit 0
fi

# Define the regex for a conventional commit
PATTERN="^(feat|fix|docs|style|refactor|perf|test|build|ci|chore)(\([a-z0-9-]+\))?!?: .+"

if ! [[ $COMMIT_MSG =~ $PATTERN ]]; then
  echo "ERROR: Your commit message doesn't follow Conventional Commits formatting."
  echo "Commit message must start with one of: feat:, fix:, docs:, style:, refactor:, perf:, test:, build:, ci:, chore:"
  echo ""
  echo "Examples:"
  echo "  feat: add new feature"
  echo "  fix: resolve issue with X"
  echo "  docs: update README"
  echo "  chore: update dependencies"
  echo ""
  echo "For release automation, use feat: or fix: to trigger version bumps"
  echo ""
  echo "Your commit message was:"
  echo "$COMMIT_MSG"
  exit 1
fi

exit 0
EOF

# Make the hook executable
chmod +x "$HOOKS_DIR/commit-msg"

echo "Git hooks installed successfully!"