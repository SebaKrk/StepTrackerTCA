# TASKS


### IOS-00001 The Composable Architecture
    * A: Add TCA package dependency
    
### IOS-00002 Dependency Injection with Factory
    * A: Container-Based Dependency Factory Package
    
### IOS-00003 Basic UI and Features
    * A: Create basic `DashboardFeature`
        - remove ContentView
        - create basic DashboardView
    * B: Add initial DashboardView layout with mock data
        - create basic GroupBoxView for Walk and Calendar container
    * C: HealthMetricContext
        - Created HealthMetricContext to represent health metrics
        - Added a Picker in DashboardView to allow the user to switch between health metrics.
        - handle state and action in `DashboardFeature`
    * D: HealthDataListFeature
        - create `HealthDataListFeature`
        - add navigation/path
    * E: AddMetricDataFeature
        - create `AddMetricDataFeature`
        - add destination
        - create UI
        - handle basic validation
        - present Alert

### IOS-00004 HealthKit
    * A: Signing & Capabilities
        - add healthKit
        - add privacy description
    * B: HealthKitManager
        - create `DefaultHealthKitManager`
        - create container for application dependencies.
    * C: HealthKitPermissionFeatures
        - create Feature and view
    * D: UserDefaults
        - create `UserDefaultsServiceManager`
        - add DashboardFeatureService
        
### IOS-00005 HealthData
    * A: Get mock HealthData
    * B: Fetch HealthKit data
        - fetch steps data
        - steps charts basic UI
    * C: Step Bar Chart customizations
        - add chartXAxis and chartYAxis customizations
        - add chartXSelection &  RuleMark for selected x data chart

### IOS-00006 PieChart
    * A: Swift Algorithms
    * B: Average steps count calculation
        - create extension for weekdayInt 
        - calculate average health data per weekday
    * C: PieChart basic UI
        - create basic UI
        - pie chart interactivity
        - calculate total steps form 28 days

### IOS-00007 Tree-based navigation TCA
    * A: Create AppScreen
        - add appScreen 
    * B: create `AppTabFeature`
    * C: create `ActivityFeature` and `WorkoutFeature`
        - folder reorganizations
        - create two empty feature for test purposes
    * D: Connect new features to `AppTabFeature`
    * E: Navigation `ActivityFeature`
        - create `ActivityDetailsFeature`
        - add destination
        
### IOS-00008 AppTabContent
    * A: Add AppTabContent to handle NavigationSplitView for adaptive layout support.
    
### IOS-00009 Weight Chart
    * A: Weight chart basic UI
        - added a switch in DashboardView to dynamically display content based on the selected health metric i
        - implemented updateWeightChartData to handle the retrieval of weight-related data and update the state to display the processed information in the chart
        - chart basic UI
        - change unit to kilo
    * B: WeightChart Interactivity
    
### IOS-00010 WidgetFeature
    * A: New independent Features for each Chart 
        - create empty chart widget feature
    * B: WeightGoalWidget chart & feature
        - extract all necessary code to WeightGoalWidgetFeature
        - refactor destination
    * C: StepPieWidget chart & feature
        - extract all necessary code to StepPieWidgetFeature
    * D: StepWidget chart & feature. Dashboard Feature and View refactor
        - extract all necessary code to StepWidgetFeature
        - refactor Dashboard feature and view
        - remove path form DashboardFeature
        - add struct and create mock data
        - add Preview to all charts
    * E: Optimized Data Loading in Widgets
        - Introduced a state flag (isFirstAppearance) to ensure data is loaded only on the initial appearance of the view.

### IOS-00011 Weight Bar Chart UI & Feature
    * A: WeightBarWidget
        - WeightBarFeature    
        - WeightDiffBarChart

### IOS-00012 HealthDataListFeature
    * A: Displaying correct data passed to the list
    * B: Write Step & Weight Data to HealthKit 
    * C: Save and reload data
        - Add delegate enum to handle events related to `AddMetricDataFeature`.

### IOS-00013 Integrate Scope in `DashboardFeature` and UI optimization
    * A: Add scope and refreshable
        - add Refreshable to DashboardFeature
        - refactor StepPieWidgetFeature
        - refactor StepWidgetFeature
        - refactor WeightDiffWidgetFeature
        - refactor WeightGoalWidgetFeature
    * B: ChartGroupBoxHeader View
        - create new view and cleanup the code
    * C: ChartContent
        - WeightGoalWidgetView+ChartContent
        - WeightDiffWidget+ChartContent
        - StepWidget+ChartContent
        - StepPieWidget+ChartContent
        
### IOS-00014 Personal Records 
    * A: PersonDataFeature (parent)
    * B: WeightAndGoal
        - Change to `Records` tab
        - WeightGoalFeature
        - CurrentWightFeature
        - SetWeightGoalFeature
        - Basic navigation in WeightAndGoal
    * C: CurrentWeight
        - Pass the date through the feature to handle time-specific data.
        - Implement a service to manage weight goals effectively.
        - Design and develop the user interface.
    * D: WeightGoalView
        - Design and develop the user interface.
    * E: Refactor UI
        - Created reusable components for improved modularity and code maintainability.
    * F: Open permission screen
        - open permission screen when no data available in current weight widget

### IOS-00015 SwiftDataManager
    * A: Create SwiftData manager and add CurrentWeightEntity
        - create SwiftDataManager
        - add to Factory
        - create first model
    * B: Create RecordsRepository
        - Added `RecordsRepository` to handle data persistence and operations related to SwiftData.
        - Organized and cleaned up folder structure to improve project maintainability.
    * C: Integrate Save Action and Fetch 
        - Connect Save Action in SetWeightGoalFeature:
        - Update WeightGoalFeature to Fetch Latest Data
    * D: WeightGoalWidgetFeature
        - Add functionality to display user’s weight goal on the chart after setting it
        
### IOS-00016 HealthPermission Bug
        - Fixed the bug where the HealthPermission sheet was not appearing (introduced during refactoring).
        - Added a ContentUnavailableView with a button to fetch mock data.
### IOS-00017 View State
    * A: Refactored state and action logic in DashboardFeature using ViewState
        - add view state to first view `Dashboard Feature`
        - differentiate behavior for simulator and physical device after HealthKit authorization
        
### IOS-00018 WeightLiftingStats
    * A: WeightLiftingStats Feature
        - create basic WeightLiftingStatsFeature
    * B: Create basic container for UI and Navigation
        - organized files into appropriate folders
        - create new basic WeightLiftingGoalsFeature
        - navigate to empty WeightLiftingGoalsFeature
    * C: WeightLifting widget body content  
        - generate mock data for display in the view. 
    * D: CleanUp
        - extract dummy data generation to mock module
        - create empty repo for WeightLifting 
        - clean up WeightLiftingStats feature
    * E: WeightLiftingGoalsContent
        - small UI improvements
        
### IOS-00019 WeightLifting flow
    * A: SetEditGoalFeature 
        - implemented `SetEditGoalFeature` to manage the goal-setting flow for weightlifting exercises.
        - designed and built the user interface for setting and editing weightlifting goals.
        - improve navigation flow for deeper feature exploration
        - added button for recording training results 
    * B: Navigation in WeightLiftingGoalsView
        - Working on the navigation flow from WeightLiftingGoalsView to ExerciseDetailsFeature.
        - Refining state handling and deep-linking between views.
        - improve navigation flow
    * C: Views Presentation
        - work in progress on view presentation format
        - refining the structure and content of views
        - using hardcoded values as placeholders for now
        - add `AddMeasurementFeature` and assigned its execution to a button
    * D: AddMeasurementFeature UI
        - Added state properties for specific movement types: weightlifting, strength, fitness, cross, hero
        - create and connect all picker in AddMeasurementFeature
        - clean up the files
        - early validation of input fields 
        
### IOS-00020 CoreData
    - CleanUp SwiftData
    * A: CoreDataManager
        - Refactored all weight goal-related logic, including setting, updating, and displaying the goal, by centralizing data handling in SetWeightGoalService, standardizing state management in WeightGoalFeature, and optimizing view updates for consistency and scalability
        - Test some staf with core data in WorkoutFeature
    * B: Combine and CoreData

### IOS-00021 Obsidian app - create flow diagram
    - project files organization
    - add new FeatureDiagram file

### IOS-00022 CoreData Diagram
    A: CoreData - new entity
        - Renamed `CurrentWeightEntity` add new property
        - created core data diagram file
    B: CoreData diagram file
    C: Test save data with fake user
    
### IOS-00023 CRUD Workout functionality
    A: Data Preparation & Save Implementation
        - Prepare data for repository and implement save functionality  
        - A unified interface (MovementType) has been introduced for exercises, ensuring consistency across different workout types.
    B: Implement CRUD for GoalWorkout & WorkoutsLog
        - Implemented saving functionality for all workout types using Core Data
        - Ensured `MovementType` consistency across different workout entities
        - Refactored repository logic for improved data integrity
        - Validated and handled user existence before workout logging
        - Established correct relationships between `WorkoutsLogEntity` and workout entities

### IOS-00024 Read WorkoutType Data 
    A: WorkoutWeightlifting - fetchWeightLiftingStats
        - create WorkoutWeightlifting
        - read WorkoutWeightliftingEntity and map 
    B: StrengthSummary
        - StrengthSummaryFeature
        - workoutStrengthRepository
        - Groupiewng strength workouts by movement type (groupWorkoutsByMovement).
        - Sorting within groups by movement name (sortGroupedWorkouts).
        - Determining the best result based on the highest value (findBestWorkout).
        - Creating summary objects (MovementSummary) based on the best results and goal (createMovementSummary).
    C: Strength Scores
        - folder reorganizations
        - create StrengthScoreFeature
        - grouped workout data and display in container views
    D: Strength Info
        - Created MovementInfoFeature, implementing a common WorkoutMovementType interface based on MovementType, allowing support for various types of workouts.
        - This abstraction ensures modularity and reusability across different parts of the application, making it easier to extend and integrate with different workout types.
    E: MovementDetailsFeature
        - create details chart
        
### IOS-00025 Refactor for a shared interface
    A: Shared interface for summary workout
        - SummaryFeature
        - ScoresFeature
        - MovementInfoFeature
        - MovementDetailsFeature
    B: CleanUp
        - Remove StrengthScoreFeature
        - Remove StrengthSummaryFeature
        - Remove ExerciseDetailsFeature
        - Remove ExerciseInfoFeature
        - Remove WeightLiftingGoalsFeature
        - Remove WeightLiftingStatsFeature
    C: Project file organization
        - Project file organization
    D: Rename protocols
        - Rename protocols nad add dock
        - Remove MovementSummary
        - Remove WeightLiftingDisplayModel
        
### IOS-00026 Implementation SetEditGoalFeature
    A: SetEditGoalFeature
    B: Create costume symbol for add Target
    C: Validate the data in SetEditGoalFeature
    D: Save data
    E: Fetch Goal 
        - show in PersonDataFeature -> SummaryFeature
        - show in SummaryFeature -> ScoresFeature
        - show in chart in MovementDetailsFeature

### IOS-00027 TASKS file 

### IOS-00028 Add next Repository
    A: Create model/mapper/repository Fitness
    B: Create model/mapper/repository Cross
    C: Create model/mapper/repository Hero
    
### IOS-00029 Facade and Strategy
    A: Implement Facade and Strategy pattern in to SummaryFeature
    B: Implement Facade and Strategy pattern in to ScoresFeature

### IOS-00030 SubmitWorkout
    A: Create SubmitWorkout Feature
    B: Serwis - save new data to CoreData
    C: Refactor SetEditGoalFeature and SubmitWorkout
     - Initial setup: refactored workout submission using Strategy pattern with factory 
     - handling multiple submission methods based on service type
    D: WorkoutSubmission
    - Cleaning up the folder structure. 
    - Code organization into appropriate files.
    - Removed SetEditGoalFeature and SubmitWorkout features by merging them into a unified flow.
    
### IOS-00031 MovementHistory
    A: MovementHistoryFeature
     - create feature and view file
    B: NavigationDestination for MovementHistoryFeature
    - add destination
    - add createPointMark
    C: MovementHistory List 
    - Create List for movements

### IOS-00032 Activity
    A: create ActivityList 
    - create ext HKWorkoutActivityType, returns a user-friendly name for the workout activity
    - create property for real data form HK in ActivityFeature
    - create and fetch workout and HeatRate data from HK manager 
    - create HeartRateDetailsFeature
    B: HeartRateDetails 
    - create details
    - create service
    - create charts
    C: ChartXSelection
    D: HeartRate by minute list
    - tapHRMetrics
    
### IOS-00033 ActivityFeature
    A: Activity List Cell
    
### IOS-00034 Settings
    A: WorkoutScheduler - AuthorizationState

### IOS-00035 WorkoutPlaner
    A: WorkoutPlanerFeature
    - create basic feature 
    - testing WorkoutKit
    - adding costume workout to apple watch
    - testing WorkoutScheduler

### IOS-00036 WorkoutTab sandbox
    A: WorkoutFeature
    - create custom buttons
    - sandbox 
    B: WorkoutPlanerFeature
    - Create SingleWorkout
    C: WorkoutKitManager
    
### IOS-00037 MyFitnessJournal App Watch
    A: My Fitness Journal: Track heart rate & workout notes 
    - Add new target to app
    B: Splash screen
    C: WorkoutSessionFeature
    - create WorkoutSessionFeature
    - add tabs sessions
    - add NowPlayingView from WatchKit
    D: Workout flow
    - Working on workout flow
    - MainView
    - ControlsView
    - SummaryView
    E: WKAppBundleIdentifier
    - Add WKAppBundleIdentifier and WKApplication set to TRUE

### IOS-00038 Visualize the UI
    A: WorkoutSession with hardcoded data to visualize the UI
    - WorkoutMetricFeature
    - ElapsedTimeFeature
    B: SummaryView with hardcoded data
    - add SummaryMetricView
    C: ActivityRings
    - ActivityRingsView
    
### IOS-00039 Workout Manager
    A: Signing & Capabilities
    - add Background modes and HealtKit
    - Privacy - Health Share/Update Usage Description
    B: Authorization
    C: create WorkoutManager
    - create training flow
    - clean up folders
    D: SummaryView
    - display real data from workout session
    - extract elapsed time, calories, heart rate metrics
    - format summary UI using real values
    - add SummaryMetricView to show detailed stats
    - validate data received from WorkoutKit/HealthKit
    E: WorkoutType
    
### IOS-00040 ActivityRings  
    A: ActivityRings 

### IOS-00041 New Packages
    A: Add new packages to facilitate communication between the iOS and watchOS apps
    - create Commons
    - crate HealthHub
    B: Created a shared TrainingManager module 
    - create SharedModels
    C: TrainingManager @unchecked Sendable
    D: Starts mirroring the workout session to the companion iOS device.
    E: Rename iOS project name 
    - iOS - MyFitnessJournal
    
### IOS-00042 Prepare session
    A: CountDown functionality
    B: Clean up Dependency
    C: Mirroring workout view
    - WorkoutMirroringFeature and view
    - HeartRateZoneInfoFeature and view

### IOS-00043 Vision framework
    A: Implement camera 
    - testing 
