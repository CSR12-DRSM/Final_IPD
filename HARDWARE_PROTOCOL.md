# Smart Safety Badge - Hardware/BLE Contract

This document is the contract between the ESP32 firmware and the Flutter app.

## BLE role

- ESP32 badge = BLE Peripheral
- Flutter phone = BLE Central

The Flutter app uses `flutter_blue_plus`.

## Service UUID

12345678-1234-1234-1234-1234567890AB

## Telemetry characteristic

12345678-1234-1234-1234-1234567890AC

Properties:

- Notify

The badge sends UTF-8 JSON.

Example:

```json
{
  "bpm": 150,
  "battery": 86,
  "lat": 40.7128,
  "lng": -74.0060,
  "serial": "SN30001234567",
  "firmware": "1.2.5"
}
```

## Command characteristic

12345678-1234-1234-1234-1234567890AD

Properties:

- Write

Possible future commands:

```text
PING
BRING_BADGE
SOS_TEST
REQUEST_STATUS
```

## Threshold

The Flutter app treats:

```text
BPM >= 150
```

as the configured alert condition.

For a real product, the hardware should also implement its own local safety behavior so that an alert does not depend entirely on the phone being connected.

## Cloud

Recommended production flow:

ESP32 --BLE--> Phone --authenticated--> Firebase

Avoid putting a Firebase Admin credential or other private service secret in the ESP32 firmware.

If the badge must connect directly to the internet, use device-specific authentication and a backend endpoint.
