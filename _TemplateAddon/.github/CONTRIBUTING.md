# Contributing to [AddonName]

Thank you for your interest in contributing!

## Quick Start

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run validation checks (see below)
5. Commit (`git commit -m 'feat: add amazing feature'`)
6. Push (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## Development Setup

### Prerequisites

- WoW Retail client (or PTR/Beta for Midnight testing)
- Git
- (Optional) Lua 5.1 for running tests locally

### Installation

1. Clone into your WoW `_dev_` folder or `Interface/AddOns`
2. Restart WoW or `/reload`

## Code Standards

### Lua Style

- Use 4-space indentation
- Use `local` for all variables
- Prefix private functions with underscore: `_privateFunc()`
- Run `format_addon("[AddonName]")` before submitting

### Linting

Before submitting a PR, ensure your code passes linting:

```bash
# Using AI tools
lint_addon("[AddonName]")

# Or manually
cd ADDON_DEV/Tools/LintingTool
.\lint.ps1 -Addon "[AddonName]"
```

### Testing

Run the test suite:

```bash
# Using AI tools
run_tests("[AddonName]")

# Or manually
cd ADDON_DEV/Tools/TestRunner
.\run_tests.ps1 -Addon "[AddonName]"
```

## Commit Messages

Use conventional commit format:

- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `refactor:` Code refactoring
- `test:` Test additions/changes
- `chore:` Maintenance tasks

Example: `feat: add cooldown tracking for charges`

## Pull Request Process

1. Fill out the PR template completely
2. Ensure CI checks pass
3. Request review from maintainers
4. Address any feedback
5. Squash commits if requested

## Midnight Compatibility

If your changes involve:

- Health, mana, or resource values
- Spell charges or cooldowns
- Unit information in instances

Please test on PTR/Beta and verify:

- [ ] No Lua errors with secret values
- [ ] Graceful degradation in M+/raids
- [ ] No combat lockdown violations

## Questions?

- Open an issue for bugs or feature requests
- Check existing issues before creating new ones
- Join the WoW Addon Development Discord for help
