# HogBar

HogBar is a macOS menu bar application written in Swift that shows active users in your application at a glance.

The default mode uses realistic mock data so you can run and explore the app without any external service dependency. You can then sign in to PostHog from a login popup and switch between projects that belong to your account.

## Features

- Menu bar status item showing the current active-user count
- Drop-down menu with user details and last-seen timing
- Manual refresh action
- Automatic refresh loop
- Fake data mode enabled by default
- Login popup for PostHog host URL and personal API key
- Project switching submenu for authenticated PostHog projects
- Sign out action that returns to mock mode

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

## Sign in and switch projects

1. Open the HogBar menu.
2. Select `Sign in to PostHog…`.
3. Enter your PostHog host URL and personal API key.
4. After successful authentication, use `Switch project` in the menu to toggle between projects.
5. Select `Sign out` to return to mock mode.

HogBar fetches organisations and projects accessible to the authenticated user and uses the selected project when running the active-user HogQL query.

## Optional environment bootstrap

You can still preconfigure PostHog for automatic sign-in at launch:

- `HOGBAR_POSTHOG_HOST` required
- `HOGBAR_POSTHOG_API_KEY` required

Optional environment variables:

- `HOGBAR_POSTHOG_PROJECT_ID` preferred initial project when available
- `HOGBAR_POSTHOG_ACTIVE_WINDOW_MINUTES` default: `15`
- `HOGBAR_POSTHOG_QUERY_OVERRIDE` custom HogQL query string

When required variables are present, HogBar attempts automatic sign-in using those values.

## Example HogQL strategy

The included query builder uses a pattern based on recent event activity, grouped by user identity fields, and sorted by latest activity time. This is a practical starting point and can be customised with `HOGBAR_POSTHOG_QUERY_OVERRIDE`.

## Testing

Run tests on macOS with:

```bash
swift test
```

CI is configured to run build and test on `macos-latest`.