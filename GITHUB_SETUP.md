# Creating GitHub Repositories for not-env

This guide provides step-by-step instructions for creating all four GitHub repositories needed for the not-env project.

## Prerequisites

- GitHub account
- Git installed locally
- All code files ready in `/Users/gavinjohnson/Documents/Development/not-env`

## Step-by-Step: Creating Repositories on GitHub

### Step 1: Create the Main Repository (`not-env`)

1. Go to https://github.com/new
2. Fill in the repository details:
   - **Repository name:** `not-env`
   - **Description:** `Self-hosted replacement for .env files`
   - **Visibility:** Choose Public or Private
   - **⚠️ IMPORTANT:** Leave all checkboxes UNCHECKED:
     - ❌ Add a README file
     - ❌ Add .gitignore
     - ❌ Choose a license
   - Click **"Create repository"**
3. **Copy the repository URL** shown on the next page (e.g., `https://github.com/YOUR_USERNAME/not-env.git`)

### Step 2: Create Component Repository 1 (`not-env-backend`)

1. Go to https://github.com/new
2. Fill in the repository details:
   - **Repository name:** `not-env-backend`
   - **Description:** `Go HTTP(S) API server for not-env - PostgreSQL, encryption, horizontal scaling`
   - **Visibility:** Choose Public or Private (should match main repo)
   - **⚠️ IMPORTANT:** Leave all checkboxes UNCHECKED
   - Click **"Create repository"**
3. **Copy the repository URL**

### Step 3: Create Component Repository 2 (`not-env-cli`)

1. Go to https://github.com/new
2. Fill in the repository details:
   - **Repository name:** `not-env-cli`
   - **Description:** `Command-line interface for managing not-env environments and variables`
   - **Visibility:** Choose Public or Private (should match main repo)
   - **⚠️ IMPORTANT:** Leave all checkboxes UNCHECKED
   - Click **"Create repository"**
3. **Copy the repository URL**

### Step 4: Create Component Repository 3 (`not-env-sdk-js`)

1. Go to https://github.com/new
2. Fill in the repository details:
   - **Repository name:** `not-env-sdk-js`
   - **Description:** `JavaScript/TypeScript SDK for not-env - transparently overrides process.env`
   - **Visibility:** Choose Public or Private (should match main repo)
   - **⚠️ IMPORTANT:** Leave all checkboxes UNCHECKED
   - Click **"Create repository"**
3. **Copy the repository URL**

## Quick Reference: Repository URLs

After creating all repositories, you should have these URLs (replace `YOUR_USERNAME`):

- Main: `https://github.com/YOUR_USERNAME/not-env.git`
- Backend: `https://github.com/YOUR_USERNAME/not-env-backend.git`
- CLI: `https://github.com/YOUR_USERNAME/not-env-cli.git`
- SDK: `https://github.com/YOUR_USERNAME/not-env-sdk-js.git`

## Next Steps

After creating all repositories on GitHub, follow the instructions in [SETUP.md](./SETUP.md) to:

1. Push code to each component repository
2. Set up the main repository with submodules
3. Verify everything is working

## Verification Checklist

After completing repository creation:

- [ ] All four repositories created on GitHub
- [ ] All repositories are empty (no initial files)
- [ ] All repository URLs copied/noted
- [ ] Ready to proceed with code push (see SETUP.md)

## Troubleshooting

### "Repository name already exists"
- Choose a different name or delete the existing repository
- For organizations, check if someone else already created it

### Can't find the repository after creation
- Check your GitHub profile's repositories page
- Verify you're logged into the correct GitHub account

### Want to change repository settings later
- Go to repository → Settings → General
- You can change name, description, visibility, etc.

