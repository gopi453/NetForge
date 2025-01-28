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

    func makeAsyncRequest<T: Decodable>(from request: RequestBuilder, decodeType: T.Type) async throws -> T {
         let request = try createURLRequest(from: request)
        #if DEBUG
        print(request.toCurl())
        #endif
        let (data, response) = try await session.data(for: request)
        guard !data.isEmpty, response.hasValidStatusCode else {
            throw NetworkError.response
        }
        let decodedData = try JSONDecoder().decode(decodeType, from: data)
        return decodedData
    }
    
    func makeRequest<T: Decodable>(from request: RequestBuilder, decodeType: T.Type) throws -> AnyPublisher<T, NetworkError> {
        do {
            let request = try createURLRequest(from: request)
#if DEBUG
            print(request.toCurl())
#endif
            return self.session.dataTaskPublisher(for: request)
                .tryMap({ (data: Data, response: URLResponse) -> T in
                    if response.hasValidStatusCode {
                        do {
                            let decodedData = try JSONDecoder().decode(decodeType, from: data)
                            return decodedData
                        } catch {
                            throw NetworkError.response
                        }
                    } else {
                        throw NetworkError.response
                    }
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
}

private extension NetworkManager {
    func createURLRequest(from request: RequestBuilder) throws -> URLRequest {
        let url = try request.getURL()
        var urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: request.timeoutInterval)
        urlRequest.httpMethod = request.method.description
        urlRequest.httpBody = request.body
        urlRequest.allHTTPHeaderFields = request.headers
        return urlRequest
    }
}

