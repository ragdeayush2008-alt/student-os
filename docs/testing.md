# Student OS — Testing Architecture

This document defines the permanent test structure and rules for all testing in Student OS. Future agents must follow these rules when adding, modifying, or organizing tests.

## Permanent Test Structure

```
test/
├── unit/          # One class, controller, service, repository, model, or isolated logic
├── widget/        # Flutter widgets and UI behavior
├── integration/   # Multiple Student OS systems working together
├── regression/    # Bugs and failures that were previously fixed
└── phases/        # Historical development-phase checkpoints (do NOT add new files here for normal dev)
```

### Feature-Based Organization

Within each category, tests are organized by **actual Student OS features**, not by phase numbers.

**Example: Focus feature**

```
test/unit/focus/focus_controller_test.dart
test/widget/focus/focus_screen_test.dart
test/integration/focus/focus_session_test.dart
test/regression/focus/focus_restore_test.dart
```

**Example: Auth feature**

```
test/unit/auth/auth_service_test.dart
test/widget/auth/sign_in_screen_test.dart
test/integration/auth/auth_flow_test.dart
test/regression/auth/user_isolation_test.dart
```

**Example: Tasks feature**

```
test/unit/tasks/task_controller_test.dart
test/widget/tasks/tasks_screen_test.dart
test/integration/tasks/subject_task_integration_test.dart
test/regression/tasks/task_persistence_test.dart
```

## Absolute Rules for New Tests

### NEVER create phase-numbered test files for normal development

```
# DO NOT create these for new features:
phase26_test.dart
phase27_test.dart
phase28_test.dart
phase29_test.dart
# etc.
```

Phase-numbered files (`phase1_test.dart` through `phase25_test.dart`) exist only in `test/phases/` as **historical checkpoints**. They document what was built at a previous stage. They are never moved, deleted, or modified.

### ALWAYS classify new tests by PURPOSE

Every new test must go into one of these four categories:

| Category | When to use | Example |
|---|---|---|
| `test/unit/` | Testing one class, controller, service, model, or isolated function | `test/unit/focus/focus_controller_test.dart` |
| `test/widget/` | Testing Flutter widgets, rendering, UI behavior | `test/widget/focus/focus_screen_test.dart` |
| `test/integration/` | Testing multiple systems working together | `test/integration/focus/focus_session_test.dart` |
| `test/regression/` | Testing a bug that was previously fixed | `test/regression/focus/focus_restore_test.dart` |

### Feature subdirectories within categories

Every category has feature subdirectories. Always place tests in the appropriate feature subdirectory:

- `test/unit/{feature}/{name}_test.dart`
- `test/widget/{feature}/{name}_test.dart`
- `test/integration/{feature}/{name}_test.dart`
- `test/regression/{feature}/{name}_test.dart`

## Existing Files (Preserved)

The following files were reorganized during the architecture setup. They must NOT be deleted or modified:

- `test/phases/` — Contains 15 historical phase checkpoint files (`phase5_test.dart` through `phase25_test.dart`)
- `test/regression/` — Contains 3 regression test files (production hardening, analytics, persistence)
- All other test files have been reclassified into `unit/`, `widget/`, or `integration/`

### Split files

Two mixed-type files were split during reorganization:
- `subject_task_integration_test.dart` → `unit/tasks/subject_task_unit_test.dart` + `integration/tasks/subject_task_integration_test.dart`
- `resource_subject_integration_test.dart` → `unit/resources/resource_unit_test.dart` + `integration/resources/resource_subject_integration_test.dart`

## Test Count

As of the last reorganization: **379 tests across 33 files**.

Run all tests with: `flutter test`

## Constraints (Never Violate)

1. **Do NOT move tests into `lib/`**
2. **Do NOT delete existing tests**
3. **Do NOT weaken or remove assertions**
4. **Do NOT change production behavior**
5. **Do NOT rewrite working business logic**

## Adding a New Feature Test

When adding tests for a new Student OS feature (e.g., "milestones"):

1. Determine what type of test each test case is (unit, widget, integration, regression)
2. Create the appropriate directory: `test/{category}/milestones/`
3. Name files descriptively: `milestone_controller_test.dart`, `milestone_screen_test.dart`
4. Never create a `phaseXX_test.dart` file
