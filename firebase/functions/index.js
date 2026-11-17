"use strict";

const { initializeApp } = require("firebase-admin/app");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");

const { sendMessage, SCAN_MODEL, NOTES_MODEL } = require("./src/anthropic");
const boardPrompt = require("./src/boardPrompt");
const notesPrompt = require("./src/notesPrompt");
const { boardSchema } = require("./src/boardSchema");
const quota = require("./src/quota");

initializeApp();

// Only the name lives in the repository. The value is uploaded per project with
// `firebase functions:secrets:set ANTHROPIC_API_KEY` and mounted at deploy time.
const anthropicKey = defineSecret("ANTHROPIC_API_KEY");

const options = {
  region: "europe-central2",
  secrets: [anthropicKey],
  timeoutSeconds: 120,
  memory: "512MiB",
  // The scan photo travels inline; a downscaled board sits far below this.
  enforceAppCheck: false,
};

const MAX_IMAGE_BASE64 = 6_000_000;
const MAX_OCR_CHARS = 20_000;
const MAX_LANGUAGE_CHARS = 40;
const MAX_WORKOUTS = 20;
const MAX_EXERCISES = 60;
const MAX_NAME_CHARS = 120;

/** Reads a board photo into the `ScannedBoard` JSON the app already decodes. */
exports.scanBoard = onCall(options, async (request) => {
  const uid = requireUid(request);
  const { mode, image, ocrText, language } = parseScanInput(request.data ?? {});

  const taken = await quota.reserve(uid, "scan");
  try {
    const content =
      mode === "text"
        ? [{ type: "text", text: boardPrompt.textUserPrompt(ocrText, language) }]
        : [
            { type: "image", source: { type: "base64", media_type: "image/jpeg", data: image } },
            { type: "text", text: boardPrompt.visionUserPrompt(mode === "visionWithHint" ? ocrText : null, language) },
          ];

    const text = await sendMessage({
      apiKey: anthropicKey.value(),
      model: SCAN_MODEL,
      system: boardPrompt.systemPrompt,
      content,
      cacheSystem: true,
      effort: "low",
      schema: boardSchema,
    });

    return { board: JSON.parse(text), quota: taken };
  } catch (error) {
    await quota.release(uid, "scan");
    throw asHttpsError(error);
  }
});

/** Writes the warm-up or cool-down cue for a planned session. */
exports.trainingNote = onCall(options, async (request) => {
  const uid = requireUid(request);
  const { kind, workouts, durationMinutes, language } = parseNoteInput(request.data ?? {});

  const taken = await quota.reserve(uid, "note");
  try {
    const text = await sendMessage({
      apiKey: anthropicKey.value(),
      model: NOTES_MODEL,
      system: notesPrompt.systemPrompt(kind, language),
      content: [{ type: "text", text: notesPrompt.userPrompt(kind, workouts, durationMinutes) }],
      cacheSystem: false,
      effort: "medium",
      schema: null,
    });

    return { text, quota: taken };
  } catch (error) {
    await quota.release(uid, "note");
    throw asHttpsError(error);
  }
});

// MARK: - Input

function requireUid(request) {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "sign-in-required");
  return uid;
}

function parseScanInput(data) {
  const mode = data.mode;
  if (!["vision", "visionWithHint", "text"].includes(mode)) {
    throw new HttpsError("invalid-argument", "unknown-mode");
  }

  const ocrText = clamp(asString(data.ocrText, ""), MAX_OCR_CHARS);
  const language = clamp(asString(data.language, "English"), MAX_LANGUAGE_CHARS);
  const image = asString(data.image, "");

  if (mode === "text") {
    if (ocrText.trim().length === 0) throw new HttpsError("invalid-argument", "missing-text");
  } else {
    if (image.length === 0) throw new HttpsError("invalid-argument", "missing-image");
    if (image.length > MAX_IMAGE_BASE64) throw new HttpsError("invalid-argument", "image-too-large");
  }

  return { mode, image, ocrText, language };
}

function parseNoteInput(data) {
  const kind = data.kind;
  if (!["warmUp", "coolDown"].includes(kind)) {
    throw new HttpsError("invalid-argument", "unknown-kind");
  }

  const rawWorkouts = Array.isArray(data.workouts) ? data.workouts.slice(0, MAX_WORKOUTS) : [];
  if (rawWorkouts.length === 0) throw new HttpsError("invalid-argument", "missing-workouts");

  const workouts = rawWorkouts.map((workout) => ({
    name: clamp(asString(workout?.name, ""), MAX_NAME_CHARS),
    type: clamp(asString(workout?.type, ""), MAX_NAME_CHARS),
    exercises: (Array.isArray(workout?.exercises) ? workout.exercises : [])
      .slice(0, MAX_EXERCISES)
      .map((exercise) => clamp(asString(exercise, ""), MAX_NAME_CHARS)),
  }));

  const duration = Number(data.durationMinutes);
  const durationMinutes = Number.isFinite(duration) && duration > 0 ? Math.round(duration) : null;

  return {
    kind,
    workouts,
    durationMinutes,
    language: clamp(asString(data.language, "English"), MAX_LANGUAGE_CHARS),
  };
}

const asString = (value, fallback) => (typeof value === "string" ? value : fallback);
const clamp = (value, max) => (value.length > max ? value.slice(0, max) : value);

/** Keeps a thrown `HttpsError` intact; anything else becomes a generic internal error. */
const asHttpsError = (error) => (error instanceof HttpsError ? error : new HttpsError("internal", "unexpected"));
