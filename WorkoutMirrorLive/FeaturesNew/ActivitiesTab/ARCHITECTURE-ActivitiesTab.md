# ActivitiesTab Architecture

## Feature Hierarchy (Mermaid)

```mermaid
graph TD

  %% Root Feature
  ActivitiesFeature["<b>ActivitiesFeature</b><br>(Parent)"]

  %% Decision Node - Tab Picker
  ActivitiesFeature --> TabPicker{"<b>Tab Picker</b><br>TrainingTabContext"}

  %% Branches from picker
  TabPicker -->|".activity"| PersonalActivity["<b>PersonalActivityFeature</b><br>HealthKit workout list<br>HR zone analysis<br>Sorting & date filtering"]
  TabPicker -->|".plans"| Plans["<b>PlansFeature</b><br>Workout plan management<br>Plan vs result comparison"]

  %% PersonalActivity Navigation
  PersonalActivity -->|"Navigate"| ActivityDetails["<b>ActivityDetailsFeature</b><br>Detailed workout stats<br>Charts & metrics"]
  PersonalActivity -->|"Sheet"| HeartRateZoneInfo["<b>HeartRateZoneInfoFeature</b><br>HR zone explanation"]

  %% ActivityDetails Children
  ActivityDetails -->|"Navigate"| MetricDetail["<b>MetricDetailFeature</b>"]

  %% Plans Navigation
  Plans -->|"FullScreenCover"| AddPlan["<b>AddPlanFeature</b><br>Create new workout plan"]

  %% AddPlan Options - Decision
  AddPlan --> AddPlanChoice{"<b>Input Method</b>"}
  AddPlanChoice -->|"Camera"| ScanPlan["<b>ScanPlanFeature</b><br>OCR from training notes<br>(TODO)"]
  AddPlanChoice -->|"Manual"| ManualEntry["<b>ManualEntryFeature</b><br>Manual plan form<br>(TODO)"]

  %% Dependencies
  PersonalActivity -.-|"Dependency"| ActivityClient["activityClient<br>HealthKit fetching"]
```

## Feature Hierarchy (ASCII Art)

```
┌─────────────────────────────────────────────────────────────────┐
│                    ACTIVITIES FEATURE                           │
│                         (Parent)                                │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                    ┌──────┴──────┐
                    │ TAB PICKER  │
                    │   ◇ ◇ ◇     │
                    └──────┬──────┘
                           │
         ┌─────────────────┴─────────────────┐
         │ .activity                  .plans │
         ▼                                   ▼
┌─────────────────────┐         ┌─────────────────────┐
│ PersonalActivity    │         │    PlansFeature     │
│ Feature             │         │                     │
│ ─────────────────── │         │ ─────────────────── │
│ • HealthKit list    │         │ • Plan management   │
│ • HR zone analysis  │         │ • Plan vs result    │
│ • Sort & filter     │         │                     │
└─────────┬───────────┘         └─────────┬───────────┘
          │                               │
    ┌─────┴─────┐                   FullScreenCover
    │           │                         │
Navigate     Sheet                        ▼
    │           │               ┌─────────────────────┐
    ▼           ▼               │   AddPlanFeature    │
┌───────────┐ ┌─────────┐       │ ─────────────────── │
│ Activity  │ │ ZoneInfo│       │ • Create new plan   │
│ Details   │ │ Feature │       └─────────┬───────────┘
│ Feature   │ └─────────┘                 │
└─────┬─────┘                    ┌────────┴────────┐
      │                          │  INPUT METHOD   │
   Navigate                      │      ◇ ◇ ◇      │
      │                          └────────┬────────┘
      ▼                     ┌─────────────┴─────────────┐
┌───────────┐               │ Camera              Manual│
│ Metric    │               ▼                           ▼
│ Detail    │        ┌────────────┐            ┌────────────┐
│ Feature   │        │ ScanPlan   │            │ ManualEntry│
└───────────┘        │ [TODO]     │            │ [TODO]     │
                     └────────────┘            └────────────┘
```
