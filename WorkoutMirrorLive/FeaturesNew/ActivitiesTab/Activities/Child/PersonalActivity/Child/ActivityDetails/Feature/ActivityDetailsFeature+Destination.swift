//
//  Destination.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 04/01/2026.
//

import ComposableArchitecture

/// Implementation of `ActivityDetailsFeature` destination
extension ActivityDetailsFeature {

    @Reducer
    enum Destination {

        ///
        case metricDetail(MetricDetailFeature)

        /// Sheet do wyboru `TrainingSession` template'a — używany w manual-entry flow
        /// (escape hatch dla nieudanego `.saving → .summary` po treningu).
        case linkTemplate(TemplatePickerFeature)

        /// Pełnoekranowy SummaryFeature w manual-entry mode — po wyborze template'a user
        /// wpisuje wyniki / notatki tak jakby właśnie skończył trening (happy-path UI, identyczne save flow).
        case summary(SummaryFeature)
    }

}
