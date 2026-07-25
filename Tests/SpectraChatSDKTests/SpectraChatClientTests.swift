import Foundation
import SpectraStorageSDK
import XCTest
@testable import SpectraChatSDK

final class SpectraChatClientTests: XCTestCase {
    override func tearDown() {
        MockURLProtocol.handler = nil
        super.tearDown()
    }

    func testListRoomsAttachesBearerAndDecodesRooms() async throws {
        let client = makeClient()
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer chat_access_token")
            XCTAssertEqual(request.url?.path, "/v1/chat/rooms")
            XCTAssertEqual(URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)?.queryItems?.first?.value, "20")
            return jsonResponse(
                status: 200,
                body: """
                {
                  "data": {
                    "rooms": [
                      {
                        "room_id": "room_123",
                        "kind": "direct",
                        "title": null,
                        "participant_user_ids": ["usr_a", "usr_b"],
                        "last_server_sequence": 10,
                        "last_read_server_sequence": 8,
                        "unread_count": 2,
                        "created_at": "2026-07-24T01:00:00Z",
                        "updated_at": "2026-07-24T01:01:00Z"
                      }
                    ]
                  }
                }
                """
            )
        }

        let rooms = try await client.listRooms(limit: 20)

        XCTAssertEqual(rooms.map(\.roomID), ["room_123"])
        XCTAssertEqual(rooms.first?.unreadCount, 2)
    }

    func testListMessagesUsesHistoryPathAndDecodesTextMessage() async throws {
        let client = makeClient()
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/v1/chat/rooms/room_123/messages")
            let query = URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)?.queryItems ?? []
            XCTAssertEqual(query.first(where: { $0.name == "before_sequence" })?.value, "10")
            XCTAssertEqual(query.first(where: { $0.name == "limit" })?.value, "30")
            return jsonResponse(
                status: 200,
                body: """
                {
                  "data": {
                    "messages": [
                      {
                        "message_id": "msg_123",
                        "room_id": "room_123",
                        "server_sequence": 9,
                        "client_message_id": "client_123",
                        "sender_user_id": "usr_a",
                        "content": {
                          "kind": "text",
                          "text": "hello",
                          "media_items": []
                        },
                        "reply_to_message_id": null,
                        "mentioned_user_ids": [],
                        "created_at": "2026-07-24T01:02:00Z",
                        "edited_at": null,
                        "deleted_at": null
                      }
                    ]
                  }
                }
                """
            )
        }

        let messages = try await client.listMessages(roomID: "room_123", beforeSequence: 10, limit: 30)

        XCTAssertEqual(messages.map(\.messageID), ["msg_123"])
        XCTAssertEqual(messages.first?.content.text, "hello")
    }

    func testListMessagesDecodesStorageObjectReferences() async throws {
        let client = makeClient()
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/v1/chat/rooms/room_123/messages")
            return jsonResponse(
                status: 200,
                body: """
                {
                  "data": {
                    "messages": [
                      {
                        "message_id": "msg_storage_123",
                        "room_id": "room_123",
                        "server_sequence": 11,
                        "client_message_id": "client_storage_123",
                        "sender_user_id": "usr_a",
                        "content": {
                          "kind": "image",
                          "text": "사진",
                          "media_items": [],
                          "storage_object_references": [
                            {
                              "object_key": "/chat/media/object_123.jpg",
                              "content_type": "image/jpeg",
                              "byte_size": 1234,
                              "checksum_sha256": "checksum",
                              "metadata": {"spectra_purpose": "chat_image"}
                            }
                          ]
                        },
                        "reply_to_message_id": null,
                        "mentioned_user_ids": [],
                        "created_at": "2026-07-24T01:02:00Z",
                        "edited_at": null,
                        "deleted_at": null
                      }
                    ]
                  }
                }
                """
            )
        }

        let messages = try await client.listMessages(roomID: "room_123")
        let reference = try XCTUnwrap(messages.first?.content.storageObjectReferences?.first)

        XCTAssertEqual(reference.objectKey, "/chat/media/object_123.jpg")
        XCTAssertEqual(reference.contentType, "image/jpeg")
        XCTAssertEqual(reference.byteSize, 1234)
        XCTAssertEqual(reference.checksumSHA256, "checksum")
        XCTAssertEqual(reference.metadata["spectra_purpose"], "chat_image")
    }

    func testCreateDirectRoomSendsParticipant() async throws {
        let client = makeClient()
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            XCTAssertEqual(request.url?.path, "/v1/chat/rooms/direct")
            let json = try JSONSerialization.jsonObject(with: requestBodyData(request)) as? [String: Any]
            XCTAssertEqual(json?["participant_user_id"] as? String, "usr_b")
            return roomResponse(status: 201)
        }

        let room = try await client.createDirectRoom(participantUserID: "usr_b")

        XCTAssertEqual(room.roomID, "room_123")
    }

    func testSendMessageUsesBearerProjectAndIdempotency() async throws {
        let client = makeClient(projectId: "project_123")
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/v1/chat/rooms/room_123/messages")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer chat_access_token")
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Spectra-Project-Id"), "project_123")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Idempotency-Key"), "idem_123")
            let json = try JSONSerialization.jsonObject(with: requestBodyData(request)) as? [String: Any]
            XCTAssertEqual(json?["client_message_id"] as? String, "client_123")
            let content = json?["content"] as? [String: Any]
            XCTAssertEqual(content?["kind"] as? String, "text")
            XCTAssertEqual(content?["text"] as? String, "hello")
            let storageRefs = content?["storage_object_references"] as? [[String: Any]]
            XCTAssertEqual(storageRefs?.first?["object_key"] as? String, "/chat/room_123/image.png")
            XCTAssertEqual(storageRefs?.first?["content_type"] as? String, "image/png")
            return messageResponse(status: 201)
        }

        let message = try await client.sendMessage(
            roomID: "room_123",
            content: SpectraChatSendContent(
                kind: "text",
                text: "hello",
                storageObjectReferences: [
                    SpectraChatStorageObjectReference(
                        objectKey: "/chat/room_123/image.png",
                        contentType: "image/png",
                        byteSize: 10,
                        checksumSHA256: "checksum"
                    ),
                ]
            ),
            clientMessageID: "client_123",
            idempotencyKey: "idem_123"
        )

        XCTAssertEqual(message.messageID, "msg_123")
        XCTAssertEqual(message.content.text, "hello")
    }

    func testStorageAttachmentSenderUploadsImageThenSendsMessage() async throws {
        let chat = makeClient(projectId: "project_123")
        let storage = makeStorageClient()
        let sender = SpectraChatStorageAttachmentSender(chat: chat, storage: storage)
        var requestIndex = 0

        MockURLProtocol.handler = { request in
            defer { requestIndex += 1 }
            switch requestIndex {
            case 0:
                XCTAssertEqual(request.httpMethod, "POST")
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer storage_access_token")
                XCTAssertEqual(request.url?.path, "/platform/v1/projects/project_123/storage/user-root/upload-intents")
                let body = try JSONSerialization.jsonObject(with: requestBodyData(request)) as? [String: Any]
                XCTAssertEqual(body?["object_key"] as? String, "/chat/room_123/images/client_image_123/0.jpg")
                XCTAssertEqual(body?["content_type"] as? String, "image/jpeg")
                let metadata = try XCTUnwrap(body?["metadata"] as? [String: String])
                XCTAssertEqual(metadata["purpose"], "chat_image")
                XCTAssertEqual(metadata["room_id"], "room_123")
                XCTAssertEqual(metadata["client_message_id"], "client_image_123")
                return jsonResponse(
                    status: 201,
                    body: """
                    {
                      "data": {
                        "upload_id": "upl_chat_image",
                        "object_key": "/chat/room_123/images/client_image_123/0.jpg",
                        "upload_method": "PUT",
                        "upload_url": "https://chat.example.test/signed-put/chat-image",
                        "upload_headers": {
                          "Content-Type": "image/jpeg"
                        },
                        "expires_at": "2026-07-24T01:15:00Z"
                      }
                    }
                    """
                )
            case 1:
                XCTAssertEqual(request.httpMethod, "PUT")
                XCTAssertEqual(request.url?.path, "/signed-put/chat-image")
                XCTAssertEqual(try requestBodyData(request), Data("image-data".utf8))
                return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data())
            case 2:
                XCTAssertEqual(request.httpMethod, "POST")
                XCTAssertEqual(request.value(forHTTPHeaderField: "Idempotency-Key"), "storage-chat_image-complete-client_image_123")
                XCTAssertEqual(request.url?.path, "/platform/v1/projects/project_123/storage/user-root/upload-intents/upl_chat_image/complete")
                return storageObjectEnvelope(
                    status: 202,
                    objectKey: "/chat/room_123/images/client_image_123/0.jpg",
                    contentType: "image/jpeg",
                    byteSize: 10,
                    metadata: [
                        "purpose": "chat_image",
                        "room_id": "room_123",
                        "client_message_id": "client_image_123"
                    ]
                )
            default:
                XCTAssertEqual(request.httpMethod, "POST")
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer chat_access_token")
                XCTAssertEqual(request.value(forHTTPHeaderField: "Idempotency-Key"), "chat-message-client_image_123")
                XCTAssertEqual(request.url?.path, "/v1/chat/rooms/room_123/messages")
                let json = try JSONSerialization.jsonObject(with: requestBodyData(request)) as? [String: Any]
                XCTAssertEqual(json?["client_message_id"] as? String, "client_image_123")
                let content = json?["content"] as? [String: Any]
                XCTAssertEqual(content?["kind"] as? String, "image")
                XCTAssertEqual(content?["text"] as? String, "caption")
                let refs = try XCTUnwrap(content?["storage_object_references"] as? [[String: Any]])
                XCTAssertEqual(refs.first?["object_key"] as? String, "/chat/room_123/images/client_image_123/0.jpg")
                XCTAssertEqual(refs.first?["content_type"] as? String, "image/jpeg")
                return messageResponse(status: 201)
            }
        }

        let message = try await sender.sendImageMessage(
            roomID: "room_123",
            imageData: Data("image-data".utf8),
            contentType: "image/jpeg",
            caption: "caption",
            clientMessageID: "client_image_123",
            idempotencySeed: "client_image_123"
        )

        XCTAssertEqual(message.messageID, "msg_123")
        XCTAssertEqual(requestIndex, 4)
    }

    func testReadMediaURLsSendsAssetIDs() async throws {
        let client = makeClient()
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/v1/chat/rooms/room_123/media/read-urls")
            let json = try JSONSerialization.jsonObject(with: requestBodyData(request)) as? [String: Any]
            XCTAssertEqual(json?["asset_ids"] as? [String], ["ast_1"])
            return jsonResponse(
                status: 200,
                body: """
                {
                  "data": {
                    "assets": [
                      {
                        "asset_id": "ast_1",
                        "url": "https://media.example.test/read",
                        "expires_at": "2026-07-24T01:05:00Z"
                      }
                    ]
                  }
                }
                """
            )
        }

        let urls = try await client.readMediaURLs(roomID: "room_123", assetIDs: ["ast_1"])

        XCTAssertEqual(urls.first?.assetID, "ast_1")
        XCTAssertEqual(urls.first?.url.absoluteString, "https://media.example.test/read")
    }

    func testCommandEnvelopeMatchesChatSocketContract() throws {
        let client = makeClient()
        let command = client.makeTextMessageCommand(
            roomID: "room_123",
            text: "hello",
            clientMessageID: "client_123",
            eventID: "evt_123"
        )

        let encoded = try JSONEncoder().encode(command)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        XCTAssertEqual(json?["schema_version"] as? Int, 1)
        XCTAssertEqual(json?["event_id"] as? String, "evt_123")
        XCTAssertEqual(json?["event_type"] as? String, "message.send")
        XCTAssertEqual(json?["room_id"] as? String, "room_123")
        let payload = json?["payload"] as? [String: Any]
        XCTAssertEqual(payload?["client_message_id"] as? String, "client_123")
        let content = payload?["content"] as? [String: Any]
        XCTAssertEqual(content?["kind"] as? String, "text")
        XCTAssertEqual(content?["text"] as? String, "hello")
    }

    func testSocketRequestUsesWebSocketURLAndBearer() async throws {
        let client = makeClient(baseURL: URL(string: "https://chat.example.test/api")!)

        let request = try await client.socketRequest()

        XCTAssertEqual(request.url?.absoluteString, "wss://chat.example.test/api/v1/socket")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer chat_access_token")
    }

    func testSocketRequestUsesExplicitSocketURLWhenConfigured() async throws {
        let client = makeClient(
            baseURL: URL(string: "https://chat.example.test/api")!,
            socketURL: URL(string: "ws://192.168.200.113:8080/v1/socket")!,
            projectId: "project_123"
        )

        let request = try await client.socketRequest()

        XCTAssertEqual(request.url?.absoluteString, "ws://192.168.200.113:8080/v1/socket")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer chat_access_token")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Spectra-Project-Id"), "project_123")
    }

    func testTypingCommandMatchesSocketContract() throws {
        let client = makeClient()

        let command = client.makeTypingCommand(roomID: "room_123", isTyping: true, eventID: "evt_typing_123")
        let encoded = try JSONEncoder().encode(command)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]

        XCTAssertEqual(json?["event_id"] as? String, "evt_typing_123")
        XCTAssertEqual(json?["event_type"] as? String, "typing.set")
        XCTAssertEqual(json?["room_id"] as? String, "room_123")
        let payload = json?["payload"] as? [String: Any]
        XCTAssertEqual(payload?["is_typing"] as? Bool, true)
    }

    func testRealtimeDecoderDecodesConnectionReady() throws {
        let data = Data(
            """
            {
              "schema_version": 1,
              "event_id": "evt_ready",
              "event_type": "connection.ready",
              "room_id": null,
              "server_sequence": null,
              "occurred_at": "2026-07-25T00:00:00Z",
              "payload": {}
            }
            """.utf8
        )

        let event = try SpectraChatRealtimeClient.decodeEvent(from: data)

        XCTAssertEqual(event, .connectionChanged(.connected))
    }

    func testRealtimeDecoderDecodesMessageCreated() throws {
        let data = Data(
            """
            {
              "schema_version": 1,
              "event_id": "evt_msg",
              "event_type": "message.created",
              "room_id": "room_123",
              "server_sequence": 2,
              "occurred_at": "2026-07-25T00:00:00Z",
              "payload": {
                "message": {
                  "message_id": "msg_123",
                  "room_id": "room_123",
                  "server_sequence": 2,
                  "client_message_id": "client_123",
                  "sender_user_id": "usr_a",
                  "content": {
                    "kind": "text",
                    "text": "hello realtime",
                    "media_items": []
                  },
                  "reply_to_message_id": null,
                  "mentioned_user_ids": [],
                  "created_at": "2026-07-25T00:00:01Z",
                  "edited_at": null,
                  "deleted_at": null
                }
              }
            }
            """.utf8
        )

        let event = try SpectraChatRealtimeClient.decodeEvent(from: data)

        guard case .messageCreated(let message) = event else {
            return XCTFail("Expected messageCreated, got \(event)")
        }
        XCTAssertEqual(message.messageID, "msg_123")
        XCTAssertEqual(message.content.text, "hello realtime")
    }

    func testRealtimeDecoderDecodesReadCursorAndTyping() throws {
        let readCursorData = Data(
            """
            {
              "schema_version": 1,
              "event_id": "evt_read",
              "event_type": "read_cursor.updated",
              "room_id": "room_123",
              "server_sequence": 3,
              "occurred_at": "2026-07-25T00:00:02Z",
              "payload": {
                "user_id": "usr_b",
                "last_read_server_sequence": 3
              }
            }
            """.utf8
        )
        let typingData = Data(
            """
            {
              "schema_version": 1,
              "event_id": "evt_typing",
              "event_type": "typing.updated",
              "room_id": "room_123",
              "server_sequence": 4,
              "occurred_at": "2026-07-25T00:00:03Z",
              "payload": {
                "user_id": "usr_b",
                "is_typing": true
              }
            }
            """.utf8
        )

        let readCursor = try SpectraChatRealtimeClient.decodeEvent(from: readCursorData)
        let typing = try SpectraChatRealtimeClient.decodeEvent(from: typingData)

        XCTAssertEqual(
            readCursor,
            .readCursorUpdated(
                SpectraChatReadCursorUpdated(
                    roomID: "room_123",
                    userID: "usr_b",
                    lastReadServerSequence: 3
                )
            )
        )
        XCTAssertEqual(
            typing,
            .typingUpdated(
                SpectraChatTypingUpdated(roomID: "room_123", userID: "usr_b", isTyping: true)
            )
        )
    }

    func testCallLifecycleEventDecodesWithoutMediaTransportCredential() throws {
        let data = Data(
            """
            {
              "event_id": "evt_call_invited_01",
              "event_type": "call.invited",
              "event_version": "2026-07-25",
              "project_id": "proj_123",
              "conversation_id": "conv_123",
              "room_id": "room_123",
              "server_sequence": 42,
              "occurred_at": "2026-07-25T00:00:00Z",
              "actor": {
                "app_user_id": "app_user_123"
              },
              "call": {
                "call_id": "call_123",
                "call_session_id": "call_session_123",
                "status": "ringing",
                "media_mode": "video",
                "call_type": "direct"
              },
              "participants": [
                {
                  "participant_id": "call_participant_123",
                  "app_user_id": "app_user_123",
                  "state": "accepted"
                },
                {
                  "participant_id": "call_participant_456",
                  "app_user_id": "app_user_456",
                  "state": "invited"
                }
              ],
              "trace": {
                "message_id": "msg_call_trace_123",
                "client_reference_id": "ios-call-compose-001"
              }
            }
            """.utf8
        )

        let event = try SpectraChatCallLifecycleEvent.decode(from: data)

        XCTAssertEqual(event.eventType, .invited)
        XCTAssertEqual(event.conversationID, "conv_123")
        XCTAssertEqual(event.roomID, "room_123")
        XCTAssertEqual(event.serverSequence, 42)
        XCTAssertEqual(event.call.mediaMode, "video")
        XCTAssertEqual(event.participants.map(\.state), ["accepted", "invited"])
        XCTAssertFalse(event.carriesMediaTransportCredential)
    }

    func testCallLifecycleEventAcceptsSingularParticipantPayload() throws {
        let data = Data(
            """
            {
              "event_id": "evt_call_accepted_01",
              "event_type": "call.accepted",
              "event_version": "2026-07-25",
              "conversation_id": "conv_123",
              "room_id": "room_123",
              "server_sequence": 43,
              "occurred_at": "2026-07-25T00:00:03Z",
              "actor": {
                "app_user_id": "app_user_456"
              },
              "call": {
                "call_id": "call_123",
                "status": "ringing",
                "media_mode": "video",
                "call_type": "direct"
              },
              "participant": {
                "participant_id": "call_participant_456",
                "app_user_id": "app_user_456",
                "state": "accepted"
              }
            }
            """.utf8
        )

        let event = try SpectraChatCallLifecycleEvent.decode(from: data)

        XCTAssertEqual(event.eventType, .accepted)
        XCTAssertEqual(event.serverSequence, 43)
        XCTAssertEqual(event.participants, [
            SpectraChatCallParticipant(
                participantID: "call_participant_456",
                appUserID: "app_user_456",
                state: "accepted"
            )
        ])
    }

    func testRealtimeCallInvitedDecodesCommunityEnvelopePayload() throws {
        let data = Data(
            """
            {
              "schema_version": 1,
              "event_id": "evt_call_123_invited",
              "event_type": "call.invited",
              "room_id": "conv_123",
              "server_sequence": 44,
              "occurred_at": "2026-07-26T04:00:00Z",
              "payload": {
                "call": {
                  "call_id": "call_123",
                  "chat_room_id": "conv_123",
                  "kind": "direct",
                  "state": "ringing",
                  "initiator_user_id": "app_user_123",
                  "max_participants": 2,
                  "connected_participant_count": 0,
                  "participants": [
                    {
                      "user_id": "app_user_123",
                      "role": "host",
                      "state": "pending",
                      "joined_at": null,
                      "left_at": null,
                      "leave_reason": null
                    },
                    {
                      "user_id": "app_user_456",
                      "role": "participant",
                      "state": "pending",
                      "joined_at": null,
                      "left_at": null,
                      "leave_reason": null
                    }
                  ],
                  "version": 1,
                  "created_at": "2026-07-26T04:00:00Z",
                  "activated_at": null,
                  "ended_at": null,
                  "end_reason": null
                }
              }
            }
            """.utf8
        )

        let decoded = try SpectraChatRealtimeClient.decodeEvent(from: data)

        guard case .callLifecycle(let event) = decoded else {
            XCTFail("Expected call lifecycle event")
            return
        }
        XCTAssertEqual(event.eventType, .invited)
        XCTAssertEqual(event.conversationID, "conv_123")
        XCTAssertEqual(event.roomID, "conv_123")
        XCTAssertEqual(event.serverSequence, 44)
        XCTAssertEqual(event.call.status, "ringing")
        XCTAssertEqual(event.call.mediaMode, "video")
        XCTAssertEqual(event.call.callType, "direct")
        XCTAssertEqual(event.participants.map(\.appUserID), ["app_user_123", "app_user_456"])
        XCTAssertEqual(event.participants.map(\.state), ["pending", "pending"])
        XCTAssertFalse(event.carriesMediaTransportCredential)
    }

    func testRealtimeCallStateUpdatedDecodesCommunityEnvelopePayload() throws {
        let data = Data(
            """
            {
              "schema_version": 1,
              "event_id": "evt_call_123_join",
              "event_type": "call.state_updated",
              "room_id": "conv_123",
              "server_sequence": 45,
              "occurred_at": "2026-07-26T04:00:05Z",
              "payload": {
                "change_type": "participant_connected",
                "actor_user_id": "app_user_456",
                "call": {
                  "call_id": "call_123",
                  "chat_room_id": "conv_123",
                  "kind": "direct",
                  "state": "active",
                  "initiator_user_id": "app_user_123",
                  "max_participants": 2,
                  "connected_participant_count": 1,
                  "participants": [
                    {
                      "user_id": "app_user_123",
                      "role": "host",
                      "state": "pending",
                      "joined_at": null,
                      "left_at": null,
                      "leave_reason": null
                    },
                    {
                      "user_id": "app_user_456",
                      "role": "participant",
                      "state": "connected",
                      "joined_at": "2026-07-26T04:00:05Z",
                      "left_at": null,
                      "leave_reason": null
                    }
                  ],
                  "version": 2,
                  "created_at": "2026-07-26T04:00:00Z",
                  "activated_at": "2026-07-26T04:00:05Z",
                  "ended_at": null,
                  "end_reason": null
                }
              }
            }
            """.utf8
        )

        let decoded = try SpectraChatRealtimeClient.decodeEvent(from: data)

        guard case .callLifecycle(let event) = decoded else {
            XCTFail("Expected call lifecycle event")
            return
        }
        XCTAssertEqual(event.eventType, .stateUpdated)
        XCTAssertEqual(event.changeType, "participant_connected")
        XCTAssertEqual(event.actor?.appUserID, "app_user_456")
        XCTAssertEqual(event.call.status, "active")
        XCTAssertEqual(event.participants.last?.state, "connected")
    }

    func testHTTPErrorDecodesChatError() async throws {
        let client = makeClient()
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer chat_access_token")
            return jsonResponse(
                status: 403,
                body: """
                {
                  "error": {
                    "code": "EMAIL_NOT_VERIFIED",
                    "message": "Email verification is required.",
                    "retryable": false,
                    "field_errors": [],
                    "request_id": "req_123",
                    "details": {}
                  }
                }
                """
            )
        }

        do {
            _ = try await client.listRooms()
            XCTFail("Expected error")
        } catch SpectraChatError.httpStatus(let status, let payload) {
            XCTAssertEqual(status, 403)
            XCTAssertEqual(payload?.code, "EMAIL_NOT_VERIFIED")
            XCTAssertEqual(payload?.requestID, "req_123")
        }
    }

    private func makeClient(
        baseURL: URL = URL(string: "https://chat.example.test")!,
        socketURL: URL? = nil,
        projectId: String? = nil
    ) -> SpectraChatClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        return SpectraChatClient(
            configuration: SpectraChatClientConfiguration(
                baseURL: baseURL,
                socketURL: socketURL,
                projectId: projectId
            ),
            tokenProvider: StaticSpectraChatAccessTokenProvider(token: "chat_access_token"),
            urlSession: session
        )
    }

    private func makeStorageClient() -> SpectraStorageClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        return SpectraStorageClient(
            configuration: SpectraStorageClientConfiguration(
                baseURL: URL(string: "https://chat.example.test")!,
                projectId: "project_123"
            ),
            tokenProvider: StaticSpectraStorageAccessTokenProvider(token: "storage_access_token"),
            urlSession: session
        )
    }
}

private final class MockURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            let handler = try XCTUnwrap(Self.handler)
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private func roomResponse(status: Int) -> (HTTPURLResponse, Data) {
    jsonResponse(
        status: status,
        body: """
        {
          "data": {
            "room_id": "room_123",
            "kind": "direct",
            "title": null,
            "participant_user_ids": ["usr_a", "usr_b"],
            "last_server_sequence": 0,
            "last_read_server_sequence": 0,
            "unread_count": 0,
            "created_at": "2026-07-24T01:00:00Z",
            "updated_at": "2026-07-24T01:00:00Z"
          }
        }
        """
    )
}

private func messageResponse(status: Int) -> (HTTPURLResponse, Data) {
    jsonResponse(
        status: status,
        body: """
        {
          "data": {
            "message_id": "msg_123",
            "room_id": "room_123",
            "server_sequence": 1,
            "client_message_id": "client_123",
            "sender_user_id": "usr_a",
            "content": {
              "kind": "text",
              "text": "hello",
              "media_items": []
            },
            "reply_to_message_id": null,
            "mentioned_user_ids": [],
            "created_at": "2026-07-24T01:02:00Z",
            "edited_at": null,
            "deleted_at": null
          }
        }
        """
    )
}

private func jsonResponse(status: Int, body: String) -> (HTTPURLResponse, Data) {
    let url = URL(string: "https://chat.example.test")!
    return (
        HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
        Data(body.utf8)
    )
}

private func storageObjectEnvelope(
    status: Int,
    objectKey: String,
    contentType: String,
    byteSize: Int64,
    metadata: [String: String]
) -> (HTTPURLResponse, Data) {
    let metadataJSON = metadata
        .map { #""\#($0.key)": "\#($0.value)""# }
        .sorted()
        .joined(separator: ",")
    return jsonResponse(
        status: status,
        body: """
        {
          "data": {
            "object_key": "\(objectKey)",
            "status": "ready",
            "visibility": "private",
            "content_type": "\(contentType)",
            "byte_size": \(byteSize),
            "checksum_sha256": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
            "metadata": { \(metadataJSON) },
            "etag": "etag-1",
            "public_url": null,
            "rejection_category": null,
            "created_at": "2026-07-24T01:00:00Z",
            "updated_at": "2026-07-24T01:00:00Z"
          }
        }
        """
    )
}

private func requestBodyData(_ request: URLRequest) throws -> Data {
    if let body = request.httpBody {
        return body
    }
    if let stream = request.httpBodyStream {
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read < 0 {
                throw stream.streamError ?? URLError(.cannotDecodeRawData)
            }
            if read == 0 { break }
            data.append(buffer, count: read)
        }
        return data
    }
    return Data()
}
