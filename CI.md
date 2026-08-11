# CI/CD

Pushing to `main` builds the iOS app and uploads it to TestFlight —
`.github/workflows/ios-testflight.yml`. The run can also be started by hand from
the **Actions** tab, which is how to retry an upload without an empty commit.

The pipeline analyzes and tests before it archives, so a build that cannot pass
`flutter analyze` or `flutter test` never reaches a tester.

## One-time setup

### 1. Create an App Store Connect API key

App Store Connect → **Users and Access** → **Integrations** → **App Store
Connect API** → **+**.

Give it the **App Manager** role. Admin also works. Developer does **not** — the
build signs itself with `-allowProvisioningUpdates`, which needs permission to
create a distribution certificate and provisioning profile, and a Developer-role
key is refused.

Download the `.p8`. Apple lets you download it exactly once.

### 2. Add three repository secrets

GitHub → **Settings** → **Secrets and variables** → **Actions** → **New
repository secret**.

| Secret | Where it comes from |
| --- | --- |
| `APP_STORE_CONNECT_KEY_ID` | The **Key ID** column, e.g. `2X9ABC3DEF` |
| `APP_STORE_CONNECT_ISSUER_ID` | **Issuer ID**, shown above the key table — a UUID, the same for every key in the account |
| `APP_STORE_CONNECT_PRIVATE_KEY` | The entire contents of the `.p8`, including the `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----` lines |

Paste the `.p8` exactly as downloaded. Do not base64-encode it and do not strip
the newlines — the workflow writes it back out verbatim.

No certificate or provisioning profile goes into GitHub. That is deliberate: the
API key is the only credential, it is written outside the workspace, and it is
deleted in a step that runs even when the build fails.

### 3. Nothing else

The team ID (`B5GMQ7S6F8`) is already committed in the Xcode project and
`ios/ExportOptions.plist`, and signing is set to Automatic. The Firebase config
files are tracked, so the runner needs no extra files.

## Version and build numbers

The **version name** comes from `pubspec.yaml` and is a deliberate act — bump it
when the release deserves it.

The **build number** is computed by the workflow as `100 + run_number`, because
App Store Connect rejects a build number it has seen before and nobody should
have to hand-edit a file before every merge. The offset clears `48`, the highest
number uploaded manually, so the automated sequence never collides with the
manual era.

To move to a new marketing version, edit `version:` in `pubspec.yaml` and leave
the `+NN` alone — CI overrides it.

## Known gate

Until **Push Notifications** is enabled on the App ID at developer.apple.com,
the archive step can fail: `Runner.entitlements` declares `aps-environment`, and
a profile cannot carry an entitlement the App ID does not have.
`-allowProvisioningUpdates` will usually enable the capability itself when the
key has App Manager rights, but if the archive fails with an entitlement or
profile error, enable it by hand and re-run — that is the first thing to check.

## Adding Android later

The same shape works for Play internal testing: swap the archive/export steps
for `flutter build appbundle --release`, and upload with
`r0adkll/upload-google-play`. It needs the upload keystore (base64) and a Play
service-account JSON as secrets — more credentials than the iOS job, which is
why iOS came first.
