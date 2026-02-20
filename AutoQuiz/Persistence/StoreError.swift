import Foundation

enum StoreError: LocalizedError {
    case persistenceUnavailable
    case decodeFailed

    var errorDescription: String? {
        switch self {
        case .persistenceUnavailable:
            return "Persistence store is unavailable"
        case .decodeFailed:
            return "Failed to decode persisted data"
        }
    }
}
