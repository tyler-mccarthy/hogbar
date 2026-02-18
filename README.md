# HogBar

HogBar is a macOS menu bar application written in Swift that shows active users in your application at a glance.

The current default data source is a realistic mock provider so you can run and explore the app without any external service dependency. A PostHog HogQL data provider is included and can be enabled through environment variables.

## Features

- Menu bar status item showing the current active-user count
- Drop-down menu with user details and last-seen timing
- Manual refresh action
- Automatic refresh loop
- Fake data mode enabled by default
- PostHog HogQL provider ready for real data

## Project layout

- `Sources/HogBar/Domain`: shared domain models
- `Sources/HogBar/Data`: provider protocol and mock provider
- `Sources/HogBar/Data/PostHog`: PostHog configuration, request models, response mapping, and provider
- `Sources/HogBar/App`: app lifecycle and coordinator
- `Sources/HogBar/UI`: status item and menu composition
- `Sources/HogBar/Support`: formatting helpers
- `Tests/HogBarTests`: unit tests for provider and mapping logic

## Requirements

- macOS 14 or later
- Xcode 15 or later, or a Swift 6 toolchain on macOS

## Build and run

```bash
swift build
swift run HogBar
```

For day-to-day development, opening the package in Xcode is usually the easiest workflow for a menu bar app.

## Default behaviour

Without any environment configuration, HogBar starts in mock mode and displays generated active users.

## Enable PostHog HogQL provider

Set these environment variables before launching the app:

- `HOGBAR_POSTHOG_HOST`
- `HOGBAR_POSTHOG_PROJECT_ID`
- `HOGBAR_POSTHOG_API_KEY`

Optional environment variables:

- `HOGBAR_POSTHOG_ACTIVE_WINDOW_MINUTES` default: `15`
- `HOGBAR_POSTHOG_QUERY_OVERRIDE` custom HogQL query string

When all required PostHog variables are present, HogBar automatically switches from mock mode to the PostHog provider.

## Example HogQL strategy

The included query builder uses a pattern based on recent event activity, grouped by user identity fields, and sorted by latest activity time. This is a practical starting point and can be customised with `HOGBAR_POSTHOG_QUERY_OVERRIDE`.

## Testing

Run tests on macOS with:

```bash
swift test
```

CI is configured to run build and test on `macos-latest`.