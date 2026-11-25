"use strict";

const { initializeApp } = require("firebase-admin/app");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const { defineSecret } = require("firebase-functions/params");

const { sendMessage, SCAN_MODEL, NOTES_MODEL, ALLOWED_MODELS } = require("./src/anthropic");
const boardPrompt = require("./src/boardPrompt");
const notesPrompt = require("./src/notesPrompt");
const { boardSchema } = require("./src/boardSchema");
const { boardForForm, withLadderInItsField } = require("./src/boardCompat");
const { notesSchema, BOUNDS } = require("./src/notesSchema");
const quota = require("./src/quota");
const stats = require("./src/stats");
const { deleteAccountData } = require("./src/account");

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

// No secret is mounted: erasing an account never reaches the model.
const accountOptions = {
  region: "europe-central2",
  timeoutSeconds: 120,
  memory: "256MiB",
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
  const { mode, image, ocrText, language, model, formVersion } = parseScanInput(request.data ?? {});

  const now = new Date();
  const taken = await reserve(uid, "scan", now);
  try {
    const content =
      mode === "text"
        ? [{ type: "text", text: boardPrompt.textUserPrompt(ocrText, language) }]
        : [
            { type: "image", source: { type: "base64", media_type: "image/jpeg", data: image } },
            { type: "text", text: boardPrompt.visionUserPrompt(mode === "visionWithHint" ? ocrText : null, language) },
          ];

    const { text, usage } = await sendMessage({
      apiKey: anthropicKey.value(),
      model,
      system: boardPrompt.systemPrompt,
      content,
      // Writing the cache costs 25% more and nothing reads it below ~70 scans a day.
      cacheSystem: false,
      effort: "low",
      schema: boardSchema,
    });

    const board = boardForForm(withLadderInItsField(JSON.parse(text)), formVersion);
    await stats.recordCall(uid, "scan", usage, now);
    return { board, quota: taken };
  } catch (error) {
    await quota.release(uid, "scan", now);
    throw asHttpsError(error);
  }
});

/** Writes the warm-up or cool-down cue for a planned session. */
exports.trainingNote = onCall(options, async (request) => {
  const uid = requireUid(request);
  const { kind, workouts, durationMinutes, language } = parseNoteInput(request.data ?? {});

  const now = new Date();
  const taken = await reserve(uid, "note", now);
  try {
    const { text, usage } = await sendMessage({
      apiKey: anthropicKey.value(),
      model: NOTES_MODEL,
      system: notesPrompt.systemPrompt(kind, language),
      content: [{ type: "text", text: notesPrompt.userPrompt(kind, workouts, durationMinutes) }],
      cacheSystem: false,
      effort: "medium",
      // No length from the caller means the model picks one, and a schema is the
      // only way it can report a number next to the prose.
      schema: durationMinutes === null ? notesSchema(kind) : null,
    });

    const cues = notes(kind, text, durationMinutes);
    await stats.recordCall(uid, "note", usage, now);
    return { ...cues, quota: taken };
  } catch (error) {
    await quota.release(uid, "note", now);
    throw asHttpsError(error);
  }
});

/** Erases everything stored under the caller's account, then the account itself. */
exports.deleteMyData = onCall(accountOptions, async (request) => {
  const uid = requireUid(request);
  try {
    return await deleteAccountData(uid);
  } catch (error) {
    logger.error("account deletion failed", { message: error.message });
    throw asHttpsError(error);
  }
});

// MARK: - Allowance

/** Takes one unit of today's allowance; a call turned away by it is counted on the way out. */
async function reserve(uid, feature, now) {
  try {
    return await quota.reserve(uid, feature, now);
  } catch (error) {
    if (error instanceof HttpsError && error.message === "daily-limit-reached") await stats.recordLimitHit(feature, now);
    throw error;
  }
}

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

  // A build that names no form predates the field, so it reads the first one.
  const formVersion = Number.isInteger(data.formVersion) && data.formVersion > 0 ? data.formVersion : 1;

  return { mode, image, ocrText, language, model: scanModel(data.model), formVersion };
}

/**
 * The model this scan runs on.
 *
 * A caller may name one only where `ALLOW_MODEL_OVERRIDE` is set, which lives in
 * the development environment file alone — production ignores the field however
 * the request was built, so comparing models never becomes a user-facing switch.
 */
function scanModel(requested) {
  if (process.env.ALLOW_MODEL_OVERRIDE !== "true") return SCAN_MODEL;
  return ALLOWED_MODELS.has(requested) ? requested : SCAN_MODEL;
}

/**
 * Every cue in the reply, whichever was asked for.
 *
 * One shape for every kind so the phone decodes a single type; anything not
 * requested is null rather than absent. A length comes back only when the model
 * chose it — one the caller set is already theirs.
 */
function notes(kind, text, durationMinutes) {
  if (durationMinutes !== null) {
    return kind === "warmUp"
      ? { warmUp: text, warmUpMinutes: null, coolDown: null, coolDownMinutes: null }
      : { warmUp: null, warmUpMinutes: null, coolDown: text, coolDownMinutes: null };
  }
  const parsed = JSON.parse(text);
  return {
    warmUp: parsed.warmUp ?? null,
    warmUpMinutes: clampMinutes(parsed.warmUpMinutes, BOUNDS.warmUp),
    coolDown: parsed.coolDown ?? null,
    coolDownMinutes: clampMinutes(parsed.coolDownMinutes, BOUNDS.coolDown),
  };
}

/** The model's own number, held to the range the prompt asked for. */
function clampMinutes(value, bounds) {
  if (!Number.isFinite(value)) return null;
  return Math.min(bounds.max, Math.max(bounds.min, Math.round(value)));
}

function parseNoteInput(data) {
  const kind = data.kind;
  if (!["warmUp", "coolDown", "both"].includes(kind)) {
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

  // Asked for both cues, the model decides each length: one number cannot serve two.
  const duration = Number(data.durationMinutes);
  const durationMinutes =
    kind !== "both" && Number.isFinite(duration) && duration > 0 ? Math.round(duration) : null;

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
