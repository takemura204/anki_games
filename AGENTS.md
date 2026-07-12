# anki_games — Agent Instructions

## Project
Flutter monorepo. Two apps: `it_pass` (IT passport exam quiz) and `block_puzzle`.

## Architecture
Feature-based layering for every feature:
```
features/xxx/
  model/         # Domain models, data classes
  repository/    # Data access, persistence
  view/          # Screens and widgets (ConsumerWidget / HookConsumerWidget)
  view/widgets/  # Private sub-widgets, collected via `part` directives
  view_model/    # AutoDisposeAsyncNotifier<XxxxState>
```

## State Management
- Package: `hooks_riverpod` (never `flutter_riverpod`)
- Pattern: `AutoDisposeAsyncNotifier` + `AsyncNotifierProvider.autoDispose`
- `ref.watch(provider)` — subscribe in build
- `ref.read(provider.notifier)` — call methods in event handlers
- `ref.invalidate(provider)` — force rebuild

## Key Rules
- **No auto-comments**: never write comments that merely restate what the code does
- **No change-log comments**: no `// Added X`, `// Updated Y`
- **No TODO/FIXME** left in code
- Use `Gap(n)` instead of `SizedBox(height: n)` / `SizedBox(width: n)`
- All UI strings in Japanese
- Follow existing folder structure and naming; do not introduce new patterns

## Common Commands
- `flutter run` — run app
- `flutter analyze` — lint (run after every implementation)
- `flutter test` — tests
- `dart run build_runner build --delete-conflicting-outputs` — code generation

## GitHub Workflow (Team Development Simulation)
- Do not commit directly to `main`.
- Always create a Git branch before making changes: `feature/issue-<number>-<name>`.
- Use Conventional Commits (`feat:`, `fix:`, `test:`, `refactor:`, `chore:`, `docs:`).
- Keep commits small and atomic.
- After implementing, create a commit, and instruct the user to open a PR and self-review.
