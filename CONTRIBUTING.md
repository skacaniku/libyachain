# Contributing to LibyaChain

Thank you for your interest in contributing to LibyaChain! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct:

- Be respectful and inclusive
- Welcome newcomers
- Focus on what is best for the community
- Show empathy towards other community members

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce**
- **Expected behavior**
- **Actual behavior**
- **Environment details** (OS, Go version, etc.)
- **Relevant logs or screenshots**

Example bug report:

```markdown
## Bug: Transaction fails with insufficient gas error

**Environment:**
- LibyaChain version: v0.1.0
- OS: Ubuntu 22.04
- Go version: 1.21.0

**Steps to Reproduce:**
1. Start local node with `./scripts/init-testnet.sh`
2. Send transaction: `libyachaind tx bank send ...`
3. Error occurs

**Expected:** Transaction should succeed
**Actual:** Error: insufficient gas

**Logs:**
```
[error log content]
```
```

### Suggesting Enhancements

Enhancement suggestions are welcome! Please provide:

- **Clear use case**
- **Detailed description**
- **Potential implementation approach**
- **Benefits to the project**

### Pull Requests

1. **Fork the repository**
   ```bash
   git clone https://github.com/skacaniku/libyachain
   cd libyachain
   git remote add upstream https://github.com/skacaniku/libyachain
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/my-feature
   # or
   git checkout -b fix/issue-123
   ```

3. **Make your changes**
   - Write clear, commented code
   - Follow the coding standards (see below)
   - Add tests for new functionality
   - Update documentation as needed

4. **Test your changes**
   ```bash
   # Run all tests
   make test

   # Format code
   make format

   # Lint code
   make lint

   # Build
   make build
   ```

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "type: description"
   ```

   See [Commit Message Guidelines](#commit-message-guidelines) below.

6. **Push and create PR**
   ```bash
   git push origin feature/my-feature
   ```

   Then create a pull request on GitHub with:
   - Clear title
   - Description of changes
   - Related issue references
   - Test results

## Development Setup

### Prerequisites

```bash
# Install Go 1.21+
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Install dependencies
sudo apt-get update
sudo apt-get install -y build-essential git
```

### Local Development

```bash
# Clone your fork
git clone https://github.com/<your-username>/libyachain
cd libyachain

# Add upstream remote
git remote add upstream https://github.com/skacaniku/libyachain

# Install dependencies
go mod download

# Build
make install

# Run tests
make test
```

### Running Tests

```bash
# Unit tests
go test ./app/...

# All tests
make test-all

# With coverage
go test -cover ./...

# Specific module
go test -v ./x/mymodule/...

# Race detection
go test -race ./...
```

## Coding Standards

### Go Style Guide

Follow the [Effective Go](https://golang.org/doc/effective_go) guidelines and:

- **Use gofmt**: All code must be formatted with `gofmt`
- **Use golangci-lint**: Code must pass linting
- **Write tests**: New features require unit tests
- **Document exports**: All exported types, functions, and constants must have comments
- **Handle errors**: Never ignore errors, handle them explicitly

### Code Organization

```go
// Good: Clear package documentation
// Package bank provides account balance management.
package bank

import (
    // Standard library imports first
    "context"
    "fmt"

    // Third-party imports
    sdk "github.com/cosmos/cosmos-sdk/types"

    // Local imports
    "github.com/skacaniku/libyachain/x/bank/types"
)

// Exported constant documentation
const (
    // ModuleName defines the module name
    ModuleName = "bank"
)

// Keeper maintains the link to storage and exposes getter/setter methods
type Keeper struct {
    storeKey sdk.StoreKey
    cdc      codec.BinaryCodec
}

// NewKeeper creates a new bank Keeper instance
func NewKeeper(
    cdc codec.BinaryCodec,
    storeKey sdk.StoreKey,
) Keeper {
    return Keeper{
        cdc:      cdc,
        storeKey: storeKey,
    }
}

// GetBalance returns the balance of a specific denom for an account
func (k Keeper) GetBalance(ctx sdk.Context, addr sdk.AccAddress, denom string) sdk.Coin {
    // Implementation
}
```

### Testing Standards

```go
func TestKeeperGetBalance(t *testing.T) {
    // Setup
    ctx, keeper := setupTest(t)
    addr := sdk.AccAddress("test")

    // Test cases
    tests := []struct {
        name    string
        denom   string
        want    sdk.Coin
        wantErr bool
    }{
        {
            name:  "valid balance",
            denom: "ulydd",
            want:  sdk.NewCoin("ulydd", sdk.NewInt(1000)),
        },
        {
            name:    "invalid denom",
            denom:   "",
            wantErr: true,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := keeper.GetBalance(ctx, addr, tt.denom)
            if tt.wantErr {
                require.Error(t, err)
                return
            }
            require.NoError(t, err)
            require.Equal(t, tt.want, got)
        })
    }
}
```

## Commit Message Guidelines

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation only changes
- **style**: Code style changes (formatting, missing semi colons, etc)
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **chore**: Changes to build process or auxiliary tools

### Examples

```bash
# Feature
feat(bank): add multi-currency send support

Implements the ability to send multiple currencies in a single
transaction for improved user experience.

Closes #123

# Bug fix
fix(staking): correct validator power calculation

The validator power was incorrectly calculated when using LYDC
as the bond denomination. This fix ensures proper calculation
regardless of denomination.

Fixes #456

# Documentation
docs: update developer guide with testing examples

# Refactor
refactor(app): simplify module initialization

# Breaking change
feat(gov)!: change voting period to 48 hours

BREAKING CHANGE: The voting period has been changed from 72 hours
to 48 hours. Existing proposals will need to be re-submitted.
```

## Module Development Guidelines

### Creating a New Module

1. **Create module structure**
   ```bash
   mkdir -p x/mymodule/{keeper,types,client/cli}
   ```

2. **Define types** (`x/mymodule/types/`)
   - `keys.go`: Store keys and prefixes
   - `msgs.go`: Message types
   - `events.go`: Event types
   - `errors.go`: Error types
   - `genesis.go`: Genesis state

3. **Implement keeper** (`x/mymodule/keeper/`)
   - `keeper.go`: Main keeper
   - `msg_server.go`: Message handlers
   - `query_server.go`: Query handlers

4. **Add CLI commands** (`x/mymodule/client/cli/`)
   - `tx.go`: Transaction commands
   - `query.go`: Query commands

5. **Create module** (`x/mymodule/module.go`)
   - Implement `AppModuleBasic` interface
   - Implement `AppModule` interface

6. **Register in app**
   - Add to `ModuleBasics`
   - Add keeper to app
   - Add to module manager

### Module Checklist

- [ ] Types defined with proper validation
- [ ] Keeper implements all required methods
- [ ] Message handlers with proper authorization
- [ ] Query handlers with pagination
- [ ] CLI commands for all messages and queries
- [ ] Unit tests with >80% coverage
- [ ] Integration tests
- [ ] Invariants defined
- [ ] Events emitted
- [ ] Documentation complete

## Pull Request Process

### Before Submitting

- [ ] Code is formatted (`make format`)
- [ ] Linting passes (`make lint`)
- [ ] All tests pass (`make test`)
- [ ] New tests added for new features
- [ ] Documentation updated
- [ ] Commit messages follow guidelines
- [ ] Branch is up to date with main

### PR Description Template

```markdown
## Description
Brief description of changes

## Related Issue
Closes #123

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing performed

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] Tests pass locally

## Screenshots (if applicable)
[Add screenshots here]

## Additional Notes
[Any additional information]
```

### Review Process

1. **Automated checks** must pass
   - Build succeeds
   - Tests pass
   - Linting passes

2. **Code review** by maintainers
   - At least one approval required
   - Address all comments

3. **Squash and merge** when approved
   - PRs will be squashed on merge
   - Ensure commit message is clear

## Release Process

### Versioning

We use [Semantic Versioning](https://semver.org/):

- **MAJOR**: Incompatible API changes
- **MINOR**: Backwards-compatible functionality
- **PATCH**: Backwards-compatible bug fixes

### Release Checklist

- [ ] All tests passing
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version bumped
- [ ] Tag created
- [ ] Release notes prepared
- [ ] Binaries built for all platforms

## Security

### Reporting Vulnerabilities

**DO NOT** open public issues for security vulnerabilities.

Instead, email: security@libyachain.net

Include:
- Description of vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Security Best Practices

- Never commit secrets or private keys
- Use environment variables for sensitive config
- Validate all inputs
- Handle errors securely
- Follow principle of least privilege
- Keep dependencies updated

## Communication

### Channels

- **GitHub Issues**: Bug reports, feature requests
- **GitHub Discussions**: General questions, ideas
- **Discord**: Real-time chat (coming soon)
- **Email**: dev@libyachain.net

### Getting Help

- Check [DEVELOPERS.md](DEVELOPERS.md) first
- Search existing issues
- Ask in discussions
- Join Discord community

## Recognition

Contributors will be recognized in:
- CONTRIBUTORS.md file
- Release notes
- Project website

Thank you for contributing to LibyaChain! 🚀
