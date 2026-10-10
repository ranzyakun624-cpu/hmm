import SwiftUI

struct LoginView: View {
    let onSuccess: () -> Void

    @State private var username: String = UserDefaults.standard.string(forKey: "saved_username") ?? ""
    @State private var licenseKey: String = UserDefaults.standard.string(forKey: "saved_license_key") ?? ""
    @State private var isVerifying: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var shakeOffset: CGFloat = 0.0

    @StateObject private var supabase = SupabaseManager.shared

    private let cyanGlow = Color(red: 0.0, green: 0.67, blue: 1.0)
    private let blueGlow = Color(red: 0.0, green: 0.4, blue: 1.0)
    private let goldGlow = Color(red: 0.0, green: 0.87, blue: 1.0)

    var body: some View {
        ZStack {
            ParticleSystemView()

            VStack {
                Spacer()

                // Login Card Container
                VStack(spacing: 12) {
                    
                    // Hexagon Logo Icon
                    ZStack {
                        HexagonShape()
                            .stroke(blueGlow, lineWidth: 3)
                            .frame(width: 56, height: 56)

                        HexagonShape()
                            .stroke(cyanGlow, lineWidth: 2)
                            .frame(width: 42, height: 42)
                    }
                    .shadow(color: blueGlow.opacity(0.8), radius: 10)
                    .padding(.bottom, 6)

                    Text("SENS X IOS ACCESS")
                        .font(.system(size: 19, weight: .bold, design: .serif))
                        .tracking(2.0)
                        .foregroundColor(goldGlow)

                    Text("Masukkan license key untuk mengaktifkan\nTOOLS INJECT IOS")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 20)

                    // User Input Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("USER")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1.2)
                            .foregroundColor(Color.white.opacity(0.45))

                        TextField("Masukkan User Anda", text: $username)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(LinearGradient(colors: [Color.white.opacity(0.075), Color.white.opacity(0.025)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(cyanGlow.opacity(0.28), lineWidth: 1)
                            )
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }

                    // License Key Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("LICENSE KEY")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1.2)
                            .foregroundColor(Color.white.opacity(0.45))

                        SecureField("NEXOR-XXXX-XXXX-XXXX", text: $licenseKey)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(LinearGradient(colors: [Color.white.opacity(0.075), Color.white.opacity(0.025)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(cyanGlow.opacity(0.28), lineWidth: 1)
                            )
                            .autocapitalization(.none)
                    }

                    // Error Banner
                    if showError {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(red: 1.0, green: 0.25, blue: 0.4))
                            .frame(minHeight: 18)
                            .padding(.top, 4)
                            .transition(.opacity)
                    }

                    // MASUK Button
                    Button {
                        SoundManager.shared.playTactileClick()
                        performLogin()
                    } label: {
                        HStack {
                            if isVerifying {
                                ProgressView().tint(.black)
                                Text("MEMERIKSA...")
                                    .font(.system(size: 15, weight: .bold))
                            } else {
                                Text("MASUK")
                                    .font(.system(size: 16, weight: .bold))
                                    .tracking(1.0)
                            }
                        }
                        .foregroundColor(Color(red: 0.01, green: 0.04, blue: 0.09))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.20, green: 0.82, blue: 1.0), cyanGlow, blueGlow],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.35), lineWidth: 1))
                        .shadow(color: blueGlow.opacity(0.48), radius: 16, y: 5)
                    }
                    .disabled(isVerifying)
                    .padding(.top, 8)

                    // Contact Hint
                    VStack(spacing: 4) {
                        Text("Belum punya key? ")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.45)) +
                        Text("CONTACT DEV FOR GET UR KEY")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(goldGlow)
                    }
                    .padding(.top, 18)
                }
                .offset(x: shakeOffset)
                .padding(.horizontal, 24)
                .padding(.vertical, 22)
                .background {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(LinearGradient(colors: [Color(red: 0.07, green: 0.14, blue: 0.24).opacity(0.92), Color(red: 0.025, green: 0.055, blue: 0.12).opacity(0.96)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(RoundedRectangle(cornerRadius: 28).stroke(LinearGradient(colors: [cyanGlow.opacity(0.35), .white.opacity(0.08), blueGlow.opacity(0.24)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
                        .shadow(color: blueGlow.opacity(0.16), radius: 24, y: 10)
                }
                .padding(.horizontal, 18)

                Spacer()

                // Footer Text
                Text("RANZY DEV")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(3.0)
                    .foregroundColor(Color.white.opacity(0.35))
                    .padding(.bottom, 24)
            }
        }
    }

    private func performLogin() {
        let trimmedKey = licenseKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedKey.isEmpty else {
            triggerError("Masukkan license key.")
            return
        }

        isVerifying = true
        showError = false

        supabase.verifyLicense(username: username, licenseKey: trimmedKey) { success, message in
            isVerifying = false
            
            if success {
                SoundManager.shared.playSuccessChord()
                UserDefaults.standard.set(username, forKey: "saved_username")
                UserDefaults.standard.set(trimmedKey, forKey: "saved_license_key")
                withAnimation {
                    onSuccess()
                }
            } else {
                triggerError(message)
            }
        }
    }

    private func triggerError(_ msg: String) {
        errorMessage = msg
        showError = true
        withAnimation(.default) {
            shakeOffset = -8
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            shakeOffset = 8
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                shakeOffset = -6
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    shakeOffset = 6
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                        shakeOffset = 0
                    }
                }
            }
        }
    }
}
