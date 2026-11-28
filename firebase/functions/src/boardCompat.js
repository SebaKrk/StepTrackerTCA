"use strict";

/** Newest board form the proxy writes; a caller names the form it reads in `formVersion`. */
const CURRENT_FORM = 4;

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

/** Format names as a board writes them, for a block put back into text. */
const FORMAT_WORDS = {
  forTime: "For Time",
  amrap: "AMRAP",
  emom: "EMOM",
  deathBy: "Death By",
  tabata: "Tabata",
  intervals: "Intervals",
  roundsUntimed: "Rounds",
  maxEffort: "Max effort",
};

/** A warm-up or cool-down block written out line by line, the way form 3 carried it in text. */
function blockAsText(section) {
  const head = [FORMAT_WORDS[section.format] ?? section.format];
  if (section.roundCount > 0) head.push(`${section.roundCount} rounds`);
  if (section.workSec > 0) head.push(`${section.workSec}/${section.restSec} s`);
  if (section.everySec > 0) head.push(`every ${section.everySec} s`);
  if (section.timeCapMin > 0) head.push(`${section.timeCapMin} min`);
  if ((section.repScheme ?? []).length > 0) head.push(section.repScheme.join("-"));
  const lines = section.movements.map((movement) => {
    const amount = movement.targetValue > 0 ? `${movement.targetValue} ${movement.targetUnit} ` : "";
    return `${amount}${movement.rawName || movement.name}`;
  });
  return [head.join(" "), ...lines].join("\n");
}

/** A warm-up or cool-down section, the only kinds whose content form 3 reads from text. */
const isSideSection = (section) => section.kind === "warmup" || section.kind === "cooldown";

/** A distance or calorie piece, the one kind of side movement that stands as a block without a format word. */
const isDistancePiece = (movement) => ["meters", "km", "calories"].includes(movement.targetUnit) && movement.targetValue > 0;

/** A cap of about twice an easy pace: 10 min per km, 2 cal a minute, never under 3 min. */
const easyCapMinutes = (movement) => {
  const minutes =
    movement.targetUnit === "calories"
      ? movement.targetValue / 2
      : (movement.targetUnit === "km" ? movement.targetValue : movement.targetValue / 1000) * 10;
  return Math.max(3, Math.round(minutes));
};

/**
 * Holds a warm-up or cool-down to what the app can show, whatever the model wrote:
 * a format with no movements becomes plain text; movements with no format become a
 * forTime block when one is a distance or calorie piece, and text lines otherwise,
 * because the app builds a side block only from a format.
 */
function withSideBlocksComplete(board) {
  return {
    ...board,
    sections: board.sections.map((section) => {
      if (!isSideSection(section)) return section;
      if (section.format !== "none") {
        return section.movements.length === 0 ? { ...section, format: "none" } : section;
      }
      if (section.movements.length === 0) return section;
      const piece = section.movements.find(isDistancePiece);
      const lines = section.movements
        .filter((movement) => movement !== piece)
        .map((movement) => {
          const amount = movement.targetValue > 0 ? `${movement.targetValue} ${movement.targetUnit} ` : "";
          return `${amount}${movement.rawName || movement.name}`;
        });
      const text = [section.text, ...lines].filter(Boolean).join("\n");
      if (!piece) return { ...section, text, movements: [] };
      const cap = section.timeCapMin > 0 ? section.timeCapMin : easyCapMinutes(piece);
      return { ...section, text, format: "forTime", movements: [piece], roundCount: 0, repScheme: [], timeCapMin: cap };
    }),
  };
}

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

/** An unequal pair closing a movement's raw name, the way a board prints its load: "Wall Balls 9/6", "@ 22,5/15 kg". */
const TRAILING_PAIR = /[a-z].*?(\d+(?:[.,]\d+)?)\s*\/\s*(\d+(?:[.,]\d+)?)\s*(kg|lb)?\s*$/i;

/** A men / women rep pair written before the name: "21/15 wall balls", "12/9 cal row". */
const LEADING_PAIR = /^\s*\d+(?:[.,]\d+)?\s*\/\s*\d+/;

/** Movements whose trailing pair is a height, calories or distance ("Box jumps 24/20", "Cal Row 15/12"), never a load. */
const NOT_A_LOAD_MOVEMENT = /jump|box|step|\bcal|row|bike|ski|erg|run/i;

const asNumber = (written) => Number(written.replace(",", "."));

/**
 * Keeps a printed load out of the rep fields, whatever the reader did with it.
 *
 * The reader mixes up "21/15 wall balls" (reps) with "Wall Balls 9/6" (a ball weight) and copies a load's
 * women value into targetValueWomen. A pair after the name that sits in the rep fields moves to loads, and a
 * women's rep count equal to the women's load is dropped as that copy.
 */
function withLoadsOutOfReps(board) {
  return {
    ...board,
    sections: board.sections.map((section) => ({
      ...section,
      movements: (section.movements ?? []).map((movement) => {
        const rawName = movement.rawName ?? "";
        const loads = movement.loads ?? [];
        if (loads.length > 0) {
          const copied =
            movement.targetValueWomen > 0 && !LEADING_PAIR.test(rawName) && loads.some((load) => load.women === movement.targetValueWomen);
          return copied ? { ...movement, targetValueWomen: 0 } : movement;
        }
        const pair = TRAILING_PAIR.exec(rawName);
        const countsReps = (movement.targetUnit ?? "reps") === "reps";
        if (!pair || !countsReps || NOT_A_LOAD_MOVEMENT.test(`${rawName} ${movement.name ?? ""}`)) return movement;
        const [men, women] = [asNumber(pair[1]), asNumber(pair[2])];
        if (men === women || movement.targetValue !== men || movement.targetValueWomen !== women) return movement;
        const unit = (pair[3] ?? "kg").toLowerCase();
        return { ...movement, targetValue: 0, targetValueWomen: 0, loads: [{ tier: "rx", men, women, unit }] };
      }),
    })),
  };
}

/** An open ladder as the note form 2 carried it: "Ladder 1-2-3-4-5-6-…". */
const ladderNote = (rungs) => `Ladder ${rungs.join("-")}-…`;

/**
 * Shapes a board for the form the caller reads.
 *
 * Form 4 added a format block to warm-up and cool-down: a build below it reads only their
 * text, so the block is written out in text and its format and movements are cleared.
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
      if (formVersion < 4 && isSideSection(shaped) && shaped.format !== "none" && shaped.movements.length > 0) {
        const block = blockAsText(shaped);
        shaped = { ...shaped, text: !shaped.text ? block : shaped.kind === "cooldown" ? `${block}\n${shaped.text}` : `${shaped.text}\n${block}`, format: "none", movements: [] };
      }
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

module.exports = { boardForForm, withLadderInItsField, withLoadsOutOfReps, withSideBlocksComplete, CURRENT_FORM };
