import Foundation
import AVFoundation
import UIKit

/// Synthesizes cinematic and tactile audio without relying on system alert tones.
final class SoundManager: ObservableObject {
    static let shared = SoundManager()

    private let sampleRate = 44_100.0
    private let renderingQueue = DispatchQueue(label: "com.sensxios.sound-render", qos: .userInitiated)
    private let playerLock = NSLock()
    private var activePlayers: [AVAudioPlayer] = []

    private init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Audio session setup warning: \(error)")
        }
    }

    // MARK: - Cinematic splash
    /// A layered low cinematic swell with a soft airy rise and a spacious harmonic finish.
    func playEpicSplashBootSound() {
        playSynthesizedSound(duration: 2.8, reverb: 0.22) { time in
            let progress = time / 2.8
            let swell = self.smoothEnvelope(progress, attack: 0.10, release: 0.90)
            let pitchRise = 1.0 + progress * 0.035
            let lowBed = self.chordSample(
                time: time,
                frequencies: [55.0, 82.41, 110.0, 164.81, 220.0, 329.63],
                pitchMultiplier: pitchRise
            )
            let airyBloom = self.chordSample(
                time: time,
                frequencies: [440.0, 554.37, 659.25],
                pitchMultiplier: 1.0 + progress * 0.08
            ) * self.pulseEnvelope(time: time, start: 0.8, duration: 1.8)
            let openingWhoosh = sin(progress * .pi) * (1.0 - min(1.0, time / 1.35))
            return (lowBed * 0.56 + airyBloom * 0.12 + openingWhoosh * 0.045) * swell
        }

        playHaptic(style: .heavy)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            self.playHaptic(style: .soft)
        }
    }

    // MARK: - Premium interaction sounds
    /// Short, soft glass-like tap; deliberately synthesized instead of an iOS keyboard beep.
    func playTactileClick() {
        playSynthesizedSound(duration: 0.20, reverb: 0.08) { time in
            let decay = exp(-time * 24.0)
            let pitch = 1.0 - min(0.12, time * 0.75)
            let glass = sin(2.0 * .pi * 1_320.0 * pitch * time) * 0.48
                + sin(2.0 * .pi * 1_980.0 * pitch * time) * 0.22
                + sin(2.0 * .pi * 2_640.0 * pitch * time) * 0.08
            let softBody = sin(2.0 * .pi * 620.0 * time) * 0.16 * exp(-time * 32.0)
            return (glass * decay + softBody) * min(1.0, time * 500.0)
        }
        playHaptic(style: .soft)
    }

    func playToggleOnSound() {
        playToggleSound(isOn: true)
        playHaptic(style: .light)
    }

    func playToggleOffSound() {
        playToggleSound(isOn: false)
        playHaptic(style: .soft)
    }

    /// Warm, ascending multi-note confirmation rather than a system notification chime.
    func playSuccessChord() {
        let notes: [(frequency: Double, start: Double, level: Double)] = [
            (392.00, 0.00, 0.30),
            (493.88, 0.12, 0.26),
            (587.33, 0.24, 0.24),
            (783.99, 0.38, 0.18)
        ]
        playSynthesizedSound(duration: 1.25, reverb: 0.18) { time in
            notes.reduce(0.0) { total, note in
                let localTime = time - note.start
                guard localTime >= 0 else { return total }
                let envelope = exp(-localTime * 4.8) * min(1.0, localTime * 60.0)
                let fundamental = sin(2.0 * .pi * note.frequency * localTime)
                let overtone = sin(2.0 * .pi * note.frequency * 2.01 * localTime) * 0.18
                return total + (fundamental + overtone) * envelope * note.level
            }
        }
        playNotificationHaptic()
    }

    // MARK: - Launch sound
    func playGameLaunchWhoosh() {
        playSynthesizedSound(duration: 1.35, reverb: 0.14) { time in
            let progress = time / 1.35
            let rise = sin(min(1.0, progress * 1.15) * .pi / 2.0)
            let pitch = 1.0 + progress * 0.22
            let chord = self.chordSample(
                time: time,
                frequencies: [73.42, 110.0, 146.83, 220.0, 293.66],
                pitchMultiplier: pitch
            )
            let airy = sin(2.0 * .pi * (380.0 + progress * 520.0) * time) * 0.09
            return (chord * 0.48 + airy * rise) * self.smoothEnvelope(progress, attack: 0.02, release: 0.78)
        }
        playHaptic(style: .heavy)
    }

    private func playToggleSound(isOn: Bool) {
        let notes = isOn ? [523.25, 659.25, 880.0] : [659.25, 523.25, 392.0]
        playSynthesizedSound(duration: 0.42, reverb: 0.07) { time in
            notes.enumerated().reduce(0.0) { total, element in
                let (index, frequency) = element
                let start = Double(index) * 0.045
                let localTime = time - start
                guard localTime >= 0 else { return total }
                let envelope = exp(-localTime * 13.0) * min(1.0, localTime * 90.0)
                return total + sin(2.0 * .pi * frequency * localTime) * envelope * 0.13
            }
        }
    }

    private func playSynthesizedSound(duration: Double, reverb: Double, sample: @escaping (Double) -> Double) {
        renderingQueue.async { [weak self] in
            self?.renderAndPlay(duration: duration, reverb: reverb, sample: sample)
        }
    }

    private func renderAndPlay(duration: Double, reverb: Double, sample: (Double) -> Double) {
        let frameCount = Int(sampleRate * duration)
        guard frameCount > 0 else { return }

        var drySamples = [Float](repeating: 0, count: frameCount)
        for index in 0..<frameCount {
            let time = Double(index) / sampleRate
            drySamples[index] = Float(sample(time))
        }

        let delayOne = Int(sampleRate * 0.085)
        let delayTwo = Int(sampleRate * 0.145)
        var wavData = Data(capacity: 44 + frameCount * 2)
        appendWavHeader(sampleCount: frameCount, to: &wavData)

        for index in 0..<frameCount {
            var value = Double(drySamples[index])
            if index >= delayOne { value += Double(drySamples[index - delayOne]) * reverb }
            if index >= delayTwo { value += Double(drySamples[index - delayTwo]) * reverb * 0.45 }
            let normalized = tanh(value * 1.25) * 0.82
            let pcm = Int16(max(-1.0, min(1.0, normalized)) * Double(Int16.max))
            appendLittleEndian(UInt16(bitPattern: pcm), to: &wavData)
        }

        do {
            let player = try AVAudioPlayer(data: wavData, fileTypeHint: AVFileType.wav.rawValue)
            player.volume = 1.0
            player.prepareToPlay()
            player.play()

            playerLock.lock()
            activePlayers.removeAll { !$0.isPlaying }
            if activePlayers.count >= 8 {
                activePlayers.removeFirst().stop()
            }
            activePlayers.append(player)
            playerLock.unlock()
        } catch {
            print("Synth playback warning: \(error)")
        }
    }

    private func appendWavHeader(sampleCount: Int, to data: inout Data) {
        let byteCount = UInt32(sampleCount * 2)
        data.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // RIFF
        appendLittleEndian(36 + byteCount, to: &data)
        data.append(contentsOf: [0x57, 0x41, 0x56, 0x45, 0x66, 0x6D, 0x74, 0x20]) // WAVE fmt
        appendLittleEndian(UInt32(16), to: &data)
        appendLittleEndian(UInt16(1), to: &data) // PCM
        appendLittleEndian(UInt16(1), to: &data) // Mono
        appendLittleEndian(UInt32(sampleRate), to: &data)
        appendLittleEndian(UInt32(sampleRate * 2), to: &data)
        appendLittleEndian(UInt16(2), to: &data)
        appendLittleEndian(UInt16(16), to: &data)
        data.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // data
        appendLittleEndian(byteCount, to: &data)
    }

    private func appendLittleEndian(_ value: UInt16, to data: inout Data) {
        data.append(UInt8(value & 0x00FF))
        data.append(UInt8((value >> 8) & 0x00FF))
    }

    private func appendLittleEndian(_ value: UInt32, to data: inout Data) {
        data.append(UInt8(value & 0x000000FF))
        data.append(UInt8((value >> 8) & 0x000000FF))
        data.append(UInt8((value >> 16) & 0x000000FF))
        data.append(UInt8((value >> 24) & 0x000000FF))
    }

    private func chordSample(time: Double, frequencies: [Double], pitchMultiplier: Double) -> Double {
        frequencies.reduce(0.0) { total, frequency in
            total + sin(2.0 * .pi * frequency * pitchMultiplier * time) / Double(frequencies.count)
        }
    }

    private func smoothEnvelope(_ progress: Double, attack: Double, release: Double) -> Double {
        let fadeIn = min(1.0, max(0.0, progress / attack))
        let fadeOut = min(1.0, max(0.0, (1.0 - progress) / (1.0 - release)))
        return fadeIn * fadeOut
    }

    private func pulseEnvelope(time: Double, start: Double, duration: Double) -> Double {
        let localTime = time - start
        guard localTime >= 0 && localTime <= duration else { return 0 }
        return sin(.pi * localTime / duration) * exp(-localTime * 0.45)
    }

    private func playHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.prepare()
            generator.impactOccurred()
        }
    }

    private func playNotificationHaptic() {
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        }
    }
}

