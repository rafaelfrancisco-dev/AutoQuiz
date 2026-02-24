import SwiftUI

enum MacModalSizePreset {
    case languageSelection
    case form
    case history
    case dashboard

    var minWidth: CGFloat {
        switch self {
        case .languageSelection:
            return 420
        case .form:
            return 500
        case .history:
            return 600
        case .dashboard:
            return 900
        }
    }

    var minHeight: CGFloat {
        switch self {
        case .languageSelection:
            return 360
        case .form, .history:
            return 400
        case .dashboard:
            return 620
        }
    }
}

extension View {
    @ViewBuilder
    func macModalSize(_ preset: MacModalSizePreset) -> some View {
        #if os(macOS)
        self.frame(minWidth: preset.minWidth, minHeight: preset.minHeight)
        #else
        self
        #endif
    }
}
