#!/usr/bin/env node
/*
 * Upload the freshly built internal-flavor APK to Firebase Storage and
 * write the `app_config/latest_internal` Firestore manifest doc.
 * Together these two writes are what the on-device AppUpdateService
 * polls to discover new builds.
 *
 * Invoked from release.ps1 as:
 *   node scripts/publish_internal_build.js \
 *     <version> <buildNumber> <apkPath> <releaseNotesFile> \
 *     <serviceAccountKeyPath> [bucketName]
 *
 * Requirements:
 *   - Node 18+ (globalThis.fetch + node:crypto signing + node:fs streams).
 *   - Service-account JSON with at minimum:
 *       - Storage Object Admin (or Editor) on the Storage bucket
 *       - Cloud Datastore User (or Editor) on the Firestore database
 *     The simplest setup is to grant the SA `Editor` on the project.
 *
 * No `npm install` required — uses Node built-ins only.
 *
 * Exit codes:
 *   0  upload + manifest write both succeeded
 *   2  CLI usage error
 *   3  service-account JSON malformed
 *   4  Google OAuth token exchange failed
 *   5  Storage upload failed
 *   6  Firestore manifest write failed
 *   7  APK file missing or unreadable
 *   8  release notes file missing
 */
'use strict';

const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');

const TOKEN_URL = 'https://oauth2.googleapis.com/token';
const TOKEN_SCOPE = 'https://www.googleapis.com/auth/cloud-platform';

function die(code, message) {
  console.error(`publish_internal_build: ${message}`);
  process.exit(code);
}

function b64url(buf) {
  return Buffer.from(buf)
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

async function getAccessToken(serviceAccount) {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claims = {
    iss: serviceAccount.client_email,
    scope: TOKEN_SCOPE,
    aud: TOKEN_URL,
    iat: now,
    exp: now + 3600,
  };

  const signingInput = `${b64url(JSON.stringify(header))}.${b64url(JSON.stringify(claims))}`;
  const signature = crypto
    .createSign('RSA-SHA256')
    .update(signingInput)
    .sign(serviceAccount.private_key);
  const assertion = `${signingInput}.${b64url(signature)}`;

  const body = new URLSearchParams({
    grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
    assertion,
  });

  const res = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: body.toString(),
  });

  if (!res.ok) {
    const text = await res.text();
    die(4, `OAuth token exchange failed (${res.status}): ${text}`);
  }
  const json = await res.json();
  return json.access_token;
}

async function uploadApk({ bucket, objectName, apkPath, accessToken }) {
  const size = fs.statSync(apkPath).size;
  const url =
    `https://storage.googleapis.com/upload/storage/v1/b/${encodeURIComponent(bucket)}` +
    `/o?uploadType=media&name=${encodeURIComponent(objectName)}`;

  // Stream the file body directly — APK is ~250 MB, buffering into memory
  // would spike RSS unnecessarily. Node 18+ fetch supports a Readable as body
  // when duplex: 'half' is set.
  const stream = fs.createReadStream(apkPath);

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/vnd.android.package-archive',
      'Content-Length': String(size),
    },
    body: stream,
    duplex: 'half',
  });

  if (!res.ok) {
    const text = await res.text();
    die(5, `Storage upload failed (${res.status}): ${text}`);
  }
  const json = await res.json();
  console.log(
    `publish_internal_build: uploaded ${apkPath} → gs://${bucket}/${objectName} (${json.size} bytes)`,
  );
}

async function writeManifest({
  projectId,
  accessToken,
  version,
  buildNumber,
  apkStoragePath,
  notes,
}) {
  const docPath = `projects/${projectId}/databases/(default)/documents/app_config/latest_internal`;
  const url =
    `https://firestore.googleapis.com/v1/${docPath}` +
    `?updateMask.fieldPaths=version` +
    `&updateMask.fieldPaths=buildNumber` +
    `&updateMask.fieldPaths=apkStoragePath` +
    `&updateMask.fieldPaths=notes` +
    `&updateMask.fieldPaths=releasedAt`;

  const body = {
    fields: {
      version: { stringValue: version },
      buildNumber: { integerValue: String(buildNumber) },
      apkStoragePath: { stringValue: apkStoragePath },
      notes: { stringValue: notes },
      releasedAt: { timestampValue: new Date().toISOString() },
    },
  };

  const res = await fetch(url, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const text = await res.text();
    die(6, `Firestore manifest PATCH failed (${res.status}): ${text}`);
  }
  console.log(
    `publish_internal_build: manifest written ${docPath.replace(/^projects\/[^/]+\/databases\/[^/]+\/documents\//, '')}`,
  );
}

async function main() {
  const [, , version, buildNumber, apkPath, releaseNotesFile, keyPath, bucketArg] =
    process.argv;
  if (!version || !buildNumber || !apkPath || !releaseNotesFile || !keyPath) {
    die(
      2,
      'usage: node scripts/publish_internal_build.js <version> <buildNumber> <apkPath> <releaseNotesFile> <serviceAccountKeyPath> [bucketName]',
    );
  }

  if (!fs.existsSync(apkPath)) {
    die(7, `APK not found at "${apkPath}"`);
  }
  if (!fs.existsSync(releaseNotesFile)) {
    die(8, `release notes file not found at "${releaseNotesFile}"`);
  }
  if (!fs.existsSync(keyPath)) {
    die(3, `service-account key not found at "${keyPath}"`);
  }

  let serviceAccount;
  try {
    serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
  } catch (e) {
    die(3, `failed to read service-account JSON: ${e.message}`);
  }
  if (
    !serviceAccount.client_email ||
    !serviceAccount.private_key ||
    !serviceAccount.project_id
  ) {
    die(3, 'service-account JSON missing client_email / private_key / project_id');
  }

  // Default bucket follows the newer Firebase Storage naming convention
  // (`<projectId>.firebasestorage.app`). Older projects created before
  // 2024 may still be on `<projectId>.appspot.com`; pass the legacy
  // bucket name as the 6th CLI arg in that case.
  const bucket = bucketArg || `${serviceAccount.project_id}.firebasestorage.app`;
  const objectName = `internal-builds/forgetrack-${version}-${buildNumber}.apk`;
  const notes = fs.readFileSync(releaseNotesFile, 'utf8').trim();

  const accessToken = await getAccessToken(serviceAccount);

  await uploadApk({ bucket, objectName, apkPath, accessToken });
  await writeManifest({
    projectId: serviceAccount.project_id,
    accessToken,
    version,
    buildNumber: Number(buildNumber),
    apkStoragePath: objectName,
    notes,
  });

  console.log('publish_internal_build: done');
}

main().catch((e) => {
  die(5, `unexpected: ${e.stack || e.message || e}`);
});
