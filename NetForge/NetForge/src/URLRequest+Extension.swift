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
        //        var curlString = "curl"
        //
        //        // Add HTTP method if it's not GET (GET is default in cURL)
        //        if let httpMethod = self.httpMethod, httpMethod != "GET" {
        //            curlString += " -X \(httpMethod)"
        //        }
        //
        //        // Add URL
        //        if let url = self.url {
        //            curlString += " '\(url.absoluteString)'"
        //        }
        //
        //        // Add headers
        //        for (header, value) in self.allHTTPHeaderFields ?? [:] {
        //            let escapedHeader = header.replacingOccurrences(of: "'", with: "'\\''")
        //            let escapedValue = value.replacingOccurrences(of: "'", with: "'\\''")
        //            curlString += " -H '\(escapedHeader): \(escapedValue)'"
        //        }
        //
        //        // Add body (for POST/PUT requests or others with a body)
        //        if let body = self.httpBody,
        //           let jsonString = String(data: body, encoding: .utf8) {
        //                let escapedBody = jsonString.replacingOccurrences(of: "'", with: "'\\''")
        //                curlString += " --data '\(escapedBody)'"
        //        }
        //
        //        return curlString
        
        //pretty printed
        guard let url = self.url else { return "" }
        
        var components: [String] = ["curl"]
        
        // Method
        if let method = self.httpMethod {
            components.append("-X \(method)")
        }
        
        // Headers
        if let headers = self.allHTTPHeaderFields {
            for (key, value) in headers {
                components.append("-H \"\(key): \(value)\"")
            }
        }
        
        // Body
        if let bodyData = self.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            components.append("-d '\(bodyString)'")
        }
        
        // URL
        components.append("\"\(url.absoluteString)\"")
        
        // Output
        return components.joined(separator: " \\\n    ")
    }
}

extension URLResponse {
    
    func getStatusCode() -> Int {
        guard let httpResponse = self as? HTTPURLResponse else {
            return 0
        }
        return httpResponse.statusCode
    }
    
    func getStatusCodeDescription() -> String {
        guard let httpResponse = self as? HTTPURLResponse else {
            return ""
        }
        return HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
    }
    
    var hasValidStatusCode: Bool {
        
        guard (200...299) ~= getStatusCode() else {
            return false
        }
        return true
    }
}
