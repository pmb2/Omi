# Omi Android build + Agent Zero integration (custom fork)

This document captures the custom build setup for the Omi Android app and how it integrates with Agent Zero.

## Repos and remotes

- Fork: https://github.com/pmb2/Omi
- Upstream: https://github.com/BasedHardware/omi

Recommended remotes:

```
git remote add upstream https://github.com/BasedHardware/omi.git
```

Update flow (keep our custom commits on top):

```
git fetch upstream
# Option A: rebase
# git checkout main
# git rebase upstream/main
# Option B: merge
# git merge upstream/main
```

## Local environment prerequisites

- Flutter SDK (stable)
- Android SDK / Android Studio (JDK bundled is fine)
- Firebase CLI + FlutterFire CLI
- `adb` in PATH

## Firebase setup (per machine)

Firebase files are gitignored; generate them locally per developer machine.

1) Login:

```
firebase login
```

2) Configure project:

```
cd app
flutterfire configure --out=lib/firebase_options_prod.dart --ios-bundle-id=com.friend-app-with-wearable.ios12 --android-app-id=com.friend.ios --android-out=android/app/src/prod/ --ios-out=ios/Config/Prod/
flutterfire configure --out=lib/firebase_options_dev.dart --ios-bundle-id=com.friend-app-with-wearable.ios12.develop --android-app-id=com.friend.ios.dev --android-out=android/app/src/dev/ --ios-out=ios/Config/Dev/
```

## App config

`.dev.env` is local-only (gitignored). Example:

```
API_BASE_URL=https://api.omiapi.com/
```

If env fields change, regenerate:

```
dart run build_runner build --delete-conflicting-outputs
```

## Build & install (Android)

From `app/`:

```
flutter pub get
flutter build apk --flavor dev --dart-define=FLAVOR=dev
```

Install to device:

```
adb install -r build/app/outputs/flutter-apk/app-dev-release.apk
```

## Custom STT provider (local Whisper)

In the Omi app:

- Settings → Transcription → **Cloud Provider** → **Custom**
- WebSocket URL: `wss://stt.backus.agency/omi`
- Save and reconnect

## Agent Zero integration

### 1) Webhook (real-time transcript)

In Settings → Developer Settings:

- **Real‑time Transcript** URL: use the pairing link from Agent Zero settings.

### 2) Wake phrase auto‑open

In Settings → Developer Settings:

- **Open URL on wake**: `https://agent.backus.agency`
- **Wake phrases**: `hey agent, hey agent zero`

When a wake phrase is detected in live transcripts, the app opens the default browser to the Agent Zero UI.

## OTA and updates

- The Omi device receives OEM OTA updates independently of this app.
- App updates are handled by building a new APK from this fork and installing over the existing app.
- To stay current with OEM app changes, rebase/merge from upstream (see remotes section) and resolve any conflicts in our customization layer.

## Notes

- This fork uses `https://github.com/pmb2/whisper_flutter_new.git` to avoid a UTF‑8 parsing issue in the upstream pubspec.

## Smoke test checklist

- App launches on device and connects to pendant.
- Transcription settings connect to `wss://stt.backus.agency/omi`.
- Agent Zero UI shows `Omi:` status.
- Clicking `Omi:` opens Settings and scrolls to Omi section.
- Wake phrase opens Agent Zero in the default browser.
