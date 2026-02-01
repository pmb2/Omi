# Agent Zero Wake Integration (Fork Customization)

This fork adds optional client-side wake handling so the Omi app can open a URL
in the default browser when a wake phrase is detected in live transcripts.

## What It Does
- Listens to live transcript segments on the device.
- If a wake phrase is detected, opens the configured URL in the default browser.
- Works alongside the existing "Real-Time Transcript Processing" webhook.

## Setup
1) Open the Omi app and go to:
   Settings -> Developer Settings
2) Configure:
   - Real-Time Transcript Processing: set your webhook URL (for the bridge).
   - Agent Zero URL: the page to open on wake (example: https://agent.backus.agency).
   - Wake Phrases: comma-separated list (example: "hey agent, hey agent zero").
3) Tap Save.

## Notes
- Wake detection is transcript-based (no audio-level detection).
- The app uses the default browser (`LaunchMode.externalApplication`).
- A short cooldown prevents duplicate opens from the same utterance.
- This fork seeds defaults on first launch (wake URL, phrases, and transcript webhook).
- If the secondary Omi backend socket drops, the app tags webhook payloads with
  `fallback_to_omi=true` so Agent Zero can forward transcripts back to the Omi
  backend for storage.
- The app always includes `forward_to_omi=true` and `omi_auth_header` (Bearer
  token) when available so Agent Zero can forward transcripts to Omi even when
  custom STT is used.

