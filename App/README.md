# Feyn app (Xcode)

The iOS/iPadOS app target lives here. It must be created and built in Xcode on a Mac:

1. Xcode → File → New → Project → iOS App, name **Feyn**, interface SwiftUI, storage SwiftData,
   and save it into this `App/` folder.
2. File → Add Package Dependencies → Add Local… → select `Packages/FeynCore`.
3. Signing & Capabilities: add **iCloud** (CloudKit) for sync, and add the
   microphone and speech recognition usage descriptions to Info.plist.

Planned frameworks: PencilKit (canvas), Speech / SpeechAnalyzer (on-device transcription),
AVSpeechSynthesizer (spoken replies), SwiftData + CloudKit (synced sessions).
