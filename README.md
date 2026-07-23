# EBN — Customer / Admin / Agent Demo

Interactive client demo, mock data, no backend. Restyled from your
`asset_platform_starter` frontend (ink/yellow palette, buttons, drawer,
listing cards) and split into three separate full flows instead of tabs.

## Run locally in Chrome

```bash
flutter pub get
flutter run -d chrome
```

## Build a static site to host/share

```bash
flutter build web --release
```

Output lands in `build/web/`. Drag that folder into
https://app.netlify.com/drop for an instant shareable URL.

## How it's structured

- `lib/screens/role_gate_screen.dart` — landing page, the door into each side.
- `lib/screens/signin_screen.dart` / `signup_screen.dart` — shared auth UI,
  parameterized by role. No real backend — `MockAuthService` resolves
  instantly with a locally-built user.
- `lib/screens/customer_home_screen.dart` — browse assets, request a tour.
- `lib/screens/admin_home_screen.dart` — approvals queue + asset catalogue.
- `lib/screens/agent_home_screen.dart` — listings feed, drawer, and the
  live ringing/countdown overlay when dispatched.
- `lib/providers/loop_controller.dart` — the one shared piece of state.
  Provided once at the app root, so even though Customer/Admin/Agent are
  separate pushed routes (not tabs), an action on one side is instantly
  reflected on the others — exactly like a realtime backend would behave,
  minus the backend.
- `lib/theme/app_theme.dart` — carried over unchanged from your starter
  (ink/yellow/cloud palette, button/input theming).

## Demo flow to show a client

1. Land on the role gate → **Enter as Customer** → sign up with any
   name/email → request a tour on any listing.
2. Open a second browser tab (or just navigate back) → **Enter as Admin**
   → see the request land in the Approvals Queue → **Approve & Publish**.
3. **Enter as Agent** → toggle Online in the drawer → the dispatch overlay
   rings with a 30s countdown → **Accept** (or **Decline** to see the
   re-dispatch loop back to Admin).

Reset the shared state anytime with the restart icon in any app bar.

## Next steps (when you're ready for a real backend)

Your `/backend` folder already has the auth + assets scaffolding. Swap
`lib/services/mock_auth_service.dart` for real HTTP calls and
`lib/services/mock_asset_data.dart` for a live `GET /api/assets` fetch —
none of the UI code needs to change.
