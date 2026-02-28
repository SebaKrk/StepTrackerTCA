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
    B: Text Detection with Apple’s Vision Framework
    C: implement FoundationModels
    D: Testing / Sandbox with Vision
    E: Remove

### IOS-00044 AI Structure 
     A: Create AI workout parsing structures

 📷 Zdjęcie → 📝 OCR → 🤖 AI Cleanup → 🏗️ AI Structure → ✅ Plan treningowy


### IOS-00045 Workout Creator sheet
    A: Implement a screen to manually add workouts.
    B: Working on Creator
    C: ReUsed components
    D: Add Debug Workout and scheduledWorkouts
    
### IOS-00046 WorkoutMirrorLive
    A: Create new target - WorkoutMirrorLive
    - sandbox 
    B: Sandbox
### IOS-00046 WorkoutTab
    A: Bluetooth - sandbox
    B: BLE - fitness device scanning
    C: WatchConnectivity
    
### IOS-00048 PersonSettings
    A: Create PersonSettingsFeature
    B: PersonalDataManager
    - create PersonalDataManager
    - create HealthKitQueryBuilder
    C: HealthCalculations
    - create strategy for calculate HR Max 

### IOS-00048 StatsFeature
    A: Build some new chart container and features
    - create TrainingReadinessFeature
    - SleepScoreCalculator
    - HRVScoreCalculator
    - RestingHeartRateScoreCalculator
    - ActivityLoadScoreCalculator

### IOS-00049 ContentState
    A: ContentState for charts in GroupBox 
    B: @Shared state for premiumStatus
    C: HealthMetricSummaryCard
    D: Clean nad fix ContentState

### IOS-00050 StatTab
    A: RingActivitiesSummary
    B: iOS26 UI improvements 
    C: RingActivitiesSummaryFeature
    D: ReadinessLevelColor
    E: Pull to refresh data

### IOS-00051 Foundation Models
    A: Setup & Availability Check
    - Prompt
    - Stream
    B: ReadinessAnalysisFeature
    C: Framework Translation
    D: Refactor - AsyncStream
    E: Refactor - Actor and real data
    - DataAnalyzer
    - HealthDataTool -> TrainingReadinessMetricsTool
    
### IOS-00052 Translation
    A: Stream Translation

### IOS-00053 ActivityTab
    A: Create Activity Feature
    - create ActivityClient
    - create ActivityManager
    B: List&Cell
    C: Sort by and Date range 
    - add new case for WorkoutActivityType
    D: WorkoutZoneAnalyzer

### IOS-00054 Fix
### IOS-00055 Fix
### IOS-00056 Activity details card
    A: ActivityDetailsFeature
    - Cal, METs, Avg HR, Max HR, HR Zones details 
    B: WorkoutMetricsCalculator
    - create Metrics calculator for all activity details
    C: MetricDetail
    D: LocationSection
    
### IOS-00058 Translation
    A: Add new Localizable files
    
### IOS-00059 HealthMetricSummaryDetails
    A: Add new HealthMetricSummaryDetailsCardFeature
    B: UI
    
### IOS-00060 Bugs&Improvements
    A: StatsTab
    - HRV discrepancy 
    - Formatting
    - Dates
    - Activity discrepancy

### IOS-00061 LiveActivity
    A: New target - WorkoutSessionWidget
    B: WorkoutSessionLiveActivity
    C: Refactor
    D: Coordinator
    - create Coordinator for LiveActivity in Workout session 
    - add timer to  Workout session 
    E: TimerWidget
    F: TrainingReadinessWidget

### IOS-00062 TrainingReadinessWidget
    A: Deliver data for Widget
    B: NoData state
    C: HealthKit Background Delivery

### IOS-00063 Refactor Empty States & Refresh Logic for Stats Dashboard
    A: Refactor Empty States & Refresh Logic for Stats Dashboard

### IOS-00064 Plans
    A: Workout Plans Feature
    - create Workout Plans Feature
    - Refactor Activities Tab: Add Plans Sectione
    B: Refactor ActivitiesFeature
    - Extract workout logic from ActivitiesFeature into a separate PersonalActivityFeature.
    C: Improve OCR accuracy and modernize ScanPlan button styles
    D: Add WorkoutExtractionClient strategy pattern for device-based extraction pipeline
    - Replace ScanPlanClient with WorkoutExtractionClient
    - Runtime strategy selection: on-device (OCR+FM) vs cloud (Claude API)
    - Add FoundationModelAvailability check in HealthHub
    - Add ClaudeAPIService skeleton in HealthHub
    E: Foundation models availability check

### IOS-00065 Foundation
    A: Add Foundation Models workout parsing
    B: Migrate TrainingSession and workout types to SharedModels
    C: Fix workout parsing accuracy - extract ONLY what's in OCR text
    D: ExtractedWorkout+Mapper
    E: Training Session Preview Integration

### IOS-00066 Claude api
    A: WorkoutParsingStrategy protocol
    - Define protocol for workout parsing strategies
    B: Add parsing strategy architecture
    C: Integrate strategies with TCA
    - Replace WorkoutParsingService with WorkoutParsingClient
    - Use @Dependency in WorkoutExtractionClient
    D: Implement Claude API HTTP client
    - ClaudePrompt with system/user prompts + JSON schema
    - ClaudeAPIStrategy HTTP implementation
    - API key from environment (ANTHROPIC_API_KEY)
    - Error handling (network, API, JSON decoding)
    E: Improve Claude parsing and add structured sets model   
    F: Refactor Claude API implementation                    
    - Split into separate files (strategy, models, errors)
    - Fix code review issues (force unwraps, race conditions)  
    G: Clean up model duplication and reorganize folder structure
    -  Remove ClaudeWorkoutResponse duplication
    -  Organize WorkoutParsingService folder structure
    
### IOS-00066 Plans
    A: Plans lists 
    B: PlanDetailView
    C: Key
    D: Settings

### IOS-00068 TrainingSessionEditorFeature
    A: TrainingSessionEditorFeature scaffold + metadata form
    - TrainingSessionEditorFeature (Reducer + State + Action + delegate)
    - TrainingSessionEditorView (Form: title, date, activity, location + placeholder sections)
    - AddPlanFeature: manualEntryTapped → editor, dismiss on save
    B: Warmup + Cooldown editing
    C: WOD editing
    -  add WorkoutSessionEditor
    D: ExercisePicker and ExerciseEditor
    E: Edit action to PlanDetailView  
    F: Edit action to WorkoutPreviewView
    G: Disable Save button when draft has no changes
    H: Refactor save flow and simplify exercise data model
    I: Add and remove workout or exercise
    J: Refactor/navigation
    
### IOS-00068 AI warmup/cooldown generation
    A: AI warmup/cooldown generation
    B: Refactor/unify-claude-strategy
