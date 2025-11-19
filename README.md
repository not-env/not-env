# not-env

not-env is a self-hosted replacement for .env files that provides centralized, encrypted environment variable management.

## Overview

not-env consists of three components, each maintained as its own repository:

1. **[not-env-backend](./not-env-backend)** - Go HTTP(S) API server with PostgreSQL, encryption, and horizontal scaling
2. **[not-env-cli](./not-env-cli)** - Go CLI tool for managing environments and variables
3. **[not-env-sdk-js](./not-env-sdk-js)** - JavaScript/TypeScript SDK that monkey-patches process.env

> **Note:** This repository uses git submodules. See [SETUP.md](./SETUP.md) for instructions on cloning and working with submodules.

## Quick Start

### 1. Clone the Repository

```bash
git clone --recursive https://github.com/your-org/not-env.git
cd not-env
```

If you've already cloned without `--recursive`:

```bash
git submodule update --init --recursive
```

### 2. Start the Backend

See [not-env-backend/README.md](./not-env-backend/README.md) for detailed instructions.

```bash
cd not-env-backend
docker-compose up -d
```

### 3. Get Your APP_ADMIN Key

```bash
docker-compose logs backend | grep "APP_ADMIN key"
```

### 4. Use the CLI

```bash
cd ../not-env-cli
go build -o not-env
./not-env login
# Enter backend URL and APP_ADMIN key

./not-env env create --name development
# Save the ENV_ADMIN key from the output

./not-env login
# Login with ENV_ADMIN key

./not-env env import --name development --file .env
```

### 5. Use in Your Application

```bash
cd ../not-env-sdk-js
npm install
npm run build

# In your Node.js app
export NOT_ENV_URL="https://not-env.example.com"
export NOT_ENV_API_KEY="your-env-read-only-key"
node --require not-env-sdk-js/register index.js
```

## Components

- **[Backend](./not-env-backend/README.md)** - API server, database, encryption
- **[CLI](./not-env-cli/README.md)** - Command-line interface for management
- **[SDK](./not-env-sdk-js/README.md)** - JavaScript/TypeScript integration

## Features

- ✅ Encrypted at rest (AES-256-GCM)
- ✅ Horizontal scaling support
- ✅ PostgreSQL and PostgreSQL-compatible databases
- ✅ API key authentication
- ✅ Environment-based organization
- ✅ Shell integration
- ✅ Transparent Node.js integration

## Documentation

Each component includes comprehensive documentation:

- **README.md** - User-focused, example-driven guides
- **REQUIREMENTS.md** - Complete functional and non-functional requirements

See [SETUP.md](./SETUP.md) for information about working with git submodules.

## License

MIT

