import Foundation
import XCTest
@testable import SpectraChatSDK

final class SpectraChatOfflineSupportTests: XCTestCase {
    func testPaginationStateBuildsNextBeforeSequenceAndExhaustion() {
        var state = SpectraChatMessagePaginationState(roomID: "room_1", limit: 2)
        XCTAssertEqual(state.nextRequest, SpectraChatMessagePageRequest(roomID: "room_1", limit: 2))

        let firstPage = SpectraChatMessagePage(
            request: state.nextRequest!,
            messages: [
                Self.message(sequence: 9),
                Self.message(sequence: 10),
            ],
            hasMore: true
        )
        state.record(firstPage)

        XCTAssertEqual(state.nextBeforeSequence, 9)
        XCTAssertFalse(state.isExhausted)
        XCTAssertEqual(
            state.nextRequest,
            SpectraChatMessagePageRequest(roomID: "room_1", beforeSequence: 9, limit: 2)
        )

        state.record(
            SpectraChatMessagePage(
                request: state.nextRequest!,
                messages: [Self.message(sequence: 8)],
                hasMore: false
            )
        )

        XCTAssertTrue(state.isExhausted)
        XCTAssertNil(state.nextRequest)
    }

    func testInMemoryStoreMergesRealtimeMessagesAndReadCursor() async {
        let store = SpectraChatInMemoryStore()

        await store.upsertMessages([
            Self.message(sequence: 2, text: "second"),
            Self.message(sequence: 1, text: "first"),
        ])
        await store.apply(.messageCreated(Self.message(sequence: 3, text: "third")))
        await store.apply(
            .readCursorUpdated(
                SpectraChatReadCursorUpdated(
                    roomID: "room_1",
                    userID: "user_2",
                    lastReadServerSequence: 2
                )
            )
        )
        await store.apply(
            .readCursorUpdated(
                SpectraChatReadCursorUpdated(
                    roomID: "room_1",
                    userID: "user_2",
                    lastReadServerSequence: 1
                )
            )
        )

        let messages = await store.messages(roomID: "room_1", beforeSequence: 3, limit: 2)
        let readCursor = await store.readCursor(roomID: "room_1")
        XCTAssertEqual(messages.map(\.serverSequence), [1, 2])
        XCTAssertEqual(messages.map(\.content.text), ["first", "second"])
        XCTAssertEqual(readCursor, 2)
    }

    func testOfflineQueueFlushSendsInOrderAndRemovesSuccessfulMessages() async {
        let queue = SpectraChatOfflineSendQueue()
        let sender = RecordingMessageSender()

        let first = await queue.enqueue(
            roomID: "room_1",
            content: SpectraChatSendContent(kind: "text", text: "one"),
            clientMessageID: "client_1",
            idempotencyKey: "idem_1"
        )
        _ = await queue.enqueue(
            roomID: "room_1",
            content: SpectraChatSendContent(kind: "text", text: "two"),
            clientMessageID: "client_2",
            idempotencyKey: "idem_2"
        )

        await sender.fail(clientMessageID: "client_2")
        let result = await queue.flush(using: sender)

        XCTAssertEqual(result.sentMessages.map(\.clientMessageID), ["client_1"])
        XCTAssertEqual(result.failedQueuedMessages.map(\.message.clientMessageID), ["client_2"])
        XCTAssertEqual(result.failedQueuedMessages.first?.attemptCount, 1)
        XCTAssertEqual(result.remainingQueuedMessages.map(\.queueID), [result.failedQueuedMessages[0].queueID])
        XCTAssertFalse(result.remainingQueuedMessages.contains(first))

        await sender.clearFailures()
        let retry = await queue.flush(using: sender)
        let recordedIdempotencyKeys = await sender.recordedIdempotencyKeys()

        XCTAssertEqual(retry.sentMessages.map(\.clientMessageID), ["client_2"])
        XCTAssertTrue(retry.remainingQueuedMessages.isEmpty)
        XCTAssertEqual(recordedIdempotencyKeys, ["idem_1", "idem_2", "idem_2"])
    }

    private static func message(
        sequence: Int64,
        roomID: String = "room_1",
        text: String = "message"
    ) -> SpectraChatMessage {
        SpectraChatMessage(
            messageID: "msg_\(sequence)",
            roomID: roomID,
            serverSequence: sequence,
            clientMessageID: "client_\(sequence)",
            senderUserID: "user_1",
            content: SpectraChatContent(kind: "text", text: text),
            replyToMessageID: nil,
            mentionedUserIDs: [],
            createdAt: Date(timeIntervalSince1970: TimeInterval(sequence)),
            editedAt: nil,
            deletedAt: nil
        )
    }
}

private actor RecordingMessageSender: SpectraChatMessageSending {
    private var failingClientMessageIDs: Set<String> = []
    private var idempotencyKeys: [String] = []

    func fail(clientMessageID: String) {
        failingClientMessageIDs.insert(clientMessageID)
    }

    func clearFailures() {
        failingClientMessageIDs.removeAll()
    }

    func recordedIdempotencyKeys() -> [String] {
        idempotencyKeys
    }

    func sendMessage(
        roomID: String,
        content: SpectraChatSendContent,
        clientMessageID: String,
        replyToMessageID: String?,
        mentionedUserIDs: [String],
        idempotencyKey: String?
    ) async throws -> SpectraChatMessage {
        idempotencyKeys.append(idempotencyKey ?? "")
        if failingClientMessageIDs.contains(clientMessageID) {
            throw SpectraChatError.invalidRequest("offline")
        }
        return SpectraChatMessage(
            messageID: "server_\(clientMessageID)",
            roomID: roomID,
            serverSequence: Int64(idempotencyKeys.count),
            clientMessageID: clientMessageID,
            senderUserID: "user_1",
            content: SpectraChatContent(
                kind: content.kind,
                text: content.text,
                storageObjectReferences: content.storageObjectReferences
            ),
            replyToMessageID: replyToMessageID,
            mentionedUserIDs: mentionedUserIDs,
            createdAt: Date(timeIntervalSince1970: TimeInterval(idempotencyKeys.count)),
            editedAt: nil,
            deletedAt: nil
        )
    }
}
