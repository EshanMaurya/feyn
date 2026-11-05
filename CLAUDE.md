# Feyn

- `Packages/FeynCore`: platform-neutral Swift. Do not import UIKit/SwiftUI/PencilKit/Speech here, so
  it keeps building on Linux. Test: `cd Packages/FeynCore && swift test`.
- `backend/`: Cloudflare Worker (TypeScript). Test: `cd backend && npm test && npm run typecheck`.
  The model call is in `src/tutor.ts`; tests inject a fake client, so they need no API key.
- `App/`: Xcode project, built only on macOS. Cloud sessions run Linux and cannot build it.
- The request/response JSON shape is shared: keep `TutorRequest`/`TutorReply` in
  `Packages/FeynCore/Sources/FeynCore/TutorEngine.swift` and the zod schemas in
  `backend/src/tutor.ts` in sync.
