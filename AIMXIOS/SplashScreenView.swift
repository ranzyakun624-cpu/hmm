import SwiftUI

struct SplashScreenView: View {
    let onFinish: () -> Void

    @State private var progress: Double = 0.0
    @State private var statusText: String = "Menyiapkan modul inti…"
    @State private var spinOuter: Double = 0.0
    @State private var spinHex: Double = 0.0

    private let cyanGlow = Color(red: 0.0, green: 0.67, blue: 1.0)
    private let blueGlow = Color(red: 0.0, green: 0.4, blue: 1.0)
    private let goldGlow = Color(red: 0.0, green: 0.87, blue: 1.0)
    private let timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            ParticleSystemView()

            VStack(spacing: 28) {
                Spacer()

                // Core Loading Ring & Hexagon
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [cyanGlow.opacity(0.22), blueGlow.opacity(0.07), .clear], center: .center, startRadius: 8, endRadius: 118))
                        .frame(width: 236, height: 236)
                        .blur(radius: 10)

                    // Outer Dashed Ring
                    Circle()
                        .stroke(
                            StrokeStyle(lineWidth: 1.5, dash: [6, 6]),
                            value: 1
                        )
                        .foregroundColor(cyanGlow.opacity(0.3))
                        .frame(width: 172, height: 172)
                        .rotationEffect(.degrees(spinOuter))

                    // Solid Inner Ring Track
                    Circle()
                        .stroke(Color.white.opacity(0.06), lineWidth: 2.5)
                        .frame(width: 150, height: 150)

                    // Active Circular Progress Ring
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(
                            LinearGradient(
                                colors: [cyanGlow, blueGlow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 150, height: 150)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: cyanGlow.opacity(0.8), radius: 8)

                    // Hexagon Center Core Icon
                    ZStack {
                        HexagonShape()
                            .stroke(blueGlow, lineWidth: 3)
                            .frame(width: 74, height: 74)

                        HexagonShape()
                            .stroke(cyanGlow, lineWidth: 2)
                            .frame(width: 56, height: 56)

                        HexagonShape()
                            .fill(cyanGlow.opacity(0.3))
                            .frame(width: 30, height: 30)
                    }
                    .rotationEffect(.degrees(spinHex))

                    // Percentage Text
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: blueGlow, radius: 10)
                }

                // Brand Header
                VStack(spacing: 6) {
                    Text("SENS X IOS")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .tracking(3.0)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, goldGlow, cyanGlow, blueGlow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: cyanGlow.opacity(0.5), radius: 16)

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, goldGlow, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 132, height: 1.5)
                        .shadow(color: goldGlow.opacity(0.55), radius: 8)

                    Text("SENS X IOS · PREMIUM")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .tracking(4.0)
                        .foregroundColor(Color.white.opacity(0.6))

                    Text("DEVICE ID ")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(goldGlow) +
                    Text("0098")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }

                Spacer()

                // Progress Bar & Status
                VStack(spacing: 10) {
                    Text(statusText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.65))

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.07))
                            .frame(width: 220, height: 3)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [blueGlow, cyanGlow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 220 * CGFloat(progress), height: 3)

                        Circle()
                            .fill(goldGlow)
                            .frame(width: 7, height: 7)
                            .shadow(color: goldGlow, radius: 8)
                            .offset(x: max(0, (220 * CGFloat(progress)) - 3.5))
                    }
                    .shadow(color: blueGlow.opacity(0.22), radius: 8, y: 2)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            // Play Epic Cinematic Boot Audio
            SoundManager.shared.playEpicSplashBootSound()

            withAnimation(.linear(duration: 22.0).repeatForever(autoreverses: false)) {
                spinOuter = 360
            }
            withAnimation(.linear(duration: 6.0).repeatForever(autoreverses: false)) {
                spinHex = 360
            }
        }
        .onReceive(timer) { _ in
            if progress < 1.0 {
                progress += (0.03 / 2.9) // ~2.9s exact loading duration matching HTML
                
                if progress >= 0.20 && progress < 0.45 {
                    statusText = "Memuat driver grafis…"
                } else if progress >= 0.45 && progress < 0.70 {
                    statusText = "Menghubungkan ke server SENS X IOS…"
                } else if progress >= 0.70 && progress < 0.95 {
                    statusText = "Mengkalibrasi sensor performa…"
                } else if progress >= 0.95 {
                    statusText = "Siap digunakan"
                }
            } else {
                timer.upstream.connect().cancel()
                withAnimation(.easeInOut(duration: 0.4)) {
                    onFinish()
                }
            }
        }
    }
}
