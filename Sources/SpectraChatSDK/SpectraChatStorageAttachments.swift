import Foundation
import SpectraStorageSDK

public struct SpectraChatStorageAttachmentUpload: Equatable, Sendable {
    public let uploaded: SpectraStorageUploadedAttachment
    public let reference: SpectraChatStorageObjectReference

    public init(uploaded: SpectraStorageUploadedAttachment, reference: SpectraChatStorageObjectReference) {
        self.uploaded = uploaded
        self.reference = reference
    }
}

public extension SpectraChatStorageObjectReference {
    init(storageObject: SpectraStorageObject) {
        self.init(
            objectKey: storageObject.objectKey,
            contentType: storageObject.contentType,
            byteSize: storageObject.byteSize,
            checksumSHA256: storageObject.checksumSHA256,
            metadata: storageObject.metadata
        )
    }

    init(storageUpload: SpectraStorageUploadedAttachment) {
        self.init(storageObject: storageUpload.object)
    }
}

public final class SpectraChatStorageAttachmentSender: @unchecked Sendable {
    private let chat: SpectraChatClient
    private let storage: SpectraStorageClient

    public init(chat: SpectraChatClient, storage: SpectraStorageClient) {
        self.chat = chat
        self.storage = storage
    }

    @discardableResult
    public func sendImageMessage(
        roomID: String,
        imageData: Data,
        contentType: String,
        caption: String? = nil,
        clientMessageID: String = UUID().uuidString,
        attachmentIndex: Int = 0,
        replyToMessageID: String? = nil,
        mentionedUserIDs: [String] = [],
        idempotencySeed: String? = nil
    ) async throws -> SpectraChatMessage {
        let seed = idempotencySeed ?? clientMessageID
        let upload = try await uploadImage(
            roomID: roomID,
            imageData: imageData,
            contentType: contentType,
            clientMessageID: clientMessageID,
            attachmentIndex: attachmentIndex,
            idempotencySeed: seed
        )
        return try await chat.sendMessage(
            roomID: roomID,
            content: SpectraChatSendContent(
                kind: "image",
                text: caption,
                storageObjectReferences: [upload.reference]
            ),
            clientMessageID: clientMessageID,
            replyToMessageID: replyToMessageID,
            mentionedUserIDs: mentionedUserIDs,
            idempotencyKey: "chat-message-\(seed)"
        )
    }

    @discardableResult
    public func sendFileMessage(
        roomID: String,
        fileData: Data,
        originalFileName: String,
        contentType: String,
        caption: String? = nil,
        clientMessageID: String = UUID().uuidString,
        replyToMessageID: String? = nil,
        mentionedUserIDs: [String] = [],
        idempotencySeed: String? = nil
    ) async throws -> SpectraChatMessage {
        let seed = idempotencySeed ?? clientMessageID
        let upload = try await uploadFile(
            roomID: roomID,
            fileData: fileData,
            originalFileName: originalFileName,
            contentType: contentType,
            clientMessageID: clientMessageID,
            idempotencySeed: seed
        )
        return try await chat.sendMessage(
            roomID: roomID,
            content: SpectraChatSendContent(
                kind: "file",
                text: caption,
                storageObjectReferences: [upload.reference]
            ),
            clientMessageID: clientMessageID,
            replyToMessageID: replyToMessageID,
            mentionedUserIDs: mentionedUserIDs,
            idempotencyKey: "chat-message-\(seed)"
        )
    }

    @discardableResult
    public func sendVoiceMessage(
        roomID: String,
        voiceData: Data,
        durationSeconds: Double? = nil,
        contentType: String = "audio/m4a",
        clientMessageID: String = UUID().uuidString,
        replyToMessageID: String? = nil,
        mentionedUserIDs: [String] = [],
        idempotencySeed: String? = nil
    ) async throws -> SpectraChatMessage {
        let seed = idempotencySeed ?? clientMessageID
        let upload = try await uploadVoice(
            roomID: roomID,
            voiceData: voiceData,
            durationSeconds: durationSeconds,
            contentType: contentType,
            clientMessageID: clientMessageID,
            idempotencySeed: seed
        )
        return try await chat.sendMessage(
            roomID: roomID,
            content: SpectraChatSendContent(
                kind: "audio",
                storageObjectReferences: [upload.reference]
            ),
            clientMessageID: clientMessageID,
            replyToMessageID: replyToMessageID,
            mentionedUserIDs: mentionedUserIDs,
            idempotencyKey: "chat-message-\(seed)"
        )
    }

    public func uploadImage(
        roomID: String,
        imageData: Data,
        contentType: String,
        clientMessageID: String = UUID().uuidString,
        attachmentIndex: Int = 0,
        idempotencySeed: String? = nil
    ) async throws -> SpectraChatStorageAttachmentUpload {
        let seed = idempotencySeed ?? "\(clientMessageID)-image-\(attachmentIndex)"
        let uploaded = try await storage.uploadChatImage(
            imageData,
            roomID: roomID,
            clientMessageID: clientMessageID,
            index: attachmentIndex,
            contentType: contentType,
            idempotencySeed: seed
        )
        return .init(uploaded: uploaded, reference: .init(storageUpload: uploaded))
    }

    public func uploadFile(
        roomID: String,
        fileData: Data,
        originalFileName: String,
        contentType: String,
        clientMessageID: String = UUID().uuidString,
        idempotencySeed: String? = nil
    ) async throws -> SpectraChatStorageAttachmentUpload {
        let seed = idempotencySeed ?? "\(clientMessageID)-file"
        let uploaded = try await storage.uploadChatFile(
            fileData,
            roomID: roomID,
            clientMessageID: clientMessageID,
            originalFileName: originalFileName,
            contentType: contentType,
            idempotencySeed: seed
        )
        return .init(uploaded: uploaded, reference: .init(storageUpload: uploaded))
    }

    public func uploadVoice(
        roomID: String,
        voiceData: Data,
        durationSeconds: Double? = nil,
        contentType: String = "audio/m4a",
        clientMessageID: String = UUID().uuidString,
        idempotencySeed: String? = nil
    ) async throws -> SpectraChatStorageAttachmentUpload {
        let seed = idempotencySeed ?? "\(clientMessageID)-voice"
        let uploaded = try await storage.uploadVoiceMessage(
            voiceData,
            roomID: roomID,
            clientMessageID: clientMessageID,
            durationSeconds: durationSeconds,
            contentType: contentType,
            idempotencySeed: seed
        )
        return .init(uploaded: uploaded, reference: .init(storageUpload: uploaded))
    }
}
