# Localization Guide

## Source of Truth

- `FranAlonso/Resources/Localizable.xcstrings` is the default catalog.
- Spanish (`es`) is the source language. Add translations to the same catalog unless a feature needs a justified separate table.
- Keep `STRING_CATALOG_GENERATE_SYMBOLS = YES` for the app target in Debug and Release.
- Consume generated `LocalizedStringResource` symbols so keys are discoverable by autocomplete and invalid references fail at compile time.

## Key Convention

Use lowercase, dot-separated semantic segments:

```text
<feature>.<screen>.<element>[.<state>]
```

Examples:

| Catalog key | Generated symbol |
|---|---|
| `bootstrap.welcome.title` | `LocalizedStringResource.bootstrapWelcomeTitle` |
| `clients.list.empty.title` | `.clientsListEmptyTitle` |
| `sales.checkout.total.label` | `.salesCheckoutTotalLabel` |

Keys describe purpose, not current copy. Avoid full sentences, punctuation, numbered keys, language-specific wording, and context-free names such as `title` or `button.ok`. A copy change must not require a Swift change.

## Usage

Use generated symbols directly in SwiftUI:

```swift
Text(LocalizedStringResource.bootstrapWelcomeTitle)
```

Do not add a parallel `L10n` wrapper or repeat raw catalog keys in production code. For user-facing text carried outside a view, use `LocalizedStringResource`; runtime user content remains `String` and is not localized.

## Translator Context

- Give every manually maintained key a comment that states the UI location and purpose.
- Keep symbol-first keys as manual catalog entries so extraction does not remove them.
- Use one complete interpolated sentence or plural entry instead of concatenating translated fragments.
- Format dates, numbers, currencies, measurements, and lists with locale-aware format styles.

## Validation

- Keep a Swift Testing guard for each critical bootstrap symbol and assert its underlying semantic key.
- Build through Xcode MCP to regenerate symbols and catch catalog errors.
- Review the catalog for missing source values, comments, stale entries, and accidental hardcoded visible strings.
- Preview representative locales and longer text when a subphase changes user-facing layout.
