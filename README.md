# BLE Workbench for iOS

A native SwiftUI BLE inspection and test-stand starter app.

## Current features

- Foreground BLE scan and RSSI list.
- Connect to a user-selected peripheral and enumerate GATT services/characteristics.
- Display standard characteristic properties and allow explicit reads of readable values.
- Make the iPhone advertise one fixed demo GATT service with read/write/notify behavior.
- Keep a short in-memory event log for the demo peripheral.

The app does not send writes to discovered devices, issue lock/unlock commands, read device credentials, modify network settings, or flash firmware. Scanning and test-stand advertisement are foreground-only. The demo stand is intended for testing a BLE client you own, preferably with a second device.

## Generate the Xcode project on macOS

```sh
brew install xcodegen
xcodegen generate
open BLEWorkbench.xcodeproj
```

The project targets iOS 26+ and uses SwiftUI Liquid Glass effects. The local Linux environment cannot run Xcode. GitHub Actions builds an unsigned device IPA on a macOS runner. Download the `BLEWorkbench-unsigned-ipa` artifact from a completed Actions run and open it in Impactor to sign and install it. A free Apple account generally needs the app refreshed every 7 days.
