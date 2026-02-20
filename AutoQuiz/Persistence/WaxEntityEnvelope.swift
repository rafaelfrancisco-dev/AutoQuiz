import Foundation

struct WaxEntityEnvelope: Codable {
    let entityType: WaxEntityType
    let entityID: UUID
    let createdAt: Date
    let updatedAt: Date
    let payload: Data

    init(entityType: WaxEntityType, entityID: UUID, payload: Data, createdAt: Date = .now, updatedAt: Date = .now) {
        self.entityType = entityType
        self.entityID = entityID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.payload = payload
    }
}
