//
//  URLRequest+Extension.swift
//  NetForge
//
//  Created by GPS on 28/01/25.
//

import Foundation

extension URLRequest {

    /// Generates a cURL command equivalent from the URLRequest.
    /// - Returns: A String representation of the cURL command.
    func toCurl() -> String {
        var curlString = "curl"

        // Add HTTP method if it's not GET (GET is default in cURL)
        if let httpMethod = self.httpMethod, httpMethod != "GET" {
            curlString += " -X \(httpMethod)"
        }

        // Add URL
        if let url = self.url {
            curlString += " '\(url.absoluteString)'"
        }

        // Add headers
        for (header, value) in self.allHTTPHeaderFields ?? [:] {
            let escapedHeader = header.replacingOccurrences(of: "'", with: "'\\''")
            let escapedValue = value.replacingOccurrences(of: "'", with: "'\\''")
            curlString += " -H '\(escapedHeader): \(escapedValue)'"
        }

        // Add body (for POST/PUT requests or others with a body)
        if let body = self.httpBody,
           let jsonString = String(data: body, encoding: .utf8) {
                let escapedBody = jsonString.replacingOccurrences(of: "'", with: "'\\''")
                curlString += " --data '\(escapedBody)'"
        }

        return curlString
    }
}

extension URLResponse {
    var hasValidStatusCode: Bool {
        guard let httpResponse = self as? HTTPURLResponse, (200...299) ~= httpResponse.statusCode else {
            return false
        }
        return true
    }
}
