import SwiftUI

struct LoginView: View {
    @State private var hostValue: String
    @State private var apiKeyValue: String = ""

    let onSubmit: (String, String) -> Void
    let onCancel: () -> Void

    init(
        initialHostValue: String,
        onSubmit: @escaping (String, String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _hostValue = State(initialValue: initialHostValue)
        self.onSubmit = onSubmit
        self.onCancel = onCancel
    }

    private var canSubmit: Bool {
        !hostValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !apiKeyValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Sign in to PostHog")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text("Host URL")
                    .font(.subheadline)
                TextField("https://us.posthog.com", text: $hostValue)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Personal API key")
                    .font(.subheadline)
                SecureField("phx_...", text: $apiKeyValue)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    onCancel()
                }
                Button("Sign in") {
                    onSubmit(hostValue, apiKeyValue)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSubmit)
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}
