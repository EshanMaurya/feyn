/// When the tutor is allowed to speak up. The user toggles between these.
public enum InterventionMode: String, Codable, Sendable, CaseIterable {
    /// Interrupt mid-explanation, like a live tutor.
    case live
    /// Wait for a natural pause in speech.
    case onPause
    /// Stay quiet until the learner says they are done.
    case endOfExplanation
}
