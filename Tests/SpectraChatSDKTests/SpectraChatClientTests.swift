import Foundation
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
        projectId: String? = nil
    ) -> SpectraChatClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        return SpectraChatClient(
            configuration: SpectraChatClientConfiguration(baseURL: baseURL, projectId: projectId),
            tokenProvider: StaticSpectraChatAccessTokenProvider(token: "chat_access_token"),
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
