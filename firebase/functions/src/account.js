"use strict";

const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");

const { COLLECTION: QUOTA_COLLECTION } = require("./quota");

// A batch holds 500 writes; staying under it leaves room for the caller's own.
const BATCH_SIZE = 400;

/**
 * Erases everything stored under one account, then the account itself.
 *
 * Runs with admin rights on purpose: the rules let a member delete only their
 * own documents, and the scan allowance cannot be written from a phone at all.
 * Every step is safe to repeat, so a run that failed halfway is finished by the
 * next call; the account goes last, because without it there is no next call.
 */
async function deleteAccountData(uid) {
  const db = getFirestore();
  let groupsLeft = 0;
  let groupsDeleted = 0;

  const memberships = await db.collectionGroup("members").where("uid", "==", uid).get();
  for (const membership of memberships.docs) {
    const group = membership.ref.parent.parent;
    if (!group) continue;
    if (await leaveGroup(db, group, uid)) {
      groupsDeleted += 1;
    } else {
      groupsLeft += 1;
    }
  }

  // Invites scanned for groups never joined have no membership leading to them.
  // Ordered the way the phone asks, so the index it already uses serves this too.
  const scans = await db.collectionGroup("recipients").where("uid", "==", uid).orderBy("scannedAt", "desc").get();
  await deleteAll(db, scans.docs.map((doc) => doc.ref));

  await db.collection(QUOTA_COLLECTION).doc(uid).delete();
  await deleteUser(uid);

  logger.info("account data deleted", { groupsLeft, groupsDeleted });
  return { groupsLeft, groupsDeleted };
}

/**
 * Takes one member out of one group; returns true when the group went with them.
 *
 * Other people's data is never the price: a group with anyone else in it stays,
 * and an owner hands it to whoever has been a member longest.
 */
async function leaveGroup(db, group, uid) {
  const [snapshot, members] = await Promise.all([
    group.get(),
    group.collection("members").orderBy("joinedAt").get(),
  ]);
  const others = members.docs.filter((member) => member.id !== uid);

  if (others.length === 0) {
    await db.recursiveDelete(group);
    return true;
  }

  const plans = await group.collection("plans").get();
  await deleteAll(db, plans.docs.map((plan) => plan.ref.collection("entries").doc(uid)));

  // A plan belongs to the group once published; only the author's name leaves it.
  const authored = plans.docs.filter((plan) => plan.get("authorUid") === uid);
  await updateAll(db, authored.map((plan) => plan.ref), { authorUid: "", authorName: "" });

  // An invite carries its creator's name and exists only to be scanned.
  const invites = await group.collection("invites").where("createdByUid", "==", uid).get();
  for (const invite of invites.docs) {
    await db.recursiveDelete(invite.ref);
  }

  const update = { memberCount: FieldValue.increment(-1) };
  if (snapshot.get("ownerUid") === uid) {
    update.ownerUid = others[0].id;
  }
  if (authored.some((plan) => plan.id === snapshot.get("lastPlan.day"))) {
    update["lastPlan.authorName"] = "";
  }

  const batch = db.batch();
  batch.delete(group.collection("members").doc(uid));
  batch.update(group, update);
  await batch.commit();
  return false;
}

async function deleteAll(db, refs) {
  for (let start = 0; start < refs.length; start += BATCH_SIZE) {
    const batch = db.batch();
    refs.slice(start, start + BATCH_SIZE).forEach((ref) => batch.delete(ref));
    await batch.commit();
  }
}

async function updateAll(db, refs, data) {
  for (let start = 0; start < refs.length; start += BATCH_SIZE) {
    const batch = db.batch();
    refs.slice(start, start + BATCH_SIZE).forEach((ref) => batch.update(ref, data));
    await batch.commit();
  }
}

/** An account already gone is the outcome asked for, not a failure. */
async function deleteUser(uid) {
  try {
    await getAuth().deleteUser(uid);
  } catch (error) {
    if (error.code !== "auth/user-not-found") throw error;
  }
}

module.exports = { deleteAccountData };
