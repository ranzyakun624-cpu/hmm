import SwiftUI

struct ContentView: View {
    // Toggles State
    @AppStorage("toggleTouch") private var toggleTouch = false
    @AppStorage("toggleDrag") private var toggleDrag = false
    @AppStorage("toggleFps") private var toggleFps = false

    @AppStorage("toggleAimdrag") private var toggleAimdrag = false
    @AppStorage("toggleRecoil") private var toggleRecoil = false
    @AppStorage("toggleStabilizer") private var toggleStabilizer = false
    @AppStorage("toggleSensitivity") private var toggleSensitivity = false
    @AppStorage("toggleHeadlock") private var toggleHeadlock = false
    @AppStorage("toggleAutoOpenGame") private var toggleAutoOpenGame = true

    // Dynamic Subtitles State
    @State private var cleanerSub = "Bersihkan cache aplikasi & file sampah"
    @State private var wifiSub = "Kurangi lag pada koneksi WiFi"
    @State private var dataSub = "Stabilkan koneksi data seluler"
    @State private var latencyValue = "14 ms"

    // App Navigation State
    @State private var appState: AppState = .splash
    @State private var hasCheckedSavedLicense = false
    @State private var startupLicenseCheckFinished = false
    @State private var startupLicenseIsValid = false
    @State private var splashFinished = false

    // Process Overlay State
    @State private var showOverlay = false
    @State private var overlayTitle = ""
    @State private var overlaySteps: [String] = []
    @State private var overlayDuration: Double = 2.5
    @State private var overlayOnDone: (() -> Void)? = nil

    // Bottom Sheet Game Selector State
    @State private var showGameSheet = false

    // Toast Notification State
    @State private var showToast = false
    @State private var toastTitle = ""
    @State private var toastSub = ""

    private let cyanGlow = Color(red: 0.0, green: 0.67, blue: 1.0)
    private let blueGlow = Color(red: 0.0, green: 0.4, blue: 1.0)
    private let goldGlow = Color(red: 0.0, green: 0.87, blue: 1.0)
    private let successGreen = Color(red: 0.2, green: 1.0, blue: 0.69)
    private let cardBg = Color.white.opacity(0.055)
    private let cardBorder = Color(red: 0.0, green: 0.53, blue: 1.0).opacity(0.26)

    enum AppState {
        case splash
        case login
        case mainDashboard
    }

    var body: some View {
        ZStack {
            switch appState {
            case .splash:
                SplashScreenView {
                    handleSplashFinished()
                }

            case .login:
                LoginView {
                    withAnimation {
                        appState = .mainDashboard
                    }
                }

            case .mainDashboard:
                mainDashboardView
            }

            // Process Overlay Ring Modal
            if showOverlay {
                CleanerOverlayView(
                    title: overlayTitle,
                    steps: overlaySteps,
                    durationSeconds: overlayDuration
                ) {
                    showOverlay = false
                    SoundManager.shared.playSuccessChord()
                    overlayOnDone?()
                }
                .transition(.opacity)
            }

            // Toast Notification Banner
            if showToast {
                VStack {
                    Spacer()
                    toastBanner
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 26)
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showToast)
            }
        }
        .ignoresSafeArea()
        .statusBar(hidden: true)
        .preferredColorScheme(.dark)
        .task {
            restoreSavedLicenseIfNeeded()
        }
        .sheet(isPresented: $showGameSheet) {
            gameSelectorSheet
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        }
    }

    private func restoreSavedLicenseIfNeeded() {
        guard !hasCheckedSavedLicense else { return }
        hasCheckedSavedLicense = true

        let username = UserDefaults.standard.string(forKey: "saved_username") ?? ""
        let licenseKey = UserDefaults.standard.string(forKey: "saved_license_key") ?? ""
        guard !licenseKey.isEmpty else {
            startupLicenseCheckFinished = true
            routeFromSplashIfReady()
            return
        }

        SupabaseManager.shared.verifyLicense(username: username, licenseKey: licenseKey) { isValid, message in
            startupLicenseCheckFinished = true
            startupLicenseIsValid = isValid
            if !isValid {
                if message == "License has expired" || message == "License key was not found" || message == "License is inactive" {
                    UserDefaults.standard.removeObject(forKey: "saved_license_key")
                }
            }
            routeFromSplashIfReady()
        }
    }

    private func handleSplashFinished() {
        splashFinished = true
        routeFromSplashIfReady()
    }

    private func routeFromSplashIfReady() {
        guard startupLicenseCheckFinished else { return }
        guard splashFinished, appState == .splash else { return }

        withAnimation {
            appState = startupLicenseIsValid ? .mainDashboard : .login
        }
    }

    // MARK: - Main Dashboard View
    private var mainDashboardView: some View {
        ZStack {
            ParticleSystemView()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    topBar
                    statusSection
                    autoLaunchSection
                    pembersihanSection
                    optimasiSection
                    aimControlSection
                    gamespacesSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)
                .padding(.bottom, 34)
            }
        }
    }

    // MARK: - TopBar
    private var topBar: some View {
        HStack {
            HStack(spacing: 10) {
                ZStack {
                    HexagonShape().stroke(blueGlow, lineWidth: 2).frame(width: 28, height: 28)
                    HexagonShape().stroke(cyanGlow, lineWidth: 1.5).frame(width: 20, height: 20)
                }
                Text("SENS X IOS SYSTEM BY RANZYNEXOR")
                    .font(.system(size: 13.5, weight: .semibold, design: .serif))
                    .tracking(1.4)
                    .foregroundColor(.white)
            }

            Spacer()

            // Status Chip
            HStack(spacing: 6) {
                Circle()
                    .fill(successGreen)
                    .frame(width: 7, height: 7)
                    .shadow(color: successGreen, radius: 4)

                Text("ACTIVATE DEVICE ID :0098")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.8))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(cardBg, in: Capsule())
            .overlay(Capsule().stroke(LinearGradient(colors: [cyanGlow.opacity(0.35), .white.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
            .shadow(color: blueGlow.opacity(0.12), radius: 12, y: 4)
        }
    }

    // MARK: - Status Sistem Section
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Status Sistem")

            HStack(spacing: 12) {
                // Latency Card
                HStack(spacing: 12) {
                    Circle()
                        .fill(LinearGradient(colors: [cyanGlow.opacity(0.2), blueGlow.opacity(0.1)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "wifi")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(cyanGlow)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("LATENCY")
                            .font(.system(size: 11, weight: .semibold, design: .serif))
                            .foregroundColor(Color.white.opacity(0.5))
                        Text(latencyValue)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(successGreen)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
                .background(LinearGradient(colors: [Color.white.opacity(0.075), cardBg], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 19))
                .overlay(RoundedRectangle(cornerRadius: 19).stroke(cardBorder, lineWidth: 1))
                .shadow(color: blueGlow.opacity(0.09), radius: 14, y: 6)

                // Status Card
                HStack(spacing: 12) {
                    Circle()
                        .fill(LinearGradient(colors: [successGreen.opacity(0.2), blueGlow.opacity(0.1)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(successGreen)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("STATUS")
                            .font(.system(size: 11, weight: .semibold, design: .serif))
                            .foregroundColor(Color.white.opacity(0.5))
                        Text("Terhubung")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(successGreen)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
                .background(LinearGradient(colors: [Color.white.opacity(0.075), cardBg], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 19))
                .overlay(RoundedRectangle(cornerRadius: 19).stroke(cardBorder, lineWidth: 1))
                .shadow(color: successGreen.opacity(0.07), radius: 14, y: 6)
            }
        }
    }

    // MARK: - Auto Launch Games Section
    private var autoLaunchSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Auto Launch Game")

            // Auto Launch Free Fire
            cardButtonRow(
                title: "AUTO LAUNCH FREE FIRE",
                subtitle: "Booster otomatis + Langsung meluncurkan Free Fire",
                systemIcon: "flame.fill",
                buttonText: "LAUNCH FF"
            ) {
                SoundManager.shared.playGameLaunchWhoosh()
                launchGame(name: "Free Fire", primaryScheme: "freefire://", fallbackScheme: "freefiremobile://")
            }

            // Auto Launch Free Fire MAX
            cardButtonRow(
                title: "AUTO LAUNCH FREE FIRE MAX",
                subtitle: "Booster otomatis + Langsung meluncurkan Free Fire MAX",
                systemIcon: "bolt.shield.fill",
                buttonText: "LAUNCH FFM"
            ) {
                SoundManager.shared.playGameLaunchWhoosh()
                launchGame(name: "Free Fire MAX", primaryScheme: "freefiremax://", fallbackScheme: "freefiremaxmobile://")
            }

            // Auto Open Toggle
            cardToggleRow(
                title: "AUTO OPEN GAME AFTER BOOST",
                subtitle: "Otomatis buka game pilihan saat proses optimasi selesai",
                systemIcon: "arrow.up.forward.app.fill",
                isOn: $toggleAutoOpenGame
            ) { on in
                triggerToast(
                    title: on ? "Auto Launch Aktif" : "Auto Launch Nonaktif",
                    sub: on ? "Game akan otomatis diluncurkan setelah booster" : "Booster berjalan tanpa meluncurkan game"
                )
            }
        }
    }

    // MARK: - Pembersihan Section
    private var pembersihanSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Pembersihan")

            HStack(spacing: 14) {
                iconWrap(systemImage: "wand.and.stars")

                VStack(alignment: .leading, spacing: 2) {
                    Text("Cleaner Cache & Junk File")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Text(cleanerSub)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.5))
                }

                Spacer()

                Button("Bersihkan") {
                    SoundManager.shared.playTactileClick()
                    triggerCleaner()
                }
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(Color(red: 0.01, green: 0.04, blue: 0.09))
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(LinearGradient(colors: [cyanGlow, blueGlow], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 11))
                .shadow(color: blueGlow.opacity(0.4), radius: 6)
            }
            .padding(16)
            .background(LinearGradient(colors: [Color.white.opacity(0.075), cardBg], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 19))
            .overlay(RoundedRectangle(cornerRadius: 19).stroke(cardBorder, lineWidth: 1))
            .shadow(color: blueGlow.opacity(0.09), radius: 14, y: 6)
        }
    }

    // MARK: - Optimasi Section
    private var optimasiSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Optimasi")

            // LOW LATENCY TOUCH
            cardToggleRow(
                title: "LOW LATENCY TOUCH",
                subtitle: "BERFUNGSI SEBAGAI RESPONSIVE TOUCH AND REDUCE LOW LATENCY TOUCH IOS",
                systemIcon: "hand.tap.fill",
                isOn: $toggleTouch
            )

            // CHANGE PIXEL IOS
            cardToggleRow(
                title: "CHANGE PIXEL IOS",
                subtitle: "PIXEL DRAG IOS V1 & GUNAKAN UNTUK MENGURANGI PIXEL IOSA DAN DAPAT MENAMBAH RASIO HS ANDA",
                systemIcon: "arrow.down.to.line.alt",
                isOn: $toggleDrag
            ) { on in
                triggerToast(
                    title: on ? "Drag iOS aktif" : "Drag iOS nonaktif",
                    sub: on ? "Sensitivitas drag disesuaikan ala iOS" : "Kembali ke pengaturan drag standar"
                )
            }

            // OPTIMISASI NETWORK WIFI
            cardButtonRow(
                title: "OPTIMISASI NETWORK WIFI ALL PROVIDER HOME",
                subtitle: wifiSub,
                systemIcon: "wifi",
                buttonText: "Optimalkan"
            ) {
                SoundManager.shared.playTactileClick()
                triggerWifiOpt()
            }

            // OPTIMISASI NETWORK DATA
            cardButtonRow(
                title: "OPTIMISASI NETWORK DATA ALL PROVIDER",
                subtitle: dataSub,
                systemIcon: "antenna.radiowaves.left.and.right",
                buttonText: "Optimalkan"
            ) {
                SoundManager.shared.playTactileClick()
                triggerDataOpt()
            }

            // FPS BOOSTER V2
            cardToggleRow(
                title: "FPS BOOSTER V2",
                subtitle: "TINGKATKAN FPS KALIAN DENGAN MENGGUNAKAN FPS BOOSTER",
                systemIcon: "bolt.fill",
                isOn: $toggleFps
            )
        }
    }

    // MARK: - Aim & Recoil Control Section
    private var aimControlSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Aim & Recoil Control")

            // AIMBOT DRAG AI
            cardToggleRow(
                title: "AIMBOT DRAG AI",
                subtitle: "BERFUNGSI SEBAGAI MEMPERMUDAH HS DENGAN BANTUAN SYSTEM AI DRAG",
                systemIcon: "scope",
                isOn: $toggleAimdrag
            ) { on in
                triggerToast(
                    title: on ? "Aimdrag HS aktif" : "Aimdrag HS nonaktif",
                    sub: on ? "Headshot lebih mudah dengan aimdrag presisi" : "Mode aimdrag dinonaktifkan"
                )
            }

            // REDUCE RECOIL AIM
            cardToggleRow(
                title: "REDUCE RECOIL AIM",
                subtitle: "MENGURANGI LATENCY AIM DAN MENAMBAH AKURASI SAAT MENEMBAK",
                systemIcon: "shield.slash.fill",
                isOn: $toggleRecoil
            ) { on in
                triggerToast(
                    title: on ? "Fix Recoil 35% aktif" : "Fix Recoil 35% nonaktif",
                    sub: on ? "Recoil dikurangi 35% untuk semua senjata" : "Recoil kembali normal"
                )
            }

            // REDUCE JITTER AIM
            cardToggleRow(
                title: "REDUCE JITTER AIM",
                subtitle: "MENGURANGI GETARAN SAAT PELURU KELUAR",
                systemIcon: "waveform.path.ecg",
                isOn: $toggleStabilizer
            ) { on in
                triggerToast(
                    title: on ? "Stabilizer Aim aktif" : "Stabilizer Aim nonaktif",
                    sub: on ? "Bidikan lebih stabil dan minim goyangan" : "Stabilizer dinonaktifkan"
                )
            }

            // MAX SENSITIVITY PIXEL
            cardToggleRow(
                title: "MAX SENSITIVITY PIXEL",
                subtitle: "AKTIFKAN FITUR INI JIKA ANDA MEMBUTUHKAN KELICINAN LAYAR DAN RESPONSIF",
                systemIcon: "speedometer",
                isOn: $toggleSensitivity
            ) { on in
                triggerToast(
                    title: on ? "Sensitivity Max aktif" : "Sensitivity Max nonaktif",
                    sub: on ? "Sensitivitas maksimum untuk rotasi cepat" : "Sensitivitas kembali normal"
                )
            }

            // NEW HEADLOCK
            cardToggleRow(
                title: "NEW HEADLOCK",
                subtitle: "MENINGKATKAN AKURASI AIM KE ARAH KEPALA LAWAN",
                systemIcon: "target",
                isOn: $toggleHeadlock
            ) { on in
                triggerToast(
                    title: on ? "NEW HEADLOCK 59% aktif" : "NEW HEADLOCK nonaktif",
                    sub: on ? "Lock ke kepala musuh dengan akurasi 55%" : "Headlock dinonaktifkan"
                )
            }
        }
    }

    // MARK: - GAMESPACES IOS Section (Gold VIP Banner)
    private var gamespacesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "GAMESPACES IOS")

            Button {
                SoundManager.shared.playTactileClick()
                showGameSheet = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 19)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.07, green: 0.14, blue: 0.24), Color(red: 0.02, green: 0.04, blue: 0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: goldGlow.opacity(0.10), radius: 18, y: 7)
                        .overlay(
                            RoundedRectangle(cornerRadius: 19)
                                .stroke(goldGlow.opacity(0.4), lineWidth: 1.5)
                        )

                    Text("VIP")
                        .font(.system(size: 9, weight: .bold, design: .serif))
                        .foregroundColor(Color(red: 0.01, green: 0.04, blue: 0.09))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(goldGlow, in: Capsule())
                        .padding(10)

                    HStack(spacing: 16) {
                        iconWrap(systemImage: "bolt.fill")

                        VStack(alignment: .leading, spacing: 3) {
                            Text("BOOSTER UR GAME")
                                .font(.system(size: 14.5, weight: .black, design: .rounded))
                                .tracking(0.8)
                                .foregroundColor(goldGlow)

                            Text("Certified Performance Enhancement — SENS X IOS × RANZY DEV")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(red: 0.53, green: 0.73, blue: 0.87))
                                .multilineTextAlignment(.leading)
                        }

                        Spacer()

                        Text("›")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(goldGlow)
                    }
                    .padding(20)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Bottom Sheet Game Selector Modal
    private var gameSelectorSheet: some View {
        ZStack {
            Color(red: 0.03, green: 0.06, blue: 0.12).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 38, height: 4)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)

                Text("PILIH GAME")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundColor(.white)

                Text("Booster akan dijalankan sebelum game dibuka")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.5))

                VStack(spacing: 12) {
                    // Free Fire
                    Button {
                        SoundManager.shared.playGameLaunchWhoosh()
                        launchGame(name: "Free Fire", primaryScheme: "freefire://", fallbackScheme: "freefiremobile://")
                    } label: {
                        HStack(spacing: 14) {
                            RoundedRectangle(cornerRadius: 13)
                                .fill(LinearGradient(colors: [blueGlow, Color(red: 0.0, green: 0.2, blue: 0.67)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 46, height: 46)
                                .overlay(Text("FF").font(.system(size: 15, weight: .black)).foregroundColor(.white))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Free Fire")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Battle royale • siap diluncurkan")
                                    .font(.system(size: 11.5, weight: .medium))
                                    .foregroundColor(Color.white.opacity(0.5))
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(cardBg, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(cardBorder, lineWidth: 1))
                    }

                    // Free Fire MAX
                    Button {
                        SoundManager.shared.playGameLaunchWhoosh()
                        launchGame(name: "Free Fire MAX", primaryScheme: "freefiremax://", fallbackScheme: "freefiremaxmobile://")
                    } label: {
                        HStack(spacing: 14) {
                            RoundedRectangle(cornerRadius: 13)
                                .fill(LinearGradient(colors: [cyanGlow, Color(red: 0.0, green: 0.33, blue: 0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 46, height: 46)
                                .overlay(Text("FFM").font(.system(size: 15, weight: .black)).foregroundColor(.white))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Free Fire MAX")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Grafis tinggi • siap diluncurkan")
                                    .font(.system(size: 11.5, weight: .medium))
                                    .foregroundColor(Color.white.opacity(0.5))
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(cardBg, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(cardBorder, lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Toast Banner Component
    private var toastBanner: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(successGreen.opacity(0.15))
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(successGreen)
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(toastTitle)
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundColor(.white)
                Text(toastSub)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.55))
            }
            Spacer()
        }
        .padding(16)
        .background(LinearGradient(colors: [Color(red: 0.07, green: 0.13, blue: 0.22), Color(red: 0.025, green: 0.05, blue: 0.11)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(LinearGradient(colors: [successGreen.opacity(0.32), .white.opacity(0.08), cardBorder], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
        .shadow(color: .black.opacity(0.5), radius: 16, y: 7)
    }

    // MARK: - Action Triggers
    private func triggerCleaner() {
        let cacheMb = Int.random(in: 180...580)
        let junkFiles = Int.random(in: 40...130)

        runOverlayProcess(
            title: "MEMBERSIHKAN SISTEM",
            steps: ["Menganalisis cache aplikasi…", "Menghapus file sementara…", "Membersihkan junk file…", "Merapikan penyimpanan…"],
            duration: 3.0
        ) {
            let removed = CacheCleaner.clearAppCaches()
            cleanerSub = "\(cacheMb) MB cache & \(junkFiles) junk file dibersihkan"
            triggerToast(title: "Pembersihan selesai", sub: "\(cacheMb) MB terbebas, \(junkFiles) file sampah dihapus")
        }
    }

    private func triggerWifiOpt() {
        let before = Int.random(in: 14...34)
        let after = max(6, before - Int.random(in: 5...13))

        runOverlayProcess(
            title: "OPTIMASI JARINGAN WIFI",
            steps: ["Memindai sinyal WiFi…", "Mengatur ulang buffer jaringan…", "Menstabilkan koneksi…"],
            duration: 2.0
        ) {
            wifiSub = "Latensi turun dari \(before)ms ke \(after)ms"
            latencyValue = "\(after) ms"
            triggerToast(title: "WiFi dioptimalkan", sub: "Latensi membaik \(before)ms → \(after)ms")
        }
    }

    private func triggerDataOpt() {
        let before = Int.random(in: 20...44)
        let after = max(8, before - Int.random(in: 6...16))

        runOverlayProcess(
            title: "OPTIMASI JARINGAN DATA",
            steps: ["Mendeteksi operator seluler…", "Menyesuaikan prioritas paket data…", "Menstabilkan koneksi…"],
            duration: 2.0
        ) {
            dataSub = "Latensi turun dari \(before)ms ke \(after)ms"
            latencyValue = "\(after) ms"
            triggerToast(title: "Data dioptimalkan", sub: "Latensi membaik \(before)ms → \(after)ms")
        }
    }

    private var enabledBoostFeatures: [String] {
        var features: [String] = []
        if toggleTouch { features.append("LOW LATENCY TOUCH") }
        if toggleDrag { features.append("CHANGE PIXEL IOS") }
        if toggleFps { features.append("FPS BOOSTER V2") }
        if toggleAimdrag { features.append("AIMBOT DRAG AI") }
        if toggleRecoil { features.append("REDUCE RECOIL AIM") }
        if toggleStabilizer { features.append("REDUCE JITTER AIM") }
        if toggleSensitivity { features.append("MAX SENSITIVITY PIXEL") }
        if toggleHeadlock { features.append("NEW HEADLOCK") }
        return features
    }

    private func launchGame(name: String, primaryScheme: String, fallbackScheme: String) {
        showGameSheet = false
        let activeFeatures = enabledBoostFeatures
        var boostSteps = ["Memindai konfigurasi untuk \(name)…"]

        if activeFeatures.isEmpty {
            boostSteps.append("Menyiapkan profil standar…")
        } else {
            boostSteps.append(contentsOf: activeFeatures.map { "Memuat konfigurasi \($0)…" })
        }

        boostSteps.append(contentsOf: ["Menyelesaikan animasi boosting…", "Meluncurkan \(name)…"])

        runOverlayProcess(
            title: "BOOSTER UR GAME",
            steps: boostSteps,
            duration: 3.0
        ) {
            let profileStatus = activeFeatures.isEmpty
                ? "Profil standar siap — membuka \(name)…"
                : "\(activeFeatures.count) konfigurasi aktif dimuat — membuka \(name)…"
            triggerToast(title: "Membuka \(name)", sub: profileStatus)
            
            let primaryURL = URL(string: primaryScheme)
            let fallbackURL = URL(string: fallbackScheme)

            if let url = primaryURL, UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else if let url = fallbackURL, UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else if let url = primaryURL {
                UIApplication.shared.open(url)
            }
        }
    }

    private func runOverlayProcess(title: String, steps: [String], duration: Double, onDone: @escaping () -> Void) {
        overlayTitle = title
        overlaySteps = steps
        overlayDuration = duration
        overlayOnDone = onDone
        withAnimation {
            showOverlay = true
        }
    }

    private func triggerToast(title: String, sub: String) {
        toastTitle = title
        toastSub = sub
        withAnimation {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            withAnimation {
                showToast = false
            }
        }
    }

    // MARK: - Reusable UI Helper Functions
    private func sectionHeader(title: String) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(LinearGradient(colors: [goldGlow, .clear], startPoint: .leading, endPoint: .trailing))
                .frame(width: 12, height: 1.5)
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .tracking(2.0)
                .foregroundColor(Color.white.opacity(0.45))
                Spacer(minLength: 0)
        }
            .padding(.top, 16)
            .padding(.bottom, 2)
    }

    private func iconWrap(systemImage: String) -> some View {
        RoundedRectangle(cornerRadius: 13)
            .fill(LinearGradient(colors: [blueGlow.opacity(0.28), cyanGlow.opacity(0.10)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 44, height: 44)
            .overlay(
                RoundedRectangle(cornerRadius: 13).stroke(LinearGradient(colors: [cyanGlow.opacity(0.35), .white.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
            .overlay(
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(cyanGlow)
            )
            .shadow(color: blueGlow.opacity(0.16), radius: 9, y: 3)
    }

    private func cardToggleRow(title: String, subtitle: String, systemIcon: String, isOn: Binding<Bool>, onChange: ((Bool) -> Void)? = nil) -> some View {
        HStack(spacing: 14) {
            iconWrap(systemImage: systemIcon)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.45))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(blueGlow)
                .onChange(of: isOn.wrappedValue) { newValue in
                    if newValue {
                        SoundManager.shared.playToggleOnSound()
                    } else {
                        SoundManager.shared.playToggleOffSound()
                    }
                    onChange?(newValue)
                }
        }
        .padding(16)
        .background(LinearGradient(colors: [Color.white.opacity(0.07), cardBg], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 19))
        .overlay(RoundedRectangle(cornerRadius: 19).stroke(LinearGradient(colors: [cyanGlow.opacity(0.24), .white.opacity(0.07), cardBorder], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
        .shadow(color: blueGlow.opacity(0.075), radius: 12, y: 5)
    }

    private func cardButtonRow(title: String, subtitle: String, systemIcon: String, buttonText: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            iconWrap(systemImage: systemIcon)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.45))
            }

            Spacer(minLength: 4)

            Button(buttonText) {
                action()
            }
            .font(.system(size: 12.5, weight: .bold))
            .foregroundColor(Color(red: 0.01, green: 0.04, blue: 0.09))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(LinearGradient(colors: [cyanGlow, blueGlow], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 11))
            .shadow(color: blueGlow.opacity(0.35), radius: 5)
        }
        .padding(16)
        .background(LinearGradient(colors: [Color.white.opacity(0.07), cardBg], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 19))
        .overlay(RoundedRectangle(cornerRadius: 19).stroke(LinearGradient(colors: [cyanGlow.opacity(0.24), .white.opacity(0.07), cardBorder], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
        .shadow(color: blueGlow.opacity(0.075), radius: 12, y: 5)
    }
}
