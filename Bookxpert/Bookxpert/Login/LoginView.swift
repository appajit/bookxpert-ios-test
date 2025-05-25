import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer()
                Image("bookxpert")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                Spacer()
                if viewModel.isLoggingIn {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
                Button(action: {
                    viewModel.googleSignIn()
                }) {
                    HStack {
                        Image("google")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text("Sign in with Google")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .padding()
                    .foregroundColor(.primary)
                    .overlay(RoundedRectangle(cornerRadius: 36).stroke(Color.gray, lineWidth: 1))
                    .opacity(viewModel.isLoggingIn ? 0.5 : 1.0)
                }
                .disabled(viewModel.isLoggingIn)
                .padding(.horizontal)

                Spacer()
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
