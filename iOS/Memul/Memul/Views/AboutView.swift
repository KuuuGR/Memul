import SwiftUI

struct AboutView: View {
    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // App title / logo
                Image("app_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(radius: 6, y: 3)

                Text("Memul")
                    .font(.largeTitle.bold())
                    .foregroundColor(AppTheme.primary)
                    .padding(.top, 4)

                // About (app facts)
                AboutSection(
                    title: NSLocalizedString("ab_section_about_app", comment: "About section title"),
                    items: [
                        NSLocalizedString("ab_app_name", comment: "App display name"),
                        String(format: NSLocalizedString("ab_version", comment: "Version format"), appVersion),
                        NSLocalizedString("ab_developer", comment: "Developer line")
                    ]
                )

                // Purpose (why this exists)
                AboutSection(
                    title: NSLocalizedString("ab_section_purpose", comment: "Purpose section title"),
                    items: [
                        NSLocalizedString("ab_purpose_learn_tables", comment: ""),
                        NSLocalizedString("ab_purpose_carries_forward", comment: ""),
                        NSLocalizedString("ab_purpose_commutativity", comment: ""),
                        NSLocalizedString("ab_purpose_accessible", comment: "")
                    ]
                )

                // App features / what it includes
                AboutSection(
                    title: NSLocalizedString("ab_section_features", comment: "Features section title"),
                    items: [
                        NSLocalizedString("ab_feature_multiplayer", comment: ""),
                        NSLocalizedString("ab_feature_puzzle_reveal", comment: ""),
                        NSLocalizedString("ab_feature_tutorial", comment: ""),
                        NSLocalizedString("ab_feature_quick_practice", comment: ""),
                        NSLocalizedString("ab_feature_customization", comment: "")
                    ]
                )

                // Author
                AboutSection(
                    title: NSLocalizedString("ab_section_author", comment: "Author section title"),
                    items: [
                        NSLocalizedString("ab_author_line1", comment: ""),
                        NSLocalizedString("ab_author_line2", comment: "")
                    ]
                )

                // Support (custom content)
                AboutSection(
                    title: NSLocalizedString("ab_section_support", comment: ""),
                    items: []
                ) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(AppTheme.primary)
                        Text("etaosin@gmail.com")
                            .foregroundColor(AppTheme.onSurface)
                            .font(.body)
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer(minLength: 32)
            }
            .padding()
        }
        .navigationTitle(Text(NSLocalizedString("ab_navigation_title", comment: "")))
    }
}

// Generic section block (works with simple text items or custom content)
struct AboutSection<Content: View>: View {
    let title: String
    let items: [String]
    let customContent: () -> Content

    init(title: String, items: [String], @ViewBuilder customContent: @escaping () -> Content = { EmptyView() }) {
        self.title = title
        self.items = items
        self.customContent = customContent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.primary)

            ForEach(items, id: \.self) { text in
                Text(text)
                    .font(.body)
                    .foregroundColor(AppTheme.onSurface)
            }

            customContent()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

// Simple app theme palette (no external color manager required)
enum AppTheme {
    static let primary = Color.blue
    static let onSurface = Color.primary
    static let surface = Color(UIColor.systemBackground)
}
