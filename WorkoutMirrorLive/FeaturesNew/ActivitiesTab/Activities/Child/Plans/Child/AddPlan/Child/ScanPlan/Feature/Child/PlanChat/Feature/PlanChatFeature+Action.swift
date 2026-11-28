//
//  PlanChatFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 27/11/2026.
//

import ComposableArchitecture
import HealthHub
import SharedModels

extension PlanChatFeature {

    @CasePathable
    enum Action: ViewAction, BindableAction {

        case binding(BindingAction<State>)
        case view(View)
        case `internal`(Internal)
        case delegate(Delegate)

        @CasePathable
        enum View {

            /// The user sent what they typed or dictated.
            case sendTapped

            /// The user accepted the corrected plan.
            case applyTapped

            /// The user closed the chat without applying anything.
            case closeTapped

            /// The message field got the keyboard.
            case inputFocused

            /// The user dragged the sheet to full or half height.
            case detentChanged(isExpanded: Bool)

            /// The user tapped the microphone to dictate instead of typing.
            case micTapped
        }

        enum Internal {

            /// The model answered the latest message.
            case replied(PlanRefinement)

            /// The latest message got no answer.
            case failed(ScanFailure)

            /// The dictation session reported progress.
            case dictationEvent(DictationEvent)

            /// The dictation session ended on its own.
            case dictationFinished

            /// The dictation session could not start or broke off.
            case dictationFailed(ScanFailure)

            /// The dictation ran for its maximum time or text length.
            case dictationTimedOut
        }

        enum Delegate {

            /// The corrected board the user applied; the parent rebuilds the plan from it.
            case applied(ScannedBoard)

            /// The chat closed with nothing applied.
            case closed
        }
    }
}
