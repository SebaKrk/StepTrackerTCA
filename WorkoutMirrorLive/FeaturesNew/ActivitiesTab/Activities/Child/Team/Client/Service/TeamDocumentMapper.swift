//
//  TeamDocumentMapper.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import FirebaseFirestore
import Foundation
import SharedModels

/// Converts Team domain types to Firestore fields and back. Field names must match `firebase/firestore.rules`.
nonisolated enum TeamDocumentMapper {

    // MARK: - Group

    static func groupData(name: String, ownerUid: String, createdAt: Date) -> [String: Any] {
        [
            "name": name,
            "ownerUid": ownerUid,
            "createdAt": Timestamp(date: createdAt),
        ]
    }

    static func group(id: String, data: [String: Any], path: String) throws -> TeamGroup {
        TeamGroup(
            id: id,
            name: try string(data, "name", path),
            ownerUid: try string(data, "ownerUid", path),
            createdAt: try date(data, "createdAt", path)
        )
    }

    // MARK: - Member

    static func memberData(uid: String, displayName: String, joinedAt: Date, joinedViaInvite: String?) -> [String: Any] {
        var data: [String: Any] = [
            "uid": uid,
            "displayName": displayName,
            "joinedAt": Timestamp(date: joinedAt),
        ]
        if let joinedViaInvite {
            data["joinedViaInvite"] = joinedViaInvite
        }
        return data
    }

    static func member(data: [String: Any], path: String) throws -> TeamMember {
        TeamMember(
            uid: try string(data, "uid", path),
            displayName: try string(data, "displayName", path),
            joinedAt: try date(data, "joinedAt", path)
        )
    }

    // MARK: - Invite

    static func inviteData(_ invite: TeamInvite) -> [String: Any] {
        [
            "groupName": invite.groupName,
            "createdByUid": invite.createdByUid,
            "createdByName": invite.createdByName,
            "createdAt": Timestamp(date: invite.createdAt),
            "expiresAt": Timestamp(date: invite.expiresAt),
            "revoked": invite.isRevoked,
        ]
    }

    static func invite(id: String, groupId: String, data: [String: Any], path: String) throws -> TeamInvite {
        TeamInvite(
            id: id,
            groupId: groupId,
            groupName: try string(data, "groupName", path),
            createdByUid: try string(data, "createdByUid", path),
            createdByName: try string(data, "createdByName", path),
            createdAt: try date(data, "createdAt", path),
            expiresAt: try date(data, "expiresAt", path),
            isRevoked: data["revoked"] as? Bool ?? false
        )
    }

    // MARK: - Recipient

    static func recipientData(uid: String, displayName: String, status: TeamRecipientStatus, scannedAt: Date) -> [String: Any] {
        [
            "uid": uid,
            "displayName": displayName,
            "status": status.rawValue,
            "scannedAt": Timestamp(date: scannedAt),
        ]
    }

    static func recipient(reference: TeamInviteReference?, data: [String: Any], path: String) throws -> TeamRecipientRecord {
        guard let status = TeamRecipientStatus(rawValue: try string(data, "status", path)) else {
            throw TeamServiceError.malformedDocument(path: path)
        }
        return TeamRecipientRecord(
            reference: reference,
            uid: try string(data, "uid", path),
            displayName: try string(data, "displayName", path),
            status: status,
            scannedAt: try date(data, "scannedAt", path),
            respondedAt: (data["respondedAt"] as? Timestamp)?.dateValue()
        )
    }

    // MARK: - Plan

    static func planData(_ plan: TeamPlan) throws -> [String: Any] {
        [
            "authorUid": plan.authorUid,
            "authorName": plan.authorName,
            "title": plan.session.title,
            "planPayload": try SharedPlanCodec.encode(plan: plan.session, exportedAt: plan.publishedAt),
            "scoredBlockIds": plan.scoredBlockIds.map(\.uuidString),
            "sessionMinutes": plan.sessionMinutes,
            "publishedAt": Timestamp(date: plan.publishedAt),
        ]
    }

    static func plan(id: String, data: [String: Any], path: String) throws -> TeamPlan {
        TeamPlan(
            id: id,
            authorUid: try string(data, "authorUid", path),
            authorName: try string(data, "authorName", path),
            session: try SharedPlanCodec.decode(try string(data, "planPayload", path)).plan,
            scoredBlockIds: scoredBlockIds(data),
            sessionMinutes: try int(data, "sessionMinutes", path),
            publishedAt: try date(data, "publishedAt", path)
        )
    }

    // MARK: - Entry

    static func entryData(_ entry: TeamEntry) -> [String: Any] {
        var data: [String: Any] = [
            "uid": entry.uid,
            "displayName": entry.displayName,
            "scores": entry.scores.reduce(into: [String: Any]()) { fields, item in
                fields[item.key.uuidString] = scoreData(item.value)
            },
            "division": entry.division.rawValue,
            "windowStart": Timestamp(date: entry.windowStart),
            "measuredMinutes": entry.measuredMinutes,
            "hrVerified": entry.hrVerified,
            "startedAfterActivity": entry.startedAfterActivity,
            "isLate": entry.isLate,
            "submittedAt": Timestamp(date: entry.submittedAt),
        ]
        if let effortPoints = entry.effortPoints {
            data["effortPoints"] = effortPoints
        }
        if let weightsVersion = entry.weightsVersion {
            data["weightsVersion"] = weightsVersion
        }
        if let kcal = entry.kcal {
            data["kcal"] = kcal
        }
        if let editedAt = entry.editedAt {
            data["editedAt"] = Timestamp(date: editedAt)
        }
        return data
    }

    static func entry(data: [String: Any], path: String) throws -> TeamEntry {
        guard let division = BoardDivision(rawValue: try string(data, "division", path)) else {
            throw TeamServiceError.malformedDocument(path: path)
        }
        return TeamEntry(
            uid: try string(data, "uid", path),
            displayName: try string(data, "displayName", path),
            scores: try scores(data, path),
            division: division,
            effortPoints: (data["effortPoints"] as? NSNumber)?.intValue,
            weightsVersion: (data["weightsVersion"] as? NSNumber)?.intValue,
            kcal: (data["kcal"] as? NSNumber)?.doubleValue,
            windowStart: try date(data, "windowStart", path),
            measuredMinutes: try int(data, "measuredMinutes", path),
            hrVerified: data["hrVerified"] as? Bool ?? false,
            startedAfterActivity: data["startedAfterActivity"] as? Bool ?? false,
            isLate: data["isLate"] as? Bool ?? false,
            submittedAt: try date(data, "submittedAt", path),
            editedAt: (data["editedAt"] as? Timestamp)?.dateValue()
        )
    }

    // MARK: - Score

    // Plans published before per-block results carry a single `scoredBlockId`.
    private static func scoredBlockIds(_ data: [String: Any]) -> [UUID] {
        if let ids = data["scoredBlockIds"] as? [String] {
            return ids.compactMap(UUID.init(uuidString:))
        }
        return (data["scoredBlockId"] as? String).flatMap(UUID.init(uuidString:)).map { [$0] } ?? []
    }

    // Entries sent before per-block results have a single `score` and no block id; they keep their points only.
    private static func scores(_ data: [String: Any], _ path: String) throws -> [UUID: BoardScore] {
        guard let fieldsByBlock = data["scores"] as? [String: Any] else { return [:] }
        var scores: [UUID: BoardScore] = [:]
        for (key, value) in fieldsByBlock {
            guard let blockId = UUID(uuidString: key), let fields = value as? [String: Any] else {
                throw TeamServiceError.malformedDocument(path: path)
            }
            scores[blockId] = try score(fields, path)
        }
        return scores
    }

    private static func scoreData(_ score: BoardScore) -> [String: Any] {
        switch score {
        case .forTime(let seconds):
            return ["kind": "forTime", "seconds": seconds]
        case .capped(let capSeconds, let remainingReps):
            return ["kind": "capped", "capSeconds": capSeconds, "remainingReps": remainingReps]
        case .cappedRounds(let capSeconds, let rounds, let extraReps):
            return ["kind": "cappedRounds", "capSeconds": capSeconds, "rounds": rounds, "extraReps": extraReps]
        case .amrap(let rounds, let extraReps):
            return ["kind": "amrap", "rounds": rounds, "extraReps": extraReps]
        case .load(let kilograms):
            return ["kind": "load", "kilograms": kilograms]
        case .reps(let reps):
            return ["kind": "reps", "reps": reps]
        case .unranked:
            return ["kind": "unranked"]
        }
    }

    private static func score(_ fields: [String: Any], _ path: String) throws -> BoardScore {
        switch try string(fields, "kind", path) {
        case "forTime":
            return .forTime(seconds: try int(fields, "seconds", path))
        case "capped":
            return .capped(capSeconds: try int(fields, "capSeconds", path), remainingReps: try int(fields, "remainingReps", path))
        case "cappedRounds":
            return .cappedRounds(
                capSeconds: try int(fields, "capSeconds", path),
                rounds: try int(fields, "rounds", path),
                extraReps: try int(fields, "extraReps", path)
            )
        case "amrap":
            return .amrap(rounds: try int(fields, "rounds", path), extraReps: try int(fields, "extraReps", path))
        case "load":
            guard let kilograms = (fields["kilograms"] as? NSNumber)?.doubleValue else {
                throw TeamServiceError.malformedDocument(path: path)
            }
            return .load(kilograms: kilograms)
        case "reps":
            return .reps(try int(fields, "reps", path))
        case "unranked":
            return .unranked
        default:
            throw TeamServiceError.malformedDocument(path: path)
        }
    }

    // MARK: - Fields

    private static func string(_ data: [String: Any], _ key: String, _ path: String) throws -> String {
        guard let value = data[key] as? String else { throw TeamServiceError.malformedDocument(path: path) }
        return value
    }

    private static func int(_ data: [String: Any], _ key: String, _ path: String) throws -> Int {
        guard let value = (data[key] as? NSNumber)?.intValue else { throw TeamServiceError.malformedDocument(path: path) }
        return value
    }

    private static func date(_ data: [String: Any], _ key: String, _ path: String) throws -> Date {
        guard let value = data[key] as? Timestamp else { throw TeamServiceError.malformedDocument(path: path) }
        return value.dateValue()
    }
}
