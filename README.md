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
        - create basic GroupBoxView for Walki and Calendar container
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

