//
//  OverlayFetcherTests.swift
//  SCRLCanvasPrototype_Tests
//
//  Created by Sergey Slobodenyuk on 2025-03-15.
//

import Foundation

import Testing
@testable import SCRLCanvasPrototype

class StubURLProtocol: URLProtocol {

    static var stubResponseData: Data?
    static var stubResponse: HTTPURLResponse?
    static var error: Error?

    override class func canInit(with request: URLRequest) -> Bool {
        // Intercept all network requests
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        if let error = StubURLProtocol.error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            if let response = StubURLProtocol.stubResponse {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }

            if let data = StubURLProtocol.stubResponseData {
                client?.urlProtocol(self, didLoad: data)
            }

            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}
}

@Suite(.serialized)
struct OverlayFetcherTests {

    @Test
    func testOverlayFetcher_FetchesDataSuccessfully() async throws {
        let mockJSON = """
        [
            {
                "title": "Category 1",
                "id": 1,
                "items": [
                    {
                        "id": 1,
                        "overlay_name": "MockOverlay",
                        "source_url": "https://example.com/mock.png"
                    }
                ]
            }
        ]
        """

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: config)

        StubURLProtocol.stubResponse = HTTPURLResponse(url: URL(string: "https://dummy-url.com")!,
                                                       statusCode: 200, httpVersion: nil, headerFields: nil)
        StubURLProtocol.stubResponseData = mockJSON.data(using: .utf8)
        StubURLProtocol.error = nil

        // Inject dummy URL that matches the stubbed response
        let fetcher = OverlayFetcher(urlSession: session, overlayURL: URL(string: "https://dummy-url.com")!)
        let overlays = try await fetcher.fetchOverlays()

        #expect(overlays.count == 1, "OverlayFetcher should return one overlay")
        #expect(overlays.first?.name == "MockOverlay", "Overlay name should be 'MockOverlay'")
    }

    @Test
    func testOverlayFetcher_HandlesNetworkError() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: config)

        StubURLProtocol.stubResponseData = nil
        StubURLProtocol.stubResponse = nil
        StubURLProtocol.error = URLError(.notConnectedToInternet)

        let fetcher = OverlayFetcher(urlSession: session, overlayURL: URL(string: "https://dummy-url.com")!)

        do {
            _ = try await fetcher.fetchOverlays()
            #expect(Bool(false), "Expected fetchOverlays to throw an error")
        } catch {
            #expect((error as? URLError)?.code == .notConnectedToInternet, "Should return URLError.notConnectedToInternet")
        }
    }
}
