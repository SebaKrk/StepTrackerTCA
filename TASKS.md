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
    G: Remove legacy WorkoutManager (HealthHub WorkoutManager/ folder + Manager+iOS/ folder + Dependencies+Key cleanup + stale comments)
    H: Memory + TASKS.md update
