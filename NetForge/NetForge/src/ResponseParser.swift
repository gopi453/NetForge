//
//  ResponseParser.swift
//  NetForge
//
//  Created by GPS on 28/01/25.
//

import Foundation

struct ResponseParser {
    private let data: Data?
    private let response: URLResponse?
    private let error: Error?
    private let decodeType: Any.Type
    
    init(data: Data?, response: URLResponse?, error: Error? = nil, decodeType: Any.Type) {
        self.data = data
        self.response = response
        self.error = error
        self.decodeType = decodeType
    }
   
    func parse() throws -> Any {
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
    
    private func decode(from data: Data) throws -> Any {
        // Attempt to decode the data into the provided type
        do {
            if let decodeType = decodeType as? Decodable.Type {
                let decoder = JSONDecoder()
                return try decoder.decode(decodeType, from: data)
            } else {
                if let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    return dictionary
                } else if let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] {
                    return array
                } else {
                    throw NetworkError.response("Parsing failed with error")
                }
            }
        } catch {
            return NetworkError.response("Parsing failed with error:\n\(error.localizedDescription)")
        }
    }
    
}
