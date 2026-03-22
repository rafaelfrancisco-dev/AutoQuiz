import SwiftUI
#if os(macOS)
import AppKit
#endif

enum AppStatusTone {
    case neutral
    case info
    case success
    case warning
    case danger

    var tint: Color {
        switch self {
        case .neutral:
            return .secondary
        case .info:
            return .blue
        case .success:
            return .green
        case .warning:
            return .orange
        case .danger:
            return .red
        }
    }

    var subtleBackground: Color {
        tint.opacity(0.12)
    }

    var subtleBorder: Color {
        tint.opacity(0.24)
    }
}

struct AppCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(cardBackground, in: .rect(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.platformBorder.opacity(0.35), lineWidth: 1)
            }
    }

    private var cardBackground: some ShapeStyle {
        #if os(macOS)
        return .background
        #else
        return .regularMaterial
        #endif
    }
}

extension View {
    func appCardStyle() -> some View {
        modifier(AppCardModifier())
    }

    func appContentWidth(_ maxWidth: CGFloat = 760) -> some View {
        frame(maxWidth: maxWidth, alignment: .center)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct AppBadge: View {
    let text: String
    var tone: AppStatusTone = .neutral
    var systemImage: String? = nil

    var body: some View {
        Label {
            Text(text)
        } icon: {
            if let systemImage {
                Image(systemName: systemImage)
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(tone.tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tone.subtleBackground, in: .capsule)
        .overlay {
            Capsule()
                .stroke(tone.subtleBorder, lineWidth: 1)
        }
    }
}

struct AppEmptyState: View {
    let title: String
    let systemImage: String
    let description: String

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text(description)
        )
        .appContentWidth()
    }
}

struct QuizActionButtonStyle: ButtonStyle {
    var tone: AppStatusTone = .info

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(tone.subtleBackground, in: .rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(tone.subtleBorder, lineWidth: 1)
            }
            .foregroundStyle(tone.tint)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

struct AppMacFormSection<Content: View>: View {
    let title: String
    var footer: String? = nil
    let content: Content

    init(
        title: String,
        footer: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            content
                .frame(maxWidth: .infinity, alignment: .leading)

            if let footer {
                Text(footer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.platformBorder.opacity(0.5), lineWidth: 1)
        }
    }
}

struct AppMacModalHeader<TrailingContent: View>: View {
    let title: String
    var subtitle: String? = nil
    let trailingContent: TrailingContent

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailingContent: () -> TrailingContent
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailingContent = trailingContent()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.semibold))

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 12)

            trailingContent
        }
    }
}

struct AppDashboardModalContainer<Content: View>: View {
    let title: String
    var maxWidth: CGFloat = 720
    var onDismiss: (() -> Void)? = nil
    let content: Content

    init(
        title: String,
        maxWidth: CGFloat = 720,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.maxWidth = maxWidth
        self.onDismiss = onDismiss
        self.content = content()
    }

    var body: some View {
        #if os(macOS)
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AppMacModalHeader(title: title) {
                    if let onDismiss {
                        Button("Close", action: onDismiss)
                    }
                }

                content
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(24)
            .frame(maxWidth: maxWidth, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        #else
        NavigationStack {
            ScrollView {
                content
                    .padding()
                    .appContentWidth(maxWidth)
            }
            .background(Color(.clear))
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                if let onDismiss {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close", action: onDismiss)
                    }
                }
            }
        }
        #endif
    }
}

struct AdaptiveMetricGrid<Content: View>: View {
    var minWidth: CGFloat = 180
    var spacing: CGFloat = 12
    let content: Content

    init(
        minWidth: CGFloat = 180,
        spacing: CGFloat = 12,
        @ViewBuilder content: () -> Content
    ) {
        self.minWidth = minWidth
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: minWidth), spacing: spacing, alignment: .top)],
            spacing: spacing
        ) {
            content
        }
    }
}
