# ActivitiesTab Architecture

## Feature Hierarchy (Mermaid)

```mermaid
graph TD

  ActivitiesFeature["ActivitiesFeature<br>(Kontener - bez viewState)"]

  %% Tab Picker
  ActivitiesFeature --> TabPicker["Tab Picker<br>TrainingTabContext"]

  %% Child Features
  TabPicker --> PersonalActivity["PersonalActivityFeature<br>viewState, workouts, zoneInfo"]
  TabPicker --> Plans["PlansFeature<br>viewState, plans"]

  %% PersonalActivity Destinations
  PersonalActivity --> ActivityDetails["ActivityDetailsFeature<br>(Navigate)"]
  PersonalActivity --> MetricDetail["MetricDetailFeature"]

  %% ActivityDetails Children
  ActivityDetails --> HeartRateZoneInfo["HeartRateZoneInfoFeature<br>(Sheet)"]

  %% Plans Destinations
  Plans --> AddPlan["AddPlanFeature<br>(FullScreenCover)"]

  %% AddPlan Options
  AddPlan --> ScanPlan["ScanPlanFeature<br>(OCR Camera) TODO"]
  AddPlan --> ManualEntry["ManualEntryFeature<br>(Form) TODO"]

  %% Dependencies
  PersonalActivity -.- ActivityClient["activityClient"]
```

## Feature Hierarchy (ASCII Art)

```
┌─────────────────────────────────────────────────────────────────┐
│                    ActivitiesFeature                            │
│                    (Kontener - bez viewState)                   │
│                    State: context, color, 2x child              │
└──────────────────────────┬──────────────────────────────────────┘
                           │
              ┌────────────┴────────────┐
              │     Tab Picker          │
              │  .activity / .plans     │
              └────────────┬────────────┘
                           │
          ┌────────────────┴────────────────┐
          │                                 │
          ▼                                 ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│ PersonalActivityFeature │     │     PlansFeature        │
│ ─────────────────────── │     │ ─────────────────────── │
│ viewState               │     │ viewState               │
│ workouts: [HKWorkout]   │     │ plans: [WorkoutPlan]    │
│ zoneInfo: [UUID: Zone]  │     │                         │
│ maxHeartRate            │     │                         │
│ days, sortDescriptors   │     │                         │
└───────────┬─────────────┘     └───────────┬─────────────┘
            │                               │
   ┌────────┴────────┐                      │
   │                 │                      │
   ▼                 ▼                      ▼
┌──────────┐  ┌──────────────┐    ┌─────────────────────┐
│ Activity │  │ MetricDetail │    │   AddPlanFeature    │
│ Details  │  │   Feature    │    │ (FullScreenCover)   │
│ Feature  │  │              │    │                     │
│(Navigate)│  └──────────────┘    └──────────┬──────────┘
└────┬─────┘                                 │
     │                          ┌────────────┴────────────┐
     ▼                          │                         │
┌────────────────┐              ▼                         ▼
│ HeartRateZone  │    ┌─────────────────┐     ┌─────────────────┐
│ InfoFeature    │    │  ScanPlan       │     │  ManualEntry    │
│ (Sheet)        │    │  Feature        │     │  Feature        │
└────────────────┘    │  (OCR) TODO     │     │  (Form) TODO    │
                      └─────────────────┘     └─────────────────┘
```

