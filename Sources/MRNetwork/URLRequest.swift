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
    static func get(url:URL, token:String? = nil, authMethod:AuthorizationMethod = .token) -> URLRequest {
        var request = URLRequest(url: url)
        if let token {
            request.setValue("\(authMethod.rawValue) \(token)",
                             forHTTPHeaderField: "Authorization")
        }
        request.httpMethod = HTTPMethods.get.rawValue
        request.timeoutInterval = 30
        request.setValue("application/json",
                         forHTTPHeaderField: "Accept")
        return request
    }
    
    static func post<JSON:Codable>(url: URL, data: JSON, method: HTTPMethods = .post,
                                   token: String? = nil, authMethod: AuthorizationMethod = .token,
                                   encoder: JSONEncoder = JSONEncoder()) -> URLRequest {
        var request = URLRequest(url: url)
        if let token {
            request.setValue("\(authMethod.rawValue) \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpMethod = method.rawValue
        request.timeoutInterval = 30
        request.setValue("application/json; charset=utf8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try? encoder.encode(data)
        return request
    }
    
    static func delete<JSON: Encodable>(
        url: URL,
        data: JSON? = nil, // Allow optional data, but DELETE usually doesn't contain a body
        token: String? = nil,
        authMethod: AuthorizationMethod = .token,
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
        // For DELETE requests, omit setting the httpBody as it's usually empty
        return request
    }
    
    static func postMultiPart<JSON: Codable>(url: URL, profileData: JSON, imageData: Data?, method: HTTPMethods = .post,
                                             token: String? = nil, authMethod: AuthorizationMethod = .token,
                                             encoder: JSONEncoder = JSONEncoder()) throws -> URLRequest {
        var request = URLRequest(url: url)
        if let token {
            request.setValue("\(authMethod.rawValue) \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpMethod = method.rawValue
        request.timeoutInterval = 30
        let boundary = UUID().uuidString
        let clrf = "\r\n"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add profile data
        guard let jsonData = try? encoder.encode(profileData), let userDataJSONString = String(data: jsonData, encoding: .utf8) else {
            throw NetworkError.unknown
        }
        body.append("--\(boundary + clrf)")
        body.append("Content-Disposition: form-data; name=\"profileData\"\(clrf)")
        body.append("Content-Type: application/json\(clrf + clrf)")
        body.append(userDataJSONString)
        body.append(clrf)
        
        // Add image data if available
        if let imageData = imageData {
            body.append("--\(boundary + clrf)")
            body.append("Content-Disposition: form-data; name=\"imageData\"; filename=\"profile.jpg\"\(clrf)")
            body.append("Content-Type: image/jpeg\(clrf + clrf)")
            body.append(imageData)
            body.append(clrf)
        }
        
        body.append("--\(boundary)--\(clrf)")
        
        request.httpBody = body
        
        return request
    }

}
