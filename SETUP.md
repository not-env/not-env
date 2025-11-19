# Setting Up not-env with Git Submodules

This repository uses git submodules to reference each component as its own repository. This allows each component to be developed independently while still being used together.

## Setting Up the Main not-env Repository

### 1. Create the Main Repository on GitHub

1. Go to https://github.com/new
2. Create a new repository:
   - **Repository name:** `not-env`
   - **Description:** "Self-hosted replacement for .env files"
   - **Visibility:** Public or Private (your choice)
   - **Important:** Do NOT initialize with README, .gitignore, or license (we'll add these)
   - Click "Create repository"

### 2. Initialize the Main Repository Locally

```bash
cd /Users/gavinjohnson/Documents/Development/not-env

# Initialize git repository
git init

# Add main repository files (submodules will be added separately)
git add README.md SETUP.md TESTING.md .gitmodules .gitignore LICENSE

# Create initial commit
git commit -m "Initial commit: not-env monorepo"

# Add remote (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/not-env.git

# Rename branch to main if needed
git branch -M main

# Push to GitHub
git push -u origin main
```

**Note:** At this point, the component directories (`not-env-backend`, `not-env-cli`, and `SDKs/not-env-sdk-js`) should still exist locally. They will be replaced with submodules in a later step.

---

## Setting Up Component Repositories

### 1. Create Separate Repositories on GitHub

Create three separate repositories for each component:

1. Go to https://github.com/new for each repository:
   - **not-env-backend** - Backend API server
   - **not-env-cli** - CLI tool
   - **not-env-sdk-js** - JavaScript/TypeScript SDK

   For each repository:
   - **Repository name:** `not-env-backend` (or `not-env-cli`, `not-env-sdk-js`)
   - **Description:** Appropriate description for each component
   - **Visibility:** Public or Private (your choice)
   - **Important:** Do NOT initialize with README, .gitignore, or license (we'll add these)
   - Click "Create repository"

### 2. Push Code to Separate Repositories

For each component, initialize a git repository and push:

```bash
# Backend
cd /Users/gavinjohnson/Documents/Development/not-env/not-env-backend
git init
git add .
git commit -m "Initial commit: not-env-backend"
git remote add origin https://github.com/YOUR_USERNAME/not-env-backend.git
git branch -M main
git push -u origin main

# CLI
cd ../not-env-cli
git init
git add .
git commit -m "Initial commit: not-env-cli"
git remote add origin https://github.com/YOUR_USERNAME/not-env-cli.git
git branch -M main
git push -u origin main

# SDK
cd ../not-env-sdk-js
git init
git add .
git commit -m "Initial commit: not-env-sdk-js"
git remote add origin https://github.com/YOUR_USERNAME/not-env-sdk-js.git
git branch -M main
git push -u origin main
```

**Note:** Replace `YOUR_USERNAME` with your actual GitHub username in all commands.

### 3. Update .gitmodules

Edit `.gitmodules` in the main repository to use your actual repository URLs:

```bash
cd /Users/gavinjohnson/Documents/Development/not-env
```

Update `.gitmodules` to replace `your-org` with your GitHub username:

```ini
[submodule "not-env-backend"]
	path = not-env-backend
	url = https://github.com/YOUR_USERNAME/not-env-backend.git
	branch = main

[submodule "not-env-cli"]
	path = not-env-cli
	url = https://github.com/YOUR_USERNAME/not-env-cli.git
	branch = main

[submodule "not-env-sdk-js"]
	path = SDKs/not-env-sdk-js
	url = https://github.com/YOUR_USERNAME/not-env-sdk-js.git
	branch = main
```

### 4. Remove Existing Directories and Add as Submodules

```bash
# From the not-env root directory
cd /Users/gavinjohnson/Documents/Development/not-env

# Remove existing directories (they'll be replaced with submodules)
rm -rf not-env-backend not-env-cli not-env-sdk-js SDKs

# Create SDKs directory (if it doesn't exist)
mkdir -p SDKs

# Add submodules (replace YOUR_USERNAME with your GitHub username)
git submodule add https://github.com/YOUR_USERNAME/not-env-backend.git not-env-backend
git submodule add https://github.com/YOUR_USERNAME/not-env-cli.git not-env-cli
git submodule add https://github.com/YOUR_USERNAME/not-env-sdk-js.git SDKs/not-env-sdk-js

# Commit the submodule configuration
git add .gitmodules
git commit -m "Add submodules for all components"
git push
```

## Cloning the Repository

When cloning the main repository, use the `--recursive` flag to include submodules:

```bash
git clone --recursive https://github.com/YOUR_USERNAME/not-env.git
cd not-env
```

If you've already cloned without `--recursive`, initialize submodules:

```bash
git submodule update --init --recursive
```

## Working with Submodules

### Updating Submodules

To update all submodules to their latest commits:

```bash
git submodule update --remote
```

To update a specific submodule:

```bash
git submodule update --remote not-env-backend
```

### Making Changes to Submodules

1. **Navigate to the submodule directory:**
   ```bash
   cd not-env-backend
   ```

2. **Make your changes and commit:**
   ```bash
   git add .
   git commit -m "Your changes"
   git push
   ```

3. **Return to the main repository and update the submodule reference:**
   ```bash
   cd ..
   git add not-env-backend
   git commit -m "Update not-env-backend submodule"
   git push
   ```

### Checking Submodule Status

```bash
git submodule status
```

This shows the current commit of each submodule.

### Updating to Latest Submodule Changes

If someone else updated a submodule reference in the main repo:

```bash
git pull
git submodule update --init --recursive
```

## Development Workflow

### Option 1: Develop in Submodule Directories

Work directly in the submodule directories:

```bash
cd not-env-backend
# Make changes, commit, push
git add .
git commit -m "Feature: add new endpoint"
git push origin main

# Update main repo reference
cd ..
git add not-env-backend
git commit -m "Update backend submodule"
git push
```

### Option 2: Develop in Separate Repositories

Clone each component separately for independent development:

```bash
# Clone backend separately
git clone https://github.com/YOUR_USERNAME/not-env-backend.git
cd not-env-backend
# Develop, commit, push

# When ready, update submodule in main repo
cd ../not-env
git submodule update --remote not-env-backend
git add not-env-backend
git commit -m "Update backend to latest"
git push
```

## CI/CD Considerations

When setting up CI/CD, ensure submodules are initialized:

```yaml
# Example GitHub Actions
- uses: actions/checkout@v3
  with:
    submodules: recursive
```

## Troubleshooting

### Submodule Shows as Modified

If `git status` shows submodules as modified:

```bash
# Check what changed
cd not-env-backend
git status

# Either commit the changes or discard them
git reset --hard HEAD
```

### Submodule Points to Wrong Commit

To reset a submodule to match the main repository:

```bash
git submodule update --init --recursive
```

### Remove a Submodule

```bash
# Remove from .gitmodules and .git/config
git submodule deinit -f not-env-backend
git rm -f not-env-backend
rm -rf .git/modules/not-env-backend
git commit -m "Remove not-env-backend submodule"
```

## Benefits of This Structure

1. **Independent Versioning**: Each component can have its own release cycle
2. **Separate CI/CD**: Each repository can have its own CI/CD pipeline
3. **Focused Development**: Developers can work on one component without cloning everything
4. **Clear Dependencies**: The main repo clearly shows which versions of each component are used together
5. **Reusability**: Components can be used independently in other projects

