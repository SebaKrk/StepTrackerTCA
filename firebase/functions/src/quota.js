"use strict";

const { getFirestore } = require("firebase-admin/firestore");
const { HttpsError } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");

const COLLECTION = "scanQuota";
const GLOBAL_DOC = "_global";

// The day the counters reset on. A fixed zone, decided here rather than on the
// phone: a device clock set to another zone would otherwise hand out extra days.
const TIME_ZONE = "Europe/Warsaw";

/** What one free account gets per day, per feature. Raising a tier raises these. */
const LIMITS = { scan: 2, note: 3 };

/**
 * Calls the whole app may make in one day, across every user.
 *
 * The last line of defence: automatic top-up covers normal growth, this covers a
 * viral morning, a retry loop and a bug. Reached, it fails before calling the API.
 *
 * Set per project in `.env.<project-id>`; the default is the production ceiling.
 */
const GLOBAL_DAILY_CALLS = Number(process.env.GLOBAL_DAILY_CALLS) || 2000;

/** Today in `TIME_ZONE` as `YYYY-MM-DD`; `sv-SE` formats dates ISO-style. */
const dayKey = (date) =>
  new Intl.DateTimeFormat("sv-SE", { timeZone: TIME_ZONE, year: "numeric", month: "2-digit", day: "2-digit" }).format(date);

/** Epoch millis of the next local midnight, walked hour by hour so DST needs no special case. */
function nextResetAt(now) {
  const today = dayKey(now);
  const cursor = new Date(now.getTime());
  for (let hour = 0; hour < 48; hour += 1) {
    cursor.setTime(cursor.getTime() + 3_600_000);
    if (dayKey(cursor) !== today) {
      cursor.setUTCMinutes(0, 0, 0);
      return cursor.getTime();
    }
  }
  return now.getTime() + 86_400_000;
}

/**
 * Takes one unit of today's allowance for `feature`, or throws.
 *
 * Reserved before the model is called and released when the call fails, so an
 * outage on our side never costs the user their free scan.
 */
async function reserve(uid, feature, now = new Date()) {
  const db = getFirestore();
  const today = dayKey(now);
  const limit = LIMITS[feature];

  const userRef = db.collection(COLLECTION).doc(uid);
  const globalRef = db.collection(COLLECTION).doc(GLOBAL_DOC);

  return db.runTransaction(async (transaction) => {
    const [userSnapshot, globalSnapshot] = await transaction.getAll(userRef, globalRef);

    const user = userSnapshot.exists && userSnapshot.data().day === today ? userSnapshot.data() : { day: today };
    const global = globalSnapshot.exists && globalSnapshot.data().day === today ? globalSnapshot.data() : { day: today, calls: 0 };

    if ((global.calls ?? 0) >= GLOBAL_DAILY_CALLS) {
      logger.error("global daily cap reached", { calls: global.calls, day: today });
      throw new HttpsError("unavailable", "service-unavailable");
    }

    const used = user[feature] ?? 0;
    if (used >= limit) {
      throw new HttpsError("resource-exhausted", "daily-limit-reached", {
        used,
        limit,
        resetsAt: nextResetAt(now),
      });
    }

    transaction.set(userRef, { ...user, [feature]: used + 1 }, { merge: true });
    transaction.set(globalRef, { day: today, calls: (global.calls ?? 0) + 1 }, { merge: true });

    return { used: used + 1, limit, resetsAt: nextResetAt(now) };
  });
}

/** Gives the reserved unit back after a failure that was not the user's doing. */
async function release(uid, feature, now = new Date()) {
  const db = getFirestore();
  const today = dayKey(now);
  const userRef = db.collection(COLLECTION).doc(uid);
  const globalRef = db.collection(COLLECTION).doc(GLOBAL_DOC);

  try {
    await db.runTransaction(async (transaction) => {
      const [userSnapshot, globalSnapshot] = await transaction.getAll(userRef, globalRef);
      if (userSnapshot.exists && userSnapshot.data().day === today) {
        const used = userSnapshot.data()[feature] ?? 0;
        transaction.update(userRef, { [feature]: Math.max(0, used - 1) });
      }
      if (globalSnapshot.exists && globalSnapshot.data().day === today) {
        transaction.update(globalRef, { calls: Math.max(0, (globalSnapshot.data().calls ?? 0) - 1) });
      }
    });
  } catch (error) {
    // A failed release costs the user one scan; failing the request on top of it
    // would tell them nothing more, so this only ever gets logged.
    logger.warn("quota release failed", { uid, feature, message: error.message });
  }
}

module.exports = { reserve, release };
