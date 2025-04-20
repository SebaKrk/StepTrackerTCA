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

  MovmentDetails

%% Records
RecordsTab --> CurrentWeight["<font color='red'>**Weight**</font><br>CurrentWeightFeature"]
RecordsTab --> WeightGoal["<font color='red'>**Goal**</font><br>WeightGoalFeature"]
RecordsTab --> WorkoutsSummary["<font color='red'>**Summary**</font><br>SummaryFeature <font color='green'>Repository:</font><br>workoutStrengthRepository<br>weightLiftingRepository"]

RecordsTab --> AddMeasurement["<font color='red'>**Measurement**</font><br><font color='purple'>(Add new data presented in the sheet)</font><br>AddMeasurementFeature"]

  %% Workouts Summary
  RecordsTab --> WorkoutsSummary["<font color='red'>**Summary**</font><br>SummaryFeature <br><font color='green'>Repository:</font><br>workoutStrengthRepository<br>weightLiftingRepository"]

  %% Scores and Submission
  WorkoutsSummary --> ScoresList["<font color='red'>**Scores**</font> <br><font color='purple'>(List of summary movement)</font> <br>ScoresFeature"]

  ScoresList --> MovmentInfo["<font color='red'>**Info**</font> <br><font color='purple'>(Present Info Sheet)</font><br>MovementInfoFeature"]
  ScoresList --> MovmentDetails["<font color='red'>**Details**</font> <br><font color='purple'>(Navigate to Details)</font><br>MovementDetailsFeature"]
  ScoresList --> WorkoutSubmission["<font color='red'>**Submission**</font> <br><font color='purple'>(Present Submission Sheet)</font><br>WorkoutSubmissionFeature"]

  WorkoutSubmission --> SetEditGoal["<font color='red'>**Goal**</font> <br><font color='purple'>(Add or Edit Goal)</font><br>SetEditGoalFeature <br><font color='green'>Repository:</font><br>goalsRepository"]
  WorkoutSubmission --> SubmitExercise["<font color='red'>**Result**</font> <br><font color='purple'>(Submit Exercise Result)</font><br>SubmitExerciseResultFeature <br><font color='green'>Repository:</font><br>addMeasurementRepository"]

