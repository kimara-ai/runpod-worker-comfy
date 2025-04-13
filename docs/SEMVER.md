# Semantic Versioning (SemVer) Guidelines for RunPod Worker ComfyUI

This document describes how semantic versioning is implemented in the RunPod Worker ComfyUI project, including conventions, processes, and tools used.

## Semantic Versioning Overview

[Semantic Versioning](https://semver.org/) (SemVer) is a versioning scheme that uses a three-part version number: `MAJOR.MINOR.PATCH`, where:

- **MAJOR** version increases when you make incompatible API changes
- **MINOR** version increases when you add functionality in a backward compatible manner
- **PATCH** version increases when you make backward compatible bug fixes

## Current Implementation

This project uses [semantic-release](https://github.com/semantic-release/semantic-release) to automate version management and package publishing. The implementation is visible in the `.releaserc` file at the root of the project.

### Key Components

1. **Commit Message Format**

   The project follows the [Conventional Commits](https://www.conventionalcommits.org/) specification:

   ```
   <type>[optional scope]: <description>

   [optional body]

   [optional footer(s)]
   ```

   Common types include:
   - `feat`: A new feature (triggers MINOR version bump)
   - `fix`: A bug fix (triggers PATCH version bump)
   - `docs`: Documentation changes
   - `style`: Changes that don't affect code functionality
   - `refactor`: Code changes that neither fix bugs nor add features
   - `test`: Adding or correcting tests
   - `chore`: Routine tasks, maintenance

   Breaking changes (triggering MAJOR version bump) are indicated by:
   - Adding `BREAKING CHANGE:` in the commit footer, or
   - Appending a `!` after the type/scope (e.g., `feat!:`)

2. **Release Configuration**

   The `.releaserc` file configures the semantic-release behavior:
   - Automatic version determination based on commit messages
   - Changelog generation
   - Updating versions in documentation
   - Creating git tags
   - Publishing GitHub releases

3. **Docker Image Versioning**

   The project builds multiple Docker images with tags reflecting the semantic version:
   - `timpietruskyblibla/runpod-worker-comfy:<version>-base`
   - `timpietruskyblibla/runpod-worker-comfy:<version>-sdxl`
   - `timpietruskyblibla/runpod-worker-comfy:<version>-sd3`

## Development Workflow

### Making Changes

1. Create a feature or fix branch from `main`
2. Make your changes
3. Commit using the Conventional Commits format
4. Push your branch and create a pull request
5. After review and approval, merge to `main`

### Automatic Release Process

When changes are merged to `main`:

1. The semantic-release GitHub Action runs
2. It analyzes commit messages since the last release
3. It determines the new version number
4. It updates the CHANGELOG.md
5. It updates version references in README.md
6. It creates a git tag and GitHub release
7. Docker images are built with the new version tag

## Examples

### Commit Messages Examples

```
# Patch release (0.0.x)
fix: correctly handle multiple image outputs

# Minor release (0.x.0)
feat: add support for Azure Blob Storage

# Major release (x.0.0)
feat!: restructure API response format
```

or:

```
feat: completely redesign workflow structure

BREAKING CHANGE: The workflow JSON format has changed significantly
```

### Version Progression Examples

- Current version: `3.4.0`
- After merging bug fix: `3.4.1`
- After adding a new feature: `3.5.0`
- After introducing a breaking change: `4.0.0`

## Troubleshooting

If semantic-release is not working as expected:

1. Check that commit messages follow the correct format
2. Verify GitHub Action workflows are properly configured
3. Examine semantic-release logs in GitHub Actions for specific errors
4. Ensure you have the required permissions to create tags and releases

## Additional Resources

- [Semantic Versioning Specification](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [semantic-release Documentation](https://semantic-release.gitbook.io/semantic-release/)