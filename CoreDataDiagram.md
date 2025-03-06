```mermaid
classDiagram

    %% 🔹 Encje i ich atrybuty

    class UserEntity {

        **id**: String

        **email**: String

        **healthKitEnabled**: Boolean

        **goals**: GoalsEntity [0..1]

        **workouts**: Set<WorkoutsLogEntity> [0..*]

    }

  

    class GoalsEntity {

        **id**: String

        **goalWeight**: GoalWeightEntity [0..1]

        **goalWorkout**: Set<GoalWorkoutEntity> [0..*]

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

  

    class WorkoutsLogEntity {

        **id**: String

        **user**: UserEntity [0..1]

        **workoutCross**: Set<WorkoutCrossEntity> [0..*]

        **workoutFitness**: Set<WorkoutFitnessEntity> [0..*]

        **workoutHero**: Set<WorkoutHeroEntity> [0..*]

        **workoutStrength**: Set<WorkoutStrengthEntity> [0..*]

        **workoutWeightlifting**: Set<WorkoutWeightliftingEntity> [0..*]

    }

  

    class WorkoutCrossEntity {

        **id**: String

        **date**: Date

        **movement**: String

        **value**: String

        **workoutType**: String

        **workouts**: WorkoutsLogEntity [0..1]

    }

  

    class WorkoutFitnessEntity {

        **id**: String

        **date**: Date

        **movement**: String

        **value**: String

        **workoutType**: String

        **workouts**: WorkoutsLogEntity [0..1]

    }

  

    class WorkoutHeroEntity {

        **id**: String

        **date**: Date

        **movement**: String

        **value**: String

        **workoutType**: String

        **workouts**: WorkoutsLogEntity [0..1]

    }

  

    class WorkoutStrengthEntity {

        **id**: String

        **date**: Date

        **movement**: String

        **value**: String

        **workoutType**: String

        **workouts**: WorkoutsLogEntity [0..1]

    }

  

    class WorkoutWeightliftingEntity {

        **id**: String

        **date**: Date

        **movement**: String

        **value**: String

        **workoutType**: String

        **workouts**: WorkoutsLogEntity [0..1]

    }

  

    %% 🔹 Relacje między encjami:

    UserEntity "0..1" --> "0..1" GoalsEntity : has

    UserEntity "0..*" --> "0..*" WorkoutsLogEntity : logs

    GoalsEntity "0..1" --> "0..1" GoalWeightEntity : goalWeight

    GoalsEntity "0..1" --> "0..*" GoalWorkoutEntity : goalWorkout

    GoalWeightEntity "0..1" --> "0..1" GoalsEntity : belongs to

    GoalWorkoutEntity "0..1" --> "0..1" GoalsEntity : belongs to

    WorkoutsLogEntity "0..1" --> "0..1" UserEntity : belongs to

  

    %% 🔹 Relacje WorkoutsLogEntity do typów treningów

    WorkoutsLogEntity "0..*" --> "0..*" WorkoutCrossEntity : contains

    WorkoutsLogEntity "0..*" --> "0..*" WorkoutFitnessEntity : contains

    WorkoutsLogEntity "0..*" --> "0..*" WorkoutHeroEntity : contains

    WorkoutsLogEntity "0..*" --> "0..*" WorkoutStrengthEntity : contains

    WorkoutsLogEntity "0..*" --> "0..*" WorkoutWeightliftingEntity : contains

  

    %% 🔹 Widoczna legenda na diagramie

    class Legend {

        **[1]**  Dokładnie jeden

        **[0..1]**  Zero lub jeden (relacja opcjonalna)

        **[0..*]**  Zero lub więcej (To Many - opcjonalne)

    }