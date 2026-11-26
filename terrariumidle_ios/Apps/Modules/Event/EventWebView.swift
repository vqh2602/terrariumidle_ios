import FirebaseAuth
import SwiftUI
import WebKit

struct EventWebScreen: View {
    let event: TerrariumEvent
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var notice: String?
    @State private var reloadID = UUID()
    @State private var showVIPSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ZStack {
                    EventWebView(event: event, url: url, isLoading: $isLoading, loadError: $loadError, notice: $notice) {
                        showVIPSheet = true
                    }
                        .id(reloadID)
                    if isLoading { ProgressView().padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12)) }
                    if let loadError {
                        VStack(spacing: 16) {
                            Text(loadError).multilineTextAlignment(.center)
                            Button("Thử lại".tr) {
                                self.loadError = nil
                                isLoading = true
                                reloadID = UUID()
                            }
                        }.padding().frame(maxWidth: .infinity, maxHeight: .infinity).background(AccountStyle.cream)
                    }
                }
                if let notice {
                    Text(notice).font(.subheadline).padding().frame(maxWidth: .infinity)
                        .background(AccountStyle.cream)
                        .accessibilityAddTraits(.updatesFrequently)
                }
            }
            .navigationTitle(event.content()?.title ?? "Terrarium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Đóng".tr) { dismiss() } } }
        }
        .sheet(isPresented: $showVIPSheet) {
            SubscriptionView(isSheet: true, highlightContext: "Nâng cấp VIP để tự động nhân đôi (×2) toàn bộ 30 phần thưởng điểm danh tháng!".tr)
        }
    }
}

struct EventWebView: UIViewRepresentable {
    let event: TerrariumEvent
    let url: URL
    @Binding var isLoading: Bool
    @Binding var loadError: String?
    @Binding var notice: String?
    var onOpenVIP: (() -> Void)? = nil

    // Cung cấp API web cho iOS với phản hồi dạng Promise từ WKWebView.
    static let bridgeScript = """
    window.TerrariumBridge = {
      callHandler: function(handler, ...args) {
        return window.webkit.messageHandlers.terrariumEvent.postMessage({handler: handler, args: args});
      }
    };
    window.dispatchEvent(new Event('TerrariumBridgeReady'));
    """

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        if event.handler != nil {
            controller.addScriptMessageHandler(context.coordinator, contentWorld: .page, name: "terrariumEvent")
            controller.addUserScript(WKUserScript(source: Self.bridgeScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        }
        if event.v2EventId != nil {
            controller.addScriptMessageHandler(context.coordinator, contentWorld: .page, name: "terrariumEventV2")
        }
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller
        let webView = WKWebView(frame: .zero, configuration: configuration)
        context.coordinator.webView = webView
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.load(URLRequest(url: url, timeoutInterval: 30))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) { context.coordinator.parent = self }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.stopLoading()
        uiView.navigationDelegate = nil
        uiView.uiDelegate = nil
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "terrariumEvent", contentWorld: .page)
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "terrariumEventV2", contentWorld: .page)
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandlerWithReply {
        var parent: EventWebView
        private var isClaiming = false
        weak var webView: WKWebView?
        private var lastWheelClaim = Date.distantPast
        private var vipObserver: NSObjectProtocol?

        init(_ parent: EventWebView) {
            self.parent = parent
            super.init()
            vipObserver = NotificationCenter.default.addObserver(
                forName: .terrariumVIPDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.webView?.evaluateJavaScript("window.dispatchEvent(new Event('terrariumEventUpdated'));", completionHandler: nil)
                }
            }
        }

        deinit {
            if let vipObserver {
                NotificationCenter.default.removeObserver(vipObserver)
            }
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
            if message.name == "terrariumEventV2" {
                handleV2Message(message, replyHandler: replyHandler)
                return
            }
            guard message.frameInfo.isMainFrame,
                  message.frameInfo.securityOrigin.protocol == "https",
                  message.frameInfo.securityOrigin.host == parent.url.host,
                  message.frameInfo.request.url?.path == parent.url.path,
                  let body = message.body as? [String: Any],
                  let handler = body["handler"] as? String, handler == parent.event.handler,
                  let args = body["args"] as? [Any], let argument = args.first else {
                replyHandler(nil, "Lệnh sự kiện không hợp lệ".tr)
                return
            }
            // Trang web gọi các handler huy hiệu với giá trị 'false' đối với người dùng không đủ điều kiện.
            if handler != "clam-lavender-plant", (argument as? String) == "false" {
                replyHandler(NSNull(), nil)
                return
            }
            guard parent.event.unavailableReason() == nil else {
                replyHandler(nil, parent.event.unavailableReason())
                return
            }
            guard !isClaiming, !(handler == "clam-lavender-plant" && Date().timeIntervalSince(lastWheelClaim) < 2) else {
                replyHandler(nil, "Phần thưởng đang được xử lý. Vui lòng chờ.".tr)
                return
            }
            let store = FireStoreService.shared
            guard let garden = store.gradenModel,
                  AuthService.shared.currentUser?.uid == garden.user.userID else {
                replyHandler(nil, "Vui lòng đăng nhập lại".tr)
                return
            }
            do {
                let updated = try EventReward.apply(handler: handler, argument: argument, to: garden)
                isClaiming = true
                parent.notice = "Đang lưu phần thưởng…".tr
                Task {
                    let saved = await store.saveEventReward(gardenModel: updated)
                    isClaiming = false
                    if saved {
                        if handler == "clam-lavender-plant" { lastWheelClaim = Date() }
                        syncWebState(updated)
                        parent.notice = "Đã nhận và lưu phần thưởng.".tr
                        replyHandler(NSNull(), nil)
                    } else {
                        parent.notice = "Chưa lưu được phần thưởng. Vui lòng kiểm tra kết nối rồi thử lại.".tr
                        replyHandler(nil, parent.notice)
                    }
                }
            } catch {
                parent.notice = error.localizedDescription
                replyHandler(nil, error.localizedDescription)
            }
        }

        private func handleV2Message(_ message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
            guard let expectedEventId = parent.event.v2EventId,
                  message.frameInfo.isMainFrame,
                  message.frameInfo.securityOrigin.protocol == "https",
                  message.frameInfo.securityOrigin.host == parent.url.host,
                  message.frameInfo.request.url?.path == parent.url.path,
                  let body = message.body as? [String: Any],
                  (body["version"] as? NSNumber)?.intValue == 2,
                  let action = body["action"] as? String else {
                replyHandler(nil, "Lệnh sự kiện không hợp lệ".tr)
                return
            }
            let payload = body["payload"] as? [String: Any] ?? [:]
            if action == "openVIP" {
                parent.onOpenVIP?()
                replyHandler(["ok": true], nil)
                return
            }
            guard parent.event.unavailableReason() == nil || action == "getContext" || action == "resolveAssets" else {
                replyHandler(nil, parent.event.unavailableReason())
                return
            }
            Task { @MainActor in
                do {
                    let result = try await EventV2Service.shared.handle(action: action, payload: payload, expectedEventId: expectedEventId)
                    replyHandler(result, nil)
                } catch {
                    replyHandler(nil, error.localizedDescription)
                }
            }
        }

        private func syncWebState(_ garden: GardenModel) {
            guard let url = parent.event.webURL(garden: garden),
                  let data = try? JSONSerialization.data(withJSONObject: [url.absoluteString]),
                  let literal = String(data: data, encoding: .utf8) else { return }
            webView?.evaluateJavaScript("""
            (() => {
              const url = \(literal)[0];
              history.replaceState({}, '', url);
              if (typeof oxygen !== 'undefined') oxygen = \(garden.money.oxygen);
              if (typeof urlParams !== 'undefined') urlParams = new URLSearchParams(location.search);
              window.dispatchEvent(new Event('terrariumUserUpdated'));
            })();
            """, completionHandler: nil)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
            parent.loadError = nil
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { parent.isLoading = false }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { failed(error) }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { failed(error) }
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            failed(URLError(.networkConnectionLost))
        }

        private func failed(_ error: Error) {
            guard (error as NSError).code != NSURLErrorCancelled else { return }
            parent.isLoading = false
            parent.loadError = "Không tải được trang sự kiện. Vui lòng thử lại.".tr
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url, url.scheme == "https" else {
                decisionHandler(.cancel)
                return
            }
            if url.host != parent.url.host {
                if navigationAction.navigationType == .linkActivated { UIApplication.shared.open(url) }
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url, url.scheme == "https" { UIApplication.shared.open(url) }
            return nil
        }

        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            guard var presenter = webView.window?.rootViewController else { completionHandler(); return }
            while let presented = presenter.presentedViewController { presenter = presented }
            let alert = UIAlertController(title: "Terrarium", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Đóng".tr, style: .default) { _ in completionHandler() })
            presenter.present(alert, animated: true)
        }
    }
}
