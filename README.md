# StepTrackerTCA

https://github.com/SebaKrk/StepTrackerTCA

## Sports Application

Inspired by Sean Allen’s course, I decided to transform his application by adapting it to the TCA (The Composable Architecture) framework.
The goal of this project is to gain a deep understanding of TCA by implementing modern design patterns and creating a modular, scalable application following best practices.

The results of my work and the details of each step can be found on GitHub: [StepTrackerTCA](https://github.com/SebaKrk/StepTrackerTCA).
This project is not only a technical exercise but also an exploration of possibilities and best practices in the context of modern iOS app development.

[Sean Allen](https://github.com/sallen0400) - Sean’s GitHub profile.
[Sean Allen Teachable - Portfolio Project](https://seanallen.teachable.com/p/portfolio-project) - direct link to the course.

******************************************************************

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
