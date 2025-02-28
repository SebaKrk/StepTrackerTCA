```mermaid
graph LR

  A[AppTabFeature]
  A --> B[DashboardFeature]
  A --> C[WorkoutFeature]
  A --> D[ActivityFeature]
  A --> E["<font color='red'>Records TAB</font> PersonDataFeature"]
  
  E --> E1["<font color='red'>Weight</font> CurrentWeightFeature"]
  E --> E2["<font color='red'>Goal</font><br> WeightGoalFeature"]
  E2 --> E3[SetWeightGoalFeature]
  
  E --> F1["<font color='red'>WeightLifting Stats</font> WeightLiftingStatsFeature"]
  F1 --> F2[SetEditGoalFeature]
  F1 --> F3[WeightLiftingSummary]
  F3 --> F3.A["<font color='red'>Lista</font><br>WeightLiftingGoalsFeature"]
  F3.A --> F3.A1[SetEditGoalFeature]
  F3.A --> F3.A2[ExerciseInfoFeature]
  F3.A --> F3.A3[ExerciseDetailsFeature]
