"use strict";

// The builder's form: the routine and the block sit in fields of their own, so a
// movement of the block cannot end up as a line of the routine, or the other way round.

const object = (required, properties) => ({ type: "object", additionalProperties: false, required, properties });
const string = (description) => ({ type: "string", description });
const number = (description) => ({ type: "number", description });
const integer = (description) => ({ type: "integer", description });
const enumeration = (values, description) => ({ type: "string", enum: values, description });
const array = (items, description) => ({ type: "array", items, description });

const movement = object(["name", "targetValue", "targetUnit"], {
  name: string("Plain English catalog name: air squats, lunges, push-ups, sit-ups, hollow rocks, running"),
  targetValue: number("Reps, seconds, metres or calories per round; 0 when the format's clock sets the work (a Tabata interval)"),
  targetUnit: enumeration(["reps", "seconds", "meters", "calories"], "Unit of targetValue"),
});

const block = object(["format", "timeCapMin", "roundCount", "workSec", "restSec", "everySec", "movements"], {
  format: enumeration(["forTime", "amrap", "emom", "tabata", "intervals"], "The block's format"),
  timeCapMin: number("Minutes of the block"),
  roundCount: integer("Rounds in all; 0 for an AMRAP and for a single distance piece"),
  workSec: integer("Work seconds of a tabata or intervals; 0 otherwise"),
  restSec: integer("Rest seconds of a tabata or intervals; 0 otherwise"),
  everySec: integer("EMOM cadence in seconds; 0 otherwise"),
  movements: array(movement, "The block's movements, done in turn round by round"),
});

const warmupSchema = object(["lines", "block", "blockFirst", "writtenDurationMin", "change"], {
  lines: array(string("One exercise with its reps, time or distance"), "The routine, one exercise per line; never the block's movements"),
  block: array(block, "Empty, or the one block the athlete asked for"),
  blockFirst: { type: "boolean", description: "True when the block is done before the routine lines; false when after, or when there is no block" },
  writtenDurationMin: integer("Minutes of the whole section, routine and block together"),
  change: string("One short line saying what you built, in the athlete's language"),
});

module.exports = { warmupSchema };
