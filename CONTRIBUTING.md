# Contributing to Maratea

## Development Setup

1. Install dependencies:
```bash
pnpm install
```

2. Start Docker services:
```bash
make docker-up
```

3. Start development:
```bash
make dev
```

## Code Style

We use Biome for linting and formatting. Run:
```bash
pnpm lint
```

## Commit Messages

We follow [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes
- `refactor:` - Code refactoring
- `test:` - Test changes
- `chore:` - Other changes

## Pull Requests

1. Create a feature branch
2. Make your changes
3. Run tests and linting
4. Submit a PR with a clear description

