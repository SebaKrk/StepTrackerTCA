"use strict";

const { HttpsError } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");

const ENDPOINT = "https://api.anthropic.com/v1/messages";
const API_VERSION = "2023-06-01";

// The cheapest model that reads a board: about a twentieth of Sonnet's price per scan.
const SCAN_MODEL = "claude-haiku-5-5";

// A cue is three formulaic lines, not a reading task, so the cheapest model
// writes it as well as any — at a twentieth of the price.
const NOTES_MODEL = "claude-haiku-5-5";
const MAX_TOKENS = 4096;

// Models a request may ask for where overriding is switched on. An allowlist
// rather than a free field: the caller must not be able to name an expensive
// model we never meant to run, or a string that only looks like one.
const ALLOWED_MODELS = new Set(["claude-haiku-5-5", "claude-sonnet-5-5", "claude-opus-5-5"]);

/**
 * How to turn thinking down, which each model spells differently.
 *
 * Reading a board needs no deliberation and thinking tokens are billed as output,
 * so every model runs with as little of it as it accepts. Sonnet 5.5 rejects
 * `disabled` and wants `between_tools`; Haiku 5.5 takes `disabled`; Opus 5.5
 * cannot turn it off at all, so it is left out and `effort` does the work.
 */
function thinkingFor(model) {
  switch (model) {
    case "claude-sonnet-5-5":
      return { type: "between_tools" };
    case "claude-haiku-5-5":
      return { type: "disabled" };
    default:
      return null;
  }
}

/**
 * One Messages API call.
 *
 * `system` is sent as a single cached block: the scan prompt is identical on every
 * request, so the cache prefix is what keeps the input cost down.
 */
async function sendMessage({ apiKey, model, system, content, cacheSystem, effort, schema }) {
  const body = {
    model,
    max_tokens: MAX_TOKENS,
    system: [cacheSystem ? { type: "text", text: system, cache_control: { type: "ephemeral" } } : { type: "text", text: system }],
    messages: [{ role: "user", content }],
    output_config: schema
      ? { effort, format: { type: "json_schema", schema } }
      : { effort },
  };

  const thinking = thinkingFor(model);
  if (thinking) body.thinking = thinking;

  let response;
  try {
    response = await fetch(ENDPOINT, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": API_VERSION,
      },
      body: JSON.stringify(body),
    });
  } catch (error) {
    logger.error("anthropic transport failure", { message: error.message });
    throw new HttpsError("unavailable", "upstream-unreachable");
  }

  if (!response.ok) {
    throw mappedError(response.status, await safeText(response));
  }

  const payload = await response.json();
  logUsage(model, payload);

  if (payload.stop_reason === "max_tokens") throw new HttpsError("internal", "truncated");
  if (payload.stop_reason === "refusal") throw new HttpsError("internal", "refused");

  const text = (payload.content ?? []).find((block) => block.type === "text")?.text;
  if (!text) throw new HttpsError("internal", "empty-response");
  return text;
}

/**
 * Upstream status → a callable error the app can act on.
 *
 * 402 means our own credit ran out. It is deliberately `unavailable` and never
 * reaches the user as a billing message: the app shows a neutral outage, the
 * cause stays in the logs.
 */
function mappedError(status, bodyText) {
  if (status === 402) {
    logger.error("anthropic credit exhausted — top up the account", { body: bodyText });
    return new HttpsError("unavailable", "service-unavailable");
  }
  if (status === 401 || status === 403) {
    logger.error("anthropic rejected the key — check the secret in this project", { status });
    return new HttpsError("unavailable", "service-unavailable");
  }
  if (status === 429) return new HttpsError("resource-exhausted", "upstream-rate-limited");
  if (status === 413) return new HttpsError("invalid-argument", "image-too-large");
  if (status >= 500) {
    logger.warn("anthropic server error", { status });
    return new HttpsError("unavailable", "service-unavailable");
  }
  // A 4xx means the request we built is wrong, so repeating it cannot succeed.
  logger.error("anthropic rejected the request", { status, body: bodyText });
  return new HttpsError("internal", "upstream-rejected");
}

function logUsage(model, payload) {
  const usage = payload.usage ?? {};
  logger.info("anthropic call", {
    model,
    stopReason: payload.stop_reason ?? null,
    inputTokens: usage.input_tokens ?? 0,
    outputTokens: usage.output_tokens ?? 0,
    cacheWriteTokens: usage.cache_creation_input_tokens ?? 0,
    cacheReadTokens: usage.cache_read_input_tokens ?? 0,
  });
}

async function safeText(response) {
  try {
    return (await response.text()).slice(0, 500);
  } catch {
    return "";
  }
}

module.exports = { sendMessage, SCAN_MODEL, NOTES_MODEL, ALLOWED_MODELS };
