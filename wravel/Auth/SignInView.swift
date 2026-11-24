//
//  SignInView.swift
//  wravel
//

import SwiftUI

struct SignInView: View {
    enum Mode {
        case signIn, signUp
    }

    @Environment(AuthStore.self) private var auth

    @State private var mode: Mode = .signIn
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isWorking = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header

                VStack(spacing: 12) {
                    if mode == .signUp {
                        TextField("Name", text: $name, prompt: appFieldPrompt("Name"))
                            .textContentType(.name)
                            .textInputAutocapitalization(.words)
                            .fieldStyle()
                    }
                    TextField("Email", text: $email, prompt: appFieldPrompt("Email"))
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .fieldStyle()
                    PasswordField(text: $password, contentType: mode == .signIn ? .password : .newPassword)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color.appError)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(Color.appError.opacity(0.15), in: .rect(cornerRadius: appFieldCornerRadius))
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                }

                Button(action: submit) {
                    Group {
                        if isWorking {
                            ProgressView()
                        } else {
                            Text(mode == .signIn ? "Sign In" : "Create Account")
                                .bold()
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 32)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: appFieldCornerRadius))
                .disabled(isWorking)

                Button(mode == .signIn ? "Don't have an account? Sign up" : "Already have an account? Sign in") {
                    withAnimation {
                        mode = mode == .signIn ? .signUp : .signIn
                        errorMessage = nil
                    }
                }
                .font(.footnote)
            }
            .padding(24)
            .padding(.top, 60)
            .animation(.steepEase(duration: 0.4), value: errorMessage)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(white: 0.05).ignoresSafeArea())
    }

    private var header: some View {
        VStack(spacing: 8) {
            VStack(spacing: 10) {
                WravelMark()
                    .frame(width: 72)
                Text("wravel")
                    .font(.subheadline.weight(.medium))
                    .tracking(1)
            }
            .padding(.bottom, 16)
            Text(mode == .signIn ? "Where are we going next?" : "Create your account")
                .foregroundStyle(.secondary)
        }
    }

    private func submit() {
        errorMessage = nil
        isWorking = true
        Task {
            defer { isWorking = false }
            do {
                switch mode {
                case .signIn: try await auth.signIn(email: email, password: password)
                case .signUp: try await auth.signUp(name: name, email: email, password: password)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

/// The password input: a secure field with an eye on its trailing edge that reveals or
/// hides the text, keeping the keyboard up across the switch.
private struct PasswordField: View {
    @Binding var text: String
    let contentType: UITextContentType

    @State private var isRevealed = false
    @FocusState private var focus: Field?

    private enum Field { case hidden, revealed }

    var body: some View {
        ZStack {
            // A secure field is a touch shorter than a text field, so size the row off a
            // hidden text field: the height then matches the other fields in both states.
            TextField("", text: .constant(""))
                .hidden()
                .disabled(true)
                .accessibilityHidden(true)
            if isRevealed {
                TextField("Password", text: $text, prompt: appFieldPrompt("Password"))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focus, equals: .revealed)
            } else {
                SecureField("Password", text: $text, prompt: appFieldPrompt("Password"))
                    .focused($focus, equals: .hidden)
            }
        }
        .textContentType(contentType)
        .multilineTextAlignment(.center)
        // Keep the text clear of the eye on both sides so it stays centered.
        .padding(.horizontal, 30)
        .appField()
        .overlay(alignment: .trailing) {
            Button {
                let wasFocused = focus != nil
                isRevealed.toggle()
                if wasFocused {
                    // The new field exists only after this update, so focus it next pass.
                    Task { @MainActor in focus = isRevealed ? .revealed : .hidden }
                }
            } label: {
                Image(systemName: isRevealed ? "eye.slash" : "eye")
                    .foregroundStyle(Color.black.opacity(0.45))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, 2)
            .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
        }
    }
}

private extension View {
    func fieldStyle() -> some View {
        multilineTextAlignment(.center)
            .appField()
    }
}

#Preview {
    SignInView()
        .appTheme()
        .environment(AuthStore())
}
