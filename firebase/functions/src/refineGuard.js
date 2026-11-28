"use strict";

// The chat model sometimes edits a warm-up or cool-down itself, leaves an empty placeholder section,
// or says it changed the board when it did not. These checks run on its proposal before the builders.

const SIDE_KINDS = ["warmup", "cooldown"];

/** Board-level fields the chat may change on its own; `reading` is left out, the chat always blanks it. */
const BOARD_FIELDS = ["title", "activity", "boardKind", "classTimeCapMin"];

/** The value as JSON with object keys sorted, so two sections compare by content, not key order. */
const canonical = (value) =>
  Array.isArray(value)
    ? `[${value.map(canonical).join(",")}]`
    : value !== null && typeof value === "object"
      ? `{${Object.keys(value).sort().map((key) => `${JSON.stringify(key)}:${canonical(value[key])}`).join(",")}}`
      : JSON.stringify(value);

const sectionsOf = (board) => (Array.isArray(board?.sections) ? board.sections : []);

/** The chat's schema has no order field, so a side it returns untouched comes back without it. */
const withoutOrder = ({ sideBlockFirst, ...section }) => section;

const notSide = (section) => !SIDE_KINDS.includes(section?.kind);

/** A section that only carries a title: no movements, and no text beyond its own name. */
function isPlaceholder(section) {
  const movements = Array.isArray(section?.movements) ? section.movements : [];
  const text = String(section?.text ?? "").trim().toLowerCase();
  const name = String(section?.name ?? "").trim().toLowerCase();
  return movements.length === 0 && (text === "" || text === name);
}

const workoutKey = (section) => `${section?.kind}|${String(section?.name ?? "").trim().toLowerCase()}`;

/** When the proposal has fewer workout blocks than it received, the lost ones go back at their old positions. */
function withMissingWorkouts(beforeSections, sections) {
  if (sections.filter(notSide).length >= beforeSections.filter(notSide).length) return sections;
  const left = new Map();
  for (const section of sections.filter(notSide)) left.set(workoutKey(section), (left.get(workoutKey(section)) ?? 0) + 1);
  const result = [...sections];
  beforeSections.forEach((section, index) => {
    if (!notSide(section)) return;
    const count = left.get(workoutKey(section)) ?? 0;
    if (count > 0) return left.set(workoutKey(section), count - 1);
    result.splice(Math.min(index, result.length), 0, section);
  });
  return result;
}

/**
 * Cleans the chat's proposal against the board it received.
 *
 * - A new section that is only a title is dropped.
 * - A warm-up or cool-down the chat created or edited itself goes back to how it was, and the edit
 *   becomes a builder request instead, so the builder fills it by its rules (formats, timings).
 *   Dropping a side is the chat's own job and stays.
 * - A proposal identical to the board, with no builder request, is no proposal: it changed nothing.
 */
function guardedProposal({ before, proposed, requests, changes }) {
  if (!proposed) return { proposed, requests };

  const beforeSections = sectionsOf(before);
  const known = new Set(beforeSections.map(canonical));
  // Sides are left to the loop below: a scanned title-only warm-up is still the athlete's warm-up.
  let sections = sectionsOf(proposed).filter(
    (section) => SIDE_KINDS.includes(section?.kind) || known.has(canonical(section)) || !isPlaceholder(section)
  );
  // A side-only turn sometimes comes back without the workouts; the chat cannot empty the plan, so they return.
  if (!sections.some(notSide) && beforeSections.some(notSide)) {
    const sideOf = (kind) => sections.find((section) => section?.kind === kind) ?? beforeSections.find((section) => section?.kind === kind);
    sections = [sideOf("warmup"), ...beforeSections.filter(notSide), sideOf("cooldown")].filter(Boolean);
  }
  // A warm-up or cool-down turn is not a request to drop a block; one the chat lost while copying returns in place.
  if (requests.length > 0) sections = withMissingWorkouts(beforeSections, sections);
  const workoutsChanged = canonical(sectionsOf(before).filter(notSide)) !== canonical(sections.filter(notSide));

  const nextRequests = [...requests];
  for (const kind of SIDE_KINDS) {
    if (nextRequests.some((request) => request.kind === kind)) continue;
    const old = beforeSections.find((section) => section?.kind === kind);
    const now = sections.find((section) => section?.kind === kind);
    if (!now) continue;
    if (old && canonical(withoutOrder(old)) === canonical(withoutOrder(now))) {
      // Untouched by the chat: keep the received section, order included.
      sections = sections.map((section) => (section === now ? old : section));
      continue;
    }

    sections = old ? sections.map((section) => (section === now ? old : section)) : sections.filter((section) => section !== now);
    // With a workout edited too, the side difference is most likely copy drift, and the change lines are
    // about the workout: restore the side and ask nothing. Alone, the side edit is the request.
    if (workoutsChanged) continue;
    const edit = changes.join("; ").trim() || String(now.text ?? "").trim() || String(now.name ?? "").trim();
    if (edit) nextRequests.push({ kind, request: old ? `Change the existing section: ${edit}` : edit });
  }

  const cleaned = { ...proposed, sections };
  const sameFields = BOARD_FIELDS.every((field) => canonical(before?.[field]) === canonical(proposed[field]));
  const unchanged = sameFields && canonical(sectionsOf(before)) === canonical(sections) && nextRequests.length === 0;
  return { proposed: unchanged ? undefined : cleaned, requests: nextRequests };
}

module.exports = { guardedProposal, isPlaceholder };
