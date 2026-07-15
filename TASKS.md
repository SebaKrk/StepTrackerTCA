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
    
### IOS-00069 AI warmup/cooldown generation
    A: AI warmup/cooldown generation
    B: Refactor/unify-claude-strategy
    
### IOS-00070 Planned Workout Session
    A: WorkoutPlanScore and WorkoutSessionResult models
    B: WorkoutPlanScoreClient with temporary JSON stub
    C: Pass trainingSession from SessionFeature to SummaryFeature
    D: Workout Summary Screen
    E: PlanDetail — workout history & session entry point
    F: WOD Results section in ActivityDetailsView
    G: LiveSession with Plan
    H: Fix Keyboard and backgound

### IOS-00071 SQLiteData Architecture — UserProfile storage
    A: AppDatabase Swift Package setup
    - UserProfile domain model w SharedModels (Identifiable, Equatable, Codable, Sendable)
    - Nowy lokalny pakiet AppDatabase (obok SharedModels/Commons/HealthHub)
    - CloudKitSyncable protocol (createdAt, updatedAt, ckRecordData) — furtka iCloud
    - UserProfileRecord (@Table, flat columns, mapowanie do/z UserProfile)
    - Schema.swift (bootstrapDatabase() + DatabaseMigrator + v1_userProfile migration)
    - AppDatabase dodany jako dependency do targetu WorkoutMirrorLive
    B: UserProfile domain model + Record
    - UserProfile w SharedModels (Identifiable, Equatable, Codable, Sendable)
    - UserProfileRecord w AppDatabase (@Table, mapowanie do/z UserProfile)
    C: UserProfile feature
    - bootstrapDatabase() w WorkoutMirrorLiveApp.init()
    - UserProfileClient (save/fetch przez defaultDatabase)
    - PersonSettingsFeature: ładowanie profilu, editProfileTapped
    - PersonProfileEditFeature + PersonProfileEditView (modal edycji)
    - PersonSettingsView: wyświetlenie danych + sheet do edycji
    D: Previews
    - #Preview dla PersonSettingsView z bootstrapDatabase + seed data
    - #Preview dla PersonProfileEditView z bootstrapDatabase + seed data

### IOS-00072 Training plans and session results persistence (SQLiteData)
    A: Records in AppDatabase
    - TrainingSessionRecord (@Table, hybrid: flat scalars + nested structures as JSON BLOB)
    - WorkoutPlanScoreRecord (@Table, resultsData as JSON BLOB)
    - Migrations v3_trainingSession + v4_workoutPlanScore in Schema.swift
    B: TrainingSessionClient
    - save / fetchAll / delete via defaultDatabase
    C: WorkoutPlanScoreClient — replace JSON storage with SQLite
    - Remove WorkoutPlanScoreStore (JSON actor)
    - liveValue via defaultDatabase on WorkoutPlanScoreRecord
    D: PlansFeature — load/save from SQLite
    - Replace @Shared(.inMemory) with TrainingSessionClient
    - fetchAll on viewDidAppear, save on delegate(.saved), delete
    E: SummaryFeature — save WorkoutPlanScore on End Workout
    - Build WorkoutPlanScore from resultInputs + trainingSession + hkWorkoutId
    - workoutPlanScoreClient.save() before dismiss()

### IOS-00073 Watch App HR Sensor Mirror
    - branch: `feature/IOS-00073`
    - plan: `PLANS/IOS-00073-Watch-HR-Sensor-Mirror.md`
    
    A: feat(SharedModels): add WatchWorkoutEvent codable enum
    B: feat(HealthHub): extend WatchConnectivityManager with bidirectional event stream
    C: feat(watch): add HRQueryClient for HealthKit HR reading without workout session
    D: feat(watch): add WatchConnectivityClientAW dependency
    E: feat(ios): extend WatchConnectivityClient with workout event send/receive
    F: feat(ios): trigger and receive watch events in WorkoutMirroringFeature
    G: feat(watch): add HRMirrorFeature and HRMirrorView
    H: feat(watch): wire HRMirrorFeature into MainFeatureAW navigation

### IOS-00075 iPhone-primary workout session architecture (WWDC25)
    - branch: feature/IOS-00075
    - plan: PLANS/IOS-00075-Workout-Session-Architecture-Refactor.md

    A: refactor(HealthHub): remove isWatchPrimary flag — iPhone always calls finishWorkout()
    B: feat(HealthHub): add addHeartRateSample — Watch HR injected into iPhone's HKLiveWorkoutBuilder
    C: fix(HealthHub): reset metrics and workoutSessionIsRunning in prepareWorkout
    D: feat(ios): add addHeartRateSample to SessionClient, remove setWatchPrimary
    E: feat(ios): forward Watch HR to HKLiveWorkoutBuilder in SessionFeature
    F: fix(ios): add sessionStateStream cancel ID — no more duplicate effects on second run
    G: fix(watch): discard instead of finish — iPhone is the canonical HKWorkout owner
    H: fix(watch): session.end() moved outside do/catch — always called regardless of endCollection result
    I: fix(HealthHub): incomingWorkoutEventStream creates a new stream per subscription — second workout now receives HR from Watch
    J: fix(watch): guard against forwarding tick/pause/resume to nil hrMirror destination

### IOS-00076 Small Fixes   
    - Watch scanning overlay
    - HR zone % 
    - SummaryView metric card layout

### IOS-00077 Workout deletion & activity improvements
  - Swipe-to-delete in activities list (TCA AlertState pattern)                                                        
  - Discard workout button in SummaryView
  - HealthKit deletion error handling (errorAlert)
  - Pull-to-refresh in activities list          
  - SummaryFeature split into separate files                        
  - Localization fixes

### IOS-00079 Watch-primary + HealthKit mirroring architecture
    - branch: `feature/IOS-00079-watch-primary-mirroring`

    A: feat(watch): WatchAppDelegate + WorkoutConfigurationStream — Watch auto-launch
        - WKApplicationDelegate.handle(_:) forwards HKWorkoutConfiguration to TCA via singleton AsyncStream
        - @WKApplicationDelegateAdaptor in WorkoutMirrorApp
        - Watch app comes to foreground automatically when iPhone calls startWatchApp(toHandle:)
    B: feat(watch): WatchWorkoutSessionClient — Watch-primary HKWorkoutSession
        - Watch owns HKWorkoutSession + HKLiveWorkoutBuilder
        - startMirroringToCompanionDevice() → iPhone receives mirrored session via workoutSessionMirroringStartHandler
        - HR forwarded to iPhone via sendToRemoteWorkoutSession (HealthKit channel, not WatchConnectivity)
        - sessionStateStream: AsyncStream<HKWorkoutSessionState> for pause/resume sync
        - stopActivityAndWait: withCheckedContinuation awaits delegate .stopped before endCollection
        - workoutFinished flag guards against double-save (race between end() and .ended safety-net)
    C: feat(watch): HRMirrorFeature — session lifecycle + pause sync
        - sessionStateChanged action syncs isPaused when iPhone initiates pause via mirrored session
        - view(.pauseResumeTapped) manages subSecondTimer directly (restart on resume, cancel on pause)
          — prevents timer stall when Watch initiates resume (isPaused already cleared before delegate fires)
        - sessionStateStream cancellable added to .start / .stop
    D: feat(ios): AppFeatureAW — dual-path workout start
        - workoutConfigurationReceived: starts HRMirrorFeature before WC event arrives (auto-launch path)
        - workoutStarted: falls back to WC path if Watch app was already running
    E: fix(HealthHub): WCSession activation race condition
        - initializeWatchConnectivity() suspends via withCheckedContinuation until activationDidCompleteWith fires
        - checkWatchStatus() now always reads correct isPaired value
    F: fix(ios): double endWorkout() crash in iPhone-standalone mode
        - ControlsFeature.endWorkoutButtonTapped returns .none — SessionFeature owns the full end sequence
    G: fix(ios): CountDownClient routed through WorkoutModeRouter
        - CountDownClient previously called DefaultWorkoutManager.startWorkout() directly
        - In Watch-primary mode this failed (no iPhone session prepared)
        - SessionClient.startWorkout added, routed as no-op in watchPrimary / real call in iPhoneStandalone
    H: refactor: strategic log cleanup
        - Removed high-frequency prints (workoutTick, HR metrics — fired every 100ms–1s)
        - Unified prefix format: [WatchSession], [WC], [AppFeatureAW], [HRMirrorFeature], [TrainingManager], [SessionFeature]
        - Added targeted logs for critical bugs: workoutFinished flag, stopActivityAndWait, sessionStateChanged, pause sync

### IOS-00080 OSLog unified logging
    - branch: `feature/IOS-00080-oslog-unified-logging`

    A: feat(SharedModels): AppLogger — centralized Logger instances
        - AppLogger.swift w SharedModels/Sources/SharedModels/Logging/
        - subsystem: com.ss.WorkoutMirror (filtrowanie w Console.app)
        - 6 kategorii: watchSession, hrMirror, appAW (Watch) + session, trainingManager, wc (iPhone/Shared)
        - dostępny na iOS 18 + watchOS 11 — oba targety przez jeden plik
    B: refactor(watch): replace print() → Logger w Watch targets
        - WatchWorkoutSessionClient: Logger.watchSession (.info lifecycle, .error failures, .debug simulator)
        - HRMirrorFeature: Logger.hrMirror (.info sessionStateChanged, .debug already-running guard)
        - AppFeatureAW: Logger.appAW (.info workoutConfiguration/workoutStarted/workoutEnded/dismiss)
    C: refactor(ios): replace print() → Logger w iPhone targets
        - SessionFeature: Logger.session (.info viewDidAppear/mode/startWatchWorkout, .error fallback, .notice hrTimeout)
        - SessionClient/WorkoutModeRouter: Logger.session (.info mode-switch, endWorkout/startWorkout no-op)
        - DefaultTrainingManager+iOS: Logger.trainingManager (.info mirrored-session/startWatchApp, .error queries)
        - TrainingSessionStateControl: Logger.trainingManager (.info pause/resume/end, .notice no-session guards)
    D: refactor(healthhub): replace print() → Logger w WatchConnectivity
        - DefaultWatchConnectivityManager: Logger.wc (.info activation/stop, .error not-activated, .notice transferUserInfo fallback)
        - WatchConnectivity+Delegate: Logger.wc (.info activated/reachability/events, .error decode-fail)
        - workoutTick pomijany na obu stronach (send + decode guard) — brak szumu co sekundę

### IOS-00081 Analytics Tab — chart animations & refactor
        A: Chart drawing animations (mask left-to-right for lines, bottom-to-top for bars)
        B: TCA Result pattern refactor — 1 send per .run in all 4 reducers
        C: File split (Feature + State + Action + Model) + HKWorkoutActivityType.color to SharedModels
        D: Selection dimming + annotation popup (StepWidget/RHR detail pattern)
        E: Fix scroll jump and flicker on metric switch
        F: Fix force-unwrap + stale selectedDataPoint on refresh
    
### IOS-00082 Workout Session — landscape redesign & Liquid Glass                                                                
      - Fullscreen landscape layout z GeometryReader (75/25)    
      - iOS 26 .glassEffect() na kartach metrycznych                                                                               
      - Gradient strefy HR z czarnym tłem na dole   
      - Dark mode wymuszony podczas sesji                                                                                          
      - Fix pause/play — poprawna kolejność startWorkout() / .closeView
      - Live Activity lock screen — dwukolumnowy layout z glass   

### IOS-0083 Exercise-Analytics-plan

### IOS-00084 Summary & Activity Details — per-set tracking                   
      A: Per-set input end-to-end                                             
        - per-set table (Set | Reps | kg) in Summary for strength/olympic     
        - per-set table in Activity Details (read-back from DB)               
        - score (max weight) derived from set entries                       
      B: Persistence                                                          
        - new column `setsData` BLOB (JSON-encoded [SetEntry])
        - new column `workoutSessionResultId` UUID (disambiguates multiple WODs of the same wodName)                   
        - fix Draft init in `ExerciseLogClient.save` (was silently dropping setsData)                                                                     
        - fix `ExerciseSessionDraft.init(exercise:)` — carry over plannedSets 
        - fix `mergeUpdatedInputs` — carry over sets + derive actualWeight/Reps                                                             
      C: AI parsing                                                         
        - bench press aliases extended (close-grip, wide-grip, incline, decline, DB / dumbbell variants)                                    
        - negative example in ClaudePrompt for Back Squat + Rest pattern(probabilistic fix, not deterministic)                              
        - `parsedDescription` parser handles bare "Scaling:" prefix (was only catching "Info: Scaling:")                                
        - re-parser info → plannedSets in ExerciseEditor save (so user typing "5x5 @80" in Notes generates 5 input rows)          
        - extractWeightKg regex extended — accepts "@80" without "kg"
      D: UI polish                                                            
        - hide actual-values table when WOD is fully untouched
        - drop duplicate exercise name in single-exercise table               
        - Edit + Info buttons trailing-aligned, shared `.bordered` style      
        - info menu shows edit window deadline                                
      E: Commons                                                              
        - `DateTimeFormatter.mediumDateShortTime` (reused by info menu)     
      F: Docs                                                                 
        - `ExerciseLog` full property documentation                           
        - `ClaudeWorkoutMapper` diagnostic prints (RAW / CLEANED / DECODED) 

### IOS-00085 Watch session recovery & standalone end
    - Recovery dialog przy starcie Watch app gdy zostanie stuck workout session
    - Standalone Stop button na Watch (long-press 1.5s + haptic)
    - iPhone automatycznie przechodzi do summary po Watch-initiated end
    - 5 nowych kluczy lokalizacji (EN/PL)

### IOS-00086 Stats — improve refresh UX across all cards

### IPad-0087 Gym Room — iPhone join flow with synthetic HR for PoC
    A: iPad target enabled + Bonjour/local network config + GymRoomView scaffold
    B: PeerMirrorClient + Service — MultipeerConnectivity transport with host/peer separation
    C: GymRoomFeature + live grid view with AthleteTile components
    D: JoinLiveClassFeature — iPhone discovery + synthetic HR forward (real Watch HR moved to IPAD-0099)
    E: UI polish & Polish translations — Liquid Glass, View Facade refactor, adaptive grid, real user profile fetch

### IOS-00088 Workout iOS 26 Hybrid Architecture
    A: WorkoutSession foundation — iPhone-primary tor + Apple Fitness-style startup
    B: TrainingSessionStateControl — AsyncSequence end-flow instead of polling 
    C: SessionFeature/Watch — HK channel for .workoutEnded in Watch-primary mode
    D: LiveActivity — Liquid Glass on Activity Lock Screen card
    E: CleanUp
    
### IOS-00089 WWDC25 compliance gaps
     A: Crash recovery for iPhone-standalone  
     B: CountdownStart over HK channel   
     C: WorkoutTick over HKchannel (with measurement spike) 

### IOS-00090 AI-driven workout type classification
    - branch: `dev/IOS-00090/IOS-00090`

    A: Extend Claude prompt with workoutType classification
    B: Add workoutType to ExtractedWorkout with decoder fallback
    C: Propagate classified type via mapper to TrainingSession
    D: Dynamic icon in Start Workout button
    E: Workout type header in CountDown view

### IOS-00091 Workout sync watchPrimary race condition fix
    - branch: `dev/IOS-00091/IOS-00091`

    A: Reset workoutFinished flag on save failure (safety-net recovery)
    B: Add workoutUUID payload to .workoutSaved event
    C: Historical HK fetch before anchored observer in handleWorkoutEndIOS
    D: Direct HK fetch fallback in getWorkoutSummary (watchPrimary)
    E: TASKS.md + memory note documentation

### IOS-00093 Finalize iPhone-standalone integration
    - branch: `dev/IOS-00093/IOS-00093`

    A: Stopwatch — `elapsedTimeAt` reads `elapsedTracker` (both modes, replaces nil legacy `manager.builder`)
    B: HK conflict — drop legacy `manager.setSelectedWorkout` to avoid parallel HKWorkoutSession (code=8 "Another session is starting")
    C: Summary — actor cache in WorkoutModeRouter subscribes `iPhoneSession.workout` + `metrics` streams for sync getWorkoutSummary
    D: Gym Room HR — JoinLiveClass routes through `SessionClient.workoutMetricsStream()` (per-mode DI replaces direct `trainingManager`)
    E: Cleanup — explicit `.countdown` send in iPhone-standalone main, remove diagnostic logs, fix `unreachable` typo, legacy warning block over `@Dependency(\.workoutManager)`

### IOS-00094 Cleanup legacy WorkoutManager + iOS 26 deployment uplift
    - branch: `dev/IOS-00094/IOS-00094`

    A: Remove @available(iOS 26.0, *) guards (iPhone session + router)
    B: Replace legacy workoutManager fallbacks with iPhoneSession-driven flow
    C: Remove dead Watch-as-HR-sensor flow (3-target synchronized: iPhone + Watch + HealthHub)
    D: Remove @Dependency(\.workoutManager) + LEGACY warning block
    E: Remove orphan Features/+AppTab/ + raise deployment to iOS 26 (Package.swift × 4 uplift, @available cleanup)
    G: Remove legacy WorkoutManager (HealthHub WorkoutManager/ folder + Manager+iOS/ folder + Dependencies+Key cleanup + stale comments///)
    I: fix PeerMirror peerEventsStream multicast (view re-mount lost events)

### IPAD-00088 GymRoom modularization — PeerMirror package + GymRoomDisplay target
    - branch: `dev/IPAD-00088/IPAD-00088`

    A: PeerMirror package extraction 
    - create standalone package from HealthHub, organize BLE delegates, fix Swift 6 races 
    B: GymRoom standalone iPad app target
    - fix Info.plist multiple-commands conflict (synchronized folder membership exception), wire OSLog import for Logger.gymRoom, BLE permission descriptions in Info.plist
    C: PeerMirror samplesStream multicast
    - replace stored single-stream with [UUID: Continuation] registry + broadcastSample helper (mirrors peerEvents fix from IOS-00094-I), prevents HR sample loss after SwiftUI view re-mount

### IPAD-00089 Peer identity + QR access control + reconnect grace
    - branch: `dev/IPAD-00089/IPAD-00089`

    A: Stable peer deviceID foundation
    - rename HRSamplePayload.userID → deviceID, JoinLiveClassFeature+State userIDString → deviceIDString (AppStorage key joinLiveClassUserID → joinLiveClassDeviceID), drop dead UUID fallback, add computed var deviceID: UUID — surrogate key ready for host indexing in subtask B
    B: Host indexes by deviceID
    - PeerEvent reshaped (.connected(deviceID:nick:), .disconnected(deviceID:)), PeerMirrorBLEHostSession: connectedCentrals keyed by deviceID + centralToDevice reverse lookup map + PeerInfo struct, AthleteTile.id: UUID + nick: String, PeerMirrorBLEPeerSession emit sites updated (4 call sites use peripheral.identifier as deviceID since peer ignores payload). Reconnect detection + nick collision fixed.
        
    - QRSessionPayload Codable (token/iPadID/gymName/createdAt) in SharedModels, QRCodeView with CIFilter.qrCodeGenerator + .interpolation(.none) + static CIContext + CGImage Image(decorative:) (no UIKit), State adds @Shared iPadIDString + sessionToken UUID? + gymName + isQRVisible, GymRoomFeature: startTapped generates UUID(), endTapped nils it, toggleQR flips visibility, GymRoomView corner overlay with qrCard/qrToggleButton + JSON payload encoder (ISO-8601 dates).
    C2: iPhone QR scanner + camera permission
    - QRScannerView (UIViewControllerRepresentable) + ScannerViewController (AVCaptureSession + AVCaptureMetadataOutput .qr + AVCaptureVideoPreviewLayer), lazy camera permission request (pre-check authorizationStatus, requestAccess only on notDetermined, log on denied/restricted), startRunning on background queue (avoid 200ms main thread block), stopRunning on viewWillDisappear (battery + red indicator). One-shot scan: first detection stops session and fires onScanned callback. NSCameraUsageDescription added to WorkoutMirrorLive/Info.plist. Standalone — not integrated with JoinLiveClassFeature (deferred to C3).
    C3: Handshake with sessionToken + reject logic
    - HRSamplePayload +sessionToken: UUID, PeerMirrorClient.startAdvertising signature (displayName, sessionToken) async, PeerMirrorService.startAdvertising(displayName:sessionToken:), PeerMirrorBLEHostSession init param currentSessionToken + didReceiveWrite guard payload.sessionToken == currentSessionToken (mismatch = warning log + skip onSample + no .connected emit), GymRoomFeature passes state.sessionToken in startAdvertising call. JoinLiveClassFeature: scannedQRPayload + isShowingScanner state (ephemeral, reset on leave), view(.qrScanned(jsonString:)) decodes JSON + closes scanner + starts BLE handshake, view(.scannerDismissed) handles swipe-down cancel, peerConnected uses scannedQRPayload.token in HRSamplePayload (guard against missing token). JoinLiveClassView: original idle (icon + Join button) restored, .fullScreenCover binding to isShowingScanner shows QRScannerView with close button — tap Join opens scanner, scan auto-triggers join (sam akt scanowania = wybór klasy).
    D: Reconnect grace period (2 min)
    - PeerEvent +.suspended(deviceID:nick:) + .reconnected(deviceID:nick:), PeerMirrorBLEHostSession emits .suspended in didUnsubscribeFrom (not .disconnected), PeerMirrorService disconnectingPeers buffer [UUID: Task] + broadcastPeerEvent orchestration: .connected with pending timer → cancel + emit .reconnected, .suspended → forward + startGraceTimer(120s — covers toilet/water break), .disconnected → cancel pending timer + forward, stopAdvertising cancels all timers + emits .disconnected for each pending peer (cleanup). AthleteTile.state: TileState enum (.live/.reconnecting), GymRoomFeature actions peerSuspended/peerReconnected/peerDisconnected handle 3 lifecycle phases. AthleteTileView .saturation(0.3) + black 30% overlay with ProgressView spinner when .reconnecting. JoinLiveClassFeature peer-side ignores .suspended (own retry backoff exists), maps .reconnected → .peerConnected.
    E: PL localization sweep for IPAD-00089 strings
    F: Graceful disconnect via endOfClass payload
    - HRSamplePayload +endOfClass: Bool = false (default for normal HR updates, true for goodbye). JoinLiveClassFeature sends goodbye payload in two paths: .leaveTapped (explicit user exit — 300ms delay before stopBrowsing so BLE write lands) + after workoutMetricsStream natural termination (HK workout end e.g. Watch end-of-class). PeerMirrorBLEHostSession.didReceiveWrite checks payload.endOfClass FIRST: graceful = remove peer immediately + emit .disconnected (skip .suspended + 2min grace period). UX: Leave button on iPhone or Watch end-of-workout now removes tile instantly from iPad instead of leaving 2min reconnecting spinner. Out-of-range disconnect (no goodbye sent) still triggers grace period as designed.

    G: iPad END Class confirm dialog
    - TCA AlertState pattern: GymRoomFeature.State +@Presents var alert: AlertState<Action.Alert>?, Action +case alert(PresentationAction<Alert>) + nested Alert.confirmEnd enum. View(.endTapped) presents alert (title "End class?", message "All athletes will be disconnected.", destructive "End" + cancel "Cancel"). alert(.presented(.confirmEnd)) runs original end logic (stopAdvertising + clear state). GymRoomView .alert($store.scope(state: \.alert, action: \.alert)) modifier. Reducer body chained with .ifLet(\.$alert, action: \.alert) for presentation lifecycle. Prevents accidental tap mid-class breaking the whole session.

    H: Bi-directional class lifecycle (host→peer broadcast + peer self-reset)
    - PeerEvent +case classEnded. PeerMirrorBLEHostSession.stop() calls broadcastClassEnded() FIRST — peripheralManager.updateValue(Data([0xFF]), for: hrCharacteristic, onSubscribedCentrals: nil) (BLE notify broadcast). PeerMirrorBLEPeerSession+CBPeripheralDelegate.didUpdateValueFor detects sentinel byte (1 byte = 0xFF) on hrCharacteristic → emits PeerEvent.classEnded. PeerMirrorService.broadcastPeerEvent handles .classEnded: cancel all pending grace timers + forward to consumers. JoinLiveClassFeature: peerEventsStream switch routes .classEnded → .classEndedReceived action. Post-loop in peerConnected effect emits .workoutEnded action (after sending goodbye payload). Both .classEndedReceived AND .workoutEnded share body: phase=.idle + scannedQRPayload=nil + isShowingScanner=false + stopBrowsing + delegate.didLeave (toolbar icon disappears). GymRoomFeature peerEventsStream switch adds .classEnded → break (host-side no-op, iPad already knows it's ending). Solves two symmetric problems: (1) iPad END → iPhone immediately resets (was stuck in .searching), (2) Watch end workout → iPhone immediately resets (was stuck in .connected requiring manual Leave).

### IPAD-00090 GymRoom class management space (history + creation)
    - branch: `dev/IPAD-00090/IPAD-00090`

    A: GymRoom UI refactor — NavigationSplitView + 2 sidebar (Classes / History)
    B: Database schema — 3 tables (gymClassRecords, classSessionRecords, athleteSessionRecords) + 4 indexes + migration v7_gymRoom
    C: LiveClass persistence — GymClassClient (8 closures) + bootstrap database + HR buffer + 30s timer flush + endAthlete with analytics. Plus endSession cancellation fix (race condition w confirmEnd — `delegate.classEnded` emit'owany w środku `.run` po `await endSession()`).
    D: ClassHistory list — reverse-chrono z empty state + date labels (Today/Yesterday/d MMM) + duration formatter ("Xh Ym" / "Xm Ys" / "Ongoing").
    E: ClassHistoryDetail charts 
    - top stats banner (athletes count + duration + total kcal + avg HR) + HR over time toggle (Per athlete cards / Combined multi-series) + Calories bar chart (sorted desc). Pie chart "Time in zones" removed per user UX decision — data still computed w ClassAnalytics dla future use.
    - ClassCreation sheet — TextField name + location, hasSchedule + DatePicker, maxParticipants Stepper z BLECapacityClient device-aware default (iPad Pro M-series = 16, Air = 12, etc.) + inline error gdy exceeds device limit.
    -  UI poprawki ClassCreation — `@FocusState` + `simultaneousGesture(TapGesture)` (tap-outside dismisses klawiaturę) + keyboard toolbar "Done" + `submitLabel(.next)` / `.done` flow + `.interactiveDismissDisabled()` (sheet zostaje aż explicit Cancel/Save).
    F: Final cleanup + cascade delete
    - PL localization sweep
    - Cascade delete template'a (kasuje też powiązane sesje + athlete records) z alert confirmation
    G: ClassDetail actions menu
     - ellipsis toolbar z Edit (prefilled sheet, upsert) + Delete (cascade z alert confirmation). Reuse ClassCreationFeature dla edit mode.
    H: Delete z History 
    - swipe-to-delete sesji w ClassHistoryView + ellipsis menu w ClassHistoryDetailView (na razie 1 akcja Delete, ready na Share/Export future). Oba z alert confirm. Cascade kasuje athleteSessionRecords + classSessionRecord (template nietknięty). Bez Edit — sesje są historical fact, immutable.

### IPAD-00091 Team and athlete card
    - Per-athlete HR chart
    - Layout athlete card
    - Insufficient data placeholders
    - Preview infrastructure

### IPAD-00092 Peer connection robustness & diagnostics
    - branch: `dev/IPAD-00092/IPAD-00092`

    A: BLE peer resume on reconnect — `findAthlete` + `resumeAthlete` w GymClassClient. Jeden athleteSessionRecord per (sessionId, deviceID) niezależnie od liczby disconnect/reconnect w trakcie zajęć.
    B: Lazy athlete creation — bez fake placeholder maxHR=190. LiveClassFeature tworzy DB record dopiero przy pierwszym realnym samplu (z payload.maxHR).
    C: TileState.loading + UI overlay — ProgressView + "Łączenie…" w AthleteTileView do czasu odebrania pierwszego sample (informuje że peer connected ale jeszcze nie ma HR).
    D: GymRoomFileLogger — actor singleton, plik `ipad_gymroom_log_<timestamp>.txt` per sesja, eksport do Files.app (UIFileSharingEnabled + LSSupportsOpeningDocumentsInPlace w Info.plist). Logi: join/handshake/resume/suspend/reconnect/leave/end.
    E: Force-end ongoing sessions z History — swipe action "Zakończ zajęcia" gdy `endedAt == nil` (workaround dla sesji których iPad nie zamknął cleanly). + ViewState (.loading/.success/.failed) dla ClassesList i ClassHistory.
    F: Charts polish — combined chart Y-axis `includesZero: false` (tighter range), per-athlete insufficient data placeholders (5-min threshold) z różnymi SF Symbols per chart type.

### IOS-00095 Workout post-mortem — manual link plan & enter results
    - branch: `dev/IOS-00095/IOS-00095`

    Escape hatch z History dla scenariusza gdy live `.saving → .summary` flow zawiódł (np. WC reachability=false po endWorkout). User otwiera workout z History i ręcznie podpina plan + wpisuje wyniki — identyczne zachowanie jak happy path (ten sam `SummaryFeature`, te same writes do `WorkoutPlanScoreRecord` + `ExerciseLogRecord`). Brak nowej migration — model już ma `WorkoutSessionResult.note` (per-WOD) i `ExerciseLog.note` (per-exercise).

    A: SummaryFeature manual init — `State.manualEntry(summary:trainingSession:hrBuffer:phaseTimestamps:existingResults:)` static factory. Reducer `.viewDidAppear` guarduje `.checkSummary` gdy state pre-filled (skip 10s timeout + 40-attempt poll). Backward-compat z happy path: `init()` zachowany, member-wise auto-init dla previews działa.
    B: WorkoutSummaryLoader (HealthHub) — bezstanowa utility, mapuje `HKWorkout → WorkoutSummary` + fetch'uje `[(date: Date, bpm: Double)]` HR samples z HealthKit dla `workout.startDate...endDate`. Jedno query (samples), average HR liczone w Swift z `samples.map(\.bpm).reduce(0,+) / count`.
    C: TemplatePickerFeature — nowa feature wybór `TrainingSession`. Sheet z listą template'ów (Liquid Glass cards jak PlansView). Tap karty → sheet z `WorkoutDetailContent` (shared component, bez Edit/Start/History). Toolbar "Wybierz" emit `.delegate(.didSelectTemplate)`. `@ViewAction` pattern.
    D: Entry point w ActivityDetailsFeature — toolbar "Podpnij plan" (gdy `planScore.loadState == .notFound`). Po wyborze template'a: `WorkoutSummaryLoader.loadComplete` ładuje summary+hrBuffer → push SummaryFeature w manual-init mode.
    E: Edit mode — toolbar "Edytuj wynik" (gdy `planScore.loadState == .loaded(score)`). Pre-fill `SummaryFeature.State.resultInputs` z `score.results` przez `existingResults: [WorkoutSessionResult]?` param w manual init. Reducer `.viewDidAppear` skip remappingu z template'a gdy resultInputs non-empty.
    F: SetInputFeature TextField fix — bonus: usunięty ifLet warning dla `.setInput(.presented(.view(.updateExerciseWeight)))`. Migracja 4 TextField'ów z `Binding(get:set:)` + `send(.updateXxx)` na direct mutation `store.exercises[i].X = ...` przez BindingReducer. Usunięte 4 view actions z Action enum (no longer needed).
    G: Code review fixes (post-merge polish) — `WorkoutSummaryLoader.loadComplete` zwraca tuple `(summary, hrBuffer)` jednym HK query'em (-50ms latency vs 2× round-trip). TemplatePicker migrated na `@ViewAction` pattern (compile-time enforcement view ≠ delegate/internal actions). PL localization sweep dla nowych stringów.
    H: Data loss prevention w manual entry — `isManualEntry` flag, Discard ukryty (kasował HKWorkout), Cancel button w toolbar.
    I: HR range chart w ActivityDetailsView — sekcja "Tętno minuta po minucie" z range bars + gradient color per HR zone + long-press scrub.
    J: TemplatePicker UX polish — Plans-style card layout, sheet preview używa `WorkoutDetailContent`, accessibilityLabel, divider.

### IOS-00096 SummaryView decomposition — WODScoringFeature child + view extract
    - branch: `dev/IOS-00095/IOS-00095` (kontynuacja, sugerowany osobny PR)

    Refactor monolithic `SummaryView` (880 linii) i `SummaryFeature.State` (4 paralelne arrays). Decomposition: WOD scoring jako TCA child feature + extract loading/toolbar/previews do osobnych plików. Po refactor SummaryView ~635 linii (-245), reszta w 3 extension plikach.

    A: WODScoringFeature foundation — child feature per-WOD: `State { wodIndex, result, showResults, showNotes, exercisesEdited }` + BindableAction + delegate `requestEditExercises`. Stand-alone testowalna.
    B: SummaryFeature refactor — 4 paralelne arrays (`resultInputs/showResults/showNotes/exercisesEdited`) → jeden `IdentifiedArrayOf<WODScoringFeature.State>`. `forEach` scope + delegate handling.
    C: SummaryView call sites adapt — `store.X[i]` → `store.wodScorings[id: i]?.Y`. 15 touchpointów, ForEach przez wodScorings.
    D: View extract — `SummaryView+Toolbar.swift`, `+LoadingStates.swift`, `+Previews.swift` jako osobne extension files.

### IOS-00097 HR formula picker — user-selectable maxHR formula + per-workout snapshot freeze
    - branch: `dev/IOS-00097/IOS-00097`

    Previously hardcoded `.nes` for all maxHR calculations. Ticket: user selects formula in Settings (Tanaka/Nes/Gulati/Fairbarn/Classic) with preview values + descriptions. Per-workout snapshot freeze: changing the formula only affects NEW workouts; historical workouts keep the formula from their first calculation.

    A: New formulas — Tanaka (208−0.7×age, modern standard), Gulati (206−0.88×age, female-calibrated), Classic as standalone struct (220−age, instead of reusing FairbarnUnknown).
    B: HRFormulaType extend + DefaultHeartRateCalculator dispatch — 2 new cases + ClassicFormula route.
    C: File rename — `FairbarnUknowFormula.swift` → `FairbarnUnknownFormula.swift`.
    D: HRFormulaSettingsFeature + View — DisclosureGroup list with preview maxHR per formula + description + target audience badge. Gulati hidden for males (`isAvailable(for: BiologicalSex)`).
    E: @Shared(.appStorage("hrFormula")) persistence + MaxHeartRateClient integration — choice persists across restarts, propagates instantly.
    F: Snapshot freeze — `WorkoutHRSnapshotRecord` + migration v8 + `WorkoutHRSnapshotClient` + `MaxHeartRateClient.forWorkout` refactor (fetchOrCreate). CloudKit sync via CloudKitSyncable.
    G: PersonSettings entry — "Formula maxHR" row shows current value, tap → push picker. PL localization sweep for "Tętno i aktywność" section.

### IPAD-00093 GymRoom peer reconnect robustness — pending connect + search timeout
    - branch: `dev/IPAD-00093/IPAD-00093`

    A: Host grace period 2→5 min (PeerMirrorService.gracePeriodSeconds)
    B: DEBUG BLE peer diagnostics to workout file log (fileLog seam, #if DEBUG)
    C: Pending-connect reconnect to known host (retrievePeripherals) — fixes stuck "searching" (RSSI gate + allowDuplicates trap)
    D: Peer search timeout → .connectionLost state with "Scan to rejoin" (symmetric to host grace)

### IOS-00098 Workout end-flow — primary-device summary + deferred results entry
    - branch: `dev/IOS-00098/IOS-00098`
    - plan + pełna historia bugów: `PLANS/IOS-00098-endflow-primary-summary.md`
    - research: Apple docs / WWDC25 #322 / sample iOS 26 — zasada "summary pokazuje właściciel sesji"

    A: Send timeout — guarded `sendToRemoteWorkoutSession` (3s + retry, Apple bug 769355), oba kierunki
    B: Stale-session identity guards — delegaty HKWorkoutSession na iPhonie ORAZ Watchu (spóźniony `.ended` starej sesji odpalał safety-net na nowym builderze)
    C: Auto-link plan↔workout — app-level listener `.workoutSaved(UUID)` + `PendingPlanLink` (`.fileStorage`, przeżywa kill). Po drodze: WC event stream przepisany na multicast ("latest-wins" zabijał równoległych subskrybentów — listener głuchł przy starcie treningu)
    D: Watch mini-summary z `finishWorkout()` (layout jak legacy TrainingSummaryView, `presented(nil)` = uczciwe "Workout ended" bez zielonego checka) + fix zapisu: reset `workoutFinished` per-workout (trening #2+ w tej samej sesji apki NIE zapisywał się — zweryfikowane logami, 66-min siłowy przepadł)
    E: Watch-primary End → teardown + auto-dismiss, bez ekranu pośredniego (rewizja: interstitial skasowany). Wycięta maszyneria oczekiwania: 10s timeout `.workoutSaved` + poll 40×3s + SUMMARY FAILED; standalone: bounded retry 5×1s
    F: Historia — badge "Uzupełnij wyniki" (chip przy dacie) + wejście w manual entry z pre-podpiętym planem; 3 stany toolbara (Podpnij plan / Uzupełnij wyniki / Edytuj wynik)
    G: Connection-lost — banner "trening trwa dalej", wstrzymanie WYSYŁEK ticków (licznik tyka — inaczej zegar Watcha cofałby się po reconnect), End → alert "zakończ na Watchu" (per Apple docs), S4 (koniec+zapis przy martwym linku → uczciwe domknięcie), wskaźnik w Dynamic Island

    * Refresh przez OBSERWACJĘ zamiast ręcznych triggerów: lista = `HKAnchoredObjectQueryDescriptor` observer (HealthKit pcha zmianę po syncu); badge = `@FetchAll` (pierwsze użycie SQLiteData observation w projekcie); tabela score = refetch na dismiss formularza
    * Code review 3 agentami (concurrency / architektura TCA / data flows): naprawiony CRITICAL (brak NSLock na multicast dict w TrainingManagerze) + wszystkie klastry MAJOR A–E (plan-link false claiming, launch race listenera, wyścigi konsumpcji na Watchu, delivery-aware End, refresh storm) + paczka drobnych; szczegóły w planie
    * Sweep komentarzy PL→EN w zmienionych plikach (konwencja: komentarze po angielsku, polski tylko w stringach UI)

### IPAD-00094 Class history HR chart — measurement-gap UX + scrub accuracy
    - branch: `dev/IPAD-00094/IPAD-00094`
    - target: GymRoom (iPad); zgłoszenie: przerwa w pomiarach (zawodnik wybiegł z sali) rysowała nurkowanie do 0 i "most" przez lukę

    A: Zero-sample filter przy dekodowaniu — artefakty rozłączenia (bpm=0) nie ciągną już linii/słupków do zera (naprawia oba wykresy + minuteRanges jednym filtrem u źródła)
    B: Gap-aware segmentation (próg 60 s, `AthleteSummary.maxContinuousSampleGap`) — combined LineMark dzielony na osobne serie per segment: przerwa = dziura, nie mostek. Prekomputowane w `athletesLoaded` (wzorem `minuteRanges`); helper `athleteHRLines` w +Chart.swift (limit type-checkera)
    C: Karty per-athlete — cieniowane pasmo przerwy (`RectangleMark`, krawędzie przyciągnięte do siatki minutowej — surowe timestampy nachodziły na sąsiednie słupki) + notka legendy "Brak pomiaru — zawodnik poza zasięgiem" (tylko gdy przerwa istnieje)
    D: Scrub na combined — tolerancja 30 s w `nearestSample` (koniec pokazywania wartości z cudzej minuty dla zawodników nieobecnych/w przerwie); annotation pokazuje WSZYSTKICH: obecni z BPM + %HR max (snapshot maxHR, cap 100%), nieobecni z "—" wyszarzeni na końcu listy
    E: Preview — dropout Marka (min 12–18) w generatorze danych + dedykowany wariant "Per athlete · measurement gap"
    F: Filtr "HR Zones" na wykresie zbiorczym (Myzone-style) — GroupBox "Wszyscy" z nagłówkiem tytuł + menu `…` + divider (wzorzec SmartCourt); przełączenie rysuje kolorowe pasma stref w tle, a oś Y przechodzi z BPM na %HRmax (granice stref w BPM są różne per zawodnik — wspólne pasma są uczciwe tylko na skali względnej); resting jako szare tło plotu (pasmo 0–50% zgniotłoby domenę); wiersz menu nazywa widok docelowy ("HR Zones" ↔ "BPM"), bez checkmarka; preview "Combined · zone bands"

### IOS-00099 Effort Points — points for time in HR zones
    - branch: `dev/IOS-00099/IOS-00099`
    - plan: `PLANS/IOS-00099-effort-points.md`
    - weights (v1): Z1=1 / Z2=2 / Z3=4 / Z4=6 / Z5=6 pts/min (Z5 capped at Z4), resting=0
    - computed on the athlete's device, frozen at workout end; historical data "from now on" (older workouts get no points)
    - CONTRACT: changing weights = bump `currentWeightsVersion` (memory `project_effort_points_weights_version`)

    A: Core in SharedModels — EffortPointsScoring + EffortPointsAccumulator + test target (13 tests)
    B: Personal live — counter in LiveSession (iPhone) + HRMirror (Watch) + Watch summary
    C: GymRoom transport — effortPoints in HRSamplePayload/HRSample (optional, no migration) + tile + ClassAnalytics
    D: Persistence v9 `workoutEffortScoreRecords` + EffortScoreClient + freeze via PendingEffortScore (@Shared) → `.workoutSaved` hook + cleanup on delete
    E: Display stored — workout detail (badge in zones header + tap toggles time↔points), list (next to "Primary zone"), iPhone summary (card + zone-tinted gradient background)
    F: Education — pts/min badge per zone in HeartRateZoneInfoView + entry from Settings (push, like HR formula); view has no own NavigationView (presenter provides it: NavigationStack around the workout sheet, Settings stack on push)
    G: Bugfixes — Max HR in summary (0→real), SummaryView previews (idempotent viewDidAppear), TemplatePicker warning (real binding), zone names Zone 1..5
    H: Review fixes (3-agent pre-commit review) —
       ① atomic EffortScoreClient.save (reuse existing id for hkWorkoutId → duplicate .workoutSaved no longer throws on the UNIQUE index / cross-workout leak); clear pending in the catch too
       ② clear pendingEffortScore on workout Discard (no .workoutSaved fires → would attach to next workout)
       ③ wrap the zone-info sheet in PersonalActivityView in NavigationStack (title regressed after removing the view's own NavigationView)
       ④ unify points unit to localized "pkt" across iPhone/Watch/GymRoom (was mixed "pkt"/"pts", some bare concatenations)
       ⑤ EffortPointsScoring.pointsByZone (largest-remainder) so per-zone rows always sum to the total badge; +2 tests
       ⑥ fix stale "recomputed from HealthKit" doc comments (contradicted the frozen contract) in 4 files
       + removed dead commented print block in DefaultWorkoutZoneAnalyzer; log when an un-consumed pending snapshot is overwritten
    - LiveSession card layout (final): zone name top-right (next to HR), effort points bottom-left, zone description bottom-right
    - iPad class-results screen split out into a separate ticket → IPAD-00095

### IPAD-00095 GymRoom — end-of-class results table + Points tab in history
    - native SwiftUI `Table` ranking all athletes by effort points (sortable column headers, stable medal ranking independent of the current sort)
    - data source: FROZEN per-athlete `ClassAnalytics` persisted by endSession/endAthlete — includes athletes who left mid-class, nothing recomputed
    - stats banner (Athletes / Duration / Calories / Avg HR) above the table — same four cards and definitions as the history detail
    - legacy peers without effort points show "—" instead of 0

    A: ClassResultsFeature + fullScreenCover after End class — presented after analytics are finalized, BEFORE delegate(.classEnded); "Done" resumes the legacy close flow; any fetch failure falls back to it (trainer can never get stuck)
    B: History detail restructured into 3 tabs (Team / Individual / Points) — existing ChartViewMode extended with `.points`; the ranking table reused via shared `ClassResultsTableView` (cover keeps chrome: banner + Done); Points tab bypasses the outer ScrollView (Table scrolls itself); "HR over time" section header removed (picker switches whole tabs now, segments are self-describing)


### IOS-00100 Honest strap data — stale-HR fix + sensor recovery
    - plan: `PLANS/IOS-00100-honest-strap-data.md` (log analysis 2026-07-09: frozen 116 bpm poisoned 39 min of Zone 2 + effort points; strap reconnect was a lottery)
    - root cause: builder's `mostRecentQuantity()` repeats the last value forever after a BLE strap drops out — the app fabricated fresh timestamps for stale values, defeating the accumulator's 5-min gap guard
    - Watch-primary path untouched (two-paths invariant) — sensor travels with the session owner, logs prove it survives 400m run-outs with zero gaps
    - hardware note: no backfill possible from memoryless straps (H7/H9); Polar H10 internal recording = separate future ticket (official SDK integration)

    A: Freshness core — `HKStatistics.mostRecentQuantityDateInterval()` → `WorkoutMetrics.heartRateSampleDate`; LiveSession credits hrBuffer/effort points/session stats ONLY when the sample timestamp moves; real sample dates make the 5-min gap guard actually reachable (+1 scenario test, 16 passing)
    B: Honest UI — `isSensorStale` (>60 s without a real sample, 1 s tick piggybacked on watchTickEffect), greyed HR + heart.slash + "sensor out of range" banner (connection-lost banner pattern); `[Connection] sensor STALE/FRESH` file logs
    C: GymRoom truth — `HRSamplePayload.isSensorStale` (optional, backward-compatible), parent bridge syncs the flag alongside effort points; host skips stale samples in the persistence buffer (honest gap in history) + tile desaturates with heart.slash (peer link alive, no reconnect spinner)
    D: Reconnect experiment (DEBUG flag `holdsStrapConnection`) — app-side parallel connection to HR sensors for the session (hold on standalone start, release on end); on drop the delegate issues a pending `connect()` (no timeout, known-host pattern) — measure whether HK re-association shrinks from minutes to seconds
    E: Log hygiene — `MirroringSendHealth` actor: transition-based send logging (link DOWN / RESTORED + failure count) instead of one NSError dump per beat (~70% of the Watch log was this noise); caller file-spam removed

    Follow-ups (2026-07-11/12 field logs + code review):
    F: Standalone effort-points persist — `SummaryFeature.delegate(.savedWorkoutFound)` → same idempotent `persistEffortScore` (Watch never sends `.workoutSaved` in standalone; frozen scores were silently overwritten by the next session); discard deletes an already-persisted score (review-caught orphan)
    G: BLE diagnostics to the session file — connect/fail/disconnect WITH CBError codes (#6 timeout vs #7 peripheral-initiated), measured reconnect latency, HR-notify STARTED/RESUMED (resolves "strap silent vs HealthKit stalls"); bounds-checked HR payload parse
    H: Double-End guard — reducer flag + `end()` claim-or-bail idempotency (a double tap corrupted the save, `workout: nil`); reset in prepare()/reattach()
    I: GymRoom duplicate athletes — find-or-create inside the write transaction + `athleteCreationInFlight` claim (two quick payloads raced past the record-id check → doubled athlete in results)
    J: Banner hysteresis (stale clears only on a sample measured within the 60 s window) + `@Dependency(\.date.now)` replacing raw `Date()` in LiveSession reducer


### IOS-00101 Exercise catalog — unknown-exercise extraction + versioned re-match
    - problem: 45 sessions collapsed into "Unknown Exercise" (51% "Mixed" in movement balance) — OCR/AI names failed exact-match against ExerciseType aliases; matching runs ONCE at scan time and the result is frozen in the DB, so catalog extensions alone never repair history
    - harvest tool: DEBUG-only "Unrecognized names" card in the Unknown Exercise detail (stays permanently as a radar) — distinct raw names + counts, Copy puts a paste-ready list on the pasteboard
    - contract: EVERY catalog extension (cases or aliases) bumps `ExerciseType.catalogVersion` in the same commit — the versioned re-match replays old `.unknown` data on next launch (logs + plan blobs); same freeze-then-recompute contract as effort-points weights
    - workflow documented in `WorkoutMirrorLive/CLAUDE.md` ("ExerciseType catalog" section): paste the copied list → extend catalog + bump version + golden tests → re-match repairs retroactively

    A: Catalog v2 — 12 existing cases gained missing aliases (bar-facing burpees, hang squat clean, sumo deadlift, seated overhead press…); 16 new cases (wallWalks, vUps, chestToBarPullUps, ghdSitUps, boxStepUps, boxStepOvers, russianTwist, lSit, gluteBridge, handstandShoulderTaps, overheadCarry, bearHugCarry, tricepsExtension, plateRaise, landmineAntiRotation, shoulderToOverhead) with categories + requiresWeight for carries
    B: Shared matcher — public `ExerciseType.matched(fromRawName:)` (Mapper delegates, one source of truth) + `catalogVersion`; golden tests from the 32 harvested field names (SharedModels 20 tests passing)
    C: Re-match — `ExerciseCatalogClient.rematchIfNeeded()` hooked at app start, guarded by stored version (idempotent): unknown logs re-resolved (type + category updated, `unmatchedName` kept as provenance), plan JSON blobs re-encoded through identity-preserving copies (public inits would regenerate exercise UUIDs); logs `[Catalog] rematch v2: X logs, Y plans`
    D: UX + cleanup — exercise-detail history rows show the raw OCR name ("Devil Press · WOD 1"); removed dead April `ExerciseCatalogClient` (duplicate filename → "Multiple commands produce .stringsdata"); StructuredQueries `.update {}` requires `#bind(value)` for plain Swift values (first use in the project)

### IOS-00102 Stationary distance gate + app icon
    - problem: indoor/stationary workouts (boxing, strength, functional, cross training) recorded bogus distance from arm swings and steps between stations — Apple Fitness then promoted it to the workout's headline metric
    - `HKWorkoutActivityType.collectsDistance` (SharedModels) — single source of truth driving both the data-source gate and `locationType` on BOTH workout paths (two-paths invariant honored)

    A: iPhone path — `iPhoneWorkoutSession.makeDataSource` (shared by `prepare()` and crash-recovery `reattach`) disables walking/running + cycling distance collection for stationary types; `WorkoutModeRouter` picks `.indoor` vs `.outdoor` location from the same flag
    B: Watch path — same gate in `WatchWorkoutSessionClient`; stationary configs get `.indoor` so Fitness labels them correctly, distance-based types keep `.unknown` (no reliable GPS fix on session start)
    C: App icon — layered SVG master in `Design/AppIcon/` (background / ring track / ring segments / wordmark) + generated 1024 px AppIcon for both iOS and Watch targets

### IOS-00103 Plan sharing via QR (snapshot copy)
    - goal: user A shares a scanned plan with user B face-to-face — A shows a QR code, B scans it, previews the plan, and adds an independent copy to their own list
    - no accounts / no CKShare: distribution is a self-contained payload (transport-agnostic core), not a backend. Copy semantics, not live sync — B's plan is decoupled from A's
    - scope this ticket: serialization core + QR channel only; file/share-sheet channel and an iCloud "plan library" (box publishes → others pull) are the follow-up steps (see PLANS/ roadmap)
    - versioned payload (`schemaVersion`) freezes the format so an older build refuses a newer plan with a clear "update the app" message instead of a corrupt read

    A: Serialization core (SharedModels) — `SharedPlanPayload` (versioned envelope) + `SharedPlanCodec` (JSON → zlib → base64url); `fitsInQR` byte-budget gate; round-trip / version-guard / malformed tests
    B: Export — `PlanShareClient` encodes + renders the QR image off the main thread; `SharePlanFeature` half-sheet shows the code (GymRoom visual language), too-large and failed states, swipe-to-dismiss
    C: Import — reused `QRScannerView` → decode → read-only preview (shared `WorkoutDetailContent`) → "add to my plans"; scanner remounts to retry after a bad scan; malformed → alert
    D: Snapshot identity — `TrainingSession.withNewIdentity` mints fresh UUIDs at every level (plan + workouts + exercises); imported plan stamped with import date so it sorts to the top; `PlansFeature` is the single writer (shared `saveAndReload`)

### *** App Version 0.2 *** 

### IOS-00104 GymRoom fair points — window-scoped class scoring + athlete recap
    - problem: the leaderboard used each athlete's CUMULATIVE effort points (from the start of their own workout), so someone who trained before the class began entered with a head start and unfairly topped the board
    - decision: the athlete's iPhone computes class points LOCALLY, scoped to the class window (join → leave), independent of transient BLE drops; the iPad only displays. Leaving the room early with a running workout still accrues class points (accepted trade-off)
    - individual vs class points are two projections of ONE source (`EffortPointsAccumulator`): the athlete's own screen/history shows the cumulative total; the class board shows the window-scoped delta since joining
    - part 2 (follow-up): the athlete sees their class participation in personal history — a dedicated recap section fed by a full results payload the iPad broadcasts at class end (place, participant count, no other athletes shown); plus class name/location and a location map

    A (done): SharedModels — `EffortPointsScoring.points(from:since:)` window-scoped delta relative to a join snapshot; monotonic-delta / parity / empty-origin tests
    B (done): iPhone — `JoinLiveClass` emits `.delegate(.joinedClass)` on connect/reconnect; `SessionFeature` snapshots `effortPoints.secondsByZone` once on first join, bridge sends the window-scoped delta instead of the cumulative total, snapshot cleared on leave; iPad unchanged
    C (backlog): personal history recap — persist class points + class marker on `WorkoutEffortScoreRecord` (migration); iPad → athlete results payload at `endSession` (place, participant count); recap section in `ActivityDetails`
    D (backlog): GymRoom class setup — location field + weekly-recurring option (replace single `scheduledAt` with recurrence + weekday)
