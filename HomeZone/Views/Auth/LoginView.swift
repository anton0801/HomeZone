import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var email = ""
    @State private var errorMsg = ""
    @State private var appear = false
    
    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && email.contains("@") }
    
    var body: some View {
        ZStack {
            (appState.preferredColorScheme == .dark ? DS.bgDark : DS.bg)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(DS.accentGradient)
                                .frame(width: 72, height: 72)
                            Image(systemName: "person.fill")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        Text("Welcome Back")
                            .font(DS.Font.display(26))
                        Text("Sign in to continue")
                            .font(DS.Font.body(15))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                    
                    VStack(spacing: 16) {
                        HZTextField(placeholder: "Your Name", text: $name, icon: "person")
                        HZTextField(placeholder: "Email Address", text: $email, icon: "envelope", keyboardType: .emailAddress)
                        
                        if !errorMsg.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(DS.error)
                                Text(errorMsg)
                                    .font(DS.Font.caption(13))
                                    .foregroundColor(DS.error)
                            }
                        }
                        
                        HZButton(title: "Sign In", style: .primary, action: signIn, icon: "arrow.right.circle.fill")
                            .disabled(!isValid)
                            .opacity(isValid ? 1 : 0.6)
                    }
                    .padding(.horizontal, 24)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 30)
                    
                    // Demo shortcut
                    VStack(spacing: 12) {
                        HStack {
                            Rectangle().fill(DS.border).frame(height: 1)
                            Text("or").font(DS.Font.caption(13)).foregroundColor(.secondary)
                            Rectangle().fill(DS.border).frame(height: 1)
                        }
                        .padding(.horizontal, 24)
                        
                        Button(action: {
                            appState.loginDemo()
                            appState.hasCompletedOnboarding = true
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(DS.warning)
                                Text("Use Demo Account")
                                    .font(DS.Font.heading(16))
                                    .foregroundColor(DS.accent)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(DS.accent.opacity(0.1))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(DS.accent.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        Text("Demo account includes pre-loaded data")
                            .font(DS.Font.caption(12))
                            .foregroundColor(.secondary)
                    }
                    .opacity(appear ? 1 : 0)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Sign In")
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) { appear = true }
        }
    }
    
    func signIn() {
        let n = name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty, email.contains("@") else {
            errorMsg = "Please enter a valid name and email."
            return
        }
        errorMsg = ""
        appState.login(name: n, email: email)
        appState.hasCompletedOnboarding = true
    }
}
