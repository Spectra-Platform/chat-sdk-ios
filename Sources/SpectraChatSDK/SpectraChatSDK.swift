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
    public var socketURL: URL?
    public var projectId: String?

    public init(baseURL: URL, socketURL: URL? = nil, projectId: String? = nil) {
        self.baseURL = baseURL
        self.socketURL = socketURL
        self.projectId = projectId
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
    public var storageObjectReferences: [SpectraChatStorageObjectReference]?

    public init(
        kind: String,
        text: String? = nil,
        mediaItems: [SpectraChatMediaItem] = [],
        storageObjectReferences: [SpectraChatStorageObjectReference]? = nil
    ) {
        self.kind = kind
        self.text = text
        self.mediaItems = mediaItems
        self.storageObjectReferences = storageObjectReferences
    }

    enum CodingKeys: String, CodingKey {
        case kind
        case text
        case mediaItems = "media_items"
        case storageObjectReferences = "storage_object_references"
    }
}

public struct SpectraChatSendContent: Codable, Equatable, Sendable {
    public var kind: String
    public var text: String?
    public var assetIDs: [String]
    public var storageObjectReferences: [SpectraChatStorageObjectReference]?

    public init(
        kind: String,
        text: String? = nil,
        assetIDs: [String] = [],
        storageObjectReferences: [SpectraChatStorageObjectReference]? = nil
    ) {
        self.kind = kind
        self.text = text
        self.assetIDs = assetIDs
        self.storageObjectReferences = storageObjectReferences
    }

    enum CodingKeys: String, CodingKey {
        case kind
        case text
        case assetIDs = "asset_ids"
        case storageObjectReferences = "storage_object_references"
    }
}

public struct SpectraChatStorageObjectReference: Codable, Equatable, Sendable {
    public var objectKey: String
    public var contentType: String?
    public var byteSize: Int64?
    public var checksumSHA256: String?
    public var metadata: [String: String]

    public init(
        objectKey: String,
        contentType: String? = nil,
        byteSize: Int64? = nil,
        checksumSHA256: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.objectKey = objectKey
        self.contentType = contentType
        self.byteSize = byteSize
        self.checksumSHA256 = checksumSHA256
        self.metadata = metadata
    }

    enum CodingKeys: String, CodingKey {
        case objectKey = "object_key"
        case contentType = "content_type"
        case byteSize = "byte_size"
        case checksumSHA256 = "checksum_sha256"
        case metadata
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

public struct SpectraChatTypingSet: Codable, Equatable, Sendable {
    public var isTyping: Bool

    public init(isTyping: Bool) {
        self.isTyping = isTyping
    }

    enum CodingKeys: String, CodingKey {
        case isTyping = "is_typing"
    }
}

public struct SpectraChatReadCursorUpdated: Equatable, Sendable {
    public var roomID: String
    public var userID: String
    public var lastReadServerSequence: Int64

    public init(roomID: String, userID: String, lastReadServerSequence: Int64) {
        self.roomID = roomID
        self.userID = userID
        self.lastReadServerSequence = lastReadServerSequence
    }
}

public struct SpectraChatTypingUpdated: Equatable, Sendable {
    public var roomID: String
    public var userID: String
    public var isTyping: Bool

    public init(roomID: String, userID: String, isTyping: Bool) {
        self.roomID = roomID
        self.userID = userID
        self.isTyping = isTyping
    }
}

public struct SpectraChatServerError: Error, Equatable, Sendable {
    public var requestEventID: String?
    public var code: String
    public var message: String
    public var retryable: Bool

    public init(requestEventID: String?, code: String, message: String, retryable: Bool) {
        self.requestEventID = requestEventID
        self.code = code
        self.message = message
        self.retryable = retryable
    }
}

public enum SpectraChatRealtimeConnectionState: Equatable, Sendable {
    case connecting
    case connected
    case reconnecting(attempt: Int)
    case disconnected
}

public enum SpectraChatRealtimeEvent: Equatable, Sendable {
    case connectionChanged(SpectraChatRealtimeConnectionState)
    case messageCreated(SpectraChatMessage)
    case readCursorUpdated(SpectraChatReadCursorUpdated)
    case typingUpdated(SpectraChatTypingUpdated)
    case callLifecycle(SpectraChatCallLifecycleEvent)
    case serverError(SpectraChatServerError)
    case unknown(eventType: String)
}

public enum SpectraChatRealtimeError: Error, Equatable, Sendable {
    case disconnected
    case acknowledgementTimedOut
    case server(SpectraChatServerError)
}

public enum SpectraChatCallEventType: String, CaseIterable, Codable, Sendable {
    case invited = "call.invited"
    case accepted = "call.accepted"
    case declined = "call.declined"
    case joined = "call.joined"
    case left = "call.left"
    case ended = "call.ended"
    case missed = "call.missed"

    public var isLifecycleEvent: Bool { true }
}

public struct SpectraChatCallActor: Codable, Equatable, Sendable {
    public var appUserID: String

    public init(appUserID: String) {
        self.appUserID = appUserID
    }

    enum CodingKeys: String, CodingKey {
        case appUserID = "app_user_id"
    }
}

public struct SpectraChatCallSummary: Codable, Equatable, Sendable {
    public var callID: String
    public var callSessionID: String?
    public var status: String
    public var mediaMode: String
    public var callType: String
    public var endedReason: String?

    public init(
        callID: String,
        callSessionID: String? = nil,
        status: String,
        mediaMode: String,
        callType: String,
        endedReason: String? = nil
    ) {
        self.callID = callID
        self.callSessionID = callSessionID
        self.status = status
        self.mediaMode = mediaMode
        self.callType = callType
        self.endedReason = endedReason
    }

    enum CodingKeys: String, CodingKey {
        case callID = "call_id"
        case callSessionID = "call_session_id"
        case status
        case mediaMode = "media_mode"
        case callType = "call_type"
        case endedReason = "ended_reason"
    }
}

public struct SpectraChatCallParticipant: Codable, Equatable, Sendable {
    public var participantID: String?
    public var appUserID: String
    public var state: String

    public init(
        participantID: String? = nil,
        appUserID: String,
        state: String
    ) {
        self.participantID = participantID
        self.appUserID = appUserID
        self.state = state
    }

    enum CodingKeys: String, CodingKey {
        case participantID = "participant_id"
        case appUserID = "app_user_id"
        case state
    }
}

public struct SpectraChatCallTrace: Codable, Equatable, Sendable {
    public var messageID: String?
    public var clientReferenceID: String?

    public init(messageID: String? = nil, clientReferenceID: String? = nil) {
        self.messageID = messageID
        self.clientReferenceID = clientReferenceID
    }

    enum CodingKeys: String, CodingKey {
        case messageID = "message_id"
        case clientReferenceID = "client_reference_id"
    }
}

public struct SpectraChatCallLifecycleEvent: Decodable, Equatable, Sendable {
    public var eventID: String
    public var eventType: SpectraChatCallEventType
    public var eventVersion: String?
    public var projectID: String?
    public var conversationID: String
    public var roomID: String
    public var serverSequence: Int64
    public var occurredAt: Date
    public var actor: SpectraChatCallActor?
    public var call: SpectraChatCallSummary
    public var participants: [SpectraChatCallParticipant]
    public var trace: SpectraChatCallTrace?

    /// Chat socket call events intentionally carry lifecycle references only.
    /// Media transport credentials such as WebRTC SDP/ICE, LiveKit participant tokens,
    /// TURN credentials, RTP data, and provider secrets must be fetched through CallSDK/Call API.
    public var carriesMediaTransportCredential: Bool { false }

    enum CodingKeys: String, CodingKey {
        case eventID = "event_id"
        case eventType = "event_type"
        case eventVersion = "event_version"
        case projectID = "project_id"
        case conversationID = "conversation_id"
        case roomID = "room_id"
        case serverSequence = "server_sequence"
        case occurredAt = "occurred_at"
        case actor
        case call
        case participant
        case participants
        case trace
    }

    public init(
        eventID: String,
        eventType: SpectraChatCallEventType,
        eventVersion: String? = nil,
        projectID: String? = nil,
        conversationID: String,
        roomID: String,
        serverSequence: Int64 = 0,
        occurredAt: Date,
        actor: SpectraChatCallActor? = nil,
        call: SpectraChatCallSummary,
        participants: [SpectraChatCallParticipant] = [],
        trace: SpectraChatCallTrace? = nil
    ) {
        self.eventID = eventID
        self.eventType = eventType
        self.eventVersion = eventVersion
        self.projectID = projectID
        self.conversationID = conversationID
        self.roomID = roomID
        self.serverSequence = serverSequence
        self.occurredAt = occurredAt
        self.actor = actor
        self.call = call
        self.participants = participants
        self.trace = trace
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        eventID = try container.decode(String.self, forKey: .eventID)
        eventType = try container.decode(SpectraChatCallEventType.self, forKey: .eventType)
        eventVersion = try container.decodeIfPresent(String.self, forKey: .eventVersion)
        projectID = try container.decodeIfPresent(String.self, forKey: .projectID)
        conversationID = try container.decode(String.self, forKey: .conversationID)
        roomID = try container.decode(String.self, forKey: .roomID)
        serverSequence = try container.decodeIfPresent(Int64.self, forKey: .serverSequence) ?? 0
        occurredAt = try Self.decodeDate(container, forKey: .occurredAt)
        actor = try container.decodeIfPresent(SpectraChatCallActor.self, forKey: .actor)
        call = try container.decode(SpectraChatCallSummary.self, forKey: .call)
        if let participants = try container.decodeIfPresent(
            [SpectraChatCallParticipant].self,
            forKey: .participants
        ) {
            self.participants = participants
        } else if let participant = try container.decodeIfPresent(
            SpectraChatCallParticipant.self,
            forKey: .participant
        ) {
            self.participants = [participant]
        } else {
            self.participants = []
        }
        trace = try container.decodeIfPresent(SpectraChatCallTrace.self, forKey: .trace)
    }

    public static func decode(from data: Data) throws -> SpectraChatCallLifecycleEvent {
        try JSONDecoder.spectraChatDecoder.decode(SpectraChatCallLifecycleEvent.self, from: data)
    }

    private static func decodeDate(
        _ container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) throws -> Date {
        let rawValue = try container.decode(String.self, forKey: key)
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: rawValue) {
            return date
        }
        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]
        if let date = standard.date(from: rawValue) {
            return date
        }
        throw DecodingError.dataCorruptedError(
            forKey: key,
            in: container,
            debugDescription: "Invalid ISO8601 date: \(rawValue)"
        )
    }
}

public struct SpectraChatCreateRoomRequest: Codable, Equatable, Sendable {
    public var kind: String
    public var title: String?
    public var participantUserIDs: [String]

    public init(kind: String, title: String? = nil, participantUserIDs: [String]) {
        self.kind = kind
        self.title = title
        self.participantUserIDs = participantUserIDs
    }

    enum CodingKeys: String, CodingKey {
        case kind
        case title
        case participantUserIDs = "participant_user_ids"
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
    case invalidRequest(String)
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

    public func createRoom(_ input: SpectraChatCreateRoomRequest) async throws -> SpectraChatRoom {
        switch input.kind {
        case "direct":
            guard let participantUserID = input.participantUserIDs.first else {
                throw SpectraChatError.invalidRequest("direct room requires one participant user id")
            }
            return try await createDirectRoom(participantUserID: participantUserID)
        case "group":
            return try await createGroupRoom(title: input.title ?? "", participantUserIDs: input.participantUserIDs)
        default:
            let request = try await makeJSONRequest(
                url: url(path: "/v1/chat/rooms"),
                method: "POST",
                body: input
            )
            return try await decodeDataResponse(request: request, expectedStatus: 201)
        }
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

    public func sendMessage(
        roomID: String,
        content: SpectraChatSendContent,
        clientMessageID: String = UUID().uuidString,
        replyToMessageID: String? = nil,
        mentionedUserIDs: [String] = [],
        idempotencyKey: String? = nil
    ) async throws -> SpectraChatMessage {
        let request = try await makeJSONRequest(
            url: url(path: "/v1/chat/rooms/\(encodedPathSegment(roomID))/messages"),
            method: "POST",
            idempotencyKey: idempotencyKey,
            body: SpectraChatSendMessage(
                clientMessageID: clientMessageID,
                content: content,
                replyToMessageID: replyToMessageID,
                mentionedUserIDs: mentionedUserIDs
            )
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

    public func markRead(roomID: String, lastReadServerSequence: Int64) async throws {
        try await updateReadCursor(roomID: roomID, lastReadServerSequence: lastReadServerSequence)
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

    public func makeTypingCommand(
        roomID: String,
        isTyping: Bool,
        eventID: String = UUID().uuidString
    ) -> SpectraChatCommandEnvelope<SpectraChatTypingSet> {
        SpectraChatCommandEnvelope(
            eventID: eventID,
            eventType: "typing.set",
            roomID: roomID,
            payload: SpectraChatTypingSet(isTyping: isTyping)
        )
    }

    public func socketURL() throws -> URL {
        if let socketURL = configuration.socketURL {
            return socketURL
        }
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

    public func socketRequest() async throws -> URLRequest {
        try await makeRequest(url: socketURL(), method: "GET")
    }

    private func makeRequest(url: URL, method: String, idempotencyKey: String? = nil) async throws -> URLRequest {
        let token = try await tokenProvider.accessToken()
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let projectId = configuration.projectId {
            request.setValue(projectId, forHTTPHeaderField: "X-Spectra-Project-Id")
        }
        if let idempotencyKey {
            request.setValue(idempotencyKey, forHTTPHeaderField: "Idempotency-Key")
        }
        return request
    }

    private func makeJSONRequest<Body: Encodable>(
        url: URL,
        method: String,
        idempotencyKey: String? = nil,
        body: Body
    ) async throws -> URLRequest {
        var request = try await makeRequest(url: url, method: method, idempotencyKey: idempotencyKey)
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

public actor SpectraChatRealtimeClient {
    private let client: SpectraChatClient
    private let urlSession: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let acknowledgementTimeoutNanoseconds: UInt64

    private var socketTask: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var subscribers: [UUID: AsyncStream<SpectraChatRealtimeEvent>.Continuation] = [:]
    private var pendingMessages: [String: PendingMessage] = [:]
    private var pendingRequestToClientMessage: [String: String] = [:]
    private var reconnectAttempt = 0
    private var intentionallyDisconnected = false

    private struct PendingMessage {
        let requestEventID: String
        let continuation: CheckedContinuation<SpectraChatMessage, Error>
    }

    public init(
        configuration: SpectraChatClientConfiguration,
        tokenProvider: any SpectraChatAccessTokenProviding,
        urlSession: URLSession = .shared,
        acknowledgementTimeoutNanoseconds: UInt64 = 10_000_000_000
    ) {
        self.client = SpectraChatClient(
            configuration: configuration,
            tokenProvider: tokenProvider,
            urlSession: urlSession
        )
        self.urlSession = urlSession
        self.encoder = JSONEncoder.spectraChatEncoder
        self.decoder = JSONDecoder.spectraChatDecoder
        self.acknowledgementTimeoutNanoseconds = acknowledgementTimeoutNanoseconds
    }

    public init(
        client: SpectraChatClient,
        urlSession: URLSession = .shared,
        acknowledgementTimeoutNanoseconds: UInt64 = 10_000_000_000
    ) {
        self.client = client
        self.urlSession = urlSession
        self.encoder = JSONEncoder.spectraChatEncoder
        self.decoder = JSONDecoder.spectraChatDecoder
        self.acknowledgementTimeoutNanoseconds = acknowledgementTimeoutNanoseconds
    }

    public func events() -> AsyncStream<SpectraChatRealtimeEvent> {
        let subscriberID = UUID()
        let (stream, continuation) = AsyncStream<SpectraChatRealtimeEvent>.makeStream()
        subscribers[subscriberID] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(subscriberID) }
        }
        Task {
            do {
                try await self.connect()
            } catch {
                self.yield(.connectionChanged(.disconnected))
            }
        }
        return stream
    }

    public func connect() async throws {
        if socketTask != nil { return }
        intentionallyDisconnected = false
        yield(.connectionChanged(.connecting))
        let request = try await client.socketRequest()
        let task = urlSession.webSocketTask(with: request)
        socketTask = task
        task.resume()
        receiveTask = Task { await self.receiveLoop(task) }
    }

    public func disconnect() {
        intentionallyDisconnected = true
        reconnectTask?.cancel()
        reconnectTask = nil
        receiveTask?.cancel()
        receiveTask = nil
        socketTask?.cancel(with: .goingAway, reason: nil)
        socketTask = nil
        failAllPending(with: SpectraChatRealtimeError.disconnected)
        yield(.connectionChanged(.disconnected))
    }

    @discardableResult
    public func sendTextMessage(
        roomID: String,
        text: String,
        clientMessageID: String = UUID().uuidString,
        replyToMessageID: String? = nil,
        mentionedUserIDs: [String] = []
    ) async throws -> SpectraChatMessage {
        try await sendMessage(
            roomID: roomID,
            content: SpectraChatSendContent(kind: "text", text: text),
            clientMessageID: clientMessageID,
            replyToMessageID: replyToMessageID,
            mentionedUserIDs: mentionedUserIDs
        )
    }

    @discardableResult
    public func sendMessage(
        roomID: String,
        content: SpectraChatSendContent,
        clientMessageID: String = UUID().uuidString,
        replyToMessageID: String? = nil,
        mentionedUserIDs: [String] = []
    ) async throws -> SpectraChatMessage {
        try await connect()
        let eventID = UUID().uuidString
        let command = SpectraChatCommandEnvelope(
            eventID: eventID,
            eventType: "message.send",
            roomID: roomID,
            payload: SpectraChatSendMessage(
                clientMessageID: clientMessageID,
                content: content,
                replyToMessageID: replyToMessageID,
                mentionedUserIDs: mentionedUserIDs
            )
        )
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                pendingMessages[clientMessageID] = PendingMessage(
                    requestEventID: eventID,
                    continuation: continuation
                )
                pendingRequestToClientMessage[eventID] = clientMessageID
                Task {
                    do {
                        try await self.send(command)
                        try await Task.sleep(nanoseconds: self.acknowledgementTimeoutNanoseconds)
                        self.expirePendingMessage(clientMessageID)
                    } catch is CancellationError {
                        self.cancelPendingMessage(clientMessageID)
                    } catch {
                        self.failPendingMessage(clientMessageID, error: error)
                    }
                }
            }
        } onCancel: {
            Task { await self.cancelPendingMessage(clientMessageID) }
        }
    }

    public func updateReadCursor(roomID: String, lastReadServerSequence: Int64) async throws {
        let command = client.makeReadCursorCommand(
            roomID: roomID,
            lastReadServerSequence: lastReadServerSequence
        )
        try await send(command)
    }

    public func setTyping(_ isTyping: Bool, roomID: String) async throws {
        let command = client.makeTypingCommand(roomID: roomID, isTyping: isTyping)
        try await send(command)
    }

    public func send<Payload: Encodable & Sendable>(
        _ envelope: SpectraChatCommandEnvelope<Payload>
    ) async throws {
        try await connect()
        guard let socketTask else {
            throw SpectraChatRealtimeError.disconnected
        }
        try await socketTask.send(.data(try encoder.encode(envelope)))
    }

    public static func decodeEvent(from data: Data) throws -> SpectraChatRealtimeEvent {
        let decoder = JSONDecoder.spectraChatDecoder
        let header = try decoder.decode(SocketEventHeader.self, from: data)
        switch header.eventType {
        case "connection.ready":
            return .connectionChanged(.connected)
        case "message.created":
            let envelope = try decoder.decode(SocketEnvelope<MessageCreatedPayload>.self, from: data)
            return .messageCreated(envelope.payload.message)
        case "read_cursor.updated":
            let roomID = header.roomID ?? ""
            let envelope = try decoder.decode(SocketEnvelope<ReadCursorUpdatedPayload>.self, from: data)
            return .readCursorUpdated(
                SpectraChatReadCursorUpdated(
                    roomID: roomID,
                    userID: envelope.payload.userID,
                    lastReadServerSequence: envelope.payload.lastReadServerSequence
                )
            )
        case "typing.updated":
            let roomID = header.roomID ?? ""
            let envelope = try decoder.decode(SocketEnvelope<TypingUpdatedPayload>.self, from: data)
            return .typingUpdated(
                SpectraChatTypingUpdated(
                    roomID: roomID,
                    userID: envelope.payload.userID,
                    isTyping: envelope.payload.isTyping
                )
            )
        case "error":
            let envelope = try decoder.decode(SocketEnvelope<SocketErrorPayload>.self, from: data)
            return .serverError(
                SpectraChatServerError(
                    requestEventID: envelope.payload.requestEventID,
                    code: envelope.payload.code,
                    message: envelope.payload.message,
                    retryable: envelope.payload.retryable
                )
            )
        case "call.invited",
             "call.accepted",
             "call.declined",
             "call.joined",
             "call.left",
             "call.ended",
             "call.missed":
            return .callLifecycle(try decoder.decode(SpectraChatCallLifecycleEvent.self, from: data))
        default:
            return .unknown(eventType: header.eventType)
        }
    }

    private func receiveLoop(_ task: URLSessionWebSocketTask) async {
        do {
            while !Task.isCancelled {
                let frame = try await task.receive()
                let data: Data
                switch frame {
                case .data(let value):
                    data = value
                case .string(let value):
                    data = Data(value.utf8)
                @unknown default:
                    continue
                }
                handle(data)
            }
        } catch is CancellationError {
            return
        } catch {
            handleDisconnect(task: task)
        }
    }

    private func handle(_ data: Data) {
        let event: SpectraChatRealtimeEvent
        do {
            event = try Self.decodeEvent(from: data)
        } catch {
#if DEBUG
            print("[SpectraChatSDK][Realtime] decoding_error=\(error)")
#endif
            return
        }
        if case .connectionChanged(.connected) = event {
            reconnectAttempt = 0
        }
        if case .messageCreated(let message) = event {
            completePendingMessage(message.clientMessageID, message: message)
        }
        if case .serverError(let serverError) = event,
           let requestEventID = serverError.requestEventID,
           let clientMessageID = pendingRequestToClientMessage[requestEventID] {
            failPendingMessage(clientMessageID, error: SpectraChatRealtimeError.server(serverError))
        }
        yield(event)
    }

    private func handleDisconnect(task: URLSessionWebSocketTask) {
        guard socketTask === task else { return }
        socketTask = nil
        receiveTask = nil
        failAllPending(with: SpectraChatRealtimeError.disconnected)
        guard !intentionallyDisconnected, !subscribers.isEmpty else {
            yield(.connectionChanged(.disconnected))
            return
        }
        scheduleReconnect()
    }

    private func scheduleReconnect() {
        guard reconnectTask == nil else { return }
        reconnectAttempt += 1
        let attempt = reconnectAttempt
        yield(.connectionChanged(.reconnecting(attempt: attempt)))
        reconnectTask = Task {
            let cappedAttempt = min(attempt, 5)
            let delay = UInt64(1 << (cappedAttempt - 1)) * 1_000_000_000
            do {
                try await Task.sleep(nanoseconds: delay)
                self.clearReconnectTask()
                try await self.connect()
            } catch is CancellationError {
                self.clearReconnectTask()
            } catch {
                self.clearReconnectTask()
                self.scheduleReconnect()
            }
        }
    }

    private func clearReconnectTask() {
        reconnectTask = nil
    }

    private func removeSubscriber(_ id: UUID) {
        subscribers[id] = nil
    }

    private func yield(_ event: SpectraChatRealtimeEvent) {
        subscribers.values.forEach { $0.yield(event) }
    }

    private func completePendingMessage(_ clientMessageID: String, message: SpectraChatMessage) {
        guard let pending = pendingMessages.removeValue(forKey: clientMessageID) else { return }
        pendingRequestToClientMessage[pending.requestEventID] = nil
        pending.continuation.resume(returning: message)
    }

    private func failPendingMessage(_ clientMessageID: String, error: Error) {
        guard let pending = pendingMessages.removeValue(forKey: clientMessageID) else { return }
        pendingRequestToClientMessage[pending.requestEventID] = nil
        pending.continuation.resume(throwing: error)
    }

    private func expirePendingMessage(_ clientMessageID: String) {
        failPendingMessage(clientMessageID, error: SpectraChatRealtimeError.acknowledgementTimedOut)
    }

    private func cancelPendingMessage(_ clientMessageID: String) {
        failPendingMessage(clientMessageID, error: CancellationError())
    }

    private func failAllPending(with error: Error) {
        let pending = pendingMessages
        pendingMessages.removeAll()
        pendingRequestToClientMessage.removeAll()
        pending.values.forEach { $0.continuation.resume(throwing: error) }
    }
}

private struct SocketEventHeader: Decodable {
    var eventType: String
    var roomID: String?

    enum CodingKeys: String, CodingKey {
        case eventType = "event_type"
        case roomID = "room_id"
    }
}

private struct SocketEnvelope<Payload: Decodable>: Decodable {
    var schemaVersion: Int
    var eventID: String
    var eventType: String
    var roomID: String?
    var serverSequence: Int64?
    var occurredAt: Date
    var payload: Payload

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

private struct MessageCreatedPayload: Decodable {
    var message: SpectraChatMessage
}

private struct ReadCursorUpdatedPayload: Decodable {
    var userID: String
    var lastReadServerSequence: Int64

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case lastReadServerSequence = "last_read_server_sequence"
    }
}

private struct TypingUpdatedPayload: Decodable {
    var userID: String
    var isTyping: Bool

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case isTyping = "is_typing"
    }
}

private struct SocketErrorPayload: Decodable {
    var requestEventID: String?
    var code: String
    var message: String
    var retryable: Bool

    enum CodingKeys: String, CodingKey {
        case requestEventID = "request_event_id"
        case code
        case message
        case retryable
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
