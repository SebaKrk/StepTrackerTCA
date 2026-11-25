"use strict";

const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");

const { dayKey, COLLECTION: QUOTA_COLLECTION } = require("./quota");

// One document per day, named by the day. It holds totals only and no account id.
const COLLECTION = "scanStats";

/**
 * Adds one finished call to today's sheet: the call, its tokens and, the first
 * time an account gets an answer today, the account.
 *
 * Runs after the model answered, so a failed call never shows up here and there
 * is nothing to take back. `now` is the moment the allowance was taken, so a call
 * that crosses midnight is counted on the day it was charged to.
 */
async function recordCall(uid, feature, usage, now) {
  const db = getFirestore();
  const today = dayKey(now);
  const userRef = db.collection(QUOTA_COLLECTION).doc(uid);
  const statsRef = db.collection(COLLECTION).doc(today);

  try {
    await db.runTransaction(async (transaction) => {
      const userSnapshot = await transaction.get(userRef);
      // No row means the account was erased while the call ran; writing one back would undo that.
      // A later day means a newer call got here first; ISO days compare as text.
      const countedDay = userSnapshot.data()?.statsDay ?? "";
      const isNewToday = userSnapshot.exists && countedDay < today;

      // A day rather than a flag: the quota row is merged, never replaced, so a flag would outlive its day.
      if (isNewToday) transaction.set(userRef, { statsDay: today }, { merge: true });
      transaction.set(
        statsRef,
        {
          day: today,
          [feature]: FieldValue.increment(1),
          [`${feature}TokensIn`]: FieldValue.increment(usage.inputTokens),
          [`${feature}TokensOut`]: FieldValue.increment(usage.outputTokens),
          users: FieldValue.increment(isNewToday ? 1 : 0),
        },
        { merge: true }
      );
    });
  } catch (error) {
    // The user already has their answer; a lost tally must not turn it into an error.
    logger.warn("stats write failed", { feature, message: error.message });
  }
}

/** Counts one call turned away by the daily allowance. */
async function recordLimitHit(feature, now) {
  const today = dayKey(now);
  try {
    await getFirestore()
      .collection(COLLECTION)
      .doc(today)
      .set({ day: today, [`${feature}LimitHits`]: FieldValue.increment(1) }, { merge: true });
  } catch (error) {
    logger.warn("stats write failed", { feature, message: error.message });
  }
}

module.exports = { recordCall, recordLimitHit, COLLECTION };
