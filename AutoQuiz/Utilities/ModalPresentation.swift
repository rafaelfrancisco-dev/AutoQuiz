import SwiftUI

enum MacModalSizePreset {
    case utilityCompact
    case utilityForm
    case history
    case dashboard

    var minWidth: CGFloat {
        switch self {
        case .utilityCompact:
            return 420
        case .utilityForm:
            return 560
        case .history:
            return 720
        case .dashboard:
            return 960
        }
    }

    var minHeight: CGFloat {
        switch self {
        case .utilityCompact:
            return 320
        case .utilityForm:
            return 460
        case .history:
            return 520
        case .dashboard:
            return 680
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
