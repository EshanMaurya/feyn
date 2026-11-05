import Foundation

/// One turn of the tutoring conversation.
public struct TutorTurn: Codable, Sendable, Equatable {
    public enum Role: String, Codable, Sendable { case learner, tutor }
    public var role: Role
    public var text: String
    public init(role: Role, text: String) { self.role = role; self.text = text }
}

/// Everything the tutor sees when deciding what to say.
public struct TutorRequest: Codable, Sendable, Equatable {
    /// What the learner is explaining, e.g. "Bernoulli's principle".
    public var topic: String
    public var mode: InterventionMode
    /// Earlier turns (learner speech chunks and tutor replies).
    public var history: [TutorTurn]
    /// New speech since the tutor last spoke.
    public var newSpeech: String
    /// PNG snapshot of the canvas, if any.
    public var canvasPNG: Data?

    public init(topic: String, mode: InterventionMode, history: [TutorTurn] = [],
                newSpeech: String, canvasPNG: Data? = nil) {
        self.topic = topic
        self.mode = mode
        self.history = history
        self.newSpeech = newSpeech
        self.canvasPNG = canvasPNG
    }
}

/// What the tutor says back (spoken aloud by the app).
public struct TutorReply: Codable, Sendable, Equatable {
    public enum Kind: String, Codable, Sendable {
        case question, correction, encouragement
    }
    public var kind: Kind
    public var text: String
    public init(kind: Kind, text: String) { self.kind = kind; self.text = text }
}

/// A source of tutor replies: cloud model now, on-device models later.
public protocol TutorEngine: Sendable {
    func respond(to request: TutorRequest) async throws -> TutorReply
}
