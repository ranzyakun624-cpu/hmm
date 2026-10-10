import SwiftUI

struct ParticleSystemView: View {
    @State private var orbFloat: Bool = false

    private let bgBlue = Color(red: 0.0, green: 0.4, blue: 1.0)
    private let bgCyan = Color(red: 0.0, green: 0.67, blue: 1.0)
    private let bgGold = Color(red: 0.0, green: 0.87, blue: 1.0)

    var body: some View {
        ZStack {
            // Deep Midnight Blue Background
            RadialGradient(
                colors: [Color(red: 0.04, green: 0.10, blue: 0.23), Color(red: 0.02, green: 0.04, blue: 0.10)],
                center: .top,
                startRadius: 50,
                endRadius: 500
            )
            .ignoresSafeArea()

            // Floating Orb 1 (Top Left)
            Circle()
                .fill(RadialGradient(colors: [bgBlue.opacity(0.35), Color.clear], center: .center, startRadius: 10, endRadius: 180))
                .frame(width: 340, height: 340)
                .blur(radius: 60)
                .offset(x: orbFloat ? -70 : -100, y: orbFloat ? -110 : -80)

            // Floating Orb 2 (Bottom Right)
            Circle()
                .fill(RadialGradient(colors: [bgCyan.opacity(0.3), Color.clear], center: .center, startRadius: 10, endRadius: 160))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: orbFloat ? 100 : 70, y: orbFloat ? 120 : 90)

            // Floating Orb 3 (Middle Right)
            Circle()
                .fill(RadialGradient(colors: [bgGold.opacity(0.18), Color.clear], center: .center, startRadius: 10, endRadius: 120))
                .frame(width: 220, height: 220)
                .blur(radius: 50)
                .offset(x: 100, y: orbFloat ? -30 : 20)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                orbFloat.toggle()
            }
        }
        .ignoresSafeArea()
    }
}
