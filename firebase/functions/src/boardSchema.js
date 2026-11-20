"use strict";

// JSON schema of `ScannedBoard` (schema v2) for structured outputs.
//
// Zero unions and zero optionals: every key is required and "not on the board"
// is 0, "" or []. The notation rules live in the descriptions, so the prompt
// only has to teach what the schema cannot express.

const object = (required, properties) => ({
  type: "object",
  additionalProperties: false,
  required,
  properties,
});

const string = (description) => ({ type: "string", description });
const number = (description) => ({ type: "number", description });
const integer = (description) => ({ type: "integer", description });
const boolean = (description) => ({ type: "boolean", description });
const enumeration = (values, description) => ({ type: "string", enum: values, description });
const array = (items, description) => ({ type: "array", items, description });

const load = object(
  ["tier", "men", "women", "unit"],
  {
    tier: enumeration(
      ["single", "rx", "rxPlus", "pro", "scaled"],
      "single when the board prints one load with no tier label"
    ),
    men: number("First number of a men/women pair; the only number for a single load"),
    women: number("Second number of the pair; equal to men for a single load"),
    unit: enumeration(
      ["kg", "lb", "pood", "percentOfMax", "percentOfBodyWeight"],
      "Unit of the pair; kg when the board gives bare numbers like 24/16; percentOfBodyWeight only when the board says body weight"
    ),
  }
);

const set = object(
  ["value", "maxEffort", "unit", "load", "loadUnit"],
  {
    value: number("Reps / seconds / meters / calories of this set; 0 with maxEffort for 'max'"),
    maxEffort: boolean("True for a 'max' set"),
    unit: enumeration(["reps", "seconds", "meters", "calories"], "What value counts"),
    load: number("Load of this set: 80 for '@ 80 kg', 70 for '@ 70%'; 0 when none"),
    loadUnit: enumeration(
      ["kg", "lb", "percentOfMax", "percentOfBodyWeight", "none"],
      "Unit of load; percentOfBodyWeight only when the board says body weight; none when load is 0"
    ),
  }
);

const movement = object(
  [
    "rawName", "name", "segment", "targetValue", "targetUnit", "targetValueWomen",
    "repRangeMax", "perSide", "maxEffort", "sets", "loads", "restAfterSetSec",
    "alternatives",
  ],
  {
    rawName: string("Exactly as written on the board"),
    name: string("Normalised English movement name: kettlebell swing, box jumps, running"),
    segment: enumeration(["buyIn", "round", "cashOut"], "round unless the board marks a buy-in or cash-out"),
    targetValue: number("Single target per round: 20 reps → 20, 400 m → 400; 0 when sets[] or the section repScheme carry the numbers"),
    targetUnit: enumeration(["reps", "seconds", "minutes", "meters", "km", "calories", "laps"], "Unit of targetValue"),
    targetValueWomen: number("Women's number of an Rx split written with a counting unit: '12/9 cal row' → targetValue 12, this 9; 0 when the board writes one number"),
    repRangeMax: integer("Upper bound of a rep range: '8-12' → targetValue 8, repRangeMax 12; 0 otherwise"),
    perSide: boolean("True for an equal pair without a unit on a unilateral movement: 8/8, 10 per side"),
    maxEffort: boolean("True for 'max reps' / 'max cal'; targetValue stays 0"),
    sets: array(set, "Set scheme expanded one entry per set: 5x5 @ 80 kg → five entries; 10-10-8-8 → four. Empty for WOD movements"),
    loads: array(load, "Loads printed after the movement: 24/16 → one rx tier; Rx 24/16, Rx+ 28/20 → two tiers; a single load → tier single. Empty when the load sits in sets[]"),
    restAfterSetSec: integer("'rest 90 s between sets' → 90; 0 otherwise"),
    alternatives: array(string("Alternative movement"), "'row or run' → [\"running\"]; empty otherwise"),
  }
);

// Key order is the order the model writes in: what is on the board first
// (format, times, movements), the judgments about it (rounds, kind, name) after.
const section = object(
  [
    "label", "format", "timeCapMin", "everySec", "workSec", "restSec", "repScheme", "text",
    "movements", "roundCount", "restBetweenRoundsSec", "writtenDurationMin", "kind", "name",
    "notes", "uncertain",
  ],
  {
    label: string("Marker as written: A), B1-B3, WOD 1; empty when none. A1/A2 share one block"),
    format: enumeration(
      ["none", "forTime", "amrap", "emom", "deathBy", "tabata", "intervals", "roundsUntimed", "maxEffort"],
      "none for plain set work; roundsUntimed for '3 rounds not for time'; maxEffort for 'max reps in N min'; deathBy for an EMOM with reps growing until failure"
    ),
    timeCapMin: number("Minutes next to the format keyword or TC of THIS block; 0 when none"),
    everySec: integer("EMOM cadence in seconds: 60, 120 for E2MOM, 0 otherwise"),
    workSec: integer("Work seconds of tabata / intervals (tabata 20); 0 otherwise"),
    restSec: integer("Rest seconds of tabata / intervals (tabata 10); 0 otherwise"),
    repScheme: array(integer("Reps of one round"), "Rep ladder like 21-15-9; empty otherwise. Never a load, never a set scheme of one movement"),
    text: string("Warm-up / cool-down board text verbatim; empty for other kinds"),
    movements: array(movement, "Movements of the block in board order; empty for warm-up / cool-down text"),
    roundCount: integer("How many times the whole list repeats ('4 rounds', tabata 8, '} 3x'); 0 when a repScheme is used"),
    restBetweenRoundsSec: integer("'rest 2 min between rounds' → 120; 0 otherwise"),
    writtenDurationMin: number("Minutes written next to the block that are not a cap ('| 12,5 min'); 0 otherwise"),
    kind: enumeration(
      ["warmup", "skill", "strength", "accessory", "conditioning", "mobility", "cooldown"],
      "strength = loaded set work; conditioning = any block with a format keyword; mobility = stretches, holds, rehab"
    ),
    name: string("What the athlete works on, never the format: Back Squat, WOD 1, Strength"),
    notes: string("Anything else written about the block; empty when nothing"),
    uncertain: array(string("Field name"), "Fields you could not read with confidence, e.g. timeCapMin"),
  }
);

const boardSchema = object(
  ["reading", "title", "classTimeCapMin", "sections", "boardKind", "activity"],
  {
    reading: string(
      "The board copied line by line exactly as written, abbreviations kept, before any interpretation; empty when it is not a workout"
    ),
    title: string("Short workout title; the board's own heading when it has one"),
    classTimeCapMin: number("A lone TC written at the top of the board (class budget); 0 when none. Never a block cap"),
    sections: array(section, "Every block in board order, warm-up and cool-down included only when written"),
    boardKind: enumeration(
      ["strengthDay", "wodDay", "mixed", "notAWorkout"],
      "Decided from the sections above; notAWorkout when the photo shows no training plan"
    ),
    activity: enumeration(
      ["crossTraining", "strengthTraining", "functional", "endurance", "boxing", "running", "cycling", "swimming", "walking"],
      "Dominant character of the whole board, decided from the sections above; crossTraining when mixed or unsure"
    ),
  }
);

module.exports = { boardSchema };
