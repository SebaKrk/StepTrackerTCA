# Claude API Workout Parsing - Sequence Diagram

```mermaid
sequenceDiagram
    actor User
    participant PP as PhotoPicker
    participant OCR as Vision OCR
    participant State as State.extractedText
    participant TE as TextEditor
    participant PC as WorkoutParsingClient
    participant Strategy as ClaudeAPIStrategy
    participant API as ClaudeAPIClient
    participant HTTP as HTTPClient
    participant Anthropic as Anthropic API
    participant Claude as Claude Model
    participant Mapper as ClaudeWorkoutMapper
    participant Decoder as JSONDecoder
    participant EW as ExtractedWorkout
    participant Feature as ScanPlanFeature
    participant DM as DomainMapper
    participant EM as ExerciseMapper
    participant TS as TrainingSession
    participant Preview as WorkoutPreviewView

    rect rgb(225, 245, 255)
    Note over User,OCR: Photo Selection & OCR
    User->>PP: Wybiera zdjecie
    PP->>OCR: Image Data
    OCR->>State: Raw Text
    State->>TE: Wyswietla tekst
    end

    rect rgb(255, 249, 196)
    Note over User,State: User Edit
    User->>TE: Edytuje tekst
    TE->>State: Zaktualizowany tekst
    end

    rect rgb(243, 229, 245)
    Note over User,Strategy: Parsing Strategy Selection
    User->>PC: Continue button
    PC->>PC: Wybor strategii

    alt Claude API
        PC->>Strategy: parseWorkoutText(rawText)

        rect rgb(232, 245, 233)
        Note over Strategy,Claude: Claude API Call
        Strategy->>API: parse(text)
        API->>HTTP: POST request
        HTTP->>Anthropic: HTTP POST
        Anthropic->>Claude: AI parsing
        Claude-->>Anthropic: JSON response
        Anthropic-->>HTTP: ClaudeAPIResponse
        HTTP-->>API: Response
        end

        rect rgb(255, 224, 178)
        Note over API,EW: JSON Mapping
        API->>Mapper: map(response)
        Mapper->>Mapper: extractJSON()
        Mapper->>Decoder: decode(jsonData)
        Decoder->>EW: ExtractedWorkout
        EW-->>Mapper: Created
        Mapper-->>API: ExtractedWorkout
        end

        API-->>Strategy: ExtractedWorkout
        Strategy-->>PC: ExtractedWorkout

    else Foundation Models
        PC->>Strategy: parseWorkoutText(rawText)
        Note over Strategy: On-device parsing
        Strategy-->>PC: ExtractedWorkout
    end
    end

    rect rgb(252, 228, 236)
    Note over PC,Preview: Domain Mapping & Navigation
    PC-->>Feature: ExtractedWorkout
    Feature->>DM: toTrainingSession()
    DM->>EM: ExerciseType.from(name)
    EM-->>DM: ExerciseType
    DM-->>Feature: TrainingSession
    Feature->>Preview: Navigate with TrainingSession
    Preview-->>User: Wyswietla workout
    end
