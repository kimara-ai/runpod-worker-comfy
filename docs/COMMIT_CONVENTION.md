# Commit Message Convention

This project follows [Conventional Commits](https://www.conventionalcommits.org/) for automatic semantic versioning and release notes generation.

## Format

```
<type>[(optional scope)]: <description>

[optional body]

[optional footer(s)]
```

## Types

- **feat**: A new feature (triggers minor release)
- **fix**: A bug fix (triggers patch release)
- **docs**: Documentation changes only
- **style**: Changes that don't affect code functionality (formatting, etc.)
- **refactor**: Code changes that neither fix bugs nor add features
- **perf**: Performance improvements (triggers patch release)
- **test**: Adding or correcting tests
- **build**: Changes to build system or dependencies
- **ci**: Changes to CI configuration files and scripts
- **chore**: Other changes that don't modify src or test files

## Breaking Changes

Breaking changes should include `!` after the type/scope or include `BREAKING CHANGE:` in the footer.

Examples:
```
feat!: add new API that breaks backward compatibility

feat(api): remove deprecated endpoints

BREAKING CHANGE: API endpoints X, Y, and Z have been removed
```

## Examples

```
feat: add automatic slim image build
fix: correct Docker image tagging
perf: optimize Docker build process
docs: update deployment instructions
chore: update dependencies
test: add tests for worker synchronization
```

## Enforcement

A commit-msg git hook will enforce this convention locally. If your commit is rejected, just adjust the message to follow the format.

## How This Affects Releases

- **Major version** (1.0.0 → 2.0.0): Any commit with `!` or `BREAKING CHANGE:` in the footer
- **Minor version** (1.0.0 → 1.1.0): Any commit with `feat:`
- **Patch version** (1.0.0 → 1.0.1): Any commit with `fix:` or `perf:`