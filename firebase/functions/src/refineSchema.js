"use strict";

const { boardSchema } = require("./boardSchema");

// The board sits in a list of zero or one: structured outputs take arrays everywhere,
// while a nullable object is not something every model honours.
const refineSchema = {
  type: "object",
  additionalProperties: false,
  required: ["reply", "proposal", "changes", "sideRequests"],
  properties: {
    reply: {
      type: "string",
      description: "What you say to the athlete: a restatement to confirm, a question, or a one-line summary of the corrected plan",
    },
    proposal: {
      type: "array",
      items: boardSchema,
      description: "Empty while you still ask or restate; exactly one corrected board once the athlete confirmed",
    },
    changes: {
      type: "array",
      items: { type: "string", description: "One change, one short line" },
      description: "What the proposed board changes; empty when there is no proposal",
    },
    sideRequests: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["kind", "request"],
        properties: {
          kind: { type: "string", enum: ["warmup", "cooldown"], description: "Which section to build" },
          request: {
            type: "string",
            description: "Everything the athlete wants in it, with every detail they gave: movements, distance, format, minutes, add or replace",
          },
        },
      },
      description: "One entry per warm-up or cool-down to build, sent with the proposal once the athlete confirmed; empty otherwise",
    },
  },
};

module.exports = { refineSchema };
