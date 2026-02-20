import Foundation
import XCTest
@testable import HogBar

final class PostHogProjectsServiceTests: XCTestCase {
    override func tearDown() {
        URLProtocolStub.handler = nil
        super.tearDown()
    }

    func testAuthenticateReturnsSessionWithPreferredProjectSelection() async throws {
        URLProtocolStub.handler = { request in
            let path = request.url?.path ?? ""
            if path.contains("/api/organizations/@current") {
                let body = Data(#"{"id":"9","name":"Acme"}"#.utf8)
                return (Self.response(url: request.url, statusCode: 200), body)
            }
            if path.contains("/api/organizations/9/projects") {
                let body = Data(#"{"results":[{"id":"21","name":"Core App","organization":"9"},{"id":"22","name":"Web App","organization":"9"}]}"#.utf8)
                return (Self.response(url: request.url, statusCode: 200), body)
            }
            XCTFail("Unexpected request path \(path)")
            return (Self.response(url: request.url, statusCode: 500), Data())
        }

        let service = PostHogProjectsService(session: makeSession())
        let configuration = PostHogConfiguration(
            hostURL: URL(string: "https://us.posthog.com")!,
            apiKey: "test_key",
            activeWindowMinutes: 15,
            queryOverride: nil,
            preferredProjectID: "22"
        )

        let session = try await service.authenticate(configuration: configuration)

        XCTAssertEqual(session.projects.count, 2)
        XCTAssertEqual(session.selectedProjectID, "22")
        XCTAssertEqual(session.selectedProject?.name, "Web App")
    }

    func testAuthenticateThrowsUnauthorisedForInvalidKey() async {
        URLProtocolStub.handler = { request in
            let body = Data("{}".utf8)
            return (Self.response(url: request.url, statusCode: 401), body)
        }

        let service = PostHogProjectsService(session: makeSession())
        let configuration = PostHogConfiguration(
            hostURL: URL(string: "https://us.posthog.com")!,
            apiKey: "invalid",
            activeWindowMinutes: 15,
            queryOverride: nil,
            preferredProjectID: nil
        )

        do {
            _ = try await service.authenticate(configuration: configuration)
            XCTFail("Expected unauthorised error")
        } catch let error as PostHogProjectsServiceError {
            XCTAssertEqual(error, .unauthorised)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: configuration)
    }

    private static func response(url: URL?, statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: url ?? URL(string: "https://us.posthog.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
    }
}

final class URLProtocolStub: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
