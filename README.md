# Smart Safety Badge — Guardian UI

This build recreates the Guardian UI shown in the supplied UI video. The existing login screen is retained. After login, the app provides five working sections:

- Home — device status, battery/signal/location, safe-area card, alert statistics and 2-second SOS.
- Health — device health, live/demo heart rate and the 150 BPM alert threshold.
- Alerts — expandable alert cards and new-alert state.
- Recordings — recording cards, waveform and play/pause demo interaction.
- Profile — device information, guardian list, add/remove guardian, alert settings, safe-area settings and sign out.

## Run

```powershell
flutter pub get
flutter run -d chrome
```

For Android after Android SDK setup:

```powershell
flutter devices
flutter run
```

## Demo behaviour

- The login screen is the existing project login screen.
- In demo mode, any non-empty email/password can enter the Guardian app because Firebase is disabled.
- Holding SOS for 2 seconds creates a new SOS alert.
- `Test 150 BPM` creates a high-heart-rate alert using the project threshold of 150 BPM.
- Recording play buttons simulate playback and waveform progress; a real audio file/recorder can be connected later.
- The map is a dependency-free visual map preview for the prototype; real device GPS/cloud location can be connected later.

## Hardware/cloud boundary

The UI logic is ready for the ESP32/BLE and Firebase layers, but real sensor readings, GPS, audio files and cloud notifications require the actual hardware credentials/protocol and Firebase project configuration. No secret Firebase Admin credential is placed in the Flutter client.
