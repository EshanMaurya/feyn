import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Talks to the Feyn backend, which holds the model API keys.
public struct CloudTutorEngine: TutorEngine {
    public enum Failure: Error, Equatable { case badStatus(Int) }

    public var baseURL: URL
    public var session: URLSession

    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    public func makeURLRequest(for request: TutorRequest) throws -> URLRequest {
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent("v1/tutor"))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request) // Data encodes as base64
        return urlRequest
    }

    public func respond(to request: TutorRequest) async throws -> TutorReply {
        let (data, response) = try await session.data(for: makeURLRequest(for: request))
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else { throw Failure.badStatus(status) }
        return try JSONDecoder().decode(TutorReply.self, from: data)
    }
}
