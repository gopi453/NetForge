//
//  NetworkManager.swift
//  CyptoCoins
//
//  Created by K Gopi on 15/10/24.
//

import Foundation
import Combine

public final class NetworkManager {
    private static let sharedInstance = NetworkManager()
    private let session: URLSession
    
    class func shared() -> NetworkManager {
        return sharedInstance
    }
    
    init(session: URLSession = .shared) {
        self.session = session
    }

    @MainActor
    func makeAsyncRequest(from request: RequestBuilder) async throws -> Any {
        let urlRequest = try createURLRequest(from: request)
        let (data, response) = try await session.data(for: urlRequest)
        let responseParser = ResponseParser(data: data, response: response, decodeType: request.decodeType)
        return try responseParser.parse()
    }
    
    func makePublisherRequest(from request: RequestBuilder) throws -> AnyPublisher<Any, NetworkError> {
        do {
            let urlRequest = try createURLRequest(from: request)
            return self.session.dataTaskPublisher(for: urlRequest)
                .tryMap({ (data: Data, response: URLResponse) -> Any in
                    let responseParser = ResponseParser(data: data, response: response, decodeType: request.decodeType)
                    return try responseParser.parse()
                })
                .mapError { error in
                    (error as? NetworkError) ?? .unknown
                }
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: NetworkError.request).eraseToAnyPublisher()
        }
    }
    

    func makeRequest(from request: RequestBuilder,_ completion: @escaping (Result<Any, NetworkError>) -> Void) {
        do {
            let urlRequest = try createURLRequest(from: request)
            self.session.dataTask(with: urlRequest) { data, response, error in
                let responseParser = ResponseParser(data: data, response: response, error: error, decodeType: request.decodeType)
                do {
                    let dataObj = try responseParser.parse()
                    DispatchQueue.main.async {
                        completion(.success(dataObj))
                    }
                    
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(NetworkError.response(error.localizedDescription)))
                    }
                }
            }.resume()
        }  catch {
            completion(.failure(NetworkError.request))
        }
        
    }
}

private extension NetworkManager {
    func createURLRequest(from request: RequestBuilder) throws -> URLRequest {
        let url = try request.getURL()
        var urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: request.timeoutInterval)
        urlRequest.httpMethod = request.method.description
        urlRequest.httpBody = request.body
        urlRequest.allHTTPHeaderFields = request.headers
#if DEBUG
        print(urlRequest.toCurl())
#endif
        return urlRequest
    }
}

