import Foundation

/// Something that happened during an explanation session.
public enum SessionEvent: Sendable, Equatable {
    /// A finalized chunk of transcribed speech.
    case speech(String, at: TimeInterval)
    /// The learner has been silent for `duration` seconds.
    case silence(duration: TimeInterval, at: TimeInterval)
    /// The learner tapped "done" / said they finished.
    case explanationEnded(at: TimeInterval)
}

/// Decides whether the tutor should respond after an event, given the current mode.
public struct InterventionPolicy: Sendable {
    public var mode: InterventionMode
    /// Silence needed before responding in `.onPause` mode.
    public var pauseThreshold: TimeInterval
    /// Minimum words of new speech before a `.live` interjection.
    public var liveMinNewWords: Int
    /// Minimum seconds between two `.live` interjections.
    public var liveCooldown: TimeInterval

    private var wordsSinceLastReply = 0
    private var lastReplyAt: TimeInterval?

    public init(
        mode: InterventionMode,
        pauseThreshold: TimeInterval = 2.5,
        liveMinNewWords: Int = 25,
        liveCooldown: TimeInterval = 15
    ) {
        self.mode = mode
        self.pauseThreshold = pauseThreshold
        self.liveMinNewWords = liveMinNewWords
        self.liveCooldown = liveCooldown
    }

    /// Feed an event; returns true when the tutor should respond now.
    public mutating func shouldRespond(after event: SessionEvent) -> Bool {
        let respond: Bool
        switch event {
        case let .speech(text, at):
            wordsSinceLastReply += text.split(whereSeparator: \.isWhitespace).count
            let cooledDown = lastReplyAt.map { at - $0 >= liveCooldown } ?? true
            respond = mode == .live && wordsSinceLastReply >= liveMinNewWords && cooledDown
            if respond { markReplied(at: at) }
        case let .silence(duration, at):
            respond = mode == .onPause && duration >= pauseThreshold && wordsSinceLastReply > 0
            if respond { markReplied(at: at) }
        case let .explanationEnded(at):
            respond = wordsSinceLastReply > 0 || mode == .endOfExplanation
            if respond { markReplied(at: at) }
        }
        return respond
    }

    private mutating func markReplied(at time: TimeInterval) {
        wordsSinceLastReply = 0
        lastReplyAt = time
    }
}
