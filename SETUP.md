# Setting Up not-env Repository

This repository uses git submodules to manage the four components of not-env. This guide explains how to clone and work with the repository.

## Cloning the Repository

To clone the repository with all submodules:

```bash
git clone --recursive https://github.com/not-env/not-env.git
cd not-env
```

If you've already cloned the repository without submodules:

```bash
git submodule update --init --recursive
```

## Updating Submodules

To update all submodules to their latest commits:

```bash
git submodule update --remote
```

To update a specific submodule:

```bash
git submodule update --remote not-env-backend
```

## Working with Submodules

### Making Changes to a Submodule

1. Navigate to the submodule directory:
   ```bash
   cd not-env-backend  # or other submodule
   ```

2. Make your changes and commit them:
   ```bash
   git add .
   git commit -m "Your commit message"
   git push
   ```

3. Return to the root repository and update the submodule reference:
   ```bash
   cd ..
   git add not-env-backend
   git commit -m "Update backend submodule"
   git push
   ```

### Checking Out a Specific Version

To use a specific version/tag of a submodule:

```bash
cd not-env-backend
git checkout v0.1.0
cd ..
git add not-env-backend
git commit -m "Pin backend to v0.1.0"
```

## Why Submodules?

Each component (backend, CLI, JavaScript SDK, Python SDK) is maintained as its own independent repository. Using git submodules allows:

- Independent versioning and releases for each component
- Separate issue tracking and pull requests
- Easier contribution to individual components
- Clear separation of concerns

## Troubleshooting

**Submodule shows as modified:**
- This usually means the submodule is on a different commit than what the parent repository expects
- Run `git submodule update` to sync, or commit the submodule changes if intentional

**Can't push submodule changes:**
- Make sure you've pushed changes in the submodule repository first
- Then push the parent repository with the updated submodule reference

