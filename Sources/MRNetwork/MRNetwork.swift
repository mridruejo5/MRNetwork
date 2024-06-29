// The Swift Programming Language
// https://docs.swift.org/swift-book


import SwiftUI

public final class MRNetwork {
    public static let shared = MRNetwork()
    
    public func getJSON<JSON:Codable>(request:URLRequest, type:JSON.Type, decoder:JSONDecoder = JSONDecoder()) async throws -> JSON {
        let (data, response) = try await URLSession.shared.dataRequest(for: request)
        guard let response = response as? HTTPURLResponse else { throw NetworkError.noHTTP }
        if response.statusCode == 200 {
            do {
                return try decoder.decode(JSON.self, from: data)
            } catch {
                throw NetworkError.json(error)
            }
        } else {
            throw NetworkError.status(response.statusCode)
        }
    }
    
    public func getJSONV<JSON:Codable>(request:URLRequest, type:JSON.Type,
                                       decoder:JSONDecoder = JSONDecoder(),
                                       statusOK:Int = 200) async throws -> JSON {
        let (data, response) = try await URLSession.shared.dataRequest(for: request)
        guard let response = response as? HTTPURLResponse else { throw NetworkError.noHTTP }
        if response.statusCode == statusOK {
            do {
                return try decoder.decode(JSON.self, from: data)
            } catch {
                throw NetworkError.json(error)
            }
        } else {
            throw NetworkError.vapor(try JSONDecoder().decode(VaporError.self, from: data).reason, response.statusCode)
        }
    }
    
    public func post(request:URLRequest, statusOK:Int = 200) async throws {
        let (_, response) = try await URLSession.shared.dataRequest(for: request)
        guard let response = response as? HTTPURLResponse else { throw NetworkError.noHTTP }
        if response.statusCode != statusOK {
            throw NetworkError.status(response.statusCode)
        }
    }
    
    public func postV(request:URLRequest, statusOK:Int = 200) async throws {
        let (data, response) = try await URLSession.shared.dataRequest(for: request)
        guard let response = response as? HTTPURLResponse else { throw NetworkError.noHTTP }
        if response.statusCode != statusOK {
            throw NetworkError.vapor(try JSONDecoder().decode(VaporError.self, from: data).reason, response.statusCode)
        }
    }

    public func postVMultipart(request: URLRequest, statusOK: Int = 200) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                // Check if there's an error
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                // Ensure the response is an HTTPURLResponse
                guard let response = response as? HTTPURLResponse else {
                    continuation.resume(throwing: NetworkError.noHTTP)
                    return
                }

                // Check if the status code is as expected
                if response.statusCode != statusOK {
                    if let data = data {
                        do {
                            let vaporError = try JSONDecoder().decode(VaporError.self, from: data)
                            continuation.resume(throwing: NetworkError.vapor(vaporError.reason, response.statusCode))
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    } else {
                        continuation.resume(throwing: NetworkError.unknown)
                    }
                    return
                }

                // If everything is fine, complete the continuation successfully
                continuation.resume(returning: ())
            }

            // Start the URLSession task
            task.resume()
        }
    }

    // Function to upload image using presigned URL
    public func uploadImageWithPresignedURL(url: URL, imageData: Data, statusOK: Int = 200) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethods.put.rawValue
        request.httpBody = imageData
        
        let (data, response) = try await URLSession.shared.dataRequest(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError.noHTTP }
        
        if httpResponse.statusCode != statusOK {
            throw NetworkError.status(httpResponse.statusCode)
        }
    }

    public func deleteV(request:URLRequest, statusOK:Int = 200) async throws {
        let (data, response) = try await URLSession.shared.dataRequest(for: request)
        guard let response = response as? HTTPURLResponse else { throw NetworkError.noHTTP }
        if response.statusCode != statusOK {
            throw NetworkError.vapor(try JSONDecoder().decode(VaporError.self, from: data).reason, response.statusCode)
        }
    }
    
    #if os(iOS)
    public func getImage(request:URLRequest) async throws -> UIImage {
        let (data, response) = try await URLSession.shared.dataRequest(for: request)
        guard let response = response as? HTTPURLResponse else { throw NetworkError.noHTTP }
        if response.statusCode == 200 {
            if let image = UIImage(data: data) {
                return image
            } else {
                throw NetworkError.dataNotValid
            }
        } else {
            throw NetworkError.status(response.statusCode)
        }
    }
    #endif
    
    #if os(iOS)
    public func getImage2(url:URL) async throws -> UIImage {
        let (data, response) = try await URLSession.shared.dataRequest(from: url)
        guard let response = response as? HTTPURLResponse else { throw NetworkError.noHTTP }
        if response.statusCode == 200 {
            if let image = UIImage(data: data) {
                return image
            } else {
                throw NetworkError.dataNotValid
            }
        } else {
            throw NetworkError.status(response.statusCode)
        }
    }
    #endif
    
    #if os(iOS)
    public func postImage(request:URLRequest, statusOK:Int = 200) async throws {
        let (data, response) = try await URLSession.shared.dataRequest(for: request)
        guard let response = response as? HTTPURLResponse else { throw NetworkError.noHTTP }
        if response.statusCode != statusOK {
            throw NetworkError.vapor(try JSONDecoder().decode(VaporError.self, from: data).reason, response.statusCode)
        }
    }
    #endif
}
