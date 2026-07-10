# Space — Flutter Mobile App Plan

> Phase 1 planning document for the Flutter port of **Space** (whisper-and-recall.lovable.app),
> an ephemeral private messenger where *conversations are temporary, memories are intentional*.

---

## 1. Product summary

Space is a calm, paper-textured private messenger. Messages ("**cards**") fade after being
seen unless a participant deliberately **keeps** them on a shared **shelf**. There are no
infinite scrollback logs, no read-receipt anxiety — presence is soft ("Here, quietly"),
and every conversation is a floating bubble in a drifting cluster.

### Core product mechanics
| Mechanic | Behaviour |
|---|---|
| Ephemeral cards | Every card has a fade timer: 10s, 30s, 1m, 5m, 15m, 30m, 45m, 60m, *After seen*, *View once* |
| Keep / Shelf | Any participant can "keep" a card → moves to the shared shelf, kept forever until removed |
| Delete for everyone | Sender can delete a card from the room and the shelf |
| Presence | `here` / `recent` / `away`, plus "last message X ago" |
| Nudge | Ping someone off-platform (WhatsApp / SMS) that unread cards are waiting |
| SpaceAI | In-room assistant: draft a message, generate an image, generate a short video |

---

## 2. Feature inventory & user flows

### F1 — Onboarding / Authentication
- Splash → "Your quiet self" profile setup: name, handle, optional note, avatar, palette.
- Mock `AuthRepository` (`signIn`, `signUp`, `signOut`, `currentSession`) — swap-in API later.
- Flow: first launch → onboarding → home. Returning launch → home directly.

### F2 — Home: the Cluster
- Full-screen drifting cluster of avatar bubbles (people) and stacked bubbles (circles).
- Bubble = gradient/photo avatar, size by closeness (`sm/md/lg/xl`), unread badge, presence dot.
- Gentle idle drift animation; tap → room; long-press → quick actions (shelf, nudge, mute).
- Search overlay ("Search by name…").
- **Begin a new space** sheet:
  - *One person*: name + palette (Ember, Rose, Tide, Moss, Sand, Iris) → creates room.
  - *A small circle*: name (optional) + pick ≥ 2 members → creates group room.
  - Contacts not on Space → **Invite via WhatsApp / SMS** (`wa.me`, `sms:` deep links).
- Flow: home → (search | new space | tap bubble) → room.

### F3 — Room (1:1 and circle)
- Header: avatar, name, presence line, shelf button, overflow (nudge, leave quietly).
- Card stream (not a dense chat log — roomy, card-like), auto-fading with countdown ring.
- Card types: **text**, **photo**, **video clip**, **voice note**, **link**, **file**.
- Composer: text field "Say something…", attach rail (photo / video / voice / link / SpaceAI),
  per-card fade-timer chip ("Fades 1 minute after seen · change per card").
- View-once cards: blurred until tapped, "Visible just once, then gone."
- Card actions (long-press): Keep, Delete for everyone, Copy (text).
- Group rooms show sender name + mini avatar per card.
- Flow: room → long-press card → keep → card animates to shelf.

### F4 — Shelf
- `shelf/:id` — grid of kept cards ("Kept on the shelf"), newest first.
- Card detail: full view + "Remove from the shelf" + "Delete this card? It will be gone for everyone."

### F5 — Profile
- Avatar (image picker), name, handle, "Something only you would say" note.
- **Theme**: Warm paper (light) / Quiet night (dark) — Material 3, persisted.
- **Default fade** timer for new cards ("You can change this per card while sending").
- "Saved · only on this device" until API lands.

### F6 — SpaceAI
- Bottom sheet with three intents:
  1. **Write with SpaceAI** — prompt chips ("Apologize for being distant", "Wish them goodnight",
     "Tell them I'm proud of them", "Plan a surprise weekend") → 3 draft variants → tap to insert.
  2. **An image of…** — prompt + optional reference photo → generated image card.
  3. **A moving moment of…** — prompt → generated video card.
- Mock `SpaceAiRepository` with staged loading copy ("Composing the scene…",
  "Painting your image…", "Bringing it to life…") — single seam for a real model API.

### F7 — Invites & Nudges
- Invite contact: WhatsApp (`https://wa.me/<phone>?text=…`) or SMS (`sms:<phone>?body=…`).
- Nudge: same channels, prefilled "unread messages waiting on Space".

---

## 3. Screen map & navigation

```
SplashScreen
 └─ OnboardingScreen (first run only)          /onboarding
 └─ HomeScreen (cluster)                       /
     ├─ SearchOverlay (in-screen)
     ├─ NewSpaceSheet (modal)
     ├─ RoomScreen (person)                    /room/person/:id
     ├─ RoomScreen (circle)                    /room/circle/:id
     │    ├─ FadeTimerSheet · AttachSheet · SpaceAiSheet · CardDetail
     │    └─ ShelfScreen                       /shelf/person/:id · /shelf/circle/:id
     └─ ProfileScreen                          /profile
```

- **go_router** with typed route names, redirect guard on onboarding state.
- Transitions: fade-through (home ↔ room), slide-up (sheets).

## 4. Architecture

**MVVM + Riverpod, feature-first.**

```
View (Screen/Widgets) ──watch──▶ ViewModel (Riverpod Notifier + immutable UiState)
        ▲                                 │ calls
        └────────── state ◀───────────────▼
                                   Repository (abstract)
                                     ├── MockDataSource  (now)
                                     └── RemoteDataSource (API later — same contract)
```

- Views are dumb: watch state, dispatch intents. No business logic in widgets.
- ViewModels: `Notifier`s exposing a single sealed/immutable state object.
- Repositories are abstract classes; DI via Riverpod providers → swapping mock → API
  is a one-line provider override per feature.
- Models: plain immutable classes with `fromJson`/`toJson` (API-ready), `copyWith`.

## 5. Folder structure

```
lib/
 ├── core/
 │    ├── constants/    app_constants, fade_options, palettes, app_strings
 │    ├── theme/        app_colors, app_typography, app_theme (M3 light+dark)
 │    ├── helpers/      validators, date_formatter, responsive, api_response
 │    ├── services/     local_storage, logger, permissions, media_picker, share_launcher
 │    ├── extensions/   context_x, string_x, datetime_x
 │    ├── utils/        result.dart (Result<T> either), debouncer, id_generator
 │    ├── widgets/      buttons, text fields, app bar, cards, sheets, dialogs, loading,
 │    │                 empty/error states, avatar, chips, search bar, toasts, badges
 │    └── routes/       app_router, route_names
 │
 ├── features/
 │    ├── authentication/  data(models, datasources, repositories) + presentation(viewmodels, screens, widgets)
 │    ├── home/            cluster canvas, new-space sheet, invite
 │    ├── chat/            room, cards, composer, fade engine
 │    ├── shelf/
 │    ├── profile/
 │    └── space_ai/
 │
 └── main.dart
```

## 6. Code standards enforced

- Screens < 300 lines; viewmodels/services/helpers < 150 lines — complex UI is split
  into `presentation/widgets/` parts.
- SOLID: repositories = interface-segregated seams; viewmodels depend on abstractions.
- Reusable `core/widgets` library used everywhere (no duplicated UI).
- All user-facing copy centralised in `app_strings.dart`.

## 7. API-integration handoff (the only remaining work)

| Seam | Today | Later |
|---|---|---|
| `AuthRepository` | mock session in local storage | `POST /auth/*` |
| `PeopleRepository` | seeded people/circles | `GET /spaces` + realtime presence |
| `ChatRepository` | in-memory stream + seeded openers | WebSocket / push |
| `ShelfRepository` | in-memory kept cards | `GET/POST /shelf` |
| `SpaceAiRepository` | staged mock generation | model API |
| `ProfileRepository` | shared_preferences | `PATCH /me` |

Each repository lives behind one Riverpod provider — replacing mock with remote is a
constructor swap, no UI/viewmodel changes.
