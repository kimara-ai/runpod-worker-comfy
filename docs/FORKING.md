# Forking RunPod Worker ComfyUI as an Independent Project

This guide explains how to fork the RunPod Worker ComfyUI project to create your own completely independent version.

## Complete Forking Process

### 1. Create a GitHub Fork

```bash
# First, fork the repository on GitHub
# Visit https://github.com/blib-la/runpod-worker-comfy and click the "Fork" button

# Then clone your fork locally
git clone https://github.com/YOUR-USERNAME/runpod-worker-comfy.git
cd runpod-worker-comfy

# Add the original repository as a remote to stay updated
git remote add upstream https://github.com/blib-la/runpod-worker-comfy.git
```

### 2. Update Project Configuration

#### Update package metadata and Docker configuration

```bash
# Modify the Docker image references
# Edit the following files:
# - docker-compose.yml
# - README.md
# - .github/workflows/dev.yml
# - .github/workflows/release.yml
# - .releaserc

# Replace all occurrences of:
# timpietruskyblibla/runpod-worker-comfy
# With your own Docker Hub repository:
# YOUR-USERNAME/YOUR-PROJECT-NAME
```

#### Update GitHub repository references

Find and replace all GitHub repository links:
```bash
# Find all references to the original repository
grep -r "blib-la/runpod-worker-comfy" --include="*.md" --include="*.yml" --include="*.json" .

# Manually update these references to point to your fork
# YOUR-USERNAME/YOUR-PROJECT-NAME
```

### 3. Configure CI/CD and Releases

#### Set up semantic-release for your fork

1. Keep or modify the existing `.releaserc` file based on your needs:

```json
{
  "branches": [
    "main"
  ],
  "tagFormat": "${version}",
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    [
      "@semantic-release/changelog",
      {
        "changelogFile": "CHANGELOG.md"
      }
    ],
    [
      "@semantic-release/exec",
      {
        "prepareCmd": "sed -i \"s/YOUR-USERNAME\\/YOUR-PROJECT-NAME:[0-9][0-9]*\\.[0-9][0-9]*\\.[0-9][0-9]*/YOUR-USERNAME\\/YOUR-PROJECT-NAME:${nextRelease.version}/g\" README.md"
      }
    ],
    [
      "@semantic-release/git",
      {
        "assets": [
          "README.md",
          "CHANGELOG.md"
        ],
        "message": "chore(release): ${nextRelease.version} \n\n${nextRelease.notes}"
      }
    ],
    "@semantic-release/github"
  ]
}
```

2. Configure GitHub Actions secrets:
   - Go to your GitHub repository settings
   - Add the following secrets:
     - `DOCKERHUB_USERNAME`: Your Docker Hub username
     - `DOCKERHUB_TOKEN`: Your Docker Hub access token
     - `HUGGINGFACE_ACCESS_TOKEN`: Your Hugging Face access token (if needed)

3. Configure GitHub Actions variables:
   - Add the following variables:
     - `DOCKERHUB_REPO`: Your Docker Hub username
     - `DOCKERHUB_IMG`: Your Docker image name

### 4. Customize the Project

#### Update the branding and documentation

1. Modify the README.md and other documentation:
   - Update project name and description
   - Update links to your repository
   - Update Docker image references
   - Update author information
   - Modify or remove the original acknowledgments

2. Replace or update assets:
   - Update images in the `assets/` directory with your own
   - Consider updating the worker image, logo, and screenshots

#### Optional: Change project structure or features

Based on your requirements, you might want to:
- Add new model support
- Modify the API interface
- Add new storage backends
- Change default configurations
- Update base images or dependencies

### 5. Build and Test Your Fork

#### Build Docker images locally

```bash
# Build the base image
docker build -t YOUR-USERNAME/YOUR-PROJECT-NAME:dev-base --target base --platform linux/amd64 .

# Build the SDXL image
docker build --build-arg MODEL_TYPE=sdxl -t YOUR-USERNAME/YOUR-PROJECT-NAME:dev-sdxl --platform linux/amd64 .

# Test your image locally
docker-compose up
```

#### Publish to Docker Hub

```bash
# Log in to Docker Hub
docker login

# Push your images
docker push YOUR-USERNAME/YOUR-PROJECT-NAME:dev-base
docker push YOUR-USERNAME/YOUR-PROJECT-NAME:dev-sdxl
```

### 6. Make Your First Release

1. Create a new release branch:
   ```bash
   git checkout -b release/initial
   ```

2. Make necessary changes to signify your first release
   ```bash
   # Make meaningful changes to establish your fork as a separate project
   # For example, update README.md with your project's vision
   ```

3. Commit with conventional commit format:
   ```bash
   git add .
   git commit -m "feat: initial release of YOUR-PROJECT-NAME fork

   BREAKING CHANGE: This is a complete fork of the original RunPod Worker ComfyUI project"
   ```

4. Push and create a pull request to your main branch:
   ```bash
   git push -u origin release/initial
   # Then create and merge the PR on GitHub
   ```

5. The semantic-release workflow should trigger automatically and create a version 1.0.0 of your project.

### 7. Update Your Project Status

1. Clean up the CHANGELOG.md:
   - You may want to reset it for your fork's history, or
   - Keep the previous history but add a clear note about the fork point

2. Announce your fork:
   - Create a "PROJECT_STATUS.md" file explaining your fork's goals
   - Update GitHub repository description 
   - Consider adding a project roadmap

## Maintaining Independence

To maintain your fork as a truly independent project:

1. **Make distinct improvements**: Add features and improvements that differentiate your fork
2. **Regular updates**: Periodically pull upstream changes you want to incorporate
3. **Version strategy**: Use clear versioning that distinguishes from the upstream project
4. **Own branding**: Develop your own visual identity and naming
5. **Community**: Build your own community around your specific vision

## Staying Updated with Upstream

Periodically sync with the upstream repository for important updates:

```bash
# Fetch upstream changes
git fetch upstream

# Create a branch for the updates
git checkout -b sync-upstream-changes

# Merge upstream main branch
git merge upstream/main

# Resolve any conflicts and commit
git commit -m "chore: sync with upstream changes"

# Push to your repository
git push origin sync-upstream-changes

# Create a PR to your main branch
```

## Legal Considerations

1. **License compliance**: Ensure you comply with the original project's license (check the LICENSE file)
2. **Attribution**: Maintain proper attribution to the original authors
3. **Trademark issues**: Avoid using original project's name in a way that implies endorsement