```mermaid
graph LR

  DashboardFeature[DashboardFeature]

  DashboardFeature --> DashboardTab["<font color='red'>Dashboard TAB</font> DashboardFeature"]
  DashboardFeature --> WorkoutTab["<font color='red'>Workout TAB</font> WorkoutFeature"]
  DashboardFeature --> ActivityTab["<font color='red'>Activity TAB</font> ActivityFeature"] 
  DashboardFeature --> RecordsTab["<font color='red'>Records TAB</font> PersonDataFeature"]

  %% Dashboard
  DashboardTab --> HealthKit["<font color='red'>HealthKit</font> HealthKitPermissionFeature"]
  DashboardTab --> DashboardContainer["<font color='red'>Dashboard Container</font> DashboardFeature"]

  %% Step & Weight Pickers
  DashboardContainer --> StepTabPicker["<font color='red'>Step Tab Picker</font>"]
  DashboardContainer --> WeightTabPicker["<font color='red'>Weight Tab Picker</font>"]

  %% Step Features
  StepTabPicker --> StepBarMark["<font color='red'>Step BarMark</font> StepWidgetFeature"]
  StepTabPicker --> StepPieChart["<font color='red'>Step Pie</font> StepPieWidgetFeature"]

  %% Weight Features
  WeightTabPicker --> WeightRuleMark["<font color='red'>Weight RuleMark</font> WeightGoalWidgetFeature"]
  WeightTabPicker --> WeightBarMark["<font color='red'>Weight BarMark</font> WeightDiffWidgetFeature"]

  %% Health Data List
  StepBarMark --- HealthDataList["<font color='red'>Health Data List</font> HealthDataListFeature <br> <font color='green'>Steps and Weight</font>"]
  StepPieChart --- HealthDataList
  WeightRuleMark --- HealthDataList
  WeightBarMark --- HealthDataList

  %% Add Metric Feature
  HealthDataList --> AddMetric["<font color='red'>Add Metric</font> AddMetricDataFeature <br> <font color='green'>Steps and Weight</font>"]

  %% Workout
  WorkoutTab --> WorkoutFeature[WorkoutFeature]

  %% Activity
  ActivityTab --> ActivityList["<font color='red'>Activity List</font> ActivityFeature"]
  ActivityList --> ActivityDetails["<font color='red'>Activity Details</font> ActivityDetailsFeature"]

  %% Records
  RecordsTab --> CurrentWeight["<font color='red'>Weight</font><br> CurrentWeightFeature"]
  RecordsTab --> WeightGoal["<font color='red'>Goal</font><br> WeightGoalFeature"]
  WeightGoal --> SetWeightGoal[SetWeightGoalFeature]

  %% Weightlifting Stats Section (Poprawione połączenia)
  RecordsTab --> WeightliftingStats["<font color='red'>WeightLifting Stats</font><br> WeightLiftingStatsFeature"]
  WeightliftingStats --> SetEditGoal[SetEditGoalFeature]
  WeightliftingStats --> WeightliftingSummary[WeightLiftingSummary]

  %% Weightlifting Goals
  WeightliftingSummary --> WeightliftingGoals["<font color='red'>Lista</font><br> WeightLiftingGoalsFeature"]
  WeightliftingGoals --> ExerciseInfo[ExerciseInfoFeature]
  WeightliftingGoals --> ExerciseDetails[ExerciseDetailsFeature]
  WeightliftingGoals --> SetEditGoalFeature[SetEditGoalFeature]