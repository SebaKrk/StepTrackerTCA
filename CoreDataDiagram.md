```mermaid
classDiagram
    %% 🔹 Encje i ich atrybuty
    class UserEntity {
        **id**: String
        **healthKitEnabled**: Boolean
        **goals**: GoalsEntity [0..1]
    }

    class GoalsEntity {
        **id**: String
        **goalWeight**: GoalWeightEntity [0..1]
        **goalWorkout**: GoalWorkoutEntity [0..*]
        **user**: UserEntity [0..1]
    }

    class GoalWeightEntity {
        **id**: String
        **weight**: Double
        **weightUnit**: String
        **dateAdded**: Date
        **goals**: GoalsEntity [0..1]
    }

    class GoalWorkoutEntity {
        **id**: String
        **workoutType**: String
        **movement**: String
        **date**: Date
        **value**: Double
        **goals**: GoalsEntity [0..1]
    }

    %% 🔹 Relacje między encjami:
    UserEntity "0..1" --> "0..1" GoalsEntity : has
    GoalsEntity "0..1" --> "0..1" GoalWeightEntity : goalWeight
    GoalsEntity "0..1" --> "0..*" GoalWorkoutEntity : goalWorkout
    GoalWeightEntity "0..1" --> "0..1" GoalsEntity : belongs to
    GoalWorkoutEntity "0..1" --> "0..1" GoalsEntity : belongs to

    %% 🔹 Widoczna legenda na diagramie
    class Legend {
        **[1]**  Dokładnie jeden
        **[0..1]**  Zero lub jeden (relacja opcjonalna)
        **[0..*]**  Zero lub więcej (To Many - opcjonalne)
    }