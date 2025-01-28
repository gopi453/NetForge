//
//  NetorkErrorHandlers.swift
//  NetForge
//
//  Created by GPS on 28/01/25.
//

import Foundation

public enum NetworkError: Error {
    case request
    case response(String)
    case unknown
}
