//
//  File.swift
//  
//
//  Created by Miguel Ridruejo on 3/12/23.
//

import Foundation

public enum HTTPMethods:String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

public enum AuthorizationMethod: String {
    case token = "Bearer"
    case basic = "Basic"
}

struct VaporError: Codable {
    let error: Bool
    let reason: String
}

public extension URLRequest {
    static func get(url: URL, token: String? = nil, authMethod: AuthorizationMethod = .token, language: String = "en") -> URLRequest {
        var request = URLRequest(url: url)
        if let token {
            request.setValue("\(authMethod.rawValue) \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpMethod = HTTPMethods.get.rawValue
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(language, forHTTPHeaderField: "Accept-Language") // Add language header
        return request
    }

    
    static func put(url: URL, data: Data, token: String? = nil, authMethod: AuthorizationMethod = .token, language: String = "en") -> URLRequest {
        var request = URLRequest(url: url)
        if let token = token {
            request.setValue("\(authMethod.rawValue) \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpMethod = HTTPMethods.put.rawValue
        request.timeoutInterval = 30
        request.setValue(language, forHTTPHeaderField: "Accept-Language") // Add language header
        request.httpBody = data
        return request
    }
    
    static func post<JSON:Codable>(url: URL, data: JSON, method: HTTPMethods = .post,
                                   token: String? = nil, authMethod: AuthorizationMethod = .token, language: String = "en",
                                   encoder: JSONEncoder = JSONEncoder()) -> URLRequest {
        var request = URLRequest(url: url)
        if let token {
            request.setValue("\(authMethod.rawValue) \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpMethod = method.rawValue
        request.timeoutInterval = 30
        request.setValue("application/json; charset=utf8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(language, forHTTPHeaderField: "Accept-Language") // Add language header
        request.httpBody = try? encoder.encode(data)
        return request
    }
    
    static func delete<JSON: Encodable>(
        url: URL,
        data: JSON? = nil, // Allow optional data, but DELETE usually doesn't contain a body
        token: String? = nil,
        authMethod: AuthorizationMethod = .token, language: String = "en",
        encoder: JSONEncoder = JSONEncoder()
    ) throws -> URLRequest {
        var request = URLRequest(url: url)
        if let token = token {
            request.setValue("\(authMethod.rawValue) \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpMethod = HTTPMethods.delete.rawValue
        request.timeoutInterval = 30
        request.setValue("application/json; charset=utf8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(language, forHTTPHeaderField: "Accept-Language") // Add language header
        // For DELETE requests, omit setting the httpBody as it's usually empty
        return request
    }
    
    static func postMultiPart(url: URL, name: String? = nil, username: String? = nil, image: Data, method: HTTPMethods = .post,
                              token: String? = nil, authMethod: AuthorizationMethod = .token, language: String = "en",
                              encoder: JSONEncoder = JSONEncoder()) throws -> URLRequest {
        var request = URLRequest(url: url)
        if let token {
            request.setValue("\(authMethod.rawValue) \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpMethod = method.rawValue
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let boundary = UUID().uuidString
        let clrf = "\r\n"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        if let name {
            // Set boundary before the first field
            body.append("--\(boundary)\(clrf)")
            body.append("Content-Disposition: form-data; name=\"name\"\(clrf + clrf)")
            body.append("\(name)\(clrf)")
        }
        
        if let username {
            // Set boundary before the second field
            body.append("--\(boundary)\(clrf)")
            body.append("Content-Disposition: form-data; name=\"username\"\(clrf + clrf)")
            body.append("\(username)\(clrf)")
        }
        
        // Add image data if available
        body.append("--\(boundary)\(clrf)")
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\(clrf)")
        body.append("Content-Type: image/jpeg\(clrf + clrf)")
        body.append(image)
        body.append(clrf)
        
        // End boundary
        body.append("--\(boundary)--\(clrf)")
        
        request.httpBody = body
        
        return request
    }
}
