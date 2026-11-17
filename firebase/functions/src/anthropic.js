"use strict";

const { HttpsError } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");

const ENDPOINT = "https://api.anthropic.com/v1/messages";
const API_VERSION = "2023-06-01";

// Both features run on the model the app pinned before the key moved server-side,
// so this ticket changes who holds the key and nothing about what the model reads.
const SCAN_MODEL = "claude-sonnet-5-5";
const NOTES_MODEL = "claude-sonnet-5-5";
const MAX_TOKENS = 4096;

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
    // Sonnet 5.5 rejects `disabled`; `between_tools` is the lowest setting it accepts.
    thinking: { type: "between_tools" },
    output_config: schema
      ? { effort, format: { type: "json_schema", schema } }
      : { effort },
  };

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
  logger.error("anthropic rejected the request", { status, body: bodyText });
  return new HttpsError("internal", "upstream-error");
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

module.exports = { sendMessage, SCAN_MODEL, NOTES_MODEL };
