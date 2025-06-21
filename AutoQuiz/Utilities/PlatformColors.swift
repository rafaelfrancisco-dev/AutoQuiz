//
//  PlatformColors.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 18/06/2025.
//

import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

extension Color {
    /// Platform-appropriate background color for input controls
    static var platformControlBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemGray6)
        #elseif os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #else
        return Color.gray.opacity(0.1)
        #endif
    }
    
    /// Platform-appropriate secondary background color
    static var platformSecondaryBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemGray5)
        #elseif os(macOS)
        return Color(NSColor.quaternaryLabelColor)
        #else
        return Color.gray.opacity(0.3)
        #endif
    }
    
    /// Platform-appropriate border/separator color
    static var platformBorder: Color {
        #if os(iOS)
        return Color(UIColor.systemGray4)
        #elseif os(macOS)
        return Color(NSColor.separatorColor)
        #else
        return Color.gray
        #endif
    }
    
    /// Platform-appropriate tertiary background color
    static var platformTertiaryBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemGray6)
        #elseif os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #else
        return Color.gray.opacity(0.05)
        #endif
    }
}