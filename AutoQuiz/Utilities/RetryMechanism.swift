//
//  RetryMechanism.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 18/06/2025.
//

import Foundation
import OSLog

struct RetryConfiguration: Sendable {
    let maxAttempts: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval
    let backoffMultiplier: Double
    
    nonisolated static let `default` = RetryConfiguration(
        maxAttempts: 3,
        baseDelay: 1.0,
        maxDelay: 10.0,
        backoffMultiplier: 2.0
    )
    
    nonisolated static let aggressive = RetryConfiguration(
        maxAttempts: 5,
        baseDelay: 0.5,
        maxDelay: 8.0,
        backoffMultiplier: 1.5
    )
}

enum RetryResult<T> {
    case success(T)
    case finalFailure(Error, totalAttempts: Int)
}

struct RetryMechanism {
    static func executeWithRetry<T>(
        configuration: RetryConfiguration = .default,
        operation: @escaping () async throws -> T,
        onRetry: ((Int, Error) -> Void)? = nil
    ) async -> RetryResult<T> {
        var lastError: Error?
        
        for attempt in 1...configuration.maxAttempts {
            do {
                let result = try await operation()
                Logger.generation.info("Operation succeeded on attempt \(attempt)")
                return .success(result)
            } catch {
                lastError = error
                Logger.generation.warning("Operation failed on attempt \(attempt)/\(configuration.maxAttempts): \(error.localizedDescription)")
                
                if attempt < configuration.maxAttempts {
                    // Call retry callback
                    onRetry?(attempt, error)
                    
                    // Calculate delay with exponential backoff
                    let delay = min(
                        configuration.baseDelay * pow(configuration.backoffMultiplier, Double(attempt - 1)),
                        configuration.maxDelay
                    )
                    
                    Logger.generation.debug("Retrying in \(delay) seconds...")
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        Logger.generation.error("Operation failed after \(configuration.maxAttempts) attempts. Final error: \(lastError?.localizedDescription ?? "Unknown error")")
        return .finalFailure(lastError ?? NSError(domain: "RetryMechanism", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error after retries"]), totalAttempts: configuration.maxAttempts)
    }
    
    /// Simplified version that returns the result or throws the final error
    static func executeWithRetryThrows<T>(
        configuration: RetryConfiguration = .default,
        operation: @escaping () async throws -> T,
        onRetry: ((Int, Error) -> Void)? = nil
    ) async throws -> T {
        let result = await executeWithRetry(
            configuration: configuration,
            operation: operation,
            onRetry: onRetry
        )
        
        switch result {
        case .success(let value):
            return value
        case .finalFailure(let error, _):
            throw error
        }
    }
}