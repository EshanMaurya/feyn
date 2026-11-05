# Feyn

Learn by explaining. Feyn applies the **Feynman technique**: you explain a concept out loud
while writing on your iPad, and an AI tutor listens, looks at your canvas, and responds
(spoken aloud) with Socratic questions and corrections where your understanding is shaky.

## Architecture

| Part | Where | What |
| --- | --- | --- |
| iOS / iPadOS app | `App/` (Xcode, SwiftUI) | PencilKit canvas, on-device speech-to-text, spoken replies, SwiftData + CloudKit sync |
| Core logic | `Packages/FeynCore` (Swift package) | Intervention modes, tutor engine interface, cloud client. No Apple-only frameworks, so it builds and tests on Linux too |
| Backend | `backend/` (Cloudflare Worker, TypeScript) | Holds model API keys; `POST /v1/tutor` calls a cheap cloud model (Claude Haiku 5.5 by default) |

**Intervention modes** (user-toggled): `live` (interjects mid-explanation), `onPause`
(waits for a pause), `endOfExplanation` (critiques when you're done).

**Engines:** `TutorEngine` is a protocol. `CloudTutorEngine` talks to the backend today; on-device
engines (Apple Foundation Models, MLX vision models on M-series iPads) plug in later behind the
same interface.

## Develop

```bash
# Core package
cd Packages/FeynCore && swift test

# Backend
cd backend && npm ci && npm test && npm run typecheck
echo 'ANTHROPIC_API_KEY=...' > .dev.vars   # local only, git-ignored
npm run dev
```

The app target is built in Xcode on a Mac; see `App/README.md`.
