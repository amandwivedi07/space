# Prompt: finish the iOS → TestFlight pipeline for Space Talk

Paste this to an agent working in `Space_talk/space_flutter`, or follow it by
hand. Everything below was verified against the Chaos pipeline, which now ships
to TestFlight on every push to `main`.

---

## The three values

| What | Value | Where it goes |
| --- | --- | --- |
| **Team ID** | `NZH7T8Y3FC` | already committed in `ios/Runner.xcodeproj` and `ios/ExportOptions.plist` — nothing to do |
| **Key ID** | the 10 characters in the `.p8` filename, e.g. `AuthKey_HRW3U96ALT.p8` → `HRW3U96ALT` | repo secret `APP_STORE_CONNECT_KEY_ID` |
| **Issuer ID** | a UUID, App Store Connect → Users and Access → Integrations, shown *above* the key table | repo secret `APP_STORE_CONNECT_ISSUER_ID` — **already set** on this repo |
| **The `.p8` itself** | the whole file, `-----BEGIN PRIVATE KEY-----` and `-----END-----` lines included | repo secret `APP_STORE_CONNECT_PRIVATE_KEY` |

**The Chaos key already covers this app.** It can see eight bundle ids,
including `com.talkinspace.talkinspace`. One App Store Connect key serves the
whole account, so reuse the same three values — do not create a second key.

Set the two that are missing:

```bash
cd Space_talk/space_flutter
gh secret set APP_STORE_CONNECT_KEY_ID --body "HRW3U96ALT"
gh secret set APP_STORE_CONNECT_PRIVATE_KEY < ~/Desktop/AuthKey_HRW3U96ALT.p8
```

Then `gh secret list` must show all three.

## Then fix the build number

`.github/workflows/ios-testflight.yml` still computes `100 + GITHUB_RUN_NUMBER`.
That is what put a **114** next to a **13** on Chaos: the comment justifying the
offset claimed nothing had ever been uploaded for the bundle id, which was never
checked and was false.

Copy the fixed step out of
`Chaos/chaos_flutter/.github/workflows/ios-testflight.yml`. It:

- reads `version: x.y.z+N` from `pubspec.yaml`, so iOS and Android carry the
  same number and it is bumped deliberately in one place;
- asks App Store Connect which builds already exist **for that marketing
  version** and refuses in ten seconds if `+N` is not higher, naming the number
  to beat;
- prints every build Apple holds, grouped by version, so "did the last upload
  land" never needs a console refresh — a build takes a few minutes to appear
  after `altool` reports success.

Also copy the **Verify the key with Apple** step. It mints an App Store Connect
token and calls one read-only endpoint before anything compiles, and separates
the failures that otherwise all look identical four minutes into an archive:

- **401** — one of the three secrets is wrong, or the Key ID belongs to a
  different key than the private key. This is the most common one.
- **403** — the key is real but its role is too low. `-allowProvisioningUpdates`
  has to mint a distribution certificate, which needs **App Manager** or Admin.
  Developer is refused.
- **key valid but the bundle id is not in its list** — wrong account, or the app
  has not been created in App Store Connect yet.

## What is already right here

- `ios/Runner/Info.plist` is **tracked**. Keep it that way. On Chaos it was
  gitignored and the archive could not run at all — `Runner.xcodeproj` names it
  as `INFOPLIST_FILE` in all six build configurations, and a CI runner clones
  the repo and finds nothing.
- Signing is Automatic, and the team ID is committed in both places.
- No certificate or provisioning profile belongs in GitHub. The API key is the
  only credential; write it outside the workspace and delete it in a step with
  `if: always()`.

## Build numbers, once it works

Bump both halves of `version:` together — `1.2.4+37`, never a name bump alone.
Within one marketing version Apple requires each build to be higher than the
last; a **new** version number starts its own sequence, which is the only way to
recover from a number that ran away.

## Push notifications are a different key

If Space Talk's push works, `space-chat-9a160` already holds an APNs `.p8`
issued from team `NZH7T8Y3FC` — and that same key will fix Chaos, whose Firebase
project has none (`THIRD_PARTY_AUTH_ERROR — Invalid APNs credential`).

An APNs key and an App Store Connect key are both `AuthKey_XXXXXXXXXX.p8` from
the same portal and are **not** interchangeable:

- **APNs key** — Certificates, Identifiers & Profiles → Keys, with "Apple Push
  Notifications service (APNs)" ticked. Goes into Firebase → Cloud Messaging.
- **App Store Connect key** — Users and Access → Integrations. Goes into GitHub
  secrets, uploads builds.

Every `.p8` on this Mac was tested against APNs for team `NZH7T8Y3FC` and
rejected, so they are all the second kind.

## How to check a key without a device

APNs validates the provider token before the device token, so a deliberately
bogus device token separates the two answers:

```
403 InvalidProviderToken  → the key, Key ID or Team ID is wrong for APNs
400 BadDeviceToken        → the key is GOOD; only the fake token was bad
```

Sign an ES256 JWT with `{"alg":"ES256","kid":KEY_ID}` and
`{"iss":TEAM_ID,"iat":now}`, then POST to
`https://api.push.apple.com/3/device/aaaa…` with `apns-topic: <bundle id>`.
Nothing leaves the machine but a signature.
