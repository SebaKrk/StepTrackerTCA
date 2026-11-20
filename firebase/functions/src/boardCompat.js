"use strict";

/** Newest board form the proxy writes; a caller names the form it reads in `formVersion`. */
const CURRENT_FORM = 2;

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

/**
 * Shapes a board for the form the caller reads.
 *
 * Form 1 has no `runBeforeEachMeters`: a build on it would drop the run, so the
 * run is written out before every station, which is what form 1 always carried.
 */
function boardForForm(board, formVersion) {
  if (formVersion >= CURRENT_FORM) return board;
  return {
    ...board,
    sections: board.sections.map((section) => {
      const meters = section.runBeforeEachMeters;
      if (!(meters > 0)) return { ...section, runBeforeEachMeters: 0 };
      return {
        ...section,
        runBeforeEachMeters: 0,
        movements: section.movements.flatMap((station) => [runMovement(meters), station]),
      };
    }),
  };
}

module.exports = { boardForForm, CURRENT_FORM };
