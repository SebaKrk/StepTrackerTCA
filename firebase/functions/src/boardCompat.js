"use strict";

/** Newest board form the proxy writes; a caller names the form it reads in `formVersion`. */
const CURRENT_FORM = 3;

/** The run of a fitness run as a movement of its own, the way form 1 carried it. */
const runMovement = (meters) => ({
  rawName: "",
  name: "running",
  segment: "round",
  targetValue: meters,
  targetUnit: "meters",
  targetValueWomen: 0,
  repRangeMax: 0,
  perSide: false,
  maxEffort: false,
  sets: [],
  loads: [],
  restAfterSetSec: 0,
  alternatives: [],
});

/** An open-ended ladder as a board writes it: "1-2-3-4-5-6-…", "2 - 4 - 6 ...". */
const OPEN_LADDER = /(\d+(?:\s*[-–]\s*\d+)+)\s*[-–]?\s*(?:…|\.{3})/;

/** A block whose movements carry no numbers of their own, so a ladder can speak for them. */
const movementsAwaitLadder = (section) =>
  section.movements.length > 0 &&
  section.movements.every((movement) => !(movement.targetValue > 0) && (movement.sets ?? []).length === 0);

/**
 * Puts an open ladder where the form wants it, whatever the reader did with it.
 *
 * The reader is told to fill `repScheme` and to keep the ladder out of the notes, and
 * does either, both or neither from one scan to the next. So the rule is enforced here:
 * a ladder with an ellipsis found in the notes of a block that has no numbers becomes
 * the ladder, and a note quoting the ladder is dropped as the restatement it is.
 */
function withLadderInItsField(board) {
  return {
    ...board,
    sections: board.sections.map((section) => {
      let shaped = section;
      const written = OPEN_LADDER.exec(shaped.notes ?? "");
      if (written && (shaped.repScheme ?? []).length === 0 && movementsAwaitLadder(shaped)) {
        const rungs = written[1].split(/\s*[-–]\s*/).map(Number);
        shaped = { ...shaped, repScheme: rungs, repSchemeContinues: true, roundCount: 0 };
      }
      const rungs = shaped.repScheme ?? [];
      if (!shaped.repSchemeContinues || rungs.length < 2) return shaped;
      const quoted = new RegExp(`${rungs[0]}\\s*[-–,]\\s*${rungs[1]}`);
      return quoted.test(shaped.notes ?? "") ? { ...shaped, notes: "" } : shaped;
    }),
  };
}

/** An open ladder as the note form 2 carried it: "Ladder 1-2-3-4-5-6-…". */
const ladderNote = (rungs) => `Ladder ${rungs.join("-")}-…`;

/**
 * Shapes a board for the form the caller reads.
 *
 * Form 3 added `repSchemeContinues`: a build below it would expand the open ladder
 * into a closed one and stop at its last rung, so the ladder goes back into the notes.
 * Form 2 added `runBeforeEachMeters`: a build on form 1 would drop the run, so the
 * run is written out before every station, which is what form 1 always carried.
 */
function boardForForm(board, formVersion) {
  if (formVersion >= CURRENT_FORM) return board;
  return {
    ...board,
    sections: board.sections.map((section) => {
      let shaped = { ...section };
      if (formVersion < 3) {
        if (shaped.repSchemeContinues) {
          const note = ladderNote(shaped.repScheme);
          shaped = { ...shaped, repScheme: [], notes: shaped.notes ? `${note}; ${shaped.notes}` : note };
        }
        shaped.repSchemeContinues = false;
      }
      if (formVersion < 2) {
        const meters = shaped.runBeforeEachMeters;
        if (meters > 0) {
          shaped.movements = shaped.movements.flatMap((station) => [runMovement(meters), station]);
        }
        shaped.runBeforeEachMeters = 0;
      }
      return shaped;
    }),
  };
}

module.exports = { boardForForm, withLadderInItsField, CURRENT_FORM };
