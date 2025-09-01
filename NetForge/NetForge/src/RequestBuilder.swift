//
//  RequestBuilder.swift
//  NetForge
//
//  Created by GPS on 28/01/25.
//

import Foundation

public enum HTTPMethod: String, CustomStringConvertible {
    case get, post, patch, put, delete
    public var description: String {
        self.rawValue.uppercased()
    }
}

public protocol RequestBuilder: Sendable {
    var baseURL: String? { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var timeoutInterval: TimeInterval { get }
    var body: Data? { get set }
    var queryItems: [URLQueryItem]? { get }
    var headers: [String: String] { get }    
}

public extension RequestBuilder {
    var baseURL: String? { nil }
    var path: String { "" }
    var method: HTTPMethod { .get }
    var timeoutInterval: TimeInterval { 15 }
    var body: Data? { nil }
    var queryItems: [URLQueryItem]? { nil }
    var headers: [String: String] { ["Content-Type": "application/json"] }
}

extension RequestBuilder {
    func getURL() throws -> URL {
        guard let baseURL else { throw NetworkError.request }
        var components = URLComponents(string: baseURL + path)
        components?.queryItems = queryItems
        guard let url = components?.url else { throw NetworkError.request }
        return url
    }
}
