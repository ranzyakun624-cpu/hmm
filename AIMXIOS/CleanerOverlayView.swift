import SwiftUI

struct CleanerOverlayView: View {
    let title: String
    let steps: [String]
    let durationSeconds: Double
    let onDismiss: () -> Void

    @State private var progress: Double = 0.0
    @State private var detailText: String = ""
    @State private var isFinished: Bool = false
    @State private var isPulsing: Bool = false
    @State private var ringRotation: Double = 0.0

    private let cyanGlow = Color(red: 0.0, green: 0.67, blue: 1.0)
    private let blueGlow = Color(red: 0.0, green: 0.4, blue: 1.0)
    private let greenSuccess = Color(red: 0.2, green: 1.0, blue: 0.69)
    private let timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()
    private let finishHoldDuration = 0.6

    private var progressDuration: Double {
        max(0.03, durationSeconds - finishHoldDuration)
    }

    var body: some View {
        ZStack {
            // Backdrop
            Color(red: 0.015, green: 0.04, blue: 0.09).opacity(0.88)
                .ignoresSafeArea()

            RadialGradient(
                colors: [cyanGlow.opacity(0.16), .clear],
                center: .center,
                startRadius: 10,
                endRadius: 320
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                
                // Process Ring
                ZStack {
                    Circle()
                        .stroke(
                            StrokeStyle(lineWidth: 1, dash: [3, 7])
                        )
                        .foregroundColor(cyanGlow.opacity(0.3))
                        .frame(width: 150, height: 150)
                        .rotationEffect(.degrees(ringRotation))

                    Circle()
                        .stroke(Color.white.opacity(0.07), lineWidth: 4)
                        .frame(width: 130, height: 130)

                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(
                            LinearGradient(
                                colors: [cyanGlow, blueGlow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: cyanGlow.opacity(0.7), radius: 6)

                    // Center Icon
                    Group {
                        if isFinished {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 44, weight: .semibold))
                                .foregroundColor(greenSuccess)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 38, weight: .light))
                                .foregroundColor(cyanGlow)
                        }
                    }
                    .scaleEffect(isFinished ? 1.0 : (isPulsing ? 1.08 : 0.92))
                    .animation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true), value: isPulsing)
                }

                // Label Title
                Text(title.uppercased())
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundColor(.white)
                    .shadow(color: cyanGlow.opacity(0.25), radius: 10)

                // Detail Step Text
                Text(detailText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 18)
            }
            .padding(30)
            .background(LinearGradient(colors: [Color.white.opacity(0.07), Color.white.opacity(0.025)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(LinearGradient(colors: [cyanGlow.opacity(0.32), .white.opacity(0.08), blueGlow.opacity(0.24)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
            .shadow(color: blueGlow.opacity(0.13), radius: 26, y: 12)
        }
        .onAppear {
            if let firstStep = steps.first {
                detailText = firstStep
            }
            isPulsing = true
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
        }
        .onReceive(timer) { _ in
            if progress < 1.0 {
                progress = min(1.0, progress + (0.03 / progressDuration))
                
                let stepCount = max(1, steps.count)
                let currentIdx = min(steps.count - 1, Int(progress * Double(stepCount)))
                if currentIdx < steps.count {
                    detailText = steps[currentIdx]
                }
                if progress >= 1.0 {
                    timer.upstream.connect().cancel()
                    withAnimation {
                        isFinished = true
                        detailText = "Selesai"
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + finishHoldDuration) {
                        onDismiss()
                    }
                }
            }
        }
    }
}
