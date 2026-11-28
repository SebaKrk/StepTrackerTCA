//
//  DictationService.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 28/11/2026.
//

import AVFoundation
import os
import Speech

/// Live dictation: microphone through `AVAudioEngine` into `SpeechAnalyzer`; `finish()` ends it gracefully, cancelling the stream drops it.
actor DictationService {

    /// Logs audio session failures that must not end the dictation.
    private static let log = Logger(subsystem: "WorkoutMirrorLive", category: "Dictation")

    /// The open microphone's audio stream; finishing it lets the analyzer finalize the last words.
    private var microphoneInputs: AsyncThrowingStream<AnalyzerInput, any Error>.Continuation?

    /// Closes the microphone without dropping what is still being recognized.
    func finish() {
        microphoneInputs?.finish()
        microphoneInputs = nil
    }

    /// A fresh stream per call, so a cancelled effect and its restart never share an iterator.
    nonisolated func events(locale: Locale, hints: [String]) -> AsyncThrowingStream<DictationEvent, any Error> {
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: DictationEvent.self)
        let task = Task {
            do {
                try await self.run(locale: locale, hints: hints, continuation: continuation)
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
        continuation.onTermination = { _ in task.cancel() }
        return stream
    }

    // MARK: - Session

    private func run(
        locale: Locale,
        hints: [String],
        continuation: AsyncThrowingStream<DictationEvent, any Error>.Continuation
    ) async throws {
        guard await AVAudioApplication.requestRecordPermission() else {
            throw DictationError.microphoneDenied
        }

        let module: any SpeechModule
        let startReader: @Sendable () -> Task<Void, any Error>
        if let supported = await DictationTranscriber.supportedLocale(equivalentTo: locale) {
            let transcriber = DictationTranscriber(locale: supported, preset: .progressiveShortDictation)
            module = transcriber
            startReader = { Task { try await Self.relay(transcriber.results, text: \.text, to: continuation) } }
        } else if SpeechTranscriber.isAvailable, let supported = await SpeechTranscriber.supportedLocale(equivalentTo: locale) {
            let transcriber = SpeechTranscriber(locale: supported, preset: .progressiveTranscription)
            module = transcriber
            startReader = { Task { try await Self.relay(transcriber.results, text: \.text, to: continuation) } }
        } else {
            throw DictationError.unsupportedLocale
        }

        // The model must be installed before the format query, which answers nil until then.
        if let request = try await AssetInventory.assetInstallationRequest(supporting: [module]) {
            try await request.downloadAndInstall()
        }
        guard let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [module]) else {
            throw DictationError.modelUnavailable
        }

        let analyzer = SpeechAnalyzer(modules: [module])
        if !hints.isEmpty {
            let context = AnalysisContext()
            context.contextualStrings[.general] = hints
            try await analyzer.setContext(context)
        }
        try await analyzer.prepareToAnalyze(in: format)

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker])
        try audioSession.setActive(true)
        defer {
            do {
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                Self.log.error("Audio session deactivation failed: \(error)")
            }
        }

        let engine = AVAudioEngine()
        let (inputs, inputsContinuation) = try Self.startMicrophone(engine, convertingTo: format)
        microphoneInputs = inputsContinuation
        defer {
            inputsContinuation.finish()
            microphoneInputs = nil
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        continuation.yield(.listening)

        let reader = startReader()
        do {
            if let lastSample = try await analyzer.analyzeSequence(inputs) {
                try await analyzer.finalizeAndFinish(through: lastSample)
            } else {
                await analyzer.cancelAndFinishNow()
            }
            try await reader.value
        } catch {
            reader.cancel()
            await analyzer.cancelAndFinishNow()
            throw error
        }
    }

    // Final results are kept; a volatile one replaces the previous volatile one, or words would repeat.
    private static func relay<Results: AsyncSequence>(
        _ results: Results,
        text: (Results.Element) -> AttributedString,
        to continuation: AsyncThrowingStream<DictationEvent, any Error>.Continuation
    ) async throws where Results.Element: SpeechModuleResult, Results.Failure == any Error {
        var finalized = ""
        var volatile = ""
        for try await result in results {
            let piece = String(text(result).characters)
            if result.isFinal {
                finalized += piece
                volatile = ""
            } else {
                volatile = piece
            }
            continuation.yield(.transcript((finalized + volatile).trimmingCharacters(in: .whitespaces)))
        }
    }

    // MARK: - Microphone

    // Nonisolated on purpose: a tap closure formed in an isolated context traps on the audio thread under Swift 6.
    private nonisolated static func startMicrophone(
        _ engine: AVAudioEngine,
        convertingTo analyzerFormat: AVAudioFormat
    ) throws -> (AsyncThrowingStream<AnalyzerInput, any Error>, AsyncThrowingStream<AnalyzerInput, any Error>.Continuation) {
        let input = engine.inputNode
        let micFormat = input.outputFormat(forBus: 0)
        // A busy or missing microphone reports a zero rate, which would break the frame math below.
        guard micFormat.sampleRate > 0, micFormat.channelCount > 0 else {
            throw DictationError.audioConversionFailed
        }
        guard let converter = AVAudioConverter(from: micFormat, to: analyzerFormat) else {
            throw DictationError.audioConversionFailed
        }
        converter.primeMethod = .none
        let rateRatio = analyzerFormat.sampleRate / micFormat.sampleRate
        let (inputs, continuation) = AsyncThrowingStream.makeStream(of: AnalyzerInput.self)

        input.installTap(onBus: 0, bufferSize: AVAudioFrameCount(micFormat.sampleRate / 10), format: micFormat) { buffer, _ in
            let capacity = AVAudioFrameCount((Double(buffer.frameLength) * rateRatio).rounded(.up))
            guard let converted = AVAudioPCMBuffer(pcmFormat: analyzerFormat, frameCapacity: capacity) else {
                continuation.finish(throwing: DictationError.audioConversionFailed)
                return
            }
            var handedOver = false
            var error: NSError?
            let status = converter.convert(to: converted, error: &error) { _, inputStatus in
                if handedOver {
                    inputStatus.pointee = .noDataNow
                    return nil
                }
                handedOver = true
                inputStatus.pointee = .haveData
                return buffer
            }
            guard status != .error else {
                continuation.finish(throwing: DictationError.audioConversionFailed)
                return
            }
            if converted.frameLength > 0 {
                continuation.yield(AnalyzerInput(buffer: converted))
            }
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            input.removeTap(onBus: 0)
            throw error
        }
        return (inputs, continuation)
    }
}
