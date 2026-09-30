---
trigger: always_on
---

# Flutter & Dart Rules

Apply these rules in every Flutter project, alongside the global rules.

---

## 1. Project Structure

```
lib/
├── core/          # Themes, constants, extensions, helpers, utils
├── features/
│   └── feature_name/
│       ├── data/          # Repos impl, API clients, models, local storage
│       ├── domain/        # Entities, use cases, repo interfaces
│       └── presentation/  # Widgets, screens, BLoC
└── main.dart
```

- Domain must never import Flutter packages.
- Data layer abstracts all sources behind repository interfaces.
- Presentation handles UI and state only — no business logic in widgets.

---

## 2. State Management — BLoC (Priority)

- `flutter_bloc` is the default state management solution.
- Use **Cubit** for simple state; use **Bloc** for complex event-driven flows.
- BLoC/Cubit depends only on domain use cases, never on data sources directly.
- Emit immutable states. Use `copyWith` or `freezed` for state classes.
- Use `BlocProvider` to inject, `BlocBuilder` to rebuild, `BlocListener` for side effects, `BlocConsumer` for both.
- For simple local single-value state, `ValueNotifier` + `ValueListenableBuilder` is acceptable.
- Use `StreamBuilder` for real-time streams and `FutureBuilder` for one-off async operations where BLoC is overkill.

---

## 3. Dart Best Practices

- Write soundly null-safe code. Avoid `!` unless value is guaranteed non-null.
- Use `const` and `final` aggressively.
- Use pattern matching and exhaustive switch expressions where they simplify code.
- Use records to return multiple values without defining a full class.
- Use `compute()` for CPU-intensive tasks to avoid blocking the UI thread.
- Use `async/await` with proper error handling. Never ignore futures silently.

---

## 4. Widgets

- Compose complex UIs from small, reusable widgets. Prefer composition over inheritance.
- Break large `build()` methods into small private Widget classes, not helper methods returning `Widget`.
- Use `const` constructors in `build()` wherever possible.
- Never perform expensive operations inside `build()`.
- Use `ListView.builder` or `SliverList` for long lists.
- Use `Expanded` to fill space; `Flexible` to shrink-to-fit. Never mix both in the same Row/Column.
- Use `LayoutBuilder` for responsive layouts based on available space.
- Keep each file under 150 lines. If a file exceeds this, it is a signal to split.
- Every widget that is logically distinct or reusable must live in its own file.
  Do not nest multiple top-level widget classes in one file.
- Screen files (e.g., `home_screen.dart`) must only contain the screen class and
  its direct scaffold/layout structure. All sections, cards, rows, and sub-widgets
  must be extracted to separate files inside a `widgets/` subfolder:
presentation/
├── screens/
│   └── home_screen.dart        # layout only — delegates to widgets
└── widgets/
├── home_header.dart
├── home_stats_card.dart
└── home_action_buttons.dart
- Private widget classes (`_MyWidget`) are only acceptable for truly trivial,
  single-use wrappers (≤ 20 lines). Anything larger gets its own file.

---

## 5. Routing

- Use `go_router` as the default routing solution.
- Configure `redirect` for authentication flows.
- Use the built-in `Navigator` only for short-lived non-deep-linkable screens (dialogs, etc.).
- Centralize all route definitions (e.g., `core/router/app_router.dart`).

---

## 6. Theming & Styling

- Define a single `ThemeData` for the whole app.
- Always implement both light and dark themes.
- Generate color palettes with `ColorScheme.fromSeed`.
- Use `ThemeExtension` for custom design tokens.
- Access theme via `Theme.of(context)` — never hardcode colors or text styles.
- Follow the 60-30-10 rule: 60% primary, 30% secondary, 10% accent.
- Meet WCAG 2.1: ≥4.5:1 contrast for normal text, ≥3:1 for large text.

---

## 7. Typography

- Use `google_fonts` for custom fonts and define a `TextTheme`.
- Always use `Theme.of(context).textTheme` — never hardcode font sizes.
- Limit to one or two font families per app.
- Set line height to 1.4x–1.6x the font size.

---

## 8. Performance

- Be careful with `setState` — minimize its scope. Prefer BLoC-driven rebuilds.
- Avoid heavy work in `build()`. Move expensive operations outside the UI tree.
- Use `cached_network_image` for network images.
- Always provide `loadingBuilder` and `errorBuilder` on `Image.network`.

---

## 9. Data & Serialization

- Use `json_serializable` + `json_annotation` for JSON. Use `fieldRename: FieldRename.snake`.
- Run: `dart run build_runner build --delete-conflicting-outputs` after modifying annotated files.
- Ensure `build_runner` is a dev dependency whenever code generation is used.

---

## 10. Accessibility

- Use the `Semantics` widget for descriptive labels on UI elements.
- Test with TalkBack (Android) and VoiceOver (iOS).
- Ensure UI remains usable when system font size is increased.

---

## 11. Localization (l10n)

- **Never hardcode user-facing strings** in widgets. Every string must go through the localization system.
- Use the `intl_utils` package with ARB files. Strings are accessed via the generated `S` class:
  ```dart
  final s = S.of(context);
  Text(s.allMatches)
  ```
- Define all strings in ARB files:
  - `lib/l10n/intl_en.arb` → English strings
  - `lib/l10n/intl_ar.arb` → Arabic strings
- Always add a new string to **both** ARB files at the same time. Never leave a key missing in either file.
- Never use `S.of(context)` in domain or data layers — only in the presentation layer.
- Support both LTR (English) and RTL (Arabic) layouts. Use `Directionality` where needed.
- Never hardcode `TextDirection.ltr` — always derive it from the current locale.
- Use `intl` for formatting dates, numbers, and currencies to respect locale differences.
- Run `flutter pub run intl_utils:generate` after modifying ARB files to regenerate the `S` class.

---

## 12. Naming & Conventions

- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables, methods, enums: `camelCase`
- Keep imports ordered and clean. Remove unused imports.
- Lines ≤ 80 characters.