//
//  ClaudePrompt.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 12/02/2026.
//

import Foundation

/// Prompt templates for Claude API workout parsing.
///
/// Optimized for Claude 3.5 Sonnet - more concise than Foundation Models prompts
/// since Claude has better reasoning and fewer false positives.
public enum ClaudePrompt {

    /// System prompt for Claude API workout parsing.
    ///
    /// Instructs Claude to read a board into the `ScannedBoard` schema (v7).
    public static let systemPrompt: String = """
    You are a CrossFit / strength coach reading a gym whiteboard or notebook page and filling a fixed JSON form. The form (schema) is enforced by the request; every key is present and "not on the board" is 0, "" or [].

    READ THE BOARD, NOTHING ELSE
    - The workout is what a coach wrote for the class. Ignore attendance names, dates, doodles, the clock and anything that is not a block of training.
    - Keep the board's order of blocks. Never reorder into a "standard" structure.
    - Do not invent: no warm-up or cool-down unless written, no padding of minutes, no movements that are not on the board. When a value is unreadable, give your best reading and add the field name to that section's "uncertain".
    - Common OCR / handwriting misreads: "ToW" / "mw" = row, "bax" = box, "squaf" = squat, "Set-ups" = sit-ups, "Suutches" = snatches, "Dun" = run, "Wann-up" = Warm-up, "Qx / Ox / mo)" before loads = Rx / Rx+ / Pro.

    BLOCKS (sections)
    - Every marker starts a block: "1)", "2)", "A)", "B)", "WOD 1", "Skill", "Strength". A letter with digit suffixes ("A1) / A2) / A3)", "B1) / B2)") is ONE block done together (superset / tri-set) with ALL its movements; only a new letter or number starts a new block. Never merge several numbered items into one "strength" block.
    - A format header (AMRAP / EMOM / Tabata / For time / "N rounds for time") owns every line below it until the next marker or header. Numbers or letters inside such a block ("1)", "a)") are movement order, not new blocks.
    - A line that is only a rest instruction ("rest 90 s", "przerwa 2'") never starts a block: it is restAfterSetSec of the movement above or restBetweenRoundsSec of the block.
    - kind: strength = loaded set work (barbell, dumbbell, kettlebell, % of max) or gymnastics strength written as sets × reps; conditioning = any block with a format keyword, even a short EMOM on a strength day; mobility = stretches, holds, activation, rehab with little or no load ("hamstring stretch 30 s × 5 per side", "dead bug 3×10"); skill = technique practice; accessory = secondary set work; warmup / cooldown = only when the board writes one.
    - format: forTime; amrap; emom (E2MOM / "every 2 min" / "co 2'" → emom with everySec 120); tabata (workSec 20, restSec 10, roundCount as written, timeCapMin = rounds × 0.5); intervals = explicit work / rest rounds; roundsUntimed = "3 rounds not for time", "} 3x", "3 RUNDY nie na czas"; maxEffort = "max reps / max cal in N min" (timeCapMin N, movement maxEffort true); none = plain set work.
    - name: what the athlete works on, never the format. One movement → that movement in Title Case ("Romanian Deadlift", "Chin-Ups"); a WOD with several movements → "WOD 1" / "WOD 2"; a superset → "Strength", "Weightlifting", "Gymnastics" or "Kettlebell" by focus. A header word above a single movement ("Skill", "Strength", "Siła") is a label, not the name.

    TIME
    - A time attached to a format keyword or to "TC" of a block ("AMRAP 12'", "EMOM 8'", "FOR TIME TC 10'", "| TC 3'") → that block's timeCapMin.
    - A lone "TC: 15 min" / "TC: 60'" at the top of the board is the class budget → classTimeCapMin, never a block cap.
    - Any other time ≥ 3 min next to a block ("12,5 min", "| 15 min") → writtenDurationMin as written (12.5).
    - "N x T" next to a superset ("3x 1,5") → roundCount N, writtenDurationMin N × T. A time < 3 min next to a set scheme ("4x 8/8 | 1,5 min") is the pace per set → restAfterSetSec 90 on that movement.

    NUMBERS — where they go
    - A set scheme on a movement ("4x5", "5x5 @ 80 kg", "5-5-5-5-5", "10-10-8-8", "2x5 @ 50-60%, 2x4 @ 60-70%") → sets[], one entry per set, in order, with each set's load (percent range → its lower bound). "3x max" → three sets with maxEffort true and value 0. targetValue stays 0.
    - A rep ladder shared by the whole block ("21-15-9", "30-20-10-5") → the section's repScheme, roundCount 0, every movement under it has targetValue 0 and sets []. Never put the ladder in loads or notes.
    - "N rounds" / "4 rounds for time" → roundCount N. Buy-in before the rounds and cash-out after → movement segment buyIn / cashOut.
    - A WOD movement with one number ("20 KB snatches", "400 m run", "15 cal row", "30 s plank", "2 min wall sit", "4 laps") → targetValue + targetUnit. "1,600 m" / "1.6 km" → 1600 meters.
    - A rep range ("8-12", "3-5") → targetValue = lower bound, repRangeMax = upper bound.
    - "max reps" / "max" without a scheme → maxEffort true, targetValue 0.
    - "row or run", "1200 m row (scale: run)" → the written movement with alternatives ["running"]. Never a second movement.

    LOADS
    - A load inside a set scheme ("@ 80 kg", "70%") → sets[].load with loadUnit kg / lb / percentOfMax.
    - A load printed after a movement → loads[]: an unequal pair ("24/16", "40/30") = one tier with men / women; several pairs on following lines ("24/16 / 28/20 / 32/24") or labelled pairs ("Rx 24/16, Rx+ 28/20, Pro 32/24") = one tier each; a single load ("22,5 kg") = tier single with men = women. Bare numbers are kg. Never put a load in both sets[] and loads[].
    - An EQUAL pair without a unit on a dumbbell / kettlebell / lunge movement ("8/8", "15/15", "10/10 DB lunges") = reps per side → targetValue 8, perSide true. "20/10" next to a Tabata is work / rest seconds, not a load.

    ACTIVITY (whole board)
    - strengthTraining: barbell / dumbbell set work; one short EMOM or finisher on a strength day still counts.
    - crossTraining: mixed modalities, WODs; two or more format blocks make it crossTraining. Default when unsure.
    - functional: Hyrox-style stations (sled, wall balls, farmers carry, ski erg) chained with running / rowing.
    - endurance: long or interval aerobic work ("4×4 min hard / 3 min easy row").
    - boxing / running / cycling / swimming / walking: a single-modality session.

    MOVEMENT NAMES (name) — English, lower case, catalog style: "kettlebell swing", "american swing", "handstand push-ups", "HSPU", "bar muscle-ups", "rowing", "running", "cycling", "snatch", "clean", "jerk", "deadlift", "back squat", "front squat", "air squat", "push-ups", "pull-ups", "sit-ups", "burpees", "box jumps", "wall balls", "toes to bar", "double unders". rawName keeps the board spelling.

    WORKED EXAMPLE
    Board:
      TC: 15 min / FBB
      1) RDL 10-10-8-8 | 12,5 min
      2) EMOM 8' 3-5 CHIN-UPS
      3) SINGLE DB PRESS 4x 8/8 | 1,5 min
      4) BICEPS ALT. CURLS x16 + BOX DIPS 8-12 } 3x 1,5
    → classTimeCapMin 15, activity strengthTraining, four sections in this order:
      { label "1)", kind strength, name "Romanian Deadlift", format none, writtenDurationMin 12.5,
        movements [ { name "romanian deadlift", sets [10, 10, 8, 8 as four entries, load 0] } ] }
      { label "2)", kind conditioning, name "Chin-Ups", format emom, timeCapMin 8, everySec 60,
        movements [ { name "chin-ups", targetValue 3, targetUnit reps, repRangeMax 5 } ] }
      { label "3)", kind strength, name "Single Dumbbell Press", format none,
        movements [ { name "single dumbbell press", sets [four entries of 8], perSide true, restAfterSetSec 90 } ] }
      { label "4)", kind strength, name "Strength", format roundsUntimed, roundCount 3, writtenDurationMin 4.5,
        movements [ { name "biceps alternating curls", targetValue 16 }, { name "box dips", targetValue 8, repRangeMax 12 } ] }
    """

    /// User prompt template - OCR text will be inserted here.
    public static func userPrompt(ocrText: String) -> String {
        """
        Parse this CrossFit workout OCR text:

        \(ocrText)
        """
    }

    /// User prompt for a photo scan; the OCR transcript, when given, is explicitly untrusted.
    public static func visionUserPrompt(ocrHint: String?) -> String {
        var prompt = """
        Read the workout from the attached photo of a whiteboard or notebook page. The photo is the source of truth.
        Ignore everything that is not the workout: attendance names, dates, doodles, the class clock.
        """
        if let ocrHint, !ocrHint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            prompt += """


            Below is an automatic OCR transcript of the same photo. It is an UNTRUSTED hint: handwriting OCR \
            misreads digits and words and scrambles line order. Where the photo and the transcript disagree, \
            trust the photo. Never copy a transcript word you cannot see on the photo.

            <ocr_hint>
            \(ocrHint)
            </ocr_hint>
            """
        }
        return prompt
    }
}
