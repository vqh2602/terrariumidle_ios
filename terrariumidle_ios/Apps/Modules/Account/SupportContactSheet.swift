import SwiftUI

struct SupportContactSheet: View {
    @ObservedObject var viewModel: AccountViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email: String
    @State private var message: String = ""
    @State private var isSending: Bool = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert: Bool = false

    init(viewModel: AccountViewModel, initialEmail: String) {
        self.viewModel = viewModel
        _email = State(initialValue: initialEmail)
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedMessage: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValidInput: Bool {
        trimmedEmail.contains("@") && trimmedEmail.contains(".") && !trimmedMessage.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Gửi phản hồi hoặc báo lỗi trực tiếp cho đội ngũ phát triển.".tr)
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(AccountStyle.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Email liên hệ".tr, systemImage: "envelope.fill")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(AccountStyle.green)

                        TextField("name@example.com", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(AccountStyle.ink)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(AccountStyle.cream, in: RoundedRectangle(cornerRadius: 14))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(AccountStyle.border, lineWidth: 1.5)
                            }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Nội dung hỗ trợ".tr, systemImage: "text.bubble.fill")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(AccountStyle.green)

                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $message)
                                .scrollContentBackground(.hidden)
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(AccountStyle.ink)
                                .frame(minHeight: 150)
                                .padding(10)

                            if message.isEmpty {
                                Text("Mô tả vấn đề bạn gặp phải hoặc góp ý của bạn...".tr)
                                    .font(.system(.body, design: .rounded))
                                    .foregroundStyle(AccountStyle.muted.opacity(0.65))
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 18)
                                    .allowsHitTesting(false)
                            }
                        }
                        .background(AccountStyle.cream, in: RoundedRectangle(cornerRadius: 14))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(AccountStyle.border, lineWidth: 1.5)
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(.footnote, design: .rounded, weight: .semibold))
                            .foregroundStyle(AccountStyle.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        submit()
                    } label: {
                        HStack(spacing: 8) {
                            if isSending {
                                ProgressView()
                                    .tint(AccountStyle.cream)
                            } else {
                                Image(systemName: "paperplane.fill")
                            }
                            Text(isSending ? "Đang gửi...".tr : "Gửi hỗ trợ".tr)
                                .font(.system(.body, design: .rounded, weight: .bold))
                        }
                        .foregroundStyle(AccountStyle.cream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            (isValidInput && !isSending) ? AccountStyle.green : AccountStyle.muted.opacity(0.45),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!isValidInput || isSending)
                }
                .padding(20)
            }
            .background(
                LinearGradient(colors: [Color(hex: "E9EED9"), Color(hex: "F7EEDB")],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
            .navigationTitle("Liên hệ hỗ trợ".tr)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy".tr) { dismiss() }
                        .foregroundStyle(AccountStyle.muted)
                }
            }
            .alert("Đã gửi yêu cầu hỗ trợ".tr, isPresented: $showSuccessAlert) {
                Button("Đóng".tr) { dismiss() }
            } message: {
                Text("Cảm ơn bạn đã liên hệ. Đội ngũ hỗ trợ sẽ phản hồi qua email sớm nhất có thể.".tr)
            }
        }
    }

    private func submit() {
        guard isValidInput, !isSending else { return }
        errorMessage = nil
        isSending = true

        Task {
            defer { isSending = false }
            do {
                try await viewModel.sendSupportRequest(email: trimmedEmail, message: trimmedMessage)
                showSuccessAlert = true
            } catch {
                errorMessage = "Không thể gửi yêu cầu lúc này. Vui lòng thử lại sau.".tr
            }
        }
    }
}
