"use strict";

const fs = require("node:fs");
const path = require("node:path");
const { coachPersona } = require("./coachPersona");

// The system prompt is a plain text file so the eval harness can rewrite it
// without touching code: PLANS/scan-eval/apply_to_function.py writes here.
/** The reading rules alone; the chat appends them to its own prompt, which already carries the persona. */
const rules = fs.readFileSync(path.join(__dirname, "boardPrompt.txt"), "utf8").trimEnd();
const systemPrompt = `${coachPersona}\n\n${rules}`;

// In the per-request user prompt, not the cached system prompt, so the cache survives a language change.
const languageRule = (language) =>
  `Write every free-text field (notes, labels, warm-up and cool-down text) in ${language}. ` +
  "Movement names (name) stay English catalog style; rawName keeps the board spelling.";

/** User prompt for a text-only scan; the OCR transcript is the source. */
const textUserPrompt = (ocrText, language) =>
  `Parse this CrossFit workout OCR text:\n\n${ocrText}\n\n${languageRule(language)}`;

/** User prompt for a photo scan; the OCR transcript, when given, is explicitly untrusted. */
const visionUserPrompt = (ocrHint, language) => {
  let prompt =
    "Read the workout from the attached photo of a whiteboard or notebook page. The photo is the source of truth.\n" +
    "Ignore everything that is not the workout: attendance names, dates, doodles, the class clock.\n" +
    languageRule(language);

  if (ocrHint && ocrHint.trim().length > 0) {
    prompt +=
      "\n\n\nBelow is an automatic OCR transcript of the same photo. It is an UNTRUSTED hint: handwriting OCR " +
      "misreads digits and words and scrambles line order. Where the photo and the transcript disagree, " +
      "trust the photo. Never copy a transcript word you cannot see on the photo.\n\n" +
      `<ocr_hint>\n${ocrHint}\n</ocr_hint>`;
  }
  return prompt;
};

module.exports = { rules, systemPrompt, textUserPrompt, visionUserPrompt };
