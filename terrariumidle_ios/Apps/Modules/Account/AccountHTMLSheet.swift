import SwiftUI
import WebKit

enum AccountHTMLDocument: String, Identifiable {
    case wiki
    case privacy
    case terms

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wiki: return "Cẩm nang khu vườn · Wiki".tr
        case .privacy: return "Chính sách bảo mật".tr
        case .terms: return "Điều khoản sử dụng".tr
        }
    }

    var resourceName: String { rawValue }
}

struct AccountHTMLSheet: View {
    let document: AccountHTMLDocument
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            LocalHTMLWebView(
                resourceName: document.resourceName,
                languageCode: LocalizationManager.shared.currentLanguage.rawValue
            )
            .ignoresSafeArea(edges: .bottom)
            .background(Color(hex: "F7EEDB").ignoresSafeArea())
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Đóng".tr) { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(AccountStyle.green)
                }
            }
        }
    }
}

private struct LocalHTMLWebView: UIViewRepresentable {
    let resourceName: String
    let languageCode: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        loadContent(into: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    private func loadContent(into webView: WKWebView) {
        let html = EncryptedResourceLoader.shared.string(forResource: resourceName, ext: "html", subdirectory: "HTML")
            ?? EncryptedResourceLoader.shared.string(forResource: resourceName, ext: "html")

        guard let html else {
            let fallback = """
            <html><body style="font-family:-apple-system,sans-serif;padding:24px;color:#2C3527;background:#F7EEDB;">
            <p>Không tìm thấy nội dung.</p>
            </body></html>
            """
            webView.loadHTMLString(fallback, baseURL: nil)
            return
        }

        let escapedLang = languageCode.replacingOccurrences(of: "\"", with: "")
        let injectedHTML = html.replacingOccurrences(
            of: "var lang = params.get(\"lang\") || \"vi\";",
            with: "var lang = params.get(\"lang\") || \"\(escapedLang)\";"
        )
        webView.loadHTMLString(injectedHTML, baseURL: Bundle.main.resourceURL)
    }
}
