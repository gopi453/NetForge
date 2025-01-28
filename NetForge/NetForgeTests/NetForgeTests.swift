//
//  NetForgeTests.swift
//  NetForgeTests
//
//  Created by GPS on 28/01/25.
//

import XCTest
import Combine
@testable import NetForge

struct MockDataModel: Decodable {
    let id: Int
    let name: String
}

struct MockRequestBuilder: RequestBuilder {
    var decodeType: Any.Type
    var baseURL: String? = "https://test.com"
}

final class MockURLProtocol: URLProtocol {
    static var stubResponseData: Data?
    static var stubResponse: URLResponse?
    static var stubError: Error?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true // This will intercept all requests
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        if let error = MockURLProtocol.stubError {
            self.client?.urlProtocol(self, didFailWithError: error)
        } else if let data = MockURLProtocol.stubResponseData, let response = MockURLProtocol.stubResponse {
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: data)
            self.client?.urlProtocolDidFinishLoading(self)
        }
    }
    
    override func stopLoading() {
        // No-op
    }
}

final class NetForgeTests: XCTestCase {
    
    private var networkManager: NetworkManager!
    private var mockSession: URLSession!
    private var cancellable: AnyCancellable?
    
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: configuration)
        networkManager = NetworkManager(session: mockSession)
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        networkManager = nil
        mockSession = nil
        cancellable = nil
    }
    
    // MARK: - Test makeAsycRequest
    func testMakeAsyncRequest_ShouldReturnDecodedObject_WhenRequestIsSuccessful() async throws {
        // Arrange
        let mockData = """
            { "id": 1, "name": "Test" }
            """.data(using: .utf8)!
        let requestBuilder = MockRequestBuilder(decodeType: MockDataModel.self)
        let mockResponse = HTTPURLResponse(url: URL(string: requestBuilder.baseURL!)!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        MockURLProtocol.stubResponse = mockResponse
        MockURLProtocol.stubResponseData = mockData
        
        // Act
        let decodedModel = try await networkManager.makeAsyncRequest(from: requestBuilder)
        if let decodedModel = decodedModel as? MockDataModel {
            XCTAssertEqual(decodedModel.id, 1)
            XCTAssertEqual(decodedModel.name, "Test")
        } else {
            XCTFail("Received incorrect value type")
        }
    }
    
    func testMakeAsyncRequest_ShouldReturnDict_WhenRequestIsSuccessful() async throws {
        // Arrange
        let mockData = """
            { "id": 1, "name": "Test" }
            """.data(using: .utf8)!
        let requestBuilder = MockRequestBuilder(decodeType: [String: Any].self)

        let mockResponse = HTTPURLResponse(url: URL(string: requestBuilder.baseURL!)!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        MockURLProtocol.stubResponse = mockResponse
        MockURLProtocol.stubResponseData = mockData
        
        // Act
        let decodedModel = try await networkManager.makeAsyncRequest(from: requestBuilder)
        if let decodedModel = decodedModel as? [String: Any] {
            XCTAssertEqual(decodedModel["id"] as? Int, 1)
            XCTAssertEqual(decodedModel["name"] as? String, "Test")
        } else {
            XCTFail("Received incorrect value type")
        }
    }
    
    func testMakeAsyncRequest_ShouldReturnDecodedArray_WhenRequestIsSuccessful() async throws {
        // Arrange
        let mockData = """
            [{ "id": 1, "name": "Test" }]
            """.data(using: .utf8)!
        let requestBuilder = MockRequestBuilder(decodeType: [Any].self)

        let mockResponse = HTTPURLResponse(url: URL(string: requestBuilder.baseURL!)!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        MockURLProtocol.stubResponse = mockResponse
        MockURLProtocol.stubResponseData = mockData
        
        // Act
        let decodedModel = try await networkManager.makeAsyncRequest(from: requestBuilder)
        if let decodedArray = decodedModel as? [Any], let model = decodedArray.first as? [String: Any] {
            XCTAssertEqual(model["id"] as? Int, 1)
            XCTAssertEqual(model["name"] as? String, "Test")
        } else {
            XCTFail("Received incorrect value type")
        }
    }
    
    func testMakeAsyncRequest_ShouldReturnError_WhenRequestIsFailure() async {
        // Arrange
        let mockData = "".data(using: .utf8)!
        let requestBuilder = MockRequestBuilder(decodeType: MockDataModel.self)

        let mockResponse = HTTPURLResponse(url: URL(string: requestBuilder.baseURL!)!, statusCode: 404, httpVersion: nil, headerFields: nil)
        
        MockURLProtocol.stubResponse = mockResponse
        MockURLProtocol.stubResponseData = mockData
        
        // Act
        do {
            let decodedModel = try await networkManager.makeAsyncRequest(from: requestBuilder)
            if let decodedModel = decodedModel as? MockDataModel {
                XCTAssertEqual(decodedModel.id, 1)
                XCTAssertEqual(decodedModel.name, "Test")
            } else {
                XCTFail("Received incorrect value type")
            }
        } catch {
            XCTAssertTrue(true)
        }
    }
    
    // MARK: - Test makePublisherRequest (AnyPublisher)
    func testMakePublisherRequest_ShouldReturnDecodedObject_WhenRequestIsSuccessful() {
        // Arrange
        let mockData = """
            { "id": 1, "name": "Test" }
            """.data(using: .utf8)!
        let requestBuilder = MockRequestBuilder(decodeType: MockDataModel.self)

        let mockResponse = HTTPURLResponse(url: URL(string: requestBuilder.baseURL!)!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        MockURLProtocol.stubResponse = mockResponse
        MockURLProtocol.stubResponseData = mockData
        let expectation = self.expectation(description: "Publisher completes successfully")

        // Act
        do {
            cancellable = try networkManager.makePublisherRequest(from: requestBuilder).sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    XCTFail("Request failed with error: \(error)")
                case .finished:
                    break
                }
            }, receiveValue: { value in
                if let decodedModel = value as? MockDataModel {
                    XCTAssertEqual(decodedModel.id, 1)
                    XCTAssertEqual(decodedModel.name, "Test")
                    expectation.fulfill()
                } else {
                    XCTFail("Received incorrect value type")
                }
            })
        } catch {
            XCTFail("Decoded value is not of expected type MyModel")
        }
        wait(for: [expectation], timeout: 1.0)

        
    }
    
    // MARK: - Test makeRequest (Completion Handler)
    func testMakeRequest_ShouldReturnDecodedObject_WhenRequestIsSuccessful() {
        // Arrange
        let mockData = """
            { "id": 1, "name": "Test" }
            """.data(using: .utf8)!
        let requestBuilder = MockRequestBuilder(decodeType: MockDataModel.self)

        let mockResponse = HTTPURLResponse(url: URL(string: requestBuilder.baseURL!)!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        MockURLProtocol.stubResponse = mockResponse
        MockURLProtocol.stubResponseData = mockData

        
        let expectation = XCTestExpectation(description: "Completion handler called")
        
        // Act
        networkManager.makeRequest(from: requestBuilder) { result in
            // Assert
            switch result {
            case .success(let dataObj):
                if let model = dataObj as? MockDataModel {
                    XCTAssertEqual(model.id, 1)
                    XCTAssertEqual(model.name, "Test")
                } else {
                    XCTFail("Received incorrect value type")
                }
            case .failure(let error):
                XCTFail("Request failed with error: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2)
    }
    
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
