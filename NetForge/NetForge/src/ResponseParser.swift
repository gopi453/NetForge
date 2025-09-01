//
//  ResponseParser.swift
//  NetForge
//
//  Created by GPS on 28/01/25.
//

import Foundation

struct ResponseParser<Value: Decodable> {
    private let data: Data?
    private let response: URLResponse?
    private let error: Error?
    private let logger: NetworkLoggerProtocol
    
    init(data: Data?, response: URLResponse?, error: Error? = nil, logger: NetworkLoggerProtocol = DefaultNetworkLogger()) {
        self.data = data
        self.response = response
        self.error = error
        self.logger = logger
    }
   
    func parse() throws -> Value {
        if let error = error {
            throw NetworkError.response(error.localizedDescription)
        }
        if let response, !response.hasValidStatusCode {
            throw NetworkError.response(response.getStatusCodeDescription())
        }
        guard let data = data, !data.isEmpty else {
            throw NetworkError.response("No data found")
        }
        return try decode(from: data)
    }
    
    private func decode(from data: Data) throws -> Value {
        // Attempt to decode the data into the provided type
        let decoder = JSONDecoder()
        logger.log(response: response, data: data, error: error)
        return try decoder.decode(Value.self, from: data)
    }
    
}
