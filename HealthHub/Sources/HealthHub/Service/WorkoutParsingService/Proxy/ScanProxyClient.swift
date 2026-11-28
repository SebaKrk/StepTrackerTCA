//
//  ScanProxyClient.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 17/11/2026.
//

import Foundation
import SharedModels

/// Transport to the server-side scan proxy.
///
/// The API key lives in the function, never on the device, so this client sends
/// the photo and an identity token and reads back the finished board. It speaks
/// the callable wire format (`{"data": …}` in, `{"result": …}` out) directly over
/// `URLSession`, which keeps the package free of a Firebase dependency.
public actor ScanProxyClient {

    // MARK: - Constants

    /// Callable that turns a board photo into a `ScannedBoard`.
    private static let scanFunction = "scanBoard"

    /// Callable that writes a warm-up or cool-down cue.
    private static let noteFunction = "trainingNote"

    /// Callable that erases the caller's account and everything stored under it.
    private static let deleteFunction = "deleteMyData"

    /// Callable that corrects a scanned board through a short chat.
    private static let refineFunction = "refinePlan"

    /// Wire value asking the proxy for both cues in one reply.
    private static let bothKinds = "both"

    // MARK: - Properties

    /// Endpoint and identity provider for the deployed functions.
    private let configuration: ScanProxyConfiguration

    /// Transport; injectable so a test can stand in for the network.
    private let session: URLSession

    // MARK: - Initialization

    public init(configuration: ScanProxyConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    // MARK: - Scan

    /// Sends a board scan and returns the parsed board.
    ///
    /// - Parameters:
    ///   - mode: Which prompt the proxy should use for this backend.
    ///   - imageData: JPEG of the board, already downscaled; `nil` for a text-only scan.
    ///   - ocrText: OCR transcript — the source for `text`, an untrusted hint for `visionWithHint`.
    ///   - language: English name of the device language, for the free-text fields.
    ///   - model: Model to run on; ignored by every deployment but development.
    public func scanBoard(
        mode: ScanProxyMode,
        imageData: Data?,
        ocrText: String,
        language: String,
        model: String? = nil
    ) async throws -> ScannedBoard {
        let request = ScanRequest(
            mode: mode.rawValue,
            image: imageData?.base64EncodedString(),
            ocrText: ocrText,
            language: language,
            model: model,
            formVersion: ScannedBoard.formVersion
        )
        let response: ScanResponse = try await call(Self.scanFunction, body: request)
        return response.board
    }

    // MARK: - Plan Chat

    /// Sends the plan chat so far and returns the model's reply, with a corrected board once confirmed.
    ///
    /// - Parameters:
    ///   - board: The board as the app holds it, before this chat's correction.
    ///   - findings: Doubts the scan review raised, as the user reads them.
    ///   - messages: The whole chat, oldest first, ending with the user's latest message.
    ///   - language: English name of the device language, for the reply and the change list.
    public func refinePlan(
        board: ScannedBoard,
        findings: [String],
        messages: [PlanChatMessage],
        language: String
    ) async throws -> PlanRefinement {
        let request = RefineRequest(
            board: board,
            findings: findings,
            messages: messages,
            language: language,
            formVersion: ScannedBoard.formVersion
        )
        let response: RefineResponse = try await call(Self.refineFunction, body: request)
        return PlanRefinement(reply: response.reply, board: response.board, changes: response.changes)
    }

    // MARK: - Training Notes

    /// Asks for the warm-up or cool-down cue of a planned session.
    ///
    /// `sideBlock` is the section's own activation or finisher block; the cue is written around it,
    /// before or after depending on `sideBlockFirst`.
    public func trainingNote(
        kind: TrainingNoteKind,
        workouts: [TrainingNoteWorkout],
        durationMinutes: Int?,
        sideBlock: TrainingNoteWorkout? = nil,
        sideBlockFirst: Bool? = nil,
        language: String
    ) async throws -> String {
        let notes = try await notes(
            kind: kind.rawValue,
            workouts: workouts,
            durationMinutes: durationMinutes,
            sideBlock: sideBlock,
            sideBlockFirst: sideBlockFirst,
            language: language
        )
        guard let text = kind == .warmUp ? notes.warmUp : notes.coolDown else {
            throw ScanProxyError.invalidResponse
        }
        return text
    }

    /// Asks for the cues a plan is missing, with the model choosing how long each takes.
    ///
    /// Both missing is one round-trip: it costs one unit of the daily allowance,
    /// and a failure cannot leave one cue paid for and the other missing.
    public func proposedNotes(
        warmUp: Bool,
        coolDown: Bool,
        workouts: [TrainingNoteWorkout],
        language: String
    ) async throws -> TrainingNotes {
        guard warmUp || coolDown else { throw ScanProxyError.invalidRequest }
        let kind = warmUp && coolDown ? Self.bothKinds : (warmUp ? TrainingNoteKind.warmUp.rawValue : TrainingNoteKind.coolDown.rawValue)
        let notes = try await notes(kind: kind, workouts: workouts, durationMinutes: nil, language: language)
        guard !warmUp || notes.warmUp != nil, !coolDown || notes.coolDown != nil else {
            throw ScanProxyError.invalidResponse
        }
        return notes
    }

    /// One note round-trip; `kind` is a wire value, not a user-facing choice.
    private func notes(
        kind: String,
        workouts: [TrainingNoteWorkout],
        durationMinutes: Int?,
        sideBlock: TrainingNoteWorkout? = nil,
        sideBlockFirst: Bool? = nil,
        language: String
    ) async throws -> TrainingNotes {
        let request = NoteRequest(
            kind: kind,
            workouts: workouts,
            durationMinutes: durationMinutes,
            sideBlock: sideBlock,
            sideBlockFirst: sideBlockFirst,
            language: language
        )
        let response: NoteResponse = try await call(Self.noteFunction, body: request)
        return TrainingNotes(
            warmUp: response.warmUp,
            warmUpMinutes: response.warmUpMinutes,
            coolDown: response.coolDown,
            coolDownMinutes: response.coolDownMinutes
        )
    }

    // MARK: - Account

    /// Erases everything the server holds under the caller's account, and the account itself.
    public func deleteAccountData() async throws {
        let _: DeleteResponse = try await call(Self.deleteFunction, body: DeleteRequest())
    }

    // MARK: - Private

    /// One callable round-trip: envelope in, envelope out, typed error on failure.
    private func call<Body: Encodable, Result: Decodable>(
        _ function: String,
        body: Body
    ) async throws -> Result {
        let endpoint = try configuration.endpoint(for: function)
        let token = try await identityToken()

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(RequestEnvelope(data: body))

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ScanProxyError.network
        }

        guard let http = response as? HTTPURLResponse else {
            throw ScanProxyError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw Self.mapped(data)
        }

        do {
            return try JSONDecoder().decode(ResultEnvelope<Result>.self, from: data).result
        } catch {
            throw ScanProxyError.invalidResponse
        }
    }

    /// Identity token for the call; a provider failure means there is no account.
    private func identityToken() async throws -> String {
        do {
            return try await configuration.idToken()
        } catch let error as ScanProxyError {
            throw error
        } catch {
            throw ScanProxyError.notSignedIn
        }
    }

    /// Maps the callable error envelope onto a typed error.
    ///
    /// The proxy sends a short machine-readable `message` precisely so the phone
    /// never has to pattern-match on prose.
    private static func mapped(_ data: Data) -> ScanProxyError {
        guard let envelope = try? JSONDecoder().decode(ErrorEnvelope.self, from: data) else {
            return .unexpected
        }
        let failure = envelope.error
        switch failure.status {
        case "UNAUTHENTICATED":
            return .notSignedIn
        case "RESOURCE_EXHAUSTED":
            if failure.message == "conversation-limit-reached" { return .conversationLimitReached }
            guard failure.message == "daily-limit-reached" else { return .rateLimited }
            let millis = failure.details?.resetsAt
            return .dailyLimitReached(resetsAt: millis.map { Date(timeIntervalSince1970: $0 / 1000) })
        case "UNAVAILABLE":
            return .serviceUnavailable
        case "INVALID_ARGUMENT":
            return failure.message == "image-too-large" ? .imageTooLarge : .invalidRequest
        case "INTERNAL":
            switch failure.message {
            case "truncated": return .truncated
            case "refused": return .refused
            case "upstream-rejected": return .invalidRequest
            default: return .unexpected
            }
        default:
            return .unexpected
        }
    }

    // MARK: - Wire Format

    /// Callable requests carry their payload under `data`.
    private struct RequestEnvelope<Body: Encodable>: Encodable {
        let data: Body
    }

    /// Callable replies carry their payload under `result`.
    private struct ResultEnvelope<Payload: Decodable>: Decodable {
        let result: Payload
    }

    /// Callable failures carry a status, a short message and optional details.
    private struct ErrorEnvelope: Decodable {

        let error: Failure

        struct Failure: Decodable {
            let status: String
            let message: String
            let details: Details?
        }

        struct Details: Decodable {
            let resetsAt: Double?
        }
    }

    /// Payload of a board scan.
    private struct ScanRequest: Encodable {
        let mode: String
        let image: String?
        let ocrText: String
        let language: String
        let model: String?
        let formVersion: Int
    }

    /// Reply of a board scan.
    private struct ScanResponse: Decodable {
        let board: ScannedBoard
    }

    /// Payload of a training-note request.
    private struct NoteRequest: Encodable {
        let kind: String
        let workouts: [TrainingNoteWorkout]
        let durationMinutes: Int?
        /// The warm-up's or cool-down's own block; omitted from the JSON when `nil`, so older servers see the same request.
        let sideBlock: TrainingNoteWorkout?
        /// Whether that block is done before the cue.
        let sideBlockFirst: Bool?
        let language: String
    }

    /// Reply of a training-note request; the cue not asked for comes back null.
    private struct NoteResponse: Decodable {
        let warmUp: String?
        let warmUpMinutes: Int?
        let coolDown: String?
        let coolDownMinutes: Int?
    }

    /// Payload of a plan chat turn.
    private struct RefineRequest: Encodable {
        let board: ScannedBoard
        let findings: [String]
        let messages: [PlanChatMessage]
        let language: String
        let formVersion: Int
    }

    /// Reply of a plan chat turn; the board is null while the model still asks.
    private struct RefineResponse: Decodable {
        let reply: String
        let board: ScannedBoard?
        let changes: [String]
    }

    /// Payload of an account erase; the identity token alone says whose.
    private struct DeleteRequest: Encodable {}

    /// Reply of an account erase; the counts in it are for the server log, not the phone.
    private struct DeleteResponse: Decodable {}
}
