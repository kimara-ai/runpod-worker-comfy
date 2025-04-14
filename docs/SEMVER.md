# Semantic Versioning (SemVer) Guidelines for RunPod Worker ComfyUI

This document outlines the semantic versioning implementation in the RunPod Worker ComfyUI project, including conventions, processes, and automation tools.

## Semantic Versioning Overview

[SemVer](https://semver.org/) uses three-part numbering: `MAJOR.MINOR.PATCH`:

- **MAJOR**: Incompatible API changes
- **MINOR**: New backward-compatible features
- **PATCH**: Bug fixes

## Implementation Details

This project leverages [semantic-release](https://github.com/semantic-release/semantic-release) to automate versioning and package publishing. Configuration is defined in the `.releaserc` file at the project root.

### Key Components

#### 1. Commit Message Format

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Common Types**:
- `feat`: New feature (triggers MINOR version bump)
- `fix`: Bug fix (triggers PATCH version bump)
- `docs`: Documentation changes
- `style`: Formatting changes (no code change)
- `refactor`: Code restructuring (no functional change)
- `test`: Test additions or corrections
- `chore`: Maintenance tasks

**Breaking Changes** (trigger MAJOR version bump):
- Add `BREAKING CHANGE:` in footer or
- Append `!` after type/scope (e.g., `feat!:`)

#### 2. Release Automation

The semantic-release configuration handles:
- Version calculation based on commit history
- CHANGELOG generation
- Documentation version updates
- Git tag creation
- GitHub release publishing

#### 3. Docker Image Versioning

Images are tagged according to semantic version:
- `kimaraai/runpod-worker-comfy:<version>-base`

Note: Model-specific images (SDXL, etc.) must be built manually due to GitHub Actions disk space limitations.

## Development Workflow

### Contributing Changes

1. Branch from `main` for your feature/fix
2. Implement your changes
3. Create commits following Conventional Commits format
4. Submit a pull request
5. After approval and merge to `main`, automation takes over

### Automated Release Process

When changes merge to `main`:

1. semantic-release GitHub Action triggers
2. Commit analysis determines version increment
3. CHANGELOG.md updates with new entries
4. README.md version references update
5. Git tag and GitHub release are created
6. Docker image builds with the new version tag

## Commit Message Examples

```
# Patch release (0.0.x)
fix: correctly handle multiple image outputs

# Minor release (0.x.0)
feat: add support for Azure Blob Storage

# Major release (x.0.0)
feat!: restructure API response format
```

Or with footer for breaking changes:

```
feat: completely redesign workflow structure

BREAKING CHANGE: The workflow JSON format has changed significantly
```

## Version Progression Examples

Starting with version `3.4.0`:
- Bug fix → `3.4.1`
- New feature → `3.5.0`
- Breaking change → `4.0.0`

## Troubleshooting

When release automation fails:

- Check commit message format
- Review Action workflow logs
- Verify tag creation permissions

## Additional Resources

- [Semantic Versioning Specification](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [semantic-release Documentation](https://semantic-release.gitbook.io/semantic-release/)