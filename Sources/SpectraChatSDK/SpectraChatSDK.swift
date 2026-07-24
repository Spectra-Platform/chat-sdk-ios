import Foundation

public protocol SpectraChatAccessTokenProviding: Sendable {
    func accessToken() async throws -> String
}

public struct StaticSpectraChatAccessTokenProvider: SpectraChatAccessTokenProviding {
    private let token: String

    public init(token: String) {
        self.token = token
    }

    public func accessToken() async throws -> String {
        token
    }
}

public struct SpectraChatClientConfiguration: Sendable {
    public var baseURL: URL

    public init(baseURL: URL) {
        self.baseURL = baseURL
    }
}

public struct SpectraChatRoom: Codable, Equatable, Sendable {
    public var roomID: String
    public var kind: String
    public var title: String?
    public var participantUserIDs: [String]
    public var lastServerSequence: Int64
    public var lastReadServerSequence: Int64
    public var unreadCount: Int64
    public var createdAt: Date
    public var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case roomID = "room_id"
        case kind
        case title
        case participantUserIDs = "participant_user_ids"
        case lastServerSequence = "last_server_sequence"
        case lastReadServerSequence = "last_read_server_sequence"
        case unreadCount = "unread_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

public struct SpectraChatMessage: Codable, Equatable, Sendable {
    public var messageID: String
    public var roomID: String
    public var serverSequence: Int64
    public var clientMessageID: String
    public var senderUserID: String
    public var content: SpectraChatContent
    public var replyToMessageID: String?
    public var mentionedUserIDs: [String]
    public var createdAt: Date
    public var editedAt: Date?
    public var deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case messageID = "message_id"
        case roomID = "room_id"
        case serverSequence = "server_sequence"
        case clientMessageID = "client_message_id"
        case senderUserID = "sender_user_id"
        case content
        case replyToMessageID = "reply_to_message_id"
        case mentionedUserIDs = "mentioned_user_ids"
        case createdAt = "created_at"
        case editedAt = "edited_at"
        case deletedAt = "deleted_at"
    }
}

public struct SpectraChatContent: Codable, Equatable, Sendable {
    public var kind: String
    public var text: String?
    public var mediaItems: [SpectraChatMediaItem]

    public init(kind: String, text: String? = nil, mediaItems: [SpectraChatMediaItem] = []) {
        self.kind = kind
        self.text = text
        self.mediaItems = mediaItems
    }

    enum CodingKeys: String, CodingKey {
        case kind
        case text
        case mediaItems = "media_items"
    }
}

public struct SpectraChatSendContent: Codable, Equatable, Sendable {
    public var kind: String
    public var text: String?
    public var assetIDs: [String]

    public init(kind: String, text: String? = nil, assetIDs: [String] = []) {
        self.kind = kind
        self.text = text
        self.assetIDs = assetIDs
    }

    enum CodingKeys: String, CodingKey {
        case kind
        case text
        case assetIDs = "asset_ids"
    }
}

public struct SpectraChatMediaItem: Codable, Equatable, Sendable {
    public var assetID: String
    public var mimeType: String
    public var byteSize: Int64
    public var thumbnailAssetID: String?
    public var width: Int?
    public var height: Int?
    public var durationSeconds: Double?

    enum CodingKeys: String, CodingKey {
        case assetID = "asset_id"
        case mimeType = "mime_type"
        case byteSize = "byte_size"
        case thumbnailAssetID = "thumbnail_asset_id"
        case width
        case height
        case durationSeconds = "duration_seconds"
    }
}

public struct SpectraChatMediaReadURL: Codable, Equatable, Sendable {
    public var assetID: String
    public var url: URL
    public var expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case assetID = "asset_id"
        case url
        case expiresAt = "expires_at"
    }
}

public struct SpectraChatCommandEnvelope<Payload: Encodable & Sendable>: Encodable, Sendable {
    public var schemaVersion: Int
    public var eventID: String
    public var eventType: String
    public var roomID: String
    public var serverSequence: Int64?
    public var occurredAt: Date
    public var payload: Payload

    public init(
        schemaVersion: Int = 1,
        eventID: String,
        eventType: String,
        roomID: String,
        serverSequence: Int64? = nil,
        occurredAt: Date = Date(),
        payload: Payload
    ) {
        self.schemaVersion = schemaVersion
        self.eventID = eventID
        self.eventType = eventType
        self.roomID = roomID
        self.serverSequence = serverSequence
        self.occurredAt = occurredAt
        self.payload = payload
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case eventID = "event_id"
        case eventType = "event_type"
        case roomID = "room_id"
        case serverSequence = "server_sequence"
        case occurredAt = "occurred_at"
        case payload
    }
}

public struct SpectraChatSendMessage: Codable, Equatable, Sendable {
    public var clientMessageID: String
    public var content: SpectraChatSendContent
    public var replyToMessageID: String?
    public var mentionedUserIDs: [String]

    public init(
        clientMessageID: String,
        content: SpectraChatSendContent,
        replyToMessageID: String? = nil,
        mentionedUserIDs: [String] = []
    ) {
        self.clientMessageID = clientMessageID
        self.content = content
        self.replyToMessageID = replyToMessageID
        self.mentionedUserIDs = mentionedUserIDs
    }

    enum CodingKeys: String, CodingKey {
        case clientMessageID = "client_message_id"
        case content
        case replyToMessageID = "reply_to_message_id"
        case mentionedUserIDs = "mentioned_user_ids"
    }
}

public struct SpectraChatReadCursorUpdate: Codable, Equatable, Sendable {
    public var lastReadServerSequence: Int64

    public init(lastReadServerSequence: Int64) {
        self.lastReadServerSequence = lastReadServerSequence
    }

    enum CodingKeys: String, CodingKey {
        case lastReadServerSequence = "last_read_server_sequence"
    }
}

public struct SpectraChatErrorResponse: Codable, Equatable, Sendable {
    public var code: String
    public var message: String
    public var retryable: Bool
    public var requestID: String?

    enum CodingKeys: String, CodingKey {
        case code
        case message
        case retryable
        case requestID = "request_id"
    }
}

public enum SpectraChatError: Error, Equatable, Sendable {
    case invalidBaseURL
    case invalidResponse
    case httpStatus(Int, SpectraChatErrorResponse?)
}

public final class SpectraChatClient: @unchecked Sendable {
    private let configuration: SpectraChatClientConfiguration
    private let tokenProvider: any SpectraChatAccessTokenProviding
    private let urlSession: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        configuration: SpectraChatClientConfiguration,
        tokenProvider: any SpectraChatAccessTokenProviding,
        urlSession: URLSession = .shared
    ) {
        self.configuration = configuration
        self.tokenProvider = tokenProvider
        self.urlSession = urlSession
        self.encoder = JSONEncoder.spectraChatEncoder
        self.decoder = JSONDecoder.spectraChatDecoder
    }

    public func listRooms(limit: Int? = nil) async throws -> [SpectraChatRoom] {
        var query: [URLQueryItem] = []
        if let limit {
            query.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        let request = try await makeRequest(url: url(path: "/v1/chat/rooms", queryItems: query), method: "GET")
        let response: RoomsResponse = try await decodeDataResponse(request: request, expectedStatus: 200)
        return response.rooms
    }

    public func createDirectRoom(participantUserID: String) async throws -> SpectraChatRoom {
        let request = try await makeJSONRequest(
            url: url(path: "/v1/chat/rooms/direct"),
            method: "POST",
            body: ["participant_user_id": participantUserID]
        )
        return try await decodeDataResponse(request: request, expectedStatus: 201)
    }

    public func createGroupRoom(title: String, participantUserIDs: [String]) async throws -> SpectraChatRoom {
        let request = try await makeJSONRequest(
            url: url(path: "/v1/chat/rooms/group"),
            method: "POST",
            body: GroupCreateRequest(title: title, participantUserIDs: participantUserIDs)
        )
        return try await decodeDataResponse(request: request, expectedStatus: 201)
    }

    public func listMessages(
        roomID: String,
        beforeSequence: Int64? = nil,
        limit: Int? = nil
    ) async throws -> [SpectraChatMessage] {
        var query: [URLQueryItem] = []
        if let beforeSequence {
            query.append(URLQueryItem(name: "before_sequence", value: String(beforeSequence)))
        }
        if let limit {
            query.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        let request = try await makeRequest(
            url: url(path: "/v1/chat/rooms/\(encodedPathSegment(roomID))/messages", queryItems: query),
            method: "GET"
        )
        let response: MessagesResponse = try await decodeDataResponse(request: request, expectedStatus: 200)
        return response.messages
    }

    public func updateReadCursor(roomID: String, lastReadServerSequence: Int64) async throws {
        let request = try await makeJSONRequest(
            url: url(path: "/v1/chat/rooms/\(encodedPathSegment(roomID))/read-cursor"),
            method: "PUT",
            body: SpectraChatReadCursorUpdate(lastReadServerSequence: lastReadServerSequence)
        )
        _ = try await decodeDataResponse(request: request, expectedStatus: 200) as EmptyData
    }

    public func readMediaURLs(roomID: String, assetIDs: [String]) async throws -> [SpectraChatMediaReadURL] {
        let request = try await makeJSONRequest(
            url: url(path: "/v1/chat/rooms/\(encodedPathSegment(roomID))/media/read-urls"),
            method: "POST",
            body: ["asset_ids": assetIDs]
        )
        let response: MediaReadURLsResponse = try await decodeDataResponse(request: request, expectedStatus: 200)
        return response.assets
    }

    public func makeTextMessageCommand(
        roomID: String,
        text: String,
        clientMessageID: String = UUID().uuidString,
        eventID: String = UUID().uuidString,
        mentionedUserIDs: [String] = [],
        replyToMessageID: String? = nil
    ) -> SpectraChatCommandEnvelope<SpectraChatSendMessage> {
        SpectraChatCommandEnvelope(
            eventID: eventID,
            eventType: "message.send",
            roomID: roomID,
            payload: SpectraChatSendMessage(
                clientMessageID: clientMessageID,
                content: SpectraChatSendContent(kind: "text", text: text),
                replyToMessageID: replyToMessageID,
                mentionedUserIDs: mentionedUserIDs
            )
        )
    }

    public func makeReadCursorCommand(
        roomID: String,
        lastReadServerSequence: Int64,
        eventID: String = UUID().uuidString
    ) -> SpectraChatCommandEnvelope<SpectraChatReadCursorUpdate> {
        SpectraChatCommandEnvelope(
            eventID: eventID,
            eventType: "read_cursor.update",
            roomID: roomID,
            payload: SpectraChatReadCursorUpdate(lastReadServerSequence: lastReadServerSequence)
        )
    }

    public func socketURL() throws -> URL {
        guard var components = URLComponents(url: configuration.baseURL, resolvingAgainstBaseURL: false) else {
            throw SpectraChatError.invalidBaseURL
        }
        components.scheme = components.scheme == "https" ? "wss" : "ws"
        let basePath = components.percentEncodedPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let prefix = basePath.isEmpty ? "" : "/\(basePath)"
        components.percentEncodedPath = "\(prefix)/v1/socket"
        components.queryItems = nil
        guard let url = components.url else {
            throw SpectraChatError.invalidBaseURL
        }
        return url
    }

    private func makeRequest(url: URL, method: String) async throws -> URLRequest {
        let token = try await tokenProvider.accessToken()
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func makeJSONRequest<Body: Encodable>(url: URL, method: String, body: Body) async throws -> URLRequest {
        var request = try await makeRequest(url: url, method: method)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        return request
    }

    private func decodeDataResponse<T: Decodable>(request: URLRequest, expectedStatus: Int) async throws -> T {
        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SpectraChatError.invalidResponse
        }
        guard http.statusCode == expectedStatus else {
            throw SpectraChatError.httpStatus(http.statusCode, decodeError(from: data))
        }
        return try decoder.decode(DataEnvelope<T>.self, from: data).data
    }

    private func decodeError(from data: Data) -> SpectraChatErrorResponse? {
        try? decoder.decode(ErrorEnvelope.self, from: data).error
    }

    private func url(path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        guard var components = URLComponents(url: configuration.baseURL, resolvingAgainstBaseURL: false) else {
            throw SpectraChatError.invalidBaseURL
        }
        let basePath = components.percentEncodedPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let prefix = basePath.isEmpty ? "" : "/\(basePath)"
        components.percentEncodedPath = "\(prefix)\(path)"
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components.url else {
            throw SpectraChatError.invalidBaseURL
        }
        return url
    }
}

private struct DataEnvelope<T: Decodable>: Decodable {
    var data: T
}

private struct ErrorEnvelope: Decodable {
    var error: SpectraChatErrorResponse
}

private struct RoomsResponse: Decodable {
    var rooms: [SpectraChatRoom]
}

private struct MessagesResponse: Decodable {
    var messages: [SpectraChatMessage]
}

private struct MediaReadURLsResponse: Decodable {
    var assets: [SpectraChatMediaReadURL]
}

private struct EmptyData: Decodable {}

private struct GroupCreateRequest: Encodable {
    var title: String
    var participantUserIDs: [String]

    enum CodingKeys: String, CodingKey {
        case title
        case participantUserIDs = "participant_user_ids"
    }
}

private func encodedPathSegment(_ value: String) -> String {
    var allowed = CharacterSet.urlPathAllowed
    allowed.remove(charactersIn: "/?#[]@!$&'()*+,;=:")
    return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
}

private extension JSONDecoder {
    static var spectraChatDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            let fractional = ISO8601DateFormatter()
            fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fractional.date(from: value) {
                return date
            }
            let standard = ISO8601DateFormatter()
            standard.formatOptions = [.withInternetDateTime]
            if let date = standard.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO8601 date: \(value)")
        }
        return decoder
    }
}

private extension JSONEncoder {
    static var spectraChatEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
