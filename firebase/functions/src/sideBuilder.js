"use strict";

const { logger } = require("firebase-functions");

const { sendMessage, SCAN_MODEL } = require("./anthropic");
const warmupPrompt = require("./warmupPrompt");
const { warmupSchema } = require("./warmupSchema");

const MAX_REQUEST_CHARS = 1000;

// Builders run after the chat inside the function's 120 s, so a hung one gives up early and is skipped.
const BUILDER_TIMEOUT_MS = 30_000;

const isSide = (section) => section.kind === "warmup" || section.kind === "cooldown";

/** The chat's requests, one per kind (the last wins), each clamped; anything malformed is dropped. */
function sideRequestsOf(reply) {
  const byKind = new Map();
  for (const entry of Array.isArray(reply.sideRequests) ? reply.sideRequests : []) {
    if ((entry?.kind !== "warmup" && entry?.kind !== "cooldown") || typeof entry.request !== "string") continue;
    const request = entry.request.trim().slice(0, MAX_REQUEST_CHARS);
    if (request.length > 0) byKind.set(entry.kind, request);
  }
  return [...byKind].map(([kind, request]) => ({ kind, request }));
}

/** A movement in the board's full form, from the builder's three fields. */
const boardMovement = (movement) => ({
  rawName: movement.name,
  name: movement.name,
  segment: "round",
  targetValue: movement.targetValue,
  targetUnit: movement.targetUnit,
  targetValueWomen: 0,
  repRangeMax: 0,
  perSide: false,
  maxEffort: false,
  sets: [],
  loads: [],
  restAfterSetSec: 0,
  alternatives: [],
});

/** The builder's form as a board section, every key the board schema requires filled. */
function boardSection(kind, built) {
  const block = Array.isArray(built.block) ? built.block[0] : undefined;
  return {
    label: "",
    format: block ? block.format : "none",
    timeCapMin: block ? block.timeCapMin : 0,
    everySec: block ? block.everySec : 0,
    workSec: block ? block.workSec : 0,
    restSec: block ? block.restSec : 0,
    repScheme: [],
    repSchemeContinues: false,
    runBeforeEachMeters: 0,
    text: (Array.isArray(built.lines) ? built.lines : []).filter((line) => typeof line === "string" && line.trim()).join("\n"),
    movements: block ? block.movements.map(boardMovement) : [],
    roundCount: block ? block.roundCount : 0,
    restBetweenRoundsSec: 0,
    writtenDurationMin: built.writtenDurationMin,
    kind,
    name: kind === "warmup" ? "Warm-up" : "Cool-down",
    notes: "",
    uncertain: [],
    // The plan places the block before or after the routine by this; it means nothing without a block.
    ...(block ? { sideBlockFirst: built.blockFirst === true } : {}),
  };
}

/** The board with `section` in its place: a warm-up first, a cool-down last, replacing one of the same kind. */
function placed(board, section) {
  const others = board.sections.filter((existing) => existing.kind !== section.kind);
  const sections = section.kind === "warmup" ? [section, ...others] : [...others, section];
  return { ...board, sections };
}

/**
 * Builds every requested warm-up and cool-down with a small call each and puts them on the board.
 *
 * The calls run side by side; one that fails leaves the board as the chat returned it,
 * so a builder outage costs the warm-up, never the whole correction.
 */
async function withBuiltSides({ apiKey, board, requests, language, previousBoard }) {
  const workouts = board.sections.filter((section) => !isSide(section));
  const results = await Promise.all(
    requests.map(async ({ kind, request }) => {
      try {
        const previous = Array.isArray(previousBoard?.sections) ? previousBoard.sections : [];
        const existing = previous.find((section) => section?.kind === kind);
        const { text, usage } = await sendMessage({
          apiKey,
          model: SCAN_MODEL,
          system: warmupPrompt.systemPrompt,
          content: [{ type: "text", text: warmupPrompt.userPrompt({ kind, request, workouts, existing, language }) }],
          cacheSystem: false,
          effort: "low",
          schema: warmupSchema,
          timeoutMs: BUILDER_TIMEOUT_MS,
        });
        const built = JSON.parse(text);
        return { section: boardSection(kind, built), change: typeof built.change === "string" ? built.change : "", usage };
      } catch (error) {
        logger.warn("side builder failed", { kind, message: error.message });
        return null;
      }
    })
  );

  let result = board;
  const changes = [];
  const usages = [];
  for (const built of results) {
    if (!built) continue;
    result = placed(result, built.section);
    if (built.change) changes.push(built.change);
    usages.push(built.usage);
  }
  return { board: result, changes, usages };
}

module.exports = { sideRequestsOf, withBuiltSides, boardSection };
