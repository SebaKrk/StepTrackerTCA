# StepTrackerTCA

https://github.com/SebaKrk/StepTrackerTCA

## Sports Application

Inspired by Sean Allen’s course, I decided to transform his application by adapting it to the TCA (The Composable Architecture) framework.
The goal of this project is to gain a deep understanding of TCA by implementing modern design patterns and creating a modular, scalable application following best practices.

The results of my work and the details of each step can be found on GitHub: [StepTrackerTCA](https://github.com/SebaKrk/StepTrackerTCA).
This project is not only a technical exercise but also an exploration of possibilities and best practices in the context of modern iOS app development.

[Sean Allen](https://github.com/sallen0400)
[Sean Allen Teachable - Portfolio Project](https://seanallen.teachable.com/p/portfolio-project)

******************************************************************

### IOS-00001 The Composable Architecture
    * A: Add TCA package dependency
    
### IOS-00002 Dependency Injection with Factory
    * A: Container-Based Dependency Factory Package
    
### IOS-0003 Basic UI and Features
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

