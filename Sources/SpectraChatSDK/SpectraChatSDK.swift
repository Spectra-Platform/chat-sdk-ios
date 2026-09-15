import Foundation
import SpectraAuthSDK
import SpectraStorageSDK

public protocol SpectraChatAccessTokenProviding: Sendable {
    func accessToken() async throws -> String
}

public protocol SpectraChatAccessTokenRefreshing: SpectraChatAccessTokenProviding {
    func accessToken(forceRefresh: Bool) async throws -> String
}

public struct SpectraChatAuthServiceTokenProvider: SpectraChatAccessTokenRefreshing {
    private let auth: any ServiceTokenProvider

    public init(auth: any ServiceTokenProvider) {
        self.auth = auth
    }

    public func accessToken() async throws -> String {
        try await accessToken(forceRefresh: false)
    }

    public func accessToken(forceRefresh: Bool) async throws -> String {
        try await auth.getAccessToken(for: .chat, forceRefresh: forceRefresh).value
    }
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
    public static let productionBaseURL = URL(string: "https://chat.spectra.kr")!
    public static let productionSocketURL = URL(string: "wss://chat.spectra.kr/v1/socket")!

    public var baseURL: URL
    public var socketURL: URL?
    public var projectId: String?

    public init(
        baseURL: URL = Self.productionBaseURL,
        socketURL: URL? = nil,
        projectId: String? = nil
    ) {
        self.baseURL = baseURL
        self.socketURL = socketURL
        self.projectId = projectId
    }

    public static func production(projectId: String? = nil) -> SpectraChatClientConfiguration {
        SpectraChatClientConfiguration(
            baseURL: productionBaseURL,
            socketURL: productionSocketURL,
            projectId: projectId
        )
    }

    public static func custom(
        baseURL: URL,
        socketURL: URL? = nil,
        projectId: String? = nil
    ) -> SpectraChatClientConfiguration {
        SpectraChatClientConfiguration(baseURL: baseURL, socketURL: socketURL, projectId: projectId)
    }
}

public enum SpectraChatLogLevel: String, Equatable, Sendable {
    case debug
    case info
    case warning
    case error
}

public typealias SpectraChatLogger = @Sendable (
    SpectraChatLogLevel,
    String,
    [String: String]
) -> Void

public protocol SpectraChatClientDelegate: AnyObject {
    func spectraChatClient(_ client: SpectraChatClient, didChangeConnectionState state: SpectraChatRealtimeConnectionState)
    func spectraChatClient(_ client: SpectraChatClient, didReceive event: SpectraChatEvent)
    func spectraChatClient(_ client: SpectraChatClient, didReceiveError error: Error)
}

public extension SpectraChatClientDelegate {
    func spectraChatClient(_ client: SpectraChatClient, didChangeConnectionState state: SpectraChatRealtimeConnectionState) {}
    func spectraChatClient(_ client: SpectraChatClient, didReceive event: SpectraChatEvent) {}
    func spectraChatClient(_ client: SpectraChatClient, didReceiveError error: Error) {}
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

    public var id: String { roomID }
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

public struct SpectraChatWebSocketTicket: Codable, Equatable, Sendable {
    public var websocketURL: String
    public var ticket: String
    public var ticketTransport: String
    public var expiresAt: Date
    public var roomID: String

    public init(
        websocketURL: String,
        ticket: String,
        ticketTransport: String,
        expiresAt: Date,
        roomID: String
    ) {
        self.websocketURL = websocketURL
        self.ticket = ticket
        self.ticketTransport = ticketTransport
        self.expiresAt = expiresAt
        self.roomID = roomID
    }

    enum CodingKeys: String, CodingKey {
        case websocketURL = "websocket_url"
        case ticket
        case ticketTransport = "ticket_transport"
        case expiresAt = "expires_at"
        case roomID = "room_id"
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

public struct SpectraChatSendMessageOptions: Equatable, Sendable {
    public var text: String?
    public var attachments: [SpectraChatStorageObjectReference]
    public var clientMessageID: String
    public var replyToMessageID: String?
    public var mentionedUserIDs: [String]
    public var idempotencyKey: String?

    public init(
        text: String? = nil,
        attachments: [SpectraChatStorageObjectReference] = [],
        clientMessageID: String = UUID().uuidString,
        replyToMessageID: String? = nil,
        mentionedUserIDs: [String] = [],
        idempotencyKey: String? = nil
    ) {
        self.text = text
        self.attachments = attachments
        self.clientMessageID = clientMessageID
        self.replyToMessageID = replyToMessageID
        self.mentionedUserIDs = mentionedUserIDs
        self.idempotencyKey = idempotencyKey
    }
}

public struct SpectraChatMembershipRequestOptions: Equatable, Sendable {
    public var timeout: TimeInterval?

    public init(timeout: TimeInterval? = nil) {
        self.timeout = timeout
    }
}

public enum SpectraChatRoomMembershipStatus: String, Codable, Equatable, Sendable {
    case active
    case left
}

public struct SpectraChatRoomMembership: Codable, Equatable, Sendable {
    public var roomID: String
    public var appUserID: String
    public var status: SpectraChatRoomMembershipStatus
    public var leftAt: Date?

    public init(
        roomID: String,
        appUserID: String,
        status: SpectraChatRoomMembershipStatus,
        leftAt: Date?
    ) {
        self.roomID = roomID
        self.appUserID = appUserID
        self.status = status
        self.leftAt = leftAt
    }

    enum CodingKeys: String, CodingKey {
        case roomID = "room_id"
        case appUserID = "app_user_id"
        case status
        case leftAt = "left_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        roomID = try container.decode(String.self, forKey: .roomID)
        appUserID = try container.decode(String.self, forKey: .appUserID)
        status = try container.decode(SpectraChatRoomMembershipStatus.self, forKey: .status)
        leftAt = try container.decodeIfPresent(Date.self, forKey: .leftAt)
        switch status {
        case .active where leftAt != nil:
            throw DecodingError.dataCorruptedError(
                forKey: .leftAt,
                in: container,
                debugDescription: "Active membership must not include left_at"
            )
        case .left where leftAt == nil:
            throw DecodingError.dataCorruptedError(
                forKey: .leftAt,
                in: container,
                debugDescription: "Left membership requires left_at"
            )
        default:
            break
        }
    }
}

public typealias SpectraChatLeaveRoomResult = SpectraChatRoomMembership

public struct SpectraChatMembershipEvent: Equatable, Sendable {
    public var roomID: String
    public var appUserID: String
    public var status: SpectraChatRoomMembershipStatus
    public var leftAt: Date
    public var occurredAt: Date

    public init(
        roomID: String,
        appUserID: String,
        status: SpectraChatRoomMembershipStatus,
        leftAt: Date,
        occurredAt: Date
    ) {
        self.roomID = roomID
        self.appUserID = appUserID
        self.status = status
        self.leftAt = leftAt
        self.occurredAt = occurredAt
    }
}

public struct SpectraChatFileDescriptor: Equatable, Sendable {
    public var data: Data
    public var name: String?
    public var path: String?
    public var contentType: String?
    public var metadata: [String: String]
    public var storageMetadata: [String: String]

    public init(
        data: Data,
        name: String? = nil,
        path: String? = nil,
        contentType: String? = nil,
        metadata: [String: String] = [:],
        storageMetadata: [String: String] = [:]
    ) {
        self.data = data
        self.name = name
        self.path = path
        self.contentType = contentType
        self.metadata = metadata
        self.storageMetadata = storageMetadata
    }
}

public struct SpectraChatFileUploadProgress: Equatable, Sendable {
    public var index: Int
    public var totalFiles: Int
    public var fileName: String
    public var objectKey: String
    public var loaded: Int64
    public var total: Int64

    public init(
        index: Int,
        totalFiles: Int,
        fileName: String,
        objectKey: String,
        loaded: Int64,
        total: Int64
    ) {
        self.index = index
        self.totalFiles = totalFiles
        self.fileName = fileName
        self.objectKey = objectKey
        self.loaded = loaded
        self.total = total
    }
}

public struct SpectraChatUploadFilesOptions: Sendable {
    public var files: [SpectraChatFileDescriptor]
    public var pathPrefix: String?
    public var metadata: [String: String]
    public var storageMetadata: [String: String]
    public var onProgress: (@Sendable (SpectraChatFileUploadProgress) -> Void)?

    public init(
        files: [SpectraChatFileDescriptor],
        pathPrefix: String? = nil,
        metadata: [String: String] = [:],
        storageMetadata: [String: String] = [:],
        onProgress: (@Sendable (SpectraChatFileUploadProgress) -> Void)? = nil
    ) {
        self.files = files
        self.pathPrefix = pathPrefix
        self.metadata = metadata
        self.storageMetadata = storageMetadata
        self.onProgress = onProgress
    }
}

public struct SpectraChatFileUploadOptions: Sendable {
    public var pathPrefix: String?
    public var metadata: [String: String]
    public var storageMetadata: [String: String]
    public var onProgress: (@Sendable (SpectraChatFileUploadProgress) -> Void)?

    public init(
        pathPrefix: String? = nil,
        metadata: [String: String] = [:],
        storageMetadata: [String: String] = [:],
        onProgress: (@Sendable (SpectraChatFileUploadProgress) -> Void)? = nil
    ) {
        self.pathPrefix = pathPrefix
        self.metadata = metadata
        self.storageMetadata = storageMetadata
        self.onProgress = onProgress
    }
}

public struct SpectraChatSendMessageWithFilesOptions: Sendable {
    public var text: String?
    public var files: [SpectraChatFileDescriptor]
    public var attachments: [SpectraChatStorageObjectReference]
    public var upload: SpectraChatFileUploadOptions?
    public var clientMessageID: String
    public var replyToMessageID: String?
    public var mentionedUserIDs: [String]
    public var idempotencyKey: String?

    public init(
        text: String? = nil,
        files: [SpectraChatFileDescriptor],
        attachments: [SpectraChatStorageObjectReference] = [],
        upload: SpectraChatFileUploadOptions? = nil,
        clientMessageID: String = UUID().uuidString,
        replyToMessageID: String? = nil,
        mentionedUserIDs: [String] = [],
        idempotencyKey: String? = nil
    ) {
        self.text = text
        self.files = files
        self.attachments = attachments
        self.upload = upload
        self.clientMessageID = clientMessageID
        self.replyToMessageID = replyToMessageID
        self.mentionedUserIDs = mentionedUserIDs
        self.idempotencyKey = idempotencyKey
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

public struct SpectraChatMessageEvent: Equatable, Sendable {
    public var roomID: String
    public var message: SpectraChatMessage
    public var sequence: Int64
    public var occurredAt: Date

    public init(roomID: String, message: SpectraChatMessage, sequence: Int64, occurredAt: Date) {
        self.roomID = roomID
        self.message = message
        self.sequence = sequence
        self.occurredAt = occurredAt
    }
}

public struct SpectraChatTypingEvent: Equatable, Sendable {
    public var roomID: String
    public var userID: String
    public var isTyping: Bool
    public var sequence: Int64
    public var occurredAt: Date

    public init(roomID: String, userID: String, isTyping: Bool, sequence: Int64, occurredAt: Date) {
        self.roomID = roomID
        self.userID = userID
        self.isTyping = isTyping
        self.sequence = sequence
        self.occurredAt = occurredAt
    }
}

public struct SpectraChatReadEvent: Equatable, Sendable {
    public var roomID: String
    public var userID: String
    public var lastReadSequence: Int64
    public var sequence: Int64
    public var occurredAt: Date

    public init(roomID: String, userID: String, lastReadSequence: Int64, sequence: Int64, occurredAt: Date) {
        self.roomID = roomID
        self.userID = userID
        self.lastReadSequence = lastReadSequence
        self.sequence = sequence
        self.occurredAt = occurredAt
    }
}

public struct SpectraChatConnectionEvent: Equatable, Sendable {
    public var roomID: String?
    public var occurredAt: Date?
    public var connectionID: String?

    public init(roomID: String? = nil, occurredAt: Date? = nil, connectionID: String? = nil) {
        self.roomID = roomID
        self.occurredAt = occurredAt
        self.connectionID = connectionID
    }
}

public struct SpectraChatErrorEvent: Equatable, Sendable {
    public var error: SpectraChatServerError
    public var roomID: String?

    public init(error: SpectraChatServerError, roomID: String? = nil) {
        self.error = error
        self.roomID = roomID
    }
}

private extension SpectraChatMessageEvent {
    var logFields: [String: String] {
        [
            "roomID": roomID,
            "messageID": message.messageID,
            "sequence": String(sequence),
        ]
    }
}

private extension SpectraChatTypingEvent {
    var logFields: [String: String] {
        [
            "roomID": roomID,
            "sequence": String(sequence),
        ]
    }
}

private extension SpectraChatReadEvent {
    var logFields: [String: String] {
        [
            "roomID": roomID,
            "sequence": String(sequence),
        ]
    }
}

private extension SpectraChatConnectionEvent {
    var logFields: [String: String] {
        var fields: [String: String] = [:]
        if let roomID {
            fields["roomID"] = roomID
        }
        if let connectionID {
            fields["connectionID"] = connectionID
        }
        return fields
    }
}

private extension SpectraChatErrorEvent {
    var logFields: [String: String] {
        var fields: [String: String] = [
            "errorCode": error.code,
        ]
        if let roomID {
            fields["roomID"] = roomID
        }
        if let requestEventID = error.requestEventID {
            fields["requestID"] = requestEventID
        }
        return fields
    }
}

public enum SpectraChatEvent: Equatable, Sendable {
    case message(SpectraChatMessageEvent)
    case typing(SpectraChatTypingEvent)
    case read(SpectraChatReadEvent)
    case membership(SpectraChatMembershipEvent)
    case connected(SpectraChatConnectionEvent)
    case disconnected(SpectraChatConnectionEvent)
    case error(SpectraChatErrorEvent)
}

public extension SpectraChatEvent {
    var roomID: String? {
        switch self {
        case .message(let event):
            return event.roomID
        case .typing(let event):
            return event.roomID
        case .read(let event):
            return event.roomID
        case .membership(let event):
            return event.roomID
        case .connected(let event), .disconnected(let event):
            return event.roomID
        case .error(let event):
            return event.roomID
        }
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
    case membership(SpectraChatMembershipEvent)
    case callLifecycle(SpectraChatCallLifecycleEvent)
    case serverError(SpectraChatServerError)
    case unknown(eventType: String)
}

public extension SpectraChatRealtimeEvent {
    var roomID: String? {
        switch self {
        case .connectionChanged, .serverError, .unknown:
            return nil
        case .messageCreated(let message):
            return message.roomID
        case .readCursorUpdated(let event):
            return event.roomID
        case .typingUpdated(let event):
            return event.roomID
        case .membership(let event):
            return event.roomID
        case .callLifecycle(let event):
            return event.roomID
        }
    }
}

public enum SpectraChatRealtimeError: Error, Equatable, Sendable {
    case disconnected
    case acknowledgementTimedOut
    case server(SpectraChatServerError)
}

public enum SpectraChatCallEventType: String, CaseIterable, Codable, Sendable {
    case invited = "call.invited"
    case stateUpdated = "call.state_updated"
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
    public var initiatorUserID: String?
    public var endedReason: String?

    public init(
        callID: String,
        callSessionID: String? = nil,
        status: String,
        mediaMode: String,
        callType: String,
        initiatorUserID: String? = nil,
        endedReason: String? = nil
    ) {
        self.callID = callID
        self.callSessionID = callSessionID
        self.status = status
        self.mediaMode = mediaMode
        self.callType = callType
        self.initiatorUserID = initiatorUserID
        self.endedReason = endedReason
    }

    enum CodingKeys: String, CodingKey {
        case callID = "call_id"
        case callSessionID = "call_session_id"
        case status
        case state
        case mediaMode = "media_mode"
        case callType = "call_type"
        case kind
        case initiatorUserID = "initiator_user_id"
        case endedReason = "ended_reason"
        case endReason = "end_reason"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        callID = try container.decode(String.self, forKey: .callID)
        callSessionID = try container.decodeIfPresent(String.self, forKey: .callSessionID)
        status = try container.decodeIfPresent(String.self, forKey: .status)
            ?? container.decode(String.self, forKey: .state)
        mediaMode = try container.decodeIfPresent(String.self, forKey: .mediaMode) ?? "video"
        callType = try container.decodeIfPresent(String.self, forKey: .callType)
            ?? container.decode(String.self, forKey: .kind)
        initiatorUserID = try container.decodeIfPresent(String.self, forKey: .initiatorUserID)
        endedReason = try container.decodeIfPresent(String.self, forKey: .endedReason)
            ?? container.decodeIfPresent(String.self, forKey: .endReason)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(callID, forKey: .callID)
        try container.encodeIfPresent(callSessionID, forKey: .callSessionID)
        try container.encode(status, forKey: .status)
        try container.encode(mediaMode, forKey: .mediaMode)
        try container.encode(callType, forKey: .callType)
        try container.encodeIfPresent(initiatorUserID, forKey: .initiatorUserID)
        try container.encodeIfPresent(endedReason, forKey: .endedReason)
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
        case userID = "user_id"
        case state
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        participantID = try container.decodeIfPresent(String.self, forKey: .participantID)
        appUserID = try container.decodeIfPresent(String.self, forKey: .appUserID)
            ?? container.decode(String.self, forKey: .userID)
        state = try container.decode(String.self, forKey: .state)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(participantID, forKey: .participantID)
        try container.encode(appUserID, forKey: .appUserID)
        try container.encode(state, forKey: .state)
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
    public var changeType: String?
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
        case actorUserID = "actor_user_id"
        case changeType = "change_type"
        case call
        case participant
        case participants
        case trace
        case payload
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
        changeType: String? = nil,
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
        self.changeType = changeType
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
        serverSequence = try container.decodeIfPresent(Int64.self, forKey: .serverSequence) ?? 0
        occurredAt = try Self.decodeDate(container, forKey: .occurredAt)
        let topLevelCall = try container.decodeIfPresent(CallLifecycleSocketCall.self, forKey: .call)
        let envelopePayload = try container.decodeIfPresent(CallLifecycleSocketPayload.self, forKey: .payload)

        actor = try container.decodeIfPresent(SpectraChatCallActor.self, forKey: .actor)
            ?? envelopePayload?.actor
            ?? Self.actor(from: try container.decodeIfPresent(String.self, forKey: .actorUserID))
            ?? Self.actor(from: envelopePayload?.actorUserID)
        changeType = try container.decodeIfPresent(String.self, forKey: .changeType)
            ?? envelopePayload?.changeType
        call = try topLevelCall?.summary
            ?? envelopePayload?.call.summary
            ?? {
                throw DecodingError.keyNotFound(
                    CodingKeys.call,
                    DecodingError.Context(
                        codingPath: container.codingPath,
                        debugDescription: "Expected call payload at top-level call or payload.call"
                    )
                )
            }()
        conversationID = try container.decodeIfPresent(String.self, forKey: .conversationID)
            ?? container.decodeIfPresent(String.self, forKey: .roomID)
            ?? topLevelCall?.chatRoomID
            ?? envelopePayload?.call.chatRoomID
            ?? call.callID
        roomID = try validatedRoomID(
            try container.decodeIfPresent(String.self, forKey: .roomID)
            ?? topLevelCall?.chatRoomID
            ?? envelopePayload?.call.chatRoomID
        )

        if let participants = try container.decodeIfPresent([SpectraChatCallParticipant].self, forKey: .participants) {
            self.participants = participants
        } else if let participant = try container.decodeIfPresent(SpectraChatCallParticipant.self, forKey: .participant) {
            self.participants = [participant]
        } else if let participants = topLevelCall?.participants {
            self.participants = participants
        } else if let participant = topLevelCall?.participant {
            self.participants = [participant]
        } else if let participants = envelopePayload?.call.participants {
            self.participants = participants
        } else if let participants = envelopePayload?.participants {
            self.participants = participants
        } else if let participant = envelopePayload?.participant {
            self.participants = [participant]
        } else {
            self.participants = []
        }
        trace = try container.decodeIfPresent(SpectraChatCallTrace.self, forKey: .trace)
            ?? envelopePayload?.trace
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

    private static func actor(from appUserID: String?) -> SpectraChatCallActor? {
        guard let appUserID else { return nil }
        return SpectraChatCallActor(appUserID: appUserID)
    }
}

private struct CallLifecycleSocketPayload: Decodable {
    var actor: SpectraChatCallActor?
    var actorUserID: String?
    var changeType: String?
    var call: CallLifecycleSocketCall
    var participants: [SpectraChatCallParticipant]?
    var participant: SpectraChatCallParticipant?
    var trace: SpectraChatCallTrace?

    enum CodingKeys: String, CodingKey {
        case actor
        case actorUserID = "actor_user_id"
        case changeType = "change_type"
        case call
        case participants
        case participant
        case trace
    }
}

private struct CallLifecycleSocketCall: Decodable {
    var summary: SpectraChatCallSummary
    var chatRoomID: String?
    var participants: [SpectraChatCallParticipant]?
    var participant: SpectraChatCallParticipant?

    enum CodingKeys: String, CodingKey {
        case chatRoomID = "chat_room_id"
        case participants
        case participant
    }

    init(from decoder: Decoder) throws {
        summary = try SpectraChatCallSummary(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        chatRoomID = try container.decodeIfPresent(String.self, forKey: .chatRoomID)
        if let participants = try container.decodeIfPresent([SpectraChatCallParticipant].self, forKey: .participants) {
            self.participants = participants
            participant = nil
        } else if let participant = try container.decodeIfPresent(SpectraChatCallParticipant.self, forKey: .participant) {
            self.participants = nil
            self.participant = participant
        } else {
            participants = nil
            participant = nil
        }
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

    public init(code: String, message: String, retryable: Bool, requestID: String? = nil) {
        self.code = code
        self.message = message
        self.retryable = retryable
        self.requestID = requestID
    }

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
    case roomIDRequired
    case invalidResponse
    case requestCancelled(SpectraChatErrorResponse)
    case requestTimeout(SpectraChatErrorResponse)
    case httpStatus(Int, SpectraChatErrorResponse?)

    public var status: Int? {
        if case .httpStatus(let status, _) = self { return status }
        return nil
    }

    public var code: String {
        switch self {
        case .invalidBaseURL:
            return "INVALID_BASE_URL"
        case .invalidRequest:
            return "INVALID_REQUEST"
        case .roomIDRequired:
            return "ROOM_ID_REQUIRED"
        case .invalidResponse:
            return "RESPONSE_INVALID"
        case .requestCancelled(let response), .requestTimeout(let response):
            return response.code
        case .httpStatus(_, let response):
            return response?.code ?? "HTTP_ERROR"
        }
    }

    public var message: String {
        switch self {
        case .invalidBaseURL:
            return "Spectra Chat base URL is invalid."
        case .invalidRequest(let message):
            return message
        case .roomIDRequired:
            return "Chat roomID is required. Do not use conversationID as a roomID fallback."
        case .invalidResponse:
            return "Spectra Chat returned an invalid response."
        case .requestCancelled(let response), .requestTimeout(let response):
            return response.message
        case .httpStatus(let status, let response):
            return response?.message ?? "Spectra Chat returned HTTP status \(status)."
        }
    }

    public var requestID: String? {
        switch self {
        case .requestCancelled(let response), .requestTimeout(let response):
            return response.requestID
        case .httpStatus(_, let response):
            return response?.requestID
        default:
            return nil
        }
    }

    public var retryable: Bool? {
        switch self {
        case .requestCancelled(let response), .requestTimeout(let response):
            return response.retryable
        case .httpStatus(_, let response):
            return response?.retryable
        default:
            return nil
        }
    }
}

public final class SpectraChatClient: @unchecked Sendable {
    private let configuration: SpectraChatClientConfiguration
    private let tokenProvider: any SpectraChatAccessTokenProviding
    private let storageClient: SpectraStorageClient?
    private let urlSession: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var eventObservationTask: Task<Void, Never>?
    private lazy var realtimeClient = SpectraChatRealtimeClient(
        client: self,
        urlSession: urlSession
    )

    public weak var delegate: (any SpectraChatClientDelegate)? {
        didSet { startEventObservationIfNeeded() }
    }

    public var logger: SpectraChatLogger? {
        didSet { startEventObservationIfNeeded() }
    }

    public init(
        configuration: SpectraChatClientConfiguration,
        tokenProvider: any SpectraChatAccessTokenProviding,
        storageClient: SpectraStorageClient? = nil,
        urlSession: URLSession = .shared
    ) {
        self.configuration = configuration
        self.tokenProvider = tokenProvider
        self.storageClient = storageClient
        self.urlSession = urlSession
        self.encoder = JSONEncoder.spectraChatEncoder
        self.decoder = JSONDecoder.spectraChatDecoder
    }

    public convenience init(
        projectId: String? = nil,
        tokenProvider: any SpectraChatAccessTokenProviding,
        storageClient: SpectraStorageClient? = nil,
        urlSession: URLSession = .shared
    ) {
        self.init(
            configuration: .production(projectId: projectId),
            tokenProvider: tokenProvider,
            storageClient: storageClient,
            urlSession: urlSession
        )
    }

    public convenience init(
        auth: any ServiceTokenProvider,
        configuration: SpectraChatClientConfiguration = .production(),
        storageClient: SpectraStorageClient? = nil,
        urlSession: URLSession = .shared
    ) {
        self.init(
            configuration: configuration,
            tokenProvider: SpectraChatAuthServiceTokenProvider(auth: auth),
            storageClient: storageClient,
            urlSession: urlSession
        )
    }

    public convenience init(
        auth: any ServiceTokenProvider,
        projectID: String? = nil,
        storageClient: SpectraStorageClient? = nil,
        urlSession: URLSession = .shared
    ) {
        self.init(
            auth: auth,
            configuration: .production(projectId: projectID),
            storageClient: storageClient,
            urlSession: urlSession
        )
    }

    public convenience init(
        auth tokenProvider: any SpectraChatAccessTokenProviding,
        projectID: String? = nil,
        storageClient: SpectraStorageClient? = nil,
        urlSession: URLSession = .shared
    ) {
        self.init(
            projectId: projectID,
            tokenProvider: tokenProvider,
            storageClient: storageClient,
            urlSession: urlSession
        )
    }

    public func getRoom(roomID: String) async throws -> SpectraChatRoom {
        let roomID = try validatedRoomID(roomID)
        let rooms = try await listRooms()
        if let room = rooms.first(where: { $0.roomID == roomID }) {
            return room
        }
        throw SpectraChatError.httpStatus(
            404,
            SpectraChatErrorResponse(
                code: "CHAT_NOT_FOUND",
                message: "Room was not found.",
                retryable: false
            )
        )
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

    public func createDirectRoom(userID: String) async throws -> SpectraChatRoom {
        guard userID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            throw SpectraChatError.invalidRequest("userID is required")
        }
        return try await createDirectRoom(participantUserID: userID)
    }

    public func createGroupRoom(title: String? = nil, userIDs: [String]) async throws -> SpectraChatRoom {
        guard userIDs.isEmpty == false else {
            throw SpectraChatError.invalidRequest("createGroupRoom requires at least one userID")
        }
        return try await createGroupRoom(title: title ?? "", participantUserIDs: userIDs)
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
        guard participantUserID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            throw SpectraChatError.invalidRequest("participantUserID is required")
        }
        let request = try await makeJSONRequest(
            url: url(path: "/v1/chat/rooms/direct"),
            method: "POST",
            body: ["participant_user_id": participantUserID]
        )
        return try await decodeDataResponse(request: request, expectedStatus: 201)
    }

    public func createGroupRoom(title: String, participantUserIDs: [String]) async throws -> SpectraChatRoom {
        guard participantUserIDs.isEmpty == false else {
            throw SpectraChatError.invalidRequest("createGroupRoom requires at least one participantUserID")
        }
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
        let roomID = try validatedRoomID(roomID)
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

    public func sendMessage(
        roomID: String,
        options: SpectraChatSendMessageOptions
    ) async throws -> SpectraChatMessage {
        let roomID = try validatedRoomID(roomID)
        var content = SpectraChatSendContent(
            kind: options.attachments.isEmpty ? "text" : "attachment",
            text: options.text,
            storageObjectReferences: options.attachments.isEmpty ? nil : options.attachments
        )
        if options.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            throw SpectraChatError.invalidRequest("message text must not be empty")
        }
        if options.text == nil && options.attachments.isEmpty {
            throw SpectraChatError.invalidRequest("sendMessage requires text or attachments")
        }
        if options.attachments.isEmpty == false, options.text == nil {
            content.text = nil
        }
        return try await sendMessage(
            roomID: roomID,
            content: content,
            clientMessageID: options.clientMessageID,
            replyToMessageID: options.replyToMessageID,
            mentionedUserIDs: options.mentionedUserIDs,
            idempotencyKey: options.idempotencyKey
        )
    }

    public func sendMessage(
        roomID: String,
        text: String,
        clientMessageID: String = UUID().uuidString,
        replyToMessageID: String? = nil,
        mentionedUserIDs: [String] = [],
        idempotencyKey: String? = nil
    ) async throws -> SpectraChatMessage {
        try await sendMessage(
            roomID: roomID,
            options: SpectraChatSendMessageOptions(
                text: text,
                clientMessageID: clientMessageID,
                replyToMessageID: replyToMessageID,
                mentionedUserIDs: mentionedUserIDs,
                idempotencyKey: idempotencyKey
            )
        )
    }

    public func listMessages(
        roomID: String,
        beforeSequence: Int64? = nil,
        limit: Int? = nil
    ) async throws -> [SpectraChatMessage] {
        let roomID = try validatedRoomID(roomID)
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

    public func markRead(roomID: String, lastReadSequence: Int64) async throws {
        try await updateReadCursor(roomID: roomID, lastReadServerSequence: lastReadSequence)
    }

    public func markRead(roomID: String, sequence: Int64) async throws {
        try await updateReadCursor(roomID: roomID, lastReadServerSequence: sequence)
    }

    public func leaveRoom(
        roomID: String,
        options: SpectraChatMembershipRequestOptions = SpectraChatMembershipRequestOptions()
    ) async throws -> SpectraChatLeaveRoomResult {
        let roomID = try validatedRoomID(roomID)
        let membership: SpectraChatRoomMembership = try await withMembershipDeadline(options) {
            let request = try await self.makeRequest(
                url: self.url(path: "/v1/chat/rooms/\(encodedPathSegment(roomID))/leave"),
                method: "POST"
            )
            let decoded: SpectraChatRoomMembership = try await self.decodeDataResponse(request: request, expectedStatus: 200)
            return decoded
        }
        try validateMembership(membership, roomID: roomID)
        guard membership.status == .left else {
            throw SpectraChatError.invalidResponse
        }
        return membership
    }

    public func getRoomMembership(
        roomID: String,
        options: SpectraChatMembershipRequestOptions = SpectraChatMembershipRequestOptions()
    ) async throws -> SpectraChatRoomMembership {
        let roomID = try validatedRoomID(roomID)
        let membership: SpectraChatRoomMembership = try await withMembershipDeadline(options) {
            let request = try await self.makeRequest(
                url: self.url(path: "/v1/chat/rooms/\(encodedPathSegment(roomID))/membership"),
                method: "GET"
            )
            let decoded: SpectraChatRoomMembership = try await self.decodeDataResponse(request: request, expectedStatus: 200)
            return decoded
        }
        try validateMembership(membership, roomID: roomID)
        return membership
    }

    public func uploadFiles(
        roomID: String,
        options: SpectraChatUploadFilesOptions
    ) async throws -> [SpectraChatStorageObjectReference] {
        let roomID = try validatedRoomID(roomID)
        guard let storageClient else {
            throw SpectraChatError.invalidRequest("uploadFiles requires a SpectraStorageClient")
        }
        guard options.files.isEmpty == false else {
            throw SpectraChatError.invalidRequest("uploadFiles requires at least one file")
        }

        var references: [SpectraChatStorageObjectReference] = []
        for (index, file) in options.files.enumerated() {
            try Task.checkCancellation()
            let fileName = normalizedFileName(file.name, fallback: "attachment-\(index + 1)")
            let contentType = normalizedContentType(file.contentType)
            let objectKey = try normalizedChatAttachmentPath(
                explicitPath: file.path,
                roomID: roomID,
                fileName: fileName,
                index: index,
                pathPrefix: options.pathPrefix
            )
            let storageMetadata = options.storageMetadata.merging(file.storageMetadata) { _, new in new }
            let uploaded = try await storageClient.uploadDataToUserRoot(
                file.data,
                path: objectKey,
                contentType: contentType,
                metadata: storageMetadata,
                uploadIdempotencyKey: "storage-chat_file-upload-\(UUID().uuidString)",
                completeIdempotencyKey: "storage-chat_file-complete-\(UUID().uuidString)"
            )
            var attachmentMetadata = options.metadata.merging(file.metadata) { _, new in new }
            attachmentMetadata["original_name"] = fileName
            attachmentMetadata["attachment_kind"] = attachmentKind(contentType)
            if let publicURL = uploaded.publicURL {
                attachmentMetadata["public_url"] = publicURL.absoluteString
            }
            options.onProgress?(
                SpectraChatFileUploadProgress(
                    index: index,
                    totalFiles: options.files.count,
                    fileName: fileName,
                    objectKey: uploaded.objectKey,
                    loaded: Int64(file.data.count),
                    total: Int64(file.data.count)
                )
            )
            references.append(
                SpectraChatStorageObjectReference(
                    objectKey: uploaded.objectKey,
                    contentType: uploaded.contentType,
                    byteSize: uploaded.byteSize,
                    checksumSHA256: uploaded.checksumSHA256,
                    metadata: attachmentMetadata
                )
            )
        }
        return references
    }

    public func sendMessageWithFiles(
        roomID: String,
        options: SpectraChatSendMessageWithFilesOptions
    ) async throws -> SpectraChatMessage {
        let roomID = try validatedRoomID(roomID)
        let uploadOptions = options.upload ?? SpectraChatFileUploadOptions()
        let uploadedReferences = options.files.isEmpty
            ? []
            : try await uploadFiles(
                roomID: roomID,
                options: SpectraChatUploadFilesOptions(
                    files: options.files,
                    pathPrefix: uploadOptions.pathPrefix,
                    metadata: uploadOptions.metadata,
                    storageMetadata: uploadOptions.storageMetadata,
                    onProgress: uploadOptions.onProgress
                )
            )
        return try await sendMessage(
            roomID: roomID,
            options: SpectraChatSendMessageOptions(
                text: options.text,
                attachments: options.attachments + uploadedReferences,
                clientMessageID: options.clientMessageID,
                replyToMessageID: options.replyToMessageID,
                mentionedUserIDs: options.mentionedUserIDs,
                idempotencyKey: options.idempotencyKey
            )
        )
    }

    public func updateReadCursor(roomID: String, lastReadServerSequence: Int64) async throws {
        let roomID = try validatedRoomID(roomID)
        let request = try await makeJSONRequest(
            url: url(path: "/v1/chat/rooms/\(encodedPathSegment(roomID))/read-cursor"),
            method: "PUT",
            body: SpectraChatReadCursorUpdate(lastReadServerSequence: lastReadServerSequence)
        )
        _ = try await decodeDataResponse(request: request, expectedStatus: 200) as EmptyData
    }

    public func readMediaURLs(roomID: String, assetIDs: [String]) async throws -> [SpectraChatMediaReadURL] {
        let roomID = try validatedRoomID(roomID)
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
        precondition(!roomID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "roomID is required")
        return SpectraChatCommandEnvelope(
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
        precondition(!roomID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "roomID is required")
        return SpectraChatCommandEnvelope(
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
        precondition(!roomID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "roomID is required")
        return SpectraChatCommandEnvelope(
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

    public func webSocketTicket(roomID: String) async throws -> SpectraChatWebSocketTicket {
        let roomID = try validatedRoomID(roomID)
        let request = try await makeRequest(
            url: url(path: "/v1/chat/rooms/\(encodedPathSegment(roomID))/websocket-ticket"),
            method: "POST"
        )
        let ticket: SpectraChatWebSocketTicket = try await decodeDataResponse(request: request, expectedStatus: 200)
        guard ticket.roomID == roomID,
              ticket.ticketTransport == "query",
              ticket.ticket.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            throw SpectraChatError.invalidResponse
        }
        return ticket
    }

    public func connect() async throws {
        startEventObservationIfNeeded()
        try await realtimeClient.connect()
    }

    public func connect(roomID: String) async throws {
        try await subscribe(roomID: roomID)
    }

    public func subscribe(roomID: String) async throws {
        let roomID = try validatedRoomID(roomID)
        startEventObservationIfNeeded()
        try await realtimeClient.subscribe(roomID: roomID)
    }

    public func disconnect() async {
        await realtimeClient.disconnect()
    }

    public func setTyping(roomID: String, isTyping: Bool) async throws {
        try await realtimeClient.setTyping(isTyping, roomID: roomID)
    }

    public func events() async -> AsyncStream<SpectraChatEvent> {
        await realtimeClient.eventStream()
    }

    private func makeRequest(url: URL, method: String, idempotencyKey: String? = nil) async throws -> URLRequest {
        let token = try await accessToken(forceRefresh: false)
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

    func ticketSocketRequest(_ ticket: SpectraChatWebSocketTicket) throws -> URLRequest {
        var components = try webSocketURLComponents(from: ticket.websocketURL)
        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "ticket", value: ticket.ticket))
        components.queryItems = queryItems
        guard let url = components.url else {
            throw SpectraChatError.invalidBaseURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func accessToken(forceRefresh: Bool) async throws -> String {
        if let refreshing = tokenProvider as? any SpectraChatAccessTokenRefreshing {
            let token = try await refreshing.accessToken(forceRefresh: forceRefresh)
            if forceRefresh {
                logger?(.info, "token refreshed", [:])
            }
            return token
        }
        return try await tokenProvider.accessToken()
    }

    private func startEventObservationIfNeeded() {
        guard eventObservationTask == nil, delegate != nil || logger != nil else { return }
        eventObservationTask = Task { [weak self] in
            guard let self else { return }
            let stream = await self.realtimeClient.eventStream()
            for await event in stream {
                self.delegate?.spectraChatClient(self, didReceive: event)
                self.log(event)
            }
        }
    }

    private func log(_ level: SpectraChatLogLevel, _ event: String, _ fields: [String: String] = [:]) {
        logger?(level, event, fields)
    }

    private func log(_ event: SpectraChatEvent) {
        switch event {
        case .message(let message):
            log(.info, "message received", message.logFields)
        case .typing(let typing):
            log(.debug, "typing received", typing.logFields)
        case .read(let read):
            log(.debug, "read received", read.logFields)
        case .membership(let membership):
            log(.info, "membership received", ["roomID": membership.roomID])
        case .connected(let connection):
            delegate?.spectraChatClient(self, didChangeConnectionState: .connected)
            log(.info, "connected", connection.logFields)
        case .disconnected(let connection):
            delegate?.spectraChatClient(self, didChangeConnectionState: .disconnected)
            log(.info, "disconnected", connection.logFields)
        case .error(let error):
            delegate?.spectraChatClient(self, didReceiveError: error.error)
            log(.error, "error", error.logFields)
        }
    }

    private func webSocketURLComponents(from ticketURL: String) throws -> URLComponents {
        if let absoluteURL = URL(string: ticketURL),
           absoluteURL.scheme == "ws" || absoluteURL.scheme == "wss" {
            guard let components = URLComponents(url: absoluteURL, resolvingAgainstBaseURL: false) else {
                throw SpectraChatError.invalidBaseURL
            }
            return components
        }
        let base = try socketURL()
        guard var components = URLComponents(url: base, resolvingAgainstBaseURL: false) else {
            throw SpectraChatError.invalidBaseURL
        }
        if ticketURL.hasPrefix("/") {
            components.percentEncodedPath = ticketURL
            components.queryItems = nil
        }
        return components
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
    private var eventSubscribers: [UUID: AsyncStream<SpectraChatEvent>.Continuation] = [:]
    private var pendingMessages: [String: PendingMessage] = [:]
    private var pendingRequestToClientMessage: [String: String] = [:]
    private var subscribedRoomIDs: Set<String> = []
    private var activeRoomID: String?
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

    public func eventStream() -> AsyncStream<SpectraChatEvent> {
        let subscriberID = UUID()
        let (stream, continuation) = AsyncStream<SpectraChatEvent>.makeStream()
        eventSubscribers[subscriberID] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeEventSubscriber(subscriberID) }
        }
        Task {
            do {
                try await self.connect()
            } catch {
                self.yield(.disconnected(SpectraChatConnectionEvent()))
            }
        }
        return stream
    }

    public func connect() async throws {
        if socketTask != nil { return }
        guard let roomID = activeRoomID ?? subscribedRoomIDs.first else { return }
        intentionallyDisconnected = false
        yield(.connectionChanged(.connecting))
        client.delegate?.spectraChatClient(client, didChangeConnectionState: .connecting)
        client.logger?(.info, "socket connecting", ["roomID": roomID])
        let ticket = try await client.webSocketTicket(roomID: roomID)
        let request = try client.ticketSocketRequest(ticket)
        let task = urlSession.webSocketTask(with: request)
        socketTask = task
        task.resume()
        receiveTask = Task { await self.receiveLoop(task) }
    }

    public func connect(roomID: String?) async throws {
        guard let roomID else {
            throw SpectraChatError.roomIDRequired
        }
        try await subscribe(roomID: roomID)
    }

    public func subscribe(roomID: String) async throws {
        let roomID = try validatedRoomID(roomID)
        subscribedRoomIDs.insert(roomID)
        activeRoomID = roomID
        do {
            try await connect()
            client.logger?(.info, "room subscribed", ["roomID": roomID])
        } catch {
            subscribedRoomIDs.remove(roomID)
            if activeRoomID == roomID {
                activeRoomID = subscribedRoomIDs.first
            }
            client.logger?(.error, "error", ["roomID": roomID, "errorCode": safeErrorCode(error)])
            throw error
        }
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
        yield(.disconnected(SpectraChatConnectionEvent()))
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
        let roomID = try validatedRoomID(roomID)
        guard subscribedRoomIDs.contains(roomID) else {
            throw SpectraChatError.invalidRequest("subscribe(roomID:) before sending realtime messages")
        }
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
        let roomID = try validatedRoomID(roomID)
        guard subscribedRoomIDs.contains(roomID) else {
            throw SpectraChatError.invalidRequest("subscribe(roomID:) before updating read cursors")
        }
        let command = client.makeReadCursorCommand(
            roomID: roomID,
            lastReadServerSequence: lastReadServerSequence
        )
        try await send(command)
    }

    public func setTyping(_ isTyping: Bool, roomID: String) async throws {
        let roomID = try validatedRoomID(roomID)
        guard subscribedRoomIDs.contains(roomID) else {
            throw SpectraChatError.invalidRequest("subscribe(roomID:) before setting typing state")
        }
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
            _ = try validatedRoomID(envelope.roomID ?? envelope.payload.message.roomID)
            return .messageCreated(envelope.payload.message)
        case "read_cursor.updated":
            let roomID = try validatedRoomID(header.roomID)
            let envelope = try decoder.decode(SocketEnvelope<ReadCursorUpdatedPayload>.self, from: data)
            return .readCursorUpdated(
                SpectraChatReadCursorUpdated(
                    roomID: roomID,
                    userID: envelope.payload.userID,
                    lastReadServerSequence: envelope.payload.lastReadServerSequence
                )
            )
        case "typing.updated":
            let roomID = try validatedRoomID(header.roomID)
            let envelope = try decoder.decode(SocketEnvelope<TypingUpdatedPayload>.self, from: data)
            return .typingUpdated(
                SpectraChatTypingUpdated(
                    roomID: roomID,
                    userID: envelope.payload.userID,
                    isTyping: envelope.payload.isTyping
                )
            )
        case "room.membership.updated":
            let envelope = try decoder.decode(SocketEnvelope<SpectraChatRoomMembership>.self, from: data)
            guard envelope.payload.status == .left,
                  let leftAt = envelope.payload.leftAt,
                  leftAt == envelope.occurredAt else {
                throw SpectraChatError.invalidResponse
            }
            return .membership(
                SpectraChatMembershipEvent(
                    roomID: envelope.payload.roomID,
                    appUserID: envelope.payload.appUserID,
                    status: envelope.payload.status,
                    leftAt: leftAt,
                    occurredAt: envelope.occurredAt
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
             "call.state_updated",
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

    public static func decodeChatEvent(from data: Data) throws -> SpectraChatEvent {
        let decoder = JSONDecoder.spectraChatDecoder
        let header = try decoder.decode(SocketEventHeader.self, from: data)
        switch header.eventType {
        case "connection.ready":
            let envelope = try decoder.decode(SocketEnvelope<EmptySocketPayload>.self, from: data)
            return .connected(
                SpectraChatConnectionEvent(
                    roomID: header.roomID,
                    occurredAt: envelope.occurredAt,
                    connectionID: connectionID(from: header.eventID)
                )
            )
        case "message.created":
            let envelope = try decoder.decode(SocketEnvelope<MessageCreatedPayload>.self, from: data)
            let roomID = try validatedRoomID(envelope.roomID ?? envelope.payload.message.roomID)
            return .message(
                SpectraChatMessageEvent(
                    roomID: roomID,
                    message: envelope.payload.message,
                    sequence: envelope.serverSequence ?? envelope.payload.message.serverSequence,
                    occurredAt: envelope.occurredAt
                )
            )
        case "typing.updated":
            let envelope = try decoder.decode(SocketEnvelope<TypingUpdatedPayload>.self, from: data)
            let roomID = try validatedRoomID(envelope.roomID)
            return .typing(
                SpectraChatTypingEvent(
                    roomID: roomID,
                    userID: envelope.payload.userID,
                    isTyping: envelope.payload.isTyping,
                    sequence: envelope.serverSequence ?? 0,
                    occurredAt: envelope.occurredAt
                )
            )
        case "read_cursor.updated":
            let envelope = try decoder.decode(SocketEnvelope<ReadCursorUpdatedPayload>.self, from: data)
            let roomID = try validatedRoomID(envelope.roomID)
            return .read(
                SpectraChatReadEvent(
                    roomID: roomID,
                    userID: envelope.payload.userID,
                    lastReadSequence: envelope.payload.lastReadServerSequence,
                    sequence: envelope.serverSequence ?? 0,
                    occurredAt: envelope.occurredAt
                )
            )
        case "room.membership.updated":
            let envelope = try decoder.decode(SocketEnvelope<SpectraChatRoomMembership>.self, from: data)
            guard envelope.payload.status == .left,
                  let leftAt = envelope.payload.leftAt,
                  leftAt == envelope.occurredAt else {
                throw SpectraChatError.invalidResponse
            }
            return .membership(
                SpectraChatMembershipEvent(
                    roomID: envelope.payload.roomID,
                    appUserID: envelope.payload.appUserID,
                    status: envelope.payload.status,
                    leftAt: leftAt,
                    occurredAt: envelope.occurredAt
                )
            )
        case "error":
            let envelope = try decoder.decode(SocketEnvelope<SocketErrorPayload>.self, from: data)
            return .error(
                SpectraChatErrorEvent(
                    error: SpectraChatServerError(
                        requestEventID: envelope.payload.requestEventID,
                        code: envelope.payload.code,
                        message: envelope.payload.message,
                        retryable: envelope.payload.retryable
                    ),
                    roomID: envelope.roomID
                )
            )
        default:
            throw SpectraChatError.invalidResponse
        }
    }

    static func shouldDeliver(_ event: SpectraChatRealtimeEvent, subscribedRoomIDs: Set<String>) -> Bool {
        guard let roomID = event.roomID else { return true }
        return subscribedRoomIDs.contains(roomID)
    }

    static func shouldDeliver(_ event: SpectraChatEvent, subscribedRoomIDs: Set<String>) -> Bool {
        guard let roomID = event.roomID else { return true }
        return subscribedRoomIDs.contains(roomID)
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
        guard shouldDeliver(event) else { return }
        yield(event)
        if let chatEvent = try? Self.decodeChatEvent(from: data) {
            guard shouldDeliver(chatEvent) else { return }
            yield(chatEvent)
        }
    }

    private func handleDisconnect(task: URLSessionWebSocketTask) {
        guard socketTask === task else { return }
        socketTask = nil
        receiveTask = nil
        failAllPending(with: SpectraChatRealtimeError.disconnected)
        guard !intentionallyDisconnected, (!subscribers.isEmpty || !eventSubscribers.isEmpty) else {
            yield(.connectionChanged(.disconnected))
            yield(.disconnected(SpectraChatConnectionEvent()))
            return
        }
        scheduleReconnect()
    }

    private func scheduleReconnect() {
        guard reconnectTask == nil else { return }
        reconnectAttempt += 1
        let attempt = reconnectAttempt
        yield(.connectionChanged(.reconnecting(attempt: attempt)))
        var fields: [String: String] = ["attempt": String(attempt)]
        if let activeRoomID {
            fields["roomID"] = activeRoomID
        }
        client.delegate?.spectraChatClient(client, didChangeConnectionState: .reconnecting(attempt: attempt))
        client.logger?(.warning, "reconnecting", fields)
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

    private func removeEventSubscriber(_ id: UUID) {
        eventSubscribers[id] = nil
    }

    private func yield(_ event: SpectraChatRealtimeEvent) {
        subscribers.values.forEach { $0.yield(event) }
    }

    private func yield(_ event: SpectraChatEvent) {
        eventSubscribers.values.forEach { $0.yield(event) }
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

    private func shouldDeliver(_ event: SpectraChatRealtimeEvent) -> Bool {
        Self.shouldDeliver(event, subscribedRoomIDs: subscribedRoomIDs)
    }

    private func shouldDeliver(_ event: SpectraChatEvent) -> Bool {
        Self.shouldDeliver(event, subscribedRoomIDs: subscribedRoomIDs)
    }
}

private struct SocketEventHeader: Decodable {
    var eventID: String?
    var eventType: String
    var roomID: String?

    enum CodingKeys: String, CodingKey {
        case eventID = "event_id"
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

private struct EmptySocketPayload: Decodable {}

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

private func withMembershipDeadline<T: Sendable>(
    _ options: SpectraChatMembershipRequestOptions,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    let timeout = options.timeout ?? 10
    let nanoseconds = try membershipTimeoutNanoseconds(timeout)
    do {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: nanoseconds)
                throw SpectraChatError.requestTimeout(
                    SpectraChatErrorResponse(
                        code: "REQUEST_TIMEOUT",
                        message: "Chat membership request timed out; query membership before updating the app.",
                        retryable: true
                    )
                )
            }
            guard let value = try await group.next() else {
                throw SpectraChatError.invalidResponse
            }
            group.cancelAll()
            return value
        }
    } catch is CancellationError {
        throw SpectraChatError.requestCancelled(
            SpectraChatErrorResponse(
                code: "REQUEST_ABORTED",
                message: "Chat membership request was cancelled; server state may have changed.",
                retryable: false
            )
        )
    }
}

private func membershipTimeoutNanoseconds(_ timeout: TimeInterval) throws -> UInt64 {
    guard timeout.isFinite, timeout > 0 else {
        throw SpectraChatError.requestTimeout(
            SpectraChatErrorResponse(
                code: "REQUEST_TIMEOUT_INVALID",
                message: "timeout must be positive.",
                retryable: false
            )
        )
    }
    let nanoseconds = timeout * 1_000_000_000
    guard nanoseconds.isFinite, nanoseconds <= Double(UInt64.max) else {
        throw SpectraChatError.requestTimeout(
            SpectraChatErrorResponse(
                code: "REQUEST_TIMEOUT_INVALID",
                message: "timeout is too large.",
                retryable: false
            )
        )
    }
    return UInt64(nanoseconds.rounded(.up))
}

private func validateMembership(_ membership: SpectraChatRoomMembership, roomID: String) throws {
    guard membership.roomID == roomID,
          membership.appUserID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
        throw SpectraChatError.invalidResponse
    }
}

private func validatedRoomID(_ roomID: String?) throws -> String {
    guard let roomID,
          roomID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
        throw SpectraChatError.roomIDRequired
    }
    return roomID
}

private func connectionID(from eventID: String?) -> String? {
    guard let eventID,
          eventID.hasPrefix("evt_connection_") else {
        return nil
    }
    return String(eventID.dropFirst("evt_connection_".count))
}

private func safeErrorCode(_ error: Error) -> String {
    if let chatError = error as? SpectraChatError {
        return chatError.code
    }
    if let realtimeError = error as? SpectraChatRealtimeError {
        switch realtimeError {
        case .disconnected:
            return "SOCKET_DISCONNECTED"
        case .acknowledgementTimedOut:
            return "MESSAGE_ACK_TIMEOUT"
        case .server(let serverError):
            return serverError.code
        }
    }
    return "UNKNOWN"
}

private func normalizedChatAttachmentPath(
    explicitPath: String?,
    roomID: String,
    fileName: String,
    index: Int,
    pathPrefix: String?
) throws -> String {
    if let explicitPath {
        let trimmed = explicitPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            throw SpectraChatError.invalidRequest("file path is required")
        }
        return trimmed.hasPrefix("/") ? trimmed : "/\(trimmed)"
    }
    let prefix = normalizedPathPrefix(pathPrefix ?? "/chat/\(safePathSegment(roomID))")
    let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
    return "\(prefix)/\(timestamp)-\(index + 1)-\(UUID().uuidString)-\(safeFileName(fileName))"
}

private func normalizedPathPrefix(_ value: String) -> String {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    let rooted = trimmed.hasPrefix("/") ? trimmed : "/\(trimmed)"
    let normalized = rooted.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    return normalized.isEmpty ? "/chat" : "/\(normalized)"
}

private func normalizedFileName(_ value: String?, fallback: String) -> String {
    let raw = value?.trimmingCharacters(in: .whitespacesAndNewlines)
    let leaf = raw?.split(whereSeparator: { $0 == "/" || $0 == "\\" }).last.map(String.init)
    let candidate = leaf?.isEmpty == false ? leaf! : fallback
    return candidate
}

private func normalizedContentType(_ value: String?) -> String {
    guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
          value.isEmpty == false else {
        return "application/octet-stream"
    }
    return value
}

private func safePathSegment(_ value: String) -> String {
    let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")
    let transformed = value.unicodeScalars.map { scalar -> Character in
        allowed.contains(scalar) ? Character(scalar) : "-"
    }
    let sanitized = String(transformed).trimmingCharacters(in: CharacterSet(charactersIn: ".-_"))
    return sanitized.isEmpty ? "room" : sanitized
}

private func safeFileName(_ value: String) -> String {
    let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")
    let transformed = value.unicodeScalars.map { scalar -> Character in
        allowed.contains(scalar) ? Character(scalar) : "-"
    }
    let sanitized = String(transformed).trimmingCharacters(in: CharacterSet(charactersIn: ".-_"))
    return sanitized.isEmpty ? "attachment" : sanitized
}

private func attachmentKind(_ contentType: String) -> String {
    if contentType.lowercased().hasPrefix("image/") { return "image" }
    if contentType.lowercased().hasPrefix("video/") { return "video" }
    if contentType.lowercased().hasPrefix("audio/") { return "audio" }
    return "file"
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
