//
//  NetworkLogger.swift
//  NetForge
//
//  Created by GPS on 01/09/25.
//

import Foundation

public protocol NetworkLoggerProtocol {
    func toCurl(for request: URLRequest)
    func log(request: URLRequest)
    func log(response: URLResponse?, data: Data?, error: Error?)
}

final public class DefaultNetworkLogger: NetworkLoggerProtocol {
    
    public init() { }
    /// Generates a cURL command equivalent from the URLRequest.
    /// - Returns: A String representation of the cURL command.
    public func toCurl(for request: URLRequest) {
        #if DEBUG
        //pretty printed
        
        guard let url = request.url else { return }
        
        print("\n🐚 ====== cURL REQUEST ======")

        var components: [String] = ["curl"]
        
        // Method
        if let method = request.httpMethod {
            components.append("-X \(method)")
        }
        
        // Headers
        if let headers = request.allHTTPHeaderFields {
            for (key, value) in headers {
                components.append("-H \"\(key): \(value)\"")
            }
        }
        
        // Body
        if let bodyData = request.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            components.append("-d '\(bodyString)'")
        }
        
        // URL
        components.append("\"\(url.absoluteString)\"")
        
        // Output
        let output = components.joined(separator: " \\\n    ")
        print(output)
        print("🐚 ====================\n")
        #endif
    }
    
    public func log(request: URLRequest) {
        #if DEBUG
        print("\n🟢 ====== REQUEST ======")
        
        // URL + Method
        print("➡️ \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        
        // Headers
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            print("📩 Headers:")
            for (key, value) in headers {
                print("   \(key): \(value)")
            }
        }
        
        // Body
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            print("📦 Body:\n\(bodyString)")
        }
        
        print("🟢 ====================\n")
        #endif
    }
    
    public func log(response: URLResponse?, data: Data?, error: Error?) {
        #if DEBUG
        print("\n🔵 ====== RESPONSE ======")
        
        if let error = error {
            print("❌ Error: \(error.localizedDescription)")
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            print("🌐 Status Code: \(httpResponse.statusCode)")
            print("📍 URL: \(httpResponse.url?.absoluteString ?? "")")
            
            // Headers
            print("📩 Headers:")
            for (key, value) in httpResponse.allHeaderFields {
                print("   \(key): \(value)")
            }
        }
        
        // Body
        if let data = data {
            if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                print("📦 Body:\n\(prettyString)")
            } else if let rawString = String(data: data, encoding: .utf8) {
                print("📦 Body:\n\(rawString)")
            } else {
                print("📦 Body: (binary, \(data.count) bytes)")
            }
        }
        
        print("🔵 =====================\n")
        #endif
    }
}
