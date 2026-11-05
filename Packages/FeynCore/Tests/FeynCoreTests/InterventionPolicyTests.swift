import Foundation
import Testing
@testable import FeynCore

private let longSpeech = Array(repeating: "word", count: 30).joined(separator: " ")

@Test func liveRespondsAfterEnoughWordsAndCooldown() {
    var policy = InterventionPolicy(mode: .live, liveMinNewWords: 25, liveCooldown: 15)
    #expect(policy.shouldRespond(after: .speech("too short", at: 1)) == false)
    #expect(policy.shouldRespond(after: .speech(longSpeech, at: 2)) == true)
    // Enough words again, but still inside the cooldown window.
    #expect(policy.shouldRespond(after: .speech(longSpeech, at: 10)) == false)
    #expect(policy.shouldRespond(after: .speech(longSpeech, at: 20)) == true)
}

@Test func onPauseWaitsForSilenceAfterSpeech() {
    var policy = InterventionPolicy(mode: .onPause, pauseThreshold: 2.5)
    #expect(policy.shouldRespond(after: .silence(duration: 5, at: 0)) == false) // nothing said yet
    #expect(policy.shouldRespond(after: .speech(longSpeech, at: 1)) == false)
    #expect(policy.shouldRespond(after: .silence(duration: 1, at: 2)) == false)
    #expect(policy.shouldRespond(after: .silence(duration: 3, at: 4)) == true)
}

@Test func endOfExplanationStaysQuietUntilDone() {
    var policy = InterventionPolicy(mode: .endOfExplanation)
    #expect(policy.shouldRespond(after: .speech(longSpeech, at: 1)) == false)
    #expect(policy.shouldRespond(after: .silence(duration: 10, at: 2)) == false)
    #expect(policy.shouldRespond(after: .explanationEnded(at: 3)) == true)
}

@Test func cloudRequestEncodesCanvasAsBase64() throws {
    let engine = CloudTutorEngine(baseURL: URL(string: "https://feyn.example")!)
    let request = TutorRequest(topic: "Entropy", mode: .onPause, newSpeech: "hi",
                               canvasPNG: Data([0x89, 0x50]))
    let urlRequest = try engine.makeURLRequest(for: request)
    #expect(urlRequest.url?.absoluteString == "https://feyn.example/v1/tutor")
    #expect(urlRequest.httpMethod == "POST")
    let json = try JSONSerialization.jsonObject(with: urlRequest.httpBody!) as! [String: Any]
    #expect(json["canvasPNG"] as? String == "iVA=")
    #expect(json["mode"] as? String == "onPause")
}
