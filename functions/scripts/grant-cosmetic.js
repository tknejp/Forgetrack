#!/usr/bin/env node
/* eslint-disable no-console */
'use strict';

/**
 * Forgetrack — ops tool for cosmetic entitlements.
 *
 * Writes / lists / revokes entitlement docs under
 * `users/{uid}/cosmeticEntitlements/{cosmeticId}`. The client subscribes
 * to that collection as a live stream (Trello #82, `FirestoreCosmetic
 * EntitlementsSource.watchForUser`) so a grant pushed by this script
 * lands without an app restart.
 *
 * **Auth.** Uses firebase-admin with a service account JSON. Set
 * `GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json`
 * before running, or place `service-account.json` in this folder
 * (covered by `.gitignore`).
 *
 * **Idempotency.** Document ID is the cosmetic id, so re-running
 * `grant` for the same uid + cosmetic is a same-data overwrite.
 *
 * **Usage.**
 *
 *   node functions/scripts/grant-cosmetic.js \
 *       --uid <firebaseUid> \
 *       --cosmetic <cosmeticId> \
 *       [--source promotional] \
 *       [--source-id <free-text-id>] \
 *       [--expires <ISO-8601 timestamp>]
 *
 *   node functions/scripts/grant-cosmetic.js --uid <uid> --revoke <cosmeticId>
 *   node functions/scripts/grant-cosmetic.js --uid <uid> --list
 *
 * Examples:
 *
 *   node functions/scripts/grant-cosmetic.js \
 *       --uid ZolbJyQwpzSuUDsCV09UDwWXgX93 \
 *       --cosmetic frame_pilgrim
 *
 *   node functions/scripts/grant-cosmetic.js \
 *       --uid X --cosmetic banner_aurora --source beta_tester_compensation
 */

const path = require('path');
const fs = require('fs');
const admin = require('firebase-admin');

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i++) {
    const token = argv[i];
    if (!token.startsWith('--')) continue;
    const key = token.slice(2);
    const next = argv[i + 1];
    if (next === undefined || next.startsWith('--')) {
      args[key] = true;
    } else {
      args[key] = next;
      i++;
    }
  }
  return args;
}

function usage() {
  console.log(`
Forgetrack cosmetic-entitlements ops tool.

Grant:
  node functions/scripts/grant-cosmetic.js --uid <uid> --cosmetic <id>
      [--source <type>] [--source-id <id>] [--expires <ISO>]

Revoke:
  node functions/scripts/grant-cosmetic.js --uid <uid> --revoke <id>

List:
  node functions/scripts/grant-cosmetic.js --uid <uid> --list

Required env: GOOGLE_APPLICATION_CREDENTIALS pointing at a service
account JSON, or service-account.json colocated with this script.
`.trim());
}

function initAdmin() {
  if (admin.apps.length > 0) return admin.app();

  const envCreds = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (envCreds && fs.existsSync(envCreds)) {
    return admin.initializeApp({
      credential: admin.credential.cert(require(path.resolve(envCreds))),
    });
  }

  const localCreds = path.join(__dirname, 'service-account.json');
  if (fs.existsSync(localCreds)) {
    return admin.initializeApp({
      credential: admin.credential.cert(require(localCreds)),
    });
  }

  console.error(
    'No service account found. Set GOOGLE_APPLICATION_CREDENTIALS or ' +
    'drop service-account.json into functions/scripts/.',
  );
  process.exit(2);
}

async function listEntitlements(db, uid) {
  const snap = await db
    .collection('users').doc(uid)
    .collection('cosmeticEntitlements')
    .get();
  if (snap.empty) {
    console.log(`No entitlements for uid=${uid}.`);
    return;
  }
  console.log(`Entitlements for uid=${uid}:`);
  snap.docs.forEach((doc) => {
    const d = doc.data();
    const expires = d.expiresAt && typeof d.expiresAt.toDate === 'function'
      ? d.expiresAt.toDate().toISOString()
      : (d.expiresAt || '');
    const active = d.active === false ? ' [inactive]' : '';
    console.log(
      `  ${doc.id}${active}  source=${d.sourceType || d.source || '-'}` +
      `  sourceId=${d.sourceId || '-'}` +
      (expires ? `  expires=${expires}` : ''),
    );
  });
}

async function grant(db, { uid, cosmetic, source, sourceId, expiresIso }) {
  const docRef = db
    .collection('users').doc(uid)
    .collection('cosmeticEntitlements').doc(cosmetic);

  const payload = {
    cosmeticId: cosmetic,
    sourceType: source || 'promotional',
    sourceId: sourceId || `manual_grant_${Date.now()}`,
    active: true,
    grantedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (expiresIso) {
    const expires = new Date(expiresIso);
    if (Number.isNaN(expires.getTime())) {
      console.error(`Invalid --expires value: ${expiresIso}`);
      process.exit(3);
    }
    payload.expiresAt = admin.firestore.Timestamp.fromDate(expires);
  }

  await docRef.set(payload, { merge: true });
  console.log(
    `granted cosmetic=${cosmetic} uid=${uid} source=${payload.sourceType} sourceId=${payload.sourceId}` +
    (expiresIso ? ` expires=${expiresIso}` : ''),
  );
}

async function revoke(db, { uid, cosmetic }) {
  const docRef = db
    .collection('users').doc(uid)
    .collection('cosmeticEntitlements').doc(cosmetic);
  const snap = await docRef.get();
  if (!snap.exists) {
    console.log(`no-op — entitlement not found: uid=${uid} cosmetic=${cosmetic}`);
    return;
  }
  await docRef.delete();
  console.log(`revoked cosmetic=${cosmetic} uid=${uid}`);
}

async function main() {
  const args = parseArgs(process.argv.slice(2));

  if (args.help || (!args.uid && !args.list && !args.cosmetic && !args.revoke)) {
    usage();
    process.exit(args.help ? 0 : 1);
  }

  if (!args.uid) {
    console.error('Missing --uid');
    process.exit(1);
  }

  initAdmin();
  const db = admin.firestore();

  if (args.list) {
    await listEntitlements(db, args.uid);
  } else if (args.revoke) {
    if (typeof args.revoke !== 'string') {
      console.error('Missing cosmetic id after --revoke');
      process.exit(1);
    }
    await revoke(db, { uid: args.uid, cosmetic: args.revoke });
  } else if (args.cosmetic) {
    if (typeof args.cosmetic !== 'string') {
      console.error('Missing cosmetic id after --cosmetic');
      process.exit(1);
    }
    await grant(db, {
      uid: args.uid,
      cosmetic: args.cosmetic,
      source: typeof args.source === 'string' ? args.source : undefined,
      sourceId: typeof args['source-id'] === 'string' ? args['source-id'] : undefined,
      expiresIso: typeof args.expires === 'string' ? args.expires : undefined,
    });
  } else {
    usage();
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('Script failed:', error);
    process.exit(10);
  });
