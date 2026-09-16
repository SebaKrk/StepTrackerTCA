//
//  View+DismissKeyboard.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 01/09/2026.
//

import SwiftUI
import UIKit

// Moved verbatim from SummaryView (second consumer: PR Board entry editor).

extension View {

    /// Dismisses the keyboard on a tap anywhere that is NOT a text input.
    /// SwiftUI exposes no keyboard-visibility Environment and numeric pads have
    /// no Return key, so this is backed by a window-level tap recognizer with
    /// `cancelsTouchesInView = false` — buttons and field-to-field focus keep
    /// working because the touch still passes through.
    func dismissesKeyboardOnBackgroundTap() -> some View {
        background(KeyboardDismissTapInstaller())
    }
}

private struct KeyboardDismissTapInstaller: UIViewRepresentable {

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let probe = UIView()
        probe.isUserInteractionEnabled = false
        let coordinator = context.coordinator
        // The probe isn't in a window yet at make-time — attach on the next turn.
        Task { @MainActor in
            guard let window = probe.window, coordinator.recognizer == nil else { return }
            let tap = UITapGestureRecognizer(
                target: coordinator,
                action: #selector(Coordinator.handleTap)
            )
            tap.cancelsTouchesInView = false
            tap.delegate = coordinator
            window.addGestureRecognizer(tap)
            coordinator.recognizer = tap
            coordinator.window = window
        }
        return probe
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        if let recognizer = coordinator.recognizer {
            coordinator.window?.removeGestureRecognizer(recognizer)
        }
    }

    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {

        weak var window: UIWindow?
        var recognizer: UITapGestureRecognizer?

        @objc func handleTap() {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
            )
        }

        // Ignore taps that land inside a text input so tapping between fields
        // moves focus instead of closing the keyboard.
        nonisolated func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldReceive touch: UITouch
        ) -> Bool {
            MainActor.assumeIsolated {
                var view = touch.view
                while let current = view {
                    if current is UITextField || current is UITextView { return false }
                    view = current.superview
                }
                return true
            }
        }
    }
}
