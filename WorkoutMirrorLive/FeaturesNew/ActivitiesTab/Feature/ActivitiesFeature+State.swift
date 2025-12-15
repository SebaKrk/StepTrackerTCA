import ComposableArchitecture
import SharedModels
import HealthKit
import HealthHub

/// Implementation of `ActivitiesFeature` state.
extension ActivitiesFeature {
    
    @ObservableState
    struct State {
        
        // MARK: - Properties
        
        /// Current view state (loading, success, or failed).
        var viewState: ViewState = .loading
        
        /// Selected tab context for filtering workouts.
        var context: TrainingTabContext = .personal
        
        /// List of fetched workouts from HealthKit.
        var workouts: [HKWorkout] = []
        
        /// Number of days to look back when fetching workouts.
        var days: Int = 28
        
        /// Current sort option for ordering workouts.
        var sortDescriptors: ActivitiesSortOption = .newestFirst
        
        // MARK: - Destination
        
        /// Presentation state for navigation destinations.
        @Presents var destination: Destination.State?
    }
    
}
