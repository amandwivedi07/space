# Space — Flutter

An ephemeral private messenger. *Conversations are temporary, memories are intentional.*
Flutter port of the Space web prototype (whisper-and-recall.lovable.app).

> Nothing is stored unless both of you choose to keep it.

## What's inside

| Feature | Status |
|---|---|
| Onboarding ("Your quiet self") — name, handle, note, avatar, palette | ✅ mock auth, API-ready |
| Home cluster — drifting bubbles, presence, unread, search | ✅ |
| New space — one person (palette) or a circle (≥2 members) | ✅ |
| Invites — WhatsApp / SMS deep links for contacts not yet here | ✅ |
| Rooms — ephemeral cards: text, photo, video, voice, link, file | ✅ |
| Fade timers — 10s → 60m, After seen, View once; per-card override | ✅ live countdown + sweep |
| Keep / Shelf — kept cards live forever on the shared shelf | ✅ |
| Delete for everyone, copy, nudge, leave quietly | ✅ |
| SpaceAI — draft messages, generate image/video | ✅ staged mock behind one seam |
| Profile — identity, Warm paper / Quiet night themes, default fade | ✅ persisted locally |

## Run it

```bash
flutter pub get
flutter run          # any iOS/Android device or simulator
flutter test         # unit + widget tests
flutter analyze      # zero issues
```

## Architecture

MVVM + Riverpod, **feature-first**. See [PLAN.md](PLAN.md) for the full plan.

```
lib/
 ├── core/            constants · theme · helpers · services · extensions
 │                    utils · widgets (design system) · routes
 ├── features/
 │    ├── authentication/   data(models·datasources·repositories) + presentation(viewmodels·screens·widgets)
 │    ├── home/             cluster canvas, new-space sheet, invites
 │    ├── chat/             rooms, cards, composer, fade engine
 │    ├── shelf/            kept memories
 │    ├── profile/          identity + settings
 │    └── space_ai/         drafts + generated media
 └── main.dart
```

- **Views** watch a single immutable state object and dispatch intents — no logic in widgets.
- **ViewModels** are Riverpod `Notifier`s (`< 150` lines each).
- **Repositories** are abstract contracts with mock implementations; models carry
  `fromJson`/`toJson` so wire formats are already defined.

## Plugging in the API (the only remaining work)

Each seam is one provider override — viewmodels and UI never change:

| Provider | Mock today | Replace with |
|---|---|---|
| `authRepositoryProvider` | local session | `POST /auth/*` |
| `spacesRepositoryProvider` | seeded people/circles | `GET /spaces` + presence socket |
| `chatRepositoryProvider` | in-memory cards + fade sweep | realtime channel |
| `shelfRepositoryProvider` | kept-card filter | `GET/POST /shelf/:roomId` |
| `spaceAiRepositoryProvider` | staged mock | model API |
| `settingsRepositoryProvider` | shared_preferences | `PATCH /me/settings` (optional) |

Example:

```dart
final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ApiChatRepository(ref.watch(apiClientProvider)), // was MockChatRepository
);
```

Also mock-only by design: the simulated one-per-room reply (`MockChatRepository.send`)
and simulated voice recording (`VoiceRecordButton`) — both documented at the call site.
# space
