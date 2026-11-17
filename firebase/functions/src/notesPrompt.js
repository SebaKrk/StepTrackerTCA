"use strict";

// A cue the athlete glances at on the gym floor, not an article: the length is the whole point.
const warmUpSystem =
  "You are a fitness coach. Write a warm-up cue for the given workout: at most 3 short lines, about 40 words in total. Line 1 names what to prime (joints, muscles, movement pattern) for these blocks. Lines 2–3 list 2–3 movements, each with a time or rep count. No introduction, no explanations, plain text only, no markdown, no bullets.";

const coolDownSystem =
  "You are a fitness coach. Write a cool-down cue for the given workout: at most 3 short lines, about 40 words in total. Line 1 names what to release after these blocks. Lines 2–3 list 2–3 stretches or breathing drills, each with a time. No introduction, no explanations, plain text only, no markdown, no bullets.";

/** The system prompt for a note kind, with the response language appended. */
const systemPrompt = (kind, language) => {
  const base = kind === "warmUp" ? warmUpSystem : coolDownSystem;
  return (
    `${base} Respond in ${language}. ` +
    'Keep exercise and movement names in English ("squat clean", "toes to bar"); everything else in that language.'
  );
};

/**
 * The workout as a few labelled lines.
 *
 * The client sends names only, never prose: the shape of the prompt stays here
 * so the request cannot be rewritten into something this key should not answer.
 */
const userPrompt = (kind, workouts, durationMinutes) => {
  const lines = ["Workout:"];
  for (const workout of workouts) {
    lines.push(`- ${workout.name} (${workout.type})`);
    for (const exercise of workout.exercises) {
      lines.push(`  • ${exercise}`);
    }
  }
  if (typeof durationMinutes === "number") {
    const label = kind === "warmUp" ? "Warm-up" : "Cool-down";
    lines.push(`${label} duration: ${durationMinutes} min`);
  }
  const verb = kind === "warmUp" ? "warm-up" : "cool-down";
  lines.push(`\nWrite the ${verb} cue for this workout.`);
  return lines.join("\n");
};

module.exports = { systemPrompt, userPrompt };
