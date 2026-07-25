import Foundation

public protocol SpectraChatMessageSending: Sendable {
    func sendMessage(
        roomID: String,
        content: SpectraChatSendContent,
        clientMessageID: String,
        replyToMessageID: String?,
        mentionedUserIDs: [String],
        idempotencyKey: String?
    ) async throws -> SpectraChatMessage
}

extension SpectraChatClient: SpectraChatMessageSending {}

public struct SpectraChatMessagePageRequest: Equatable, Sendable {
    public var roomID: String
    public var beforeSequence: Int64?
    public var limit: Int

    public init(roomID: String, beforeSequence: Int64? = nil, limit: Int = 50) {
        self.roomID = roomID
        self.beforeSequence = beforeSequence
        self.limit = limit
    }
}

public struct SpectraChatMessagePage: Equatable, Sendable {
    public var request: SpectraChatMessagePageRequest
    public var messages: [SpectraChatMessage]
    public var hasMore: Bool

    public init(
        request: SpectraChatMessagePageRequest,
        messages: [SpectraChatMessage],
        hasMore: Bool
    ) {
        self.request = request
        self.messages = messages
        self.hasMore = hasMore
    }

    public var nextBeforeSequence: Int64? {
        messages.map(\.serverSequence).min()
    }
}

public struct SpectraChatMessagePaginationState: Equatable, Sendable {
    public var roomID: String
    public var limit: Int
    public var nextBeforeSequence: Int64?
    public var isExhausted: Bool

    public init(
        roomID: String,
        limit: Int = 50,
        nextBeforeSequence: Int64? = nil,
        isExhausted: Bool = false
    ) {
        self.roomID = roomID
        self.limit = limit
        self.nextBeforeSequence = nextBeforeSequence
        self.isExhausted = isExhausted
    }

    public var nextRequest: SpectraChatMessagePageRequest? {
        guard !isExhausted else { return nil }
        return SpectraChatMessagePageRequest(
            roomID: roomID,
            beforeSequence: nextBeforeSequence,
            limit: limit
        )
    }

    public mutating func record(_ page: SpectraChatMessagePage) {
        nextBeforeSequence = page.nextBeforeSequence
        isExhausted = !page.hasMore || page.messages.isEmpty
    }
}

public actor SpectraChatMessagePaginator {
    private let client: SpectraChatClient
    private var state: SpectraChatMessagePaginationState

    public init(
        client: SpectraChatClient,
        roomID: String,
        limit: Int = 50,
        beforeSequence: Int64? = nil
    ) {
        self.client = client
        self.state = SpectraChatMessagePaginationState(
            roomID: roomID,
            limit: limit,
            nextBeforeSequence: beforeSequence
        )
    }

    public func currentState() -> SpectraChatMessagePaginationState {
        state
    }

    public func reset(beforeSequence: Int64? = nil) {
        state.nextBeforeSequence = beforeSequence
        state.isExhausted = false
    }

    @discardableResult
    public func loadNextPage() async throws -> SpectraChatMessagePage {
        guard let request = state.nextRequest else {
            return SpectraChatMessagePage(
                request: SpectraChatMessagePageRequest(
                    roomID: state.roomID,
                    beforeSequence: state.nextBeforeSequence,
                    limit: state.limit
                ),
                messages: [],
                hasMore: false
            )
        }
        let messages = try await client.listMessages(
            roomID: request.roomID,
            beforeSequence: request.beforeSequence,
            limit: request.limit
        )
        let page = SpectraChatMessagePage(
            request: request,
            messages: messages,
            hasMore: messages.count >= request.limit
        )
        state.record(page)
        return page
    }
}

public actor SpectraChatInMemoryStore {
    private var roomsByID: [String: SpectraChatRoom] = [:]
    private var messagesByRoomID: [String: [Int64: SpectraChatMessage]] = [:]
    private var readCursorsByRoomID: [String: Int64] = [:]

    public init() {}

    public func upsertRoom(_ room: SpectraChatRoom) {
        roomsByID[room.roomID] = room
    }

    public func upsertRooms(_ rooms: [SpectraChatRoom]) {
        for room in rooms {
            roomsByID[room.roomID] = room
        }
    }

    public func room(roomID: String) -> SpectraChatRoom? {
        roomsByID[roomID]
    }

    public func roomsSortedByUpdatedAtDescending() -> [SpectraChatRoom] {
        roomsByID.values.sorted { lhs, rhs in
            if lhs.updatedAt == rhs.updatedAt {
                return lhs.roomID < rhs.roomID
            }
            return lhs.updatedAt > rhs.updatedAt
        }
    }

    public func upsertMessage(_ message: SpectraChatMessage) {
        var messages = messagesByRoomID[message.roomID, default: [:]]
        messages[message.serverSequence] = message
        messagesByRoomID[message.roomID] = messages
    }

    public func upsertMessages(_ messages: [SpectraChatMessage]) {
        for message in messages {
            upsertMessage(message)
        }
    }

    public func messages(
        roomID: String,
        beforeSequence: Int64? = nil,
        limit: Int? = nil
    ) -> [SpectraChatMessage] {
        let sorted = messagesByRoomID[roomID, default: [:]]
            .values
            .filter { message in
                guard let beforeSequence else { return true }
                return message.serverSequence < beforeSequence
            }
            .sorted { $0.serverSequence < $1.serverSequence }
        if let limit, sorted.count > limit {
            return Array(sorted.suffix(limit))
        }
        return sorted
    }

    public func apply(_ event: SpectraChatRealtimeEvent) {
        switch event {
        case .messageCreated(let message):
            upsertMessage(message)
        case .readCursorUpdated(let cursor):
            updateReadCursor(
                roomID: cursor.roomID,
                lastReadServerSequence: cursor.lastReadServerSequence
            )
        default:
            break
        }
    }

    public func updateReadCursor(roomID: String, lastReadServerSequence: Int64) {
        let current = readCursorsByRoomID[roomID] ?? 0
        readCursorsByRoomID[roomID] = max(current, lastReadServerSequence)
    }

    public func readCursor(roomID: String) -> Int64? {
        readCursorsByRoomID[roomID]
    }

    public func removeRoom(roomID: String) {
        roomsByID.removeValue(forKey: roomID)
        messagesByRoomID.removeValue(forKey: roomID)
        readCursorsByRoomID.removeValue(forKey: roomID)
    }

    public func removeAll() {
        roomsByID.removeAll()
        messagesByRoomID.removeAll()
        readCursorsByRoomID.removeAll()
    }
}

public struct SpectraChatQueuedMessage: Codable, Equatable, Sendable {
    public var queueID: String
    public var roomID: String
    public var message: SpectraChatSendMessage
    public var idempotencyKey: String
    public var enqueuedAt: Date
    public var attemptCount: Int
    public var lastFailureDescription: String?

    public init(
        queueID: String = UUID().uuidString,
        roomID: String,
        message: SpectraChatSendMessage,
        idempotencyKey: String? = nil,
        enqueuedAt: Date = Date(),
        attemptCount: Int = 0,
        lastFailureDescription: String? = nil
    ) {
        self.queueID = queueID
        self.roomID = roomID
        self.message = message
        self.idempotencyKey = idempotencyKey ?? message.clientMessageID
        self.enqueuedAt = enqueuedAt
        self.attemptCount = attemptCount
        self.lastFailureDescription = lastFailureDescription
    }
}

public struct SpectraChatOfflineFlushResult: Equatable, Sendable {
    public var sentMessages: [SpectraChatMessage]
    public var failedQueuedMessages: [SpectraChatQueuedMessage]
    public var remainingQueuedMessages: [SpectraChatQueuedMessage]

    public init(
        sentMessages: [SpectraChatMessage],
        failedQueuedMessages: [SpectraChatQueuedMessage],
        remainingQueuedMessages: [SpectraChatQueuedMessage]
    ) {
        self.sentMessages = sentMessages
        self.failedQueuedMessages = failedQueuedMessages
        self.remainingQueuedMessages = remainingQueuedMessages
    }
}

public actor SpectraChatOfflineSendQueue {
    private var queuedMessages: [SpectraChatQueuedMessage] = []

    public init() {}

    @discardableResult
    public func enqueue(
        roomID: String,
        content: SpectraChatSendContent,
        clientMessageID: String = UUID().uuidString,
        replyToMessageID: String? = nil,
        mentionedUserIDs: [String] = [],
        idempotencyKey: String? = nil,
        enqueuedAt: Date = Date()
    ) -> SpectraChatQueuedMessage {
        let queued = SpectraChatQueuedMessage(
            roomID: roomID,
            message: SpectraChatSendMessage(
                clientMessageID: clientMessageID,
                content: content,
                replyToMessageID: replyToMessageID,
                mentionedUserIDs: mentionedUserIDs
            ),
            idempotencyKey: idempotencyKey,
            enqueuedAt: enqueuedAt
        )
        queuedMessages.append(queued)
        return queued
    }

    public func pendingMessages(roomID: String? = nil) -> [SpectraChatQueuedMessage] {
        guard let roomID else { return queuedMessages }
        return queuedMessages.filter { $0.roomID == roomID }
    }

    public func remove(queueID: String) {
        queuedMessages.removeAll { $0.queueID == queueID }
    }

    public func removeAll() {
        queuedMessages.removeAll()
    }

    @discardableResult
    public func flush(
        using sender: any SpectraChatMessageSending,
        roomID: String? = nil,
        limit: Int? = nil
    ) async -> SpectraChatOfflineFlushResult {
        let candidates = queuedMessages
            .filter { queued in
                guard let roomID else { return true }
                return queued.roomID == roomID
            }
            .prefix(limit ?? queuedMessages.count)

        var sent: [SpectraChatMessage] = []
        var failed: [SpectraChatQueuedMessage] = []

        for queued in candidates {
            do {
                let message = try await sender.sendMessage(
                    roomID: queued.roomID,
                    content: queued.message.content,
                    clientMessageID: queued.message.clientMessageID,
                    replyToMessageID: queued.message.replyToMessageID,
                    mentionedUserIDs: queued.message.mentionedUserIDs,
                    idempotencyKey: queued.idempotencyKey
                )
                sent.append(message)
                queuedMessages.removeAll { $0.queueID == queued.queueID }
            } catch {
                var updated = queued
                updated.attemptCount += 1
                updated.lastFailureDescription = String(describing: error)
                if let index = queuedMessages.firstIndex(where: { $0.queueID == queued.queueID }) {
                    queuedMessages[index] = updated
                }
                failed.append(updated)
            }
        }

        return SpectraChatOfflineFlushResult(
            sentMessages: sent,
            failedQueuedMessages: failed,
            remainingQueuedMessages: queuedMessages
        )
    }
}
