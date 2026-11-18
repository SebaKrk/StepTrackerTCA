"use strict";

// Reply shape for a note request, used when the caller did not set a length.
//
// The model then picks one, and a schema is the only way it can report a number
// alongside the prose. The bounds live here because the prompt asks for them and
// the endpoint enforces them: a length goes straight into the plan as a time cap.

const BOUNDS = {
  warmUp: { min: 5, max: 20 },
  coolDown: { min: 3, max: 15 },
};

const cue = (what) => ({
  type: "string",
  description: `The ${what} cue, plain text, at most 3 short lines.`,
});

const minutes = (what, bounds) => ({
  type: "integer",
  description: `How long the ${what} takes, in minutes, between ${bounds.min} and ${bounds.max}.`,
});

/** Schema for the cues this `kind` asks for, each with its own length. */
const notesSchema = (kind) => {
  const properties = {};
  if (kind !== "coolDown") {
    properties.warmUp = cue("warm-up");
    properties.warmUpMinutes = minutes("warm-up", BOUNDS.warmUp);
  }
  if (kind !== "warmUp") {
    properties.coolDown = cue("cool-down");
    properties.coolDownMinutes = minutes("cool-down", BOUNDS.coolDown);
  }
  return {
    type: "object",
    additionalProperties: false,
    required: Object.keys(properties),
    properties,
  };
};

module.exports = { notesSchema, BOUNDS };
