# Creating a GitHub Release for Memory Monitor

This document provides step-by-step instructions for creating a release on GitHub for Memory Monitor.

## Prerequisites

1. You have created a GitHub repository for Memory Monitor.
2. You have pushed your code to the repository.
3. You have created a DMG file using the `create_dmg.sh` script.

## Step 1: Create a Git Tag

Tags mark specific points in your repository's history, typically used to mark release versions.

```bash
# Ensure you're on the branch you want to release (usually main)
git checkout main

# Create a tag with a version number
git tag -a v1.0.0 -m "Memory Monitor v1.0.0"

# Push the tag to GitHub
git push origin v1.0.0
```

## Step 2: Create a Release on GitHub

1. Go to your repository on GitHub.
2. Click on "Releases" in the right sidebar (or navigate to https://github.com/USERNAME/REPO-NAME/releases)
3. Click on "Draft a new release"
4. In the "Tag version" field, select the tag you just created (v1.0.0)
5. Fill in the "Release title" (e.g., "Memory Monitor v1.0.0")
6. Add a description of your release, including features, improvements, and bug fixes
7. You can use markdown in the description to format it

## Step 3: Upload the DMG File

1. In the "Attach binaries" section, drag and drop your DMG file or click "choose your files" to locate it
2. Wait for the upload to complete

## Step 4: Publish the Release

1. Review all the information you entered
2. Click "Publish release" to make it available to the public

## Step 5: Share Your Release

1. After publishing, GitHub will provide a URL to your release
2. You can share this URL with users to download the DMG directly

## Creating Release with GitHub CLI (gh)

Alternatively, if you have GitHub CLI installed, you can create a release using the command line:

```bash
# Create a release with a specific tag and upload DMG
gh release create v1.0.0 \
  --title "Memory Monitor v1.0.0" \
  --notes "Initial release of Memory Monitor" \
  MemoryMonitor-YYYYMMDD.dmg
```

Replace `YYYYMMDD` with the actual date in your DMG filename.

## Updating Releases

To update a release:

1. Create a new tag for the new version (e.g., v1.0.1)
2. Create a new DMG file for the updated version
3. Follow the same steps above, but with the new tag and DMG file

## Automating Releases

For future versions, you might want to automate this process using GitHub Actions. This would allow you to automatically build and release your application when you push a tag. 