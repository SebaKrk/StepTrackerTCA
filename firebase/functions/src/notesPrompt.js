"use strict";

const { BOUNDS } = require("./notesSchema");

// A cue the athlete glances at on the gym floor, not an article: the length is the whole point.
const warmUpSystem =
  "You are a fitness coach. Write a warm-up cue for the given workout: at most 3 short lines, about 40 words in total. Line 1 names what to prime (joints, muscles, movement pattern) for these blocks. Lines 2–3 list 2–3 movements, each with a time or rep count. No introduction, no explanations, plain text only, no markdown, no bullets.";

const coolDownSystem =
  "You are a fitness coach. Write a cool-down cue for the given workout: at most 3 short lines, about 40 words in total. Line 1 names what to release after these blocks. Lines 2–3 list 2–3 stretches or breathing drills, each with a time. No introduction, no explanations, plain text only, no markdown, no bullets.";

const bothSystem =
  "You are a fitness coach. Write both a warm-up cue and a cool-down cue for the given workout. Each is at most 3 short lines, about 40 words in total. The warm-up names what to prime (joints, muscles, movement pattern) for these blocks, then 2–3 movements with a time or rep count. The cool-down names what to release after these blocks, then 2–3 stretches or breathing drills, each with a time. No introduction, no explanations, plain text only, no markdown, no bullets.";

const baseSystem = (kind) => {
  if (kind === "warmUp") return warmUpSystem;
  if (kind === "coolDown") return coolDownSystem;
  return bothSystem;
};

/** The system prompt for a note kind, with the response language appended. */
const systemPrompt = (kind, language) => {
  const base = baseSystem(kind);
  return (
    `${base} Respond in ${language}. ` +
    "Write natural, fluent text in that language. Body parts, muscles, stretches and everyday movements " +
    "must be in that language. " +
    "Never translate a movement name word for word: use the name coaches actually use in that language, " +
    'and keep the English name when there is none ("Turkish get-up", "toes to bar").'
  );
};

/** Asks the model for a length when the caller did not set one. */
const chooseLength = (kind) => {
  const range = (bounds) => `between ${bounds.min} and ${bounds.max} minutes`;
  if (kind === "warmUp") return `Decide how long the warm-up takes, ${range(BOUNDS.warmUp)}, and report it.`;
  if (kind === "coolDown") return `Decide how long the cool-down takes, ${range(BOUNDS.coolDown)}, and report it.`;
  return (
    `Decide how long each cue takes and report both: the warm-up ${range(BOUNDS.warmUp)}, ` +
    `the cool-down ${range(BOUNDS.coolDown)}. A warm-up is normally the longer of the two.`
  );
};

/**
 * The workout as a few labelled lines.
 *
 * The client sends names only, never prose: the shape of the prompt stays here
 * so the request cannot be rewritten into something this key should not answer.
 */
const userPrompt = (kind, workouts, durationMinutes, sideBlock = null, sideBlockFirst = false) => {
  const lines = ["Workout:"];
  for (const workout of workouts) {
    pushWorkout(lines, workout);
  }
  if (sideBlock && kind !== "both") {
    const section = kind === "warmUp" ? "warm-up" : "cool-down";
    const when = sideBlockFirst ? "before" : "after";
    const rest = sideBlockFirst ? "after" : "before";
    lines.push(`The ${section} already contains this block, done ${when} your cue:`);
    pushWorkout(lines, sideBlock);
    lines.push(`Your cue complements it: do not repeat its movements, and cover what comes ${rest} it.`);
    if (typeof durationMinutes === "number") {
      lines.push(`The duration below includes this block, so keep your part shorter.`);
    }
  }
  if (typeof durationMinutes === "number") {
    const label = kind === "warmUp" ? "Warm-up" : "Cool-down";
    lines.push(`${label} duration: ${durationMinutes} min`);
  } else {
    lines.push(chooseLength(kind));
  }
  if (kind === "both") {
    lines.push("\nWrite the warm-up and the cool-down cue for this workout.");
  } else {
    const verb = kind === "warmUp" ? "warm-up" : "cool-down";
    lines.push(`\nWrite the ${verb} cue for this workout.`);
  }
  return lines.join("\n");
};

/** One workout as a name line followed by its exercises. */
const pushWorkout = (lines, workout) => {
  lines.push(`- ${workout.name} (${workout.type})`);
  for (const exercise of workout.exercises) {
    lines.push(`  • ${exercise}`);
  }
};

module.exports = { systemPrompt, userPrompt };
