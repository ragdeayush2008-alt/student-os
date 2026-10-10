# Student OS — Agent Rules

These rules are enforced for every OpenCode agent session in this repository.

## Testing Rules (Absolute)

**Never create another `phaseXX_test.dart` for normal development.**

All new tests must be classified by PURPOSE into these directories:

- `test/unit/{feature}/{name}_test.dart` — One class, controller, service, model, or isolated logic
- `test/widget/{feature}/{name}_test.dart` — Flutter widgets and UI behavior
- `test/integration/{feature}/{name}_test.dart` — Multiple systems working together
- `test/regression/{feature}/{name}_test.dart` — Previously fixed bugs

`test/phases/` contains only historical checkpoint files (`phase5_test.dart` through `phase25_test.dart`). Do NOT add new files there.

See [docs/testing.md](docs/testing.md) for full testing architecture documentation.

## Development Rules

- Inspect all local sources before asking questions
- Never claim success without device/test verification
- Never expose secrets
- Always run `flutter test` after changes

Full details: [docs/DEVELOPMENT_RULES.md](docs/DEVELOPMENT_RULES.md)
