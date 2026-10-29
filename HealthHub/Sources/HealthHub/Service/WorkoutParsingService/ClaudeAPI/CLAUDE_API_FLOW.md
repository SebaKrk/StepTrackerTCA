# Plan scan — flow (schema v2)

```mermaid
graph TD
    User[User] -->|Camera / gallery| Photo[JPEG]
    Photo --> Backend{WorkoutParsingBackend}

    Backend -->|claudeVision default| Vision[ClaudeVisionStrategy]
    Backend -->|claudeText| OCR[Vision OCR] --> TextEdit[Text editor] --> Text[ClaudeStrategy]
    Backend -->|claudeVisionWithOCRHint| OCR2[Vision OCR, no editor] --> Vision

    Vision -->|image block + visionUserPrompt| Client[ClaudeAPIClient]
    Text -->|userPrompt| Client
    Client -->|system cache_control, between_tools, output_config.format = ClaudeBoardOutputSchema| API[Anthropic Messages API]
    API -->|ClaudeAPIResponse: content blocks, stop_reason, usage| Mapper[ClaudeBoardMapper]
    Mapper -->|JSONDecoder| Board[ScannedBoard]

    Board -->|normalized| Norm[ladder/rounds, duplicate names]
    Norm -->|toTrainingSession| Plan[TrainingSession]
    Norm --> Validator[ScanReviewValidator]
    Validator -->|hard| Failed[Scan failed]
    Validator -->|doubts + rules| Findings[ScanFinding list]
    Plan --> Preview[WorkoutPreviewFeature]
    Findings --> Preview
    Preview -->|Edit| Editor[TrainingSessionEditor] -->|saved| Preview
    Preview -->|Save enabled when no finding is open| DB[(SQLite)]
```

- Backend choice lives in `WorkoutParsingBackend` + `WorkoutParsingStrategyFactory`; the scan feature only knows the enum.
- `ScannedBoard` has no optionals: 0, "" and [] mean "not on the board"; enums are closed, so the API enforces them.
- `ExtractedWorkout` (schema v1) was removed in IOS-00161; the harness for it lives in `PLANS/scan-eval/legacy-v1/`.
