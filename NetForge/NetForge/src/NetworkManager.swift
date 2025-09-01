//
//  NetworkManager.swift
//  NetForge
//
//  Created by K Gopi on 15/10/24.
//

import Foundation
import Combine

public protocol NetworkManagerProtocol {
    func sendAsyncRequest<T: Decodable>(from request: RequestBuilder) async throws -> T
    func sendPublisherRequest<T: Decodable>(from request: RequestBuilder) throws -> AnyPublisher<T, NetworkError>
    func sendRequest<T: Decodable>(from request: RequestBuilder,_ completion: @escaping @Sendable (Result<T, NetworkError>) -> Void)
}

public final class NetworkManager: NetworkManagerProtocol {
    
    private let session: URLSession
    
    private let logger: NetworkLoggerProtocol
    
    public init(session: URLSession = .shared, logger: NetworkLoggerProtocol = DefaultNetworkLogger()) {
        self.session = session
        self.logger = logger
    }
    
    //MARK: - Request Methods
    public func sendRequest<T>(from request: any RequestBuilder, _ completion: @escaping @Sendable (Result<T, NetworkError>) -> Void) where T : Decodable {
        do {
            let urlRequest = try createURLRequest(from: request)
            self.session.dataTask(with: urlRequest) { data, response, error in
                let responseParser = ResponseParser<T>(data: data, response: response, error: error)
                do {
                    let dataObj = try responseParser.parse()
                    completion(.success(dataObj))
                } catch {
                    completion(.failure(NetworkError.response(error.localizedDescription)))
                }
            }.resume()
        }  catch {
            completion(.failure(NetworkError.request))
        }
    }
    
    public func sendAsyncRequest<T>(from request: any RequestBuilder) async throws -> T where T : Decodable {
        let urlRequest = try createURLRequest(from: request)
        let (data, response) = try await session.data(for: urlRequest)
        let responseParser = ResponseParser<T>(data: data, response: response)
        return try responseParser.parse()
    }
    
    public func sendPublisherRequest<T>(from request: any RequestBuilder) throws -> AnyPublisher<T, NetworkError> where T : Decodable {
        let urlRequest = try createURLRequest(from: request)
        return self.session.dataTaskPublisher(for: urlRequest)
            .tryCompactMap({ (data: Data, response: URLResponse) -> T in
                let responseParser = ResponseParser<T>(data: data, response: response)
                return try responseParser.parse()
            })
            .mapError { error in
                (error as? NetworkError) ?? .unknown
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
}

private extension NetworkManager {
    func createURLRequest(from request: RequestBuilder) throws -> URLRequest {
        let url = try request.getURL()
        var urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: request.timeoutInterval)
        urlRequest.httpMethod = request.method.description
        urlRequest.httpBody = request.body
        urlRequest.allHTTPHeaderFields = request.headers
        logger.log(request: urlRequest)
        logger.toCurl(for: urlRequest)
        return urlRequest
    }
}

